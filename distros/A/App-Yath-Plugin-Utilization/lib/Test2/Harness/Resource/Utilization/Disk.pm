package Test2::Harness::Resource::Utilization::Disk;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak/;
use Time::HiRes qw/time/;

use App::Yath::Plugin::Utilization::Units qw/parse_size_or_pct/;

use parent 'Test2::Harness::Runner::Resource';
use Test2::Harness::Util::HashBase qw/<settings <mounts <samples +permanent_broken/;

sub new {
    my $class = shift;
    my $self = bless({@_}, $class);
    $self->init;
    return $self;
}

sub init {
    my $self = shift;

    $self->{+SAMPLES} //= {};

    my $mounts = $self->{+MOUNTS};
    if (!$mounts || !keys %$mounts) {
        my $settings = $self->{+SETTINGS};
        if ($settings && $settings->check_prefix('utilization')) {
            my $list = $settings->utilization->disk_mounts // [];
            my %m;
            for my $entry (@$list) {
                next unless defined $entry && length $entry;
                $entry =~ m{^(/.+?):(.+)\z}
                    or croak "Resource::Disk: bad --disk-mount entry '$entry' (expected /path:THRESHOLD)";
                my ($path, $thr) = ($1, $2);
                my $parsed;
                eval { $parsed = parse_size_or_pct($thr, default_unit => '%', name => 'threshold'); 1 }
                    or croak "Resource::Disk: bad threshold in '$entry': $@";
                $m{$path} = {min_free => $parsed};
            }
            $mounts = \%m;
        }
    }

    croak "Resource::Disk: at least one --disk-mount is required"
        unless ref($mounts) eq 'HASH' && keys %$mounts;

    my $loaded = eval { require Filesys::Df; 1 };
    my $err    = $@;
    unless ($loaded) {
        warn $err if $err && $err !~ m{\bCan't locate Filesys/Df\.pm\b};
        croak "Resource::Disk requires Filesys::Df; install it (cpanm Filesys::Df) and retry";
    }

    for my $mp (sort keys %$mounts) {
        croak "Resource::Disk: mount '$mp' does not exist" unless -e $mp;
        my $sample;
        eval { $sample = Filesys::Df::df($mp, 1); 1 }
            or croak "Resource::Disk: mount '$mp' could not be sampled: $@";
        croak "Resource::Disk: mount '$mp' returned no sample"
            unless ref($sample) eq 'HASH' && defined $sample->{bavail};
    }

    $self->{+MOUNTS} = $mounts;
    $self->{+PERMANENT_BROKEN} //= 0;
}

sub _evaluate_threshold {
    my ($threshold, $free, $total) = @_;

    if ($threshold->{kind} eq 'pct') {
        return 'low' unless $total && $total > 0;
        return (($free / $total) * 100) >= $threshold->{value} ? 'ok' : 'low';
    }

    return $free >= $threshold->{value} ? 'ok' : 'low'
        if $threshold->{kind} eq 'bytes';

    croak "evaluate_threshold: unknown threshold kind '$threshold->{kind}'";
}

sub _take_sample {
    my ($self, $mp) = @_;

    my $now   = time;
    my $cache = $self->{+SAMPLES}->{$mp};

    my $sample;
    my $ok  = eval { $sample = Filesys::Df::df($mp, 1); 1 };
    my $err = $@;

    if (!$ok || !$sample || ref($sample) ne 'HASH' || !defined $sample->{bavail}) {
        my $fails = ($cache->{consecutive_failures} // 0) + 1;
        $self->{+SAMPLES}->{$mp} = {
            ts                   => $now,
            free_bytes           => $cache ? $cache->{free_bytes}  : undef,
            total_bytes          => $cache ? $cache->{total_bytes} : undef,
            state                => 'unknown',
            consecutive_failures => $fails,
            last_error           => $err || 'sample returned no data',
        };
        $self->{+PERMANENT_BROKEN} = 1 if $fails >= 3;
        return $self->{+SAMPLES}->{$mp};
    }

    my $free  = $sample->{bavail};
    my $total = $sample->{blocks};

    my $threshold = $self->{+MOUNTS}->{$mp}->{min_free};
    my $state     = _evaluate_threshold($threshold, $free, $total);

    $self->{+SAMPLES}->{$mp} = {
        ts                   => $now,
        free_bytes           => $free,
        total_bytes          => $total,
        state                => $state,
        consecutive_failures => 0,
        last_error           => undef,
    };

    return $self->{+SAMPLES}->{$mp};
}

sub available {
    my $self = shift;
    my ($task) = @_;

    return -1 if $self->{+PERMANENT_BROKEN};

    $self->_take_sample($_) for keys %{$self->{+MOUNTS}};
    return -1 if $self->{+PERMANENT_BROKEN};

    for my $mp (keys %{$self->{+MOUNTS}}) {
        my $sample = $self->{+SAMPLES}->{$mp};
        return 0 if !$sample || ($sample->{state} // 'unknown') ne 'ok';
    }

    return 1;
}

sub status_data {
    my $self = shift;

    my @rows;
    for my $mp (sort keys %{$self->{+MOUNTS}}) {
        my $thr  = $self->{+MOUNTS}->{$mp}->{min_free};
        my $samp = $self->{+SAMPLES}->{$mp} // {};
        push @rows => [
            $mp,
            $thr->{kind} . '=' . $thr->{value},
            $samp->{state} // 'unknown',
            $samp->{free_bytes}  // '--',
            $samp->{total_bytes} // '--',
        ];
    }

    return [
        {
            title  => 'Disk',
            tables => [
                {
                    header => [qw/mount threshold state free total/],
                    rows   => \@rows,
                },
            ],
            lines => [$self->{+PERMANENT_BROKEN} ? 'PERMANENT_BROKEN' : ()],
        },
    ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Harness::Runner::Resource::Disk - Throttle jobs when disk space is low.

=head1 SYNOPSIS

    yath test -R Disk --disk-mount /tmp:25%
    yath test -R Disk --disk-mount /tmp:25% --disk-mount /var:1gb

=head1 DESCRIPTION

Gates new test launches when free space on any tracked mount drops
below its threshold. Every C<available()> call performs a fresh
L<Filesys::Df> sample on each tracked mount (no TTL cache).

Three consecutive sample failures on any mount mark the resource
permanently broken; subsequent C<available()> calls return C<-1>
which skips dependent tests (or fails them with
C<--fail-on-resource-skip>).

=head1 OPTIONAL DEPENDENCY

Requires L<Filesys::Df>: C<cpanm Filesys::Df>.

=head1 NETWORK FILESYSTEMS

Do not use on network filesystems (NFS, CIFS, sshfs, fuse). Each
C<available()> call performs C<statvfs(2)>, which on a network mount
blocks on a round-trip and may return stale client-cached data.

=head1 SOURCE

The source code repository for Test2-Harness can be found at
F<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
