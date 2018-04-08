package App::Koyomi::Job;

use strict;
use warnings;
use 5.010_001;
use Class::Accessor::Lite (
    ro => [qw/ctx times/],
);
use DateTime;
use IPC::Cmd;
use Log::Minimal env_debug => 'KOYOMI_LOG_DEBUG';
use Smart::Args;

use App::Koyomi::Semaphore;

use version; our $VERSION = 'v0.6.1';

our @JOB_FIELDS  = qw/id user command memo created_on updated_at/;
our @TIME_FIELDS = qw/id job_id year month day hour minute weekday created_on updated_at/;

{
    no strict 'refs';
    for my $field (@JOB_FIELDS) {
        *{ __PACKAGE__ . '::' . $field } = sub {
            my $self = shift;
            $self->{_data}->$field;
        };
    }
}

sub new {
    my $class = shift;
    return bless +{}, $class;
}

sub get_jobs {
    args(
        my $class,
        my $ctx => 'App::Koyomi::Context',
    );
    my @data = $ctx->datasource_job->gets(ctx => $ctx);
    my @jobs;
    for my $d (@data) {
        my $job = bless +{
            ctx   => $ctx,
            _data => $d,
            times => $d->times,
        }, $class;
        debugf(q/(id,user,command) = (%d,%s,"%s")/, $job->id, $job->user || '<NULL>', $job->command);
        push(@jobs, $job);
    }
    return \@jobs;
}

sub proceed {
    my $self = shift;
    my $now  = shift // $self->ctx->now;

    my $header = sprintf(q/%d %d/, $$, $self->id);
    unless ($self->_get_lock(now => $now)) {
        infof(q/%s Failed to get lock. Quit./, $header);
        return;
    }

    my $user = $self->user || $self->_proc_user;
    infof(q/%s USER=%s COMMAND="%s"/, $header, $user, $self->command_to_exec);
    my ($ok, $err, undef, $stdout, $stderr) = IPC::Cmd::run(command => $self->command_to_exec);
    if ($ok) {
        infof(q/%s Succeeded./, $header);
        if (scalar(@$stdout)) {
            infof(q/%s ===== STDOUT =====/, $header);
            infof(q/%s %s/, $header, $_) for @$stdout;
        }
        if (scalar(@$stderr)) {
            infof(q/%s ===== STDERR =====/, $header);
            infof(q/%s %s/, $header, $_) for @$stderr;
        }
    } else {
        critf(q/%d Failed!!/, $self->id);
        critf(q/%d ERROR=%s/, $self->id, $err);
        if (scalar(@$stdout)) {
            critf(q/%d ===== STDOUT =====/, $self->id);
            critf(q/%d %s/, $self->id, $_) for @$stdout;
        }
        if (scalar(@$stderr)) {
            critf(q/%d ===== STDERR =====/, $self->id);
            critf(q/%d %s/, $self->id, $_) for @$stderr;
        }
    }
}

sub command_to_exec {
    my $self = shift;
    return ($self->user && $self->user ne $self->_proc_user)
        ? sprintf('sudo -u %s %s', $self->user, $self->command)
        : $self->command;
}

sub _proc_user {
    my $self = shift;
    return
        $ENV{USER} || $ENV{LOGNAME} || getlogin() || getpwuid($<)
            || croakf(q/Can't get user of process! id=%d/, $self->id);
}

sub _get_lock {
    args(
        my $self,
        my $now => +{ isa => 'DateTime', optional => 1 },
    );
    $now ||= $self->ctx->now;

    return App::Koyomi::Semaphore->consume(
        job_id => $self->id,
        now    => $now,
        ctx    => $self->ctx,
    );
}

1;

__END__

=encoding utf8

=head1 NAME

B<App::Koyomi::Job> - koyomi job

=head1 SYNOPSIS

    use App::Koyomi::Job;
    my $job = App::Koyomi::Job->new;

=head1 DESCRIPTION

This module represents job object.

=head1 METHODS

=over 4

=item B<new>

Construction.

=item B<proceed>

Execute job.

=back

=head1 AUTHORS

IKEDA Kiyoshi E<lt>progrhyme@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015-2017 IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

