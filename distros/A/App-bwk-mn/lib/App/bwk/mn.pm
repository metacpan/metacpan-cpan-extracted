package App::bwk::mn;

our $DATE = '2019-07-22'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use IPC::System::Options qw(system readpipe);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Some commands to manage Bulwark masternode',
};

$SPEC{status} = {
    v => 1.1,
    summary => 'bulwark-cli getblockcount + masternode status',
    description => <<'_',

This is mostly just a shortcut for running `bulwark-cli getblockcount` and
`bulwark-cli masternode status`.

_
    args => {
    },
    deps => {
        prog => 'bulwark-cli',
    },
};
sub status {
    my %args = @_;

    system({log=>1}, "bulwark-cli", "getblockcount");
    system({log=>1}, "bulwark-cli", "masternode", "status");
    [200];
}

sub __zfs_list_snapshots {
    my %res;
    for (`zfs list -t snapshot -H`) {
        chomp;
        my @row = split /\t/, $_;
        $row[0] =~ m!(.+?)/(.+?)@(.+)!;
        $res{$row[0]} = {
            full_name => $row[0],
            pool => $1,
            fs => $2,
            snapshot_name => $3,
            used => $row[1],
            avail => $row[2],
            refer => $row[3],
            mountpoint => $row[4],
        };
    }
    \%res;
}

sub _newest_bulwark_zfs_snapshots {
    my $picked_snapshot;
    my $snapshot_date;
    my $picked_s;
    my $snapshots = __zfs_list_snapshots();
    for my $full_name (keys %$snapshots) {
        unless ($full_name =~ /bwk|bulwark/i) {
            log_trace "Snapshot '$full_name' does not have bwk|bulwark in its name, skipped";
            next;
        }
        my $s = $snapshots->{$full_name};
        unless ($s->{snapshot_name} =~ /\A(\d{4})-(\d{2})-(\d{2})/) {
            log_trace "Snapshot '$full_name' is not named using YYYY-MM-DD format, skipped";
            next;
        }
        if (!$picked_snapshot || $snapshot_date lt $s->{snapshot_name}) {
            $s->{date} = "$1-$2-$3";
            $picked_s = $s;
            $picked_snapshot = $full_name;
            $snapshot_date = $s->{snapshot_name};
        }
    }
    unless ($picked_snapshot) {
        return [412, "Cannot find any suitable ZFS snapshot"];
    }
    [200, "OK", $picked_snapshot, {"func.all_snapshots"=>$snapshots, "func.raw"=>$picked_s}];
}

$SPEC{restore_from_zfs_snapshot} = {
    v => 1.1,
    summary => 'Restore broken installation from ZFS snapshot',
    description => <<'_',

This subcommand will:

1. stop bulwarkd
2. rollback to a specific ZFS snapshot
3. restart bulwarkd again
4. wait until node is fully sync-ed (not yet implemented)

For this to work, a specific setup is required. First, at least the `blocks/`
and `chainstate` directory are put in a ZFS filesystem (this part is assumed and
not checked) and a snapshot of that filesytem has been made. The ZFS filesystem
needs to have "bulwark" or "bwk" as part of its name, and the snapshot must be
named using YYYY-MM-DD. The most recent snapshot will be selected.

Rationale: as of this writing (2019-07-22, Bulwark version 2.2.0.0) a Bulwark
masternode still from time to time gets corrupted with this message in the
`debug.log`:

    2019-07-22 02:30:17 ERROR: VerifyDB() : *** irrecoverable inconsistency in block data at xxxxxx, hash=xxxxxxxx

(It used to happen more often prior to 2.1.0 release, and less but still happens
from time to time since 2.1.0.)

Resync-ing from scratch will take at least 1-2 hours, and if this happens on
each masternode every few days then resync-ing will waste a lot of time. Thus
the ZFS snapshot. Snapshots will of course need to be created regularly for this
setup to benefit.

_
    args => {
    },
    deps => {
        all => [
            {prog => 'systemctl'},
            {prog => 'bulwark-cli'},
            {prog => 'zfs'},
        ],
    },
};
sub restore_from_zfs_snapshot {
    my %args = @_;

    my $res = _newest_bulwark_zfs_snapshots();
    return $res unless $res->[0] == 200;

    my $newest;

    system({log=>1, die=>1}, "systemctl", "stop", "bulwarkd");

    system({log=>1, die=>1}, "zfs", "rollback", $res->[2]);

    system({log=>1, die=>1}, "systemctl", "start", "bulwarkd");

    # TODO: wait until fully sync-ed

    [200];
}

$SPEC{new_zfs_snapshot} = {
    v => 1.1,
    summary => 'Create a new ZFS snapshot',
    description => <<'_',

This subcommand will:

1. stop bulwarkd
2. create a new ZFS snapshot
3. restart bulwarkd again

See `restore_from_zfs_snapshot` for more details.

_
    args => {
    },
    deps => {
        all => [
            {prog => 'systemctl'},
            {prog => 'bulwark-cli'},
            {prog => 'zfs'},
        ],
    },
};
sub new_zfs_snapshot {
    require DateTime;

    my %args = @_;

    my $res = _newest_bulwark_zfs_snapshots();
    return $res unless $res->[0] == 200;
    my $snapshots = $res->[3]{'func.all_snapshots'};
    my $s = $res->[3]{'func.raw'};

    my $today = DateTime->now->ymd;
    my $new_snapshot;
    my $i = 0;
    while (1) {
        $new_snapshot = sprintf(
            "%s/%s\@%s%s",
            $s->{pool}, $s->{fs},
            $today,
            $i++ ? sprintf("_%03d", $i) : "",
        );
        last unless $snapshots->{$new_snapshot};
    }

    system({log=>1, die=>1}, "systemctl", "stop", "bulwarkd");

    system({log=>1, die=>1}, "zfs", "snapshot", $new_snapshot);

    system({log=>1, die=>1}, "systemctl", "start", "bulwarkd");

    # TODO: wait until fully sync-ed

    [200];
}

1;
# ABSTRACT: Some commands to manage Bulwark masternode

__END__

=pod

=encoding UTF-8

=head1 NAME

App::bwk::mn - Some commands to manage Bulwark masternode

=head1 VERSION

This document describes version 0.001 of App::bwk::mn (from Perl distribution App-bwk-mn), released on 2019-07-22.

=head1 SYNOPSIS

Please see included script L<bwk-mn>.

=head1 FUNCTIONS


=head2 new_zfs_snapshot

Usage:

 new_zfs_snapshot() -> [status, msg, payload, meta]

Create a new ZFS snapshot.

This subcommand will:

=over

=item 1. stop bulwarkd

=item 2. create a new ZFS snapshot

=item 3. restart bulwarkd again

=back

See C<restore_from_zfs_snapshot> for more details.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 restore_from_zfs_snapshot

Usage:

 restore_from_zfs_snapshot() -> [status, msg, payload, meta]

Restore broken installation from ZFS snapshot.

This subcommand will:

=over

=item 1. stop bulwarkd

=item 2. rollback to a specific ZFS snapshot

=item 3. restart bulwarkd again

=item 4. wait until node is fully sync-ed (not yet implemented)

=back

For this to work, a specific setup is required. First, at least the C<blocks/>
and C<chainstate> directory are put in a ZFS filesystem (this part is assumed and
not checked) and a snapshot of that filesytem has been made. The ZFS filesystem
needs to have "bulwark" or "bwk" as part of its name, and the snapshot must be
named using YYYY-MM-DD. The most recent snapshot will be selected.

Rationale: as of this writing (2019-07-22, Bulwark version 2.2.0.0) a Bulwark
masternode still from time to time gets corrupted with this message in the
C<debug.log>:

 2019-07-22 02:30:17 ERROR: VerifyDB() : *** irrecoverable inconsistency in block data at xxxxxx, hash=xxxxxxxx

(It used to happen more often prior to 2.1.0 release, and less but still happens
from time to time since 2.1.0.)

Resync-ing from scratch will take at least 1-2 hours, and if this happens on
each masternode every few days then resync-ing will waste a lot of time. Thus
the ZFS snapshot. Snapshots will of course need to be created regularly for this
setup to benefit.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 status

Usage:

 status() -> [status, msg, payload, meta]

bulwark-cli getblockcount + masternode status.

This is mostly just a shortcut for running C<bulwark-cli getblockcount> and
C<bulwark-cli masternode status>.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-bwk-mn>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-bwk-mn>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-bwk-mn>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<cryp-mn> from L<App::cryp::mn>

Other C<App::cryp::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
