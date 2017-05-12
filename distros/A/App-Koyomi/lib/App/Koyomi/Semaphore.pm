package App::Koyomi::Semaphore;

use strict;
use warnings;
use 5.010_001;
use Class::Accessor::Lite (
    ro => [qw/ctx data/],
);
use DateTime;
use DateTime::Format::MySQL;
use Log::Minimal env_debug => 'KOYOMI_LOG_DEBUG';
use Smart::Args;
use Sys::Hostname;

use version; our $VERSION = 'v0.6.0';

sub consume {
    args(
        my $class,
        my $job_id => 'Int',
        my $now    => +{ isa => 'DateTime', optional => 1 },
        my $ctx    => 'App::Koyomi::Context',
    );
    my $ds = $ctx->datasource_semaphore;
    if ($ds->isa('App::Koyomi::DataSource::Semaphore::None')) {
        return 1;
    }

    $now ||= $ctx->now;
    my $header = sprintf('%d %d', $$, $job_id);

    my $semaphore = $ds->get_by_job_id(
        job_id => $job_id,
        ctx    => $ctx,
    );
    unless ($semaphore) {
        critf(q/%s Not found semaphore data!/, $header);
        return;
    }

    my $ttl = $ctx->config->{job}{lock_ttl_seconds};
    debugf(q/now:%d semaphore:%d diff:%d/, $now->epoch, $semaphore->run_date->epoch, $now->epoch - $semaphore->run_date->epoch);
    if ($now->epoch - $semaphore->run_date->epoch < $ttl) {
        debugf(
            q/%s run on another proc. Host=%s, Pid=%d, Run_On='%s'/,
            $header, $semaphore->run_host, $semaphore->run_pid, $semaphore->run_date->datetime
        );
        return;
    }

    my $ret = $semaphore->update_with_condition(
        data => +{
            run_host => hostname,
            run_pid  => $$,
            run_date => $now,
        },
        where => +{
            run_date => $semaphore->run_date,
        },
        ctx => $ctx,
    );

    unless ($ret) {
        warnf(q/%s Failed to update semaphore; Probably another process got lock./, $header);
    }

    return $ret;
}

1;

__END__

=encoding utf8

=head1 NAME

B<App::Koyomi::Semaphore> - koyomi semaphore

=head1 SYNOPSIS

    use App::Koyomi::Semaphore;
    if (App::Koyomi::Semaphore->consume(%args)) {
        # Succeeded to consume semaphore
    } else {
        # Failed to consume semaphore
    }

=head1 DESCRIPTION

This module represents semaphore for exclusive job execution.

=head1 METHODS

=over 4

=item B<consume>

Try to consume semaphore.
Return true when successful.

=back

=head1 AUTHORS

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015 YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

