package Test2::Harness::Resource::Utilization::UnixLimits;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak/;

use Test2::Harness::Resource::Utilization::Util qw/read_file_lines/;
use App::Yath::Plugin::Utilization::Units qw/parse_count_or_pct parse_size_or_pct/;

use parent 'Test2::Harness::Runner::Resource';
use Test2::Harness::Util::HashBase qw/<settings <utilize_percent <nproc <nofile <as <min_concurrent +in_flight +assigned/;

sub new {
    my $class = shift;
    my $self = bless({@_}, $class);
    $self->init;
    return $self;
}

sub init {
    my $self = shift;

    croak "Resource::UnixLimits requires Linux (this is $^O)" unless $^O eq 'linux';

    my $settings = $self->{+SETTINGS};

    my $u = $self->{+UTILIZE_PERCENT};
    $u //= $settings->utilization->utilize if $settings && $settings->check_prefix('utilization');
    if (defined $u) {
        croak "Resource::UnixLimits: utilize_percent must be > 0 and < 100"
            unless $u =~ m/^[0-9]+(?:\.[0-9]+)?\z/ && $u > 0 && $u < 100;
        $self->{+UTILIZE_PERCENT} = $u + 0;
    }

    for my $dim (qw/nproc nofile/) {
        my $v = $self->{$dim};
        if (!$v && $settings && $settings->check_prefix('utilization')) {
            my $method = "unixlimits_$dim";
            my $raw    = $settings->utilization->$method;
            $v = parse_count_or_pct($raw, name => $dim) if defined $raw && length $raw;
        }
        $v //= {kind => 'pct', value => 10};

        croak "Resource::UnixLimits: $dim.kind must be 'count' or 'pct'"
            unless ref($v) eq 'HASH' && $v->{kind} && ($v->{kind} eq 'count' || $v->{kind} eq 'pct');
        croak "Resource::UnixLimits: $dim.value must be > 0" unless $v->{value} > 0;
        $self->{$dim} = $v;
    }

    my $as = $self->{+AS};
    if (!$as && $settings && $settings->check_prefix('utilization')) {
        my $raw = $settings->utilization->unixlimits_as;
        $as = parse_size_or_pct($raw, name => 'as') if defined $raw && length $raw;
    }
    if ($as) {
        croak "Resource::UnixLimits: as.kind must be 'bytes' or 'pct'"
            unless ref($as) eq 'HASH' && $as->{kind} && ($as->{kind} eq 'bytes' || $as->{kind} eq 'pct');
        croak "Resource::UnixLimits: as.value must be > 0" unless $as->{value} > 0;
        $self->{+AS} = $as;
    }

    $self->{+MIN_CONCURRENT} //= 1;
    $self->{+IN_FLIGHT}      //= 0;
}

sub _read_self_limits {
    my %out;
    for my $line (read_file_lines('/proc/self/limits')) {
        if    ($line =~ m/^Max processes\s+(\S+)/)     { $out{nproc}  = $1 eq 'unlimited' ? undef : $1 + 0 }
        elsif ($line =~ m/^Max open files\s+(\S+)/)    { $out{nofile} = $1 eq 'unlimited' ? undef : $1 + 0 }
        elsif ($line =~ m/^Max address space\s+(\S+)/) { $out{as}     = $1 eq 'unlimited' ? undef : $1 + 0 }
    }
    return \%out;
}

sub _read_self_status {
    my %out;
    for my $line (read_file_lines('/proc/self/status')) {
        $out{Threads} = $1 + 0 if $line =~ m/^Threads:\s+([0-9]+)/;
        $out{VmSize}  = $1 + 0 if $line =~ m/^VmSize:\s+([0-9]+)\s*kB/;
    }
    return \%out;
}

sub _count_self_fd {
    opendir my $dh, '/proc/self/fd' or die "opendir /proc/self/fd: $!";
    my $n = 0;
    while (my $e = readdir $dh) {
        next if $e eq '.' || $e eq '..';
        $n++;
    }
    closedir $dh;
    return $n;
}

sub _assess_dimension {
    my ($self, $dim, $soft_cap, $current) = @_;

    return {state => 'ok', soft_cap => undef, current => $current}
        unless defined $soft_cap;

    my $headroom = $self->{$dim};
    my $explicit =
          $headroom->{kind} eq 'count' ? $headroom->{value}
        : $headroom->{kind} eq 'bytes' ? $headroom->{value}
        :                                int($soft_cap * $headroom->{value} / 100);

    my $utilize = 0;
    if (defined $self->{+UTILIZE_PERCENT}) {
        $utilize = int($soft_cap * (100 - $self->{+UTILIZE_PERCENT}) / 100);
    }

    my $effective = $explicit > $utilize ? $explicit : $utilize;
    my $free      = $soft_cap - $current;
    my $state     = $free < $effective ? 'low' : 'ok';

    return {
        state              => $state,
        soft_cap           => $soft_cap,
        current            => $current,
        free               => $free,
        effective_min_free => $effective,
    };
}

sub _dimension_states {
    my $self = shift;

    my $limits  = $self->_read_self_limits;
    my $status  = $self->_read_self_status;
    my $fdcount = $self->_count_self_fd;

    my %dims;
    $dims{nproc}  = $self->_assess_dimension('nproc',  $limits->{nproc},  $status->{Threads} // 0);
    $dims{nofile} = $self->_assess_dimension('nofile', $limits->{nofile}, $fdcount);
    if ($self->{+AS}) {
        my $vmsize_bytes = ($status->{VmSize} // 0) * 1024;
        $dims{as} = $self->_assess_dimension('as', $limits->{as}, $vmsize_bytes);
    }
    return \%dims;
}

sub available {
    my $self = shift;
    my ($task) = @_;

    return 1 if $self->{+IN_FLIGHT} < $self->{+MIN_CONCURRENT};

    my $dims = $self->_dimension_states;
    for my $d (values %$dims) {
        return 0 if $d->{state} eq 'low';
    }
    return 1;
}

sub assign {
    my $self = shift;
    my ($task, $state) = @_;
    $state->{record} = {ul_assign => 1};
}

sub record {
    my $self = shift;
    my ($job_id, $info) = @_;
    return unless $info && $info->{ul_assign};
    $self->{+IN_FLIGHT}++;
    $self->{+ASSIGNED}->{$job_id} = 1;
}

sub release {
    my $self = shift;
    my ($job_id) = @_;
    return unless delete $self->{+ASSIGNED}->{$job_id};
    $self->{+IN_FLIGHT}-- if $self->{+IN_FLIGHT} > 0;
}

sub status_data {
    my $self = shift;

    my $dims = eval { $self->_dimension_states } || {};

    my @rows;
    for my $d (sort keys %$dims) {
        my $s = $dims->{$d};
        push @rows => [
            $d,
            $s->{state},
            $s->{soft_cap} // 'unlimited',
            $s->{current} // '--',
            $s->{free}    // '--',
            $s->{effective_min_free} // '--',
        ];
    }

    return [
        {
            title  => 'UnixLimits',
            tables => [
                {
                    header => [qw/dim state soft_cap current free effective_min_free/],
                    rows   => \@rows,
                },
            ],
        },
    ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Harness::Runner::Resource::UnixLimits - Throttle jobs against per-process Unix ulimits.

=head1 SYNOPSIS

    yath test -R UnixLimits
    yath test -R UnixLimits --unixlimits-nproc 10%
    yath test -R UnixLimits --unixlimits-nproc 128 --unixlimits-nofile 10%
    yath test -R UnixLimits --unixlimits-as 512mb

=head1 DESCRIPTION

Defers starts when the runner process's soft ulimits (C<nproc>,
C<nofile>, C<as>) are near saturation. C<nproc> and C<nofile> default
on with 10% headroom; C<as> is off until an explicit threshold is
supplied.

Thresholds accept count / bytes / percent; C<--utilize PCT> layers
on top (effective threshold is C<max(explicit, utilize-derived)>).

=head1 LIMITATIONS

Linux only. Samples are per-runner-process, not per-test-process.

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
