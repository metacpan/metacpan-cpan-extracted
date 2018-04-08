package App::Koyomi::CLI;

use strict;
use warnings;
use 5.010_001;
use Class::Accessor::Lite (
    ro => [qw/ctx/],
);
use File::Temp qw(tempfile);
use Getopt::Long qw(:config posix_default no_ignore_case no_ignore_case_always);
use IO::Prompt::Tiny qw(prompt);
use Log::Minimal env_debug => 'KOYOMI_LOG_DEBUG';
use Perl6::Slurp;
use Smart::Args;
use Text::ASCIITable;
use Text::Diff ();
use YAML::XS ();

use App::Koyomi::Context;
use App::Koyomi::JobTime::Formatter qw(str2time);
use App::Koyomi::JobTime::Object;

use version; our $VERSION = 'v0.6.1';

my @CLI_METHODS = qw/help man add list modify delete/;

sub new {
    args(
        my $class,
        my $config => +{ isa => 'Str',  optional => 1 },
        my $debug  => +{ isa => 'Bool', optional => 1 },
    );
    $ENV{KOYOMI_CONFIG_PATH} = $config if $config;
    $ENV{KOYOMI_LOG_DEBUG}   = 1       if $debug;

    my $ctx   = App::Koyomi::Context->instance;
    return bless +{ ctx => $ctx }, $class;
}

sub parse_args {
    my $class  = shift;
    my $method = shift or return;
    my @args   = @_;

    unless (grep { $_ eq $method } @CLI_METHODS) {
        warnf('No such method:%s', $method);
        return;
    }

    Getopt::Long::GetOptionsFromArray(
        \@args, \my %opt, 'config|c=s',
        'job-id|id=i', 'editor|e=s', 'debug|d'
    );
    my %cmd_args;
    $cmd_args{job_id} = $opt{'job-id'} if $opt{'job-id'};
    $cmd_args{editor} = $opt{editor}   if $opt{editor};

    my %property = ();
    for my $key (qw/config debug/) {
        $property{$key} = $opt{$key} if $opt{$key};
    }
    return ($method, \%property, \%cmd_args);
}

sub add {
    args(
        my $self,
        my $editor => +{ isa => 'Str', default => $ENV{EDITOR} || 'vi' },
    );

    my $ctx = $self->ctx;

    my %t = map { $_ => '*' } qw/year month day hour minute weekday/;
    my $time = App::Koyomi::JobTime::Object->new(\%t);
    my %data = (
        user    => q{},
        command => q{},
        memo    => q{},
        times   => [ $time->time2str ],
    );
    my $yaml = YAML::XS::Dump(\%data);

    my ($fh, $tempfile) = tempfile();
    print $fh $yaml;
    print $fh _yaml_description();
    close $fh;
    system($editor, $tempfile);
    my $new_yaml = slurp($tempfile);
    unlink $tempfile;

    my $new_data = YAML::XS::Load($new_yaml);
    print YAML::XS::Dump($new_data) . "\n";
    my @new_times = map { str2time($_) } @{$new_data->{times}};
    $new_data->{times} = \@new_times;

    if (prompt('Add this job. OK? (y/n)', 'n') ne 'y') {
        infof('[add] Canceled.');
        return;
    }

    $ctx->datasource_job->create(data => $new_data, ctx => $ctx);

    infof('[add] Finished.');
}

sub list {
    my $self = shift;

    my @job_cols  = qw/id user command/;
    my @time_cols = qw/Y m d H M weekday/;
    my $t = Text::ASCIITable->new();
    $t->setCols(@job_cols, @time_cols);

    my @time_keys = qw/year month day hour minute weekday/;

    my $ctx  = $self->ctx;
    my @jobs = $ctx->datasource_job->gets(ctx => $ctx);
    for my $job (@jobs) {
        my @job_row = map { $job->$_ } @job_cols;
        for my $time (@{$job->times}) {
            my @row = (@job_row, map { $time->$_ } @time_keys);
            $t->addRow(@row);
        }
    }

    print $t->draw;
}

sub modify {
    args(
        my $self,
        my $job_id => 'Int',
        my $editor => +{ isa => 'Str', default => $ENV{EDITOR} || 'vi' },
    );

    my $ctx = $self->ctx;
    my $job = $ctx->datasource_job->get_by_id(
        id  => $job_id,
        ctx => $ctx
    );
    croakf(q/No such job! id=%d/, $job_id) unless $job;

    my %data = (
        user    => $job->user || q{},
        command => $job->command,
        memo    => $job->memo,
    );

    my @times = map { $_->time2str } @{$job->times};
    $data{times} = \@times;

    my $yaml = YAML::XS::Dump(\%data);

    my ($fh, $tempfile) = tempfile();
    print $fh $yaml;
    print $fh _yaml_description();
    close $fh;
    system($editor, $tempfile);
    my $new_yaml = slurp($tempfile);
    unlink $tempfile;

    my $new_data = YAML::XS::Load($new_yaml);
    $new_yaml = YAML::XS::Dump($new_data);
    print Text::Diff::diff(\$yaml, \$new_yaml, +{ STYLE => 'Unified', CONTEXT => 5 });

    my @new_times = map { str2time($_) } @{$new_data->{times}};
    $new_data->{times} = \@new_times;

    if (prompt('Modify a job. OK? (y/n)', 'n') ne 'y') {
        infof('[modify] Canceled.');
        return;
    }

    $ctx->datasource_job->update_by_id(
        id => $job_id, data => $new_data, ctx => $ctx
    );

    infof('[modify] Finished.');
}

sub delete {
    args(
        my $self,
        my $job_id => 'Int',
    );

    my $ctx = $self->ctx;
    my $job = $ctx->datasource_job->get_by_id(
        id  => $job_id,
        ctx => $ctx
    );
    croakf(q/No such job! id=%d/, $job_id) unless $job;

    my %data = (
        user    => $job->user || q{},
        command => $job->command,
        memo    => $job->memo,
    );

    my @times = map { $_->time2str } @{$job->times};
    $data{times} = \@times;

    my $yaml = YAML::XS::Dump(\%data);

    print $yaml . "\n";

    if (prompt('Delete this job. OK? (y/n)', 'n') ne 'y') {
        infof('[delete] Canceled.');
        return;
    }

    $ctx->datasource_job->delete_by_id(id => $job_id, ctx => $ctx);

    infof('[delete] Finished.');
}

sub _yaml_description {
    state $desc = <<'EOS';

# __EOF__
# Format and Description:
#   "command": String. Job as shell command to execute.
#   "memo":    String. You can add comment about the job on this field.
#   "times":   Array. Each entry follows this format:
#     - 'YYYY/mm/dd HH:MM (number of day in week)'
#     Examples:
#       - '2015/*/* 0:0 (7)' ... At 0:00 am every sunday in 2015
#       - '*/*/* *:30 (*)'   ... At 30 minutes after every o'clock
#   "user": String. OS user to execute the command. Leave it blank to execute by the user of worker
EOS
}

1;

__END__

=encoding utf8

=head1 NAME

B<App::Koyomi::CLI> - Koyomi CLI module

=head1 SYNOPSIS

    use App::Koyomi::CLI;
    my ($method, $props, $args) = App::Koyomi::CLI->parse_args(@ARGV);
    App::Koyomi::CLI->new(%$props)->$method(%$args);

=head1 DESCRIPTION

I<Koyomi> CLI module.

=head1 METHODS

=over 4

=item B<new>

Construction.

=item B<add>

Create a job schedule.

=item B<list>

List scheduled jobs.

=item B<modify>

Modify a job schedule.

=item B<delete>

Delete a job schedule.

=back

=head1 SEE ALSO

L<koyomi-cli>,
L<App::Koyomi::Context>

=head1 AUTHORS

IKEDA Kiyoshi E<lt>progrhyme@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015-2017 IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

