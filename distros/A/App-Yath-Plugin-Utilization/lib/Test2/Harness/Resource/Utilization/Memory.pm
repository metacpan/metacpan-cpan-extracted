package Test2::Harness::Resource::Utilization::Memory;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak/;

use Test2::Harness::Resource::Utilization::Util qw/read_file_lines/;
use App::Yath::Plugin::Utilization::Units qw/parse_size_or_pct/;

use parent 'Test2::Harness::Runner::Resource';
use Test2::Harness::Util::HashBase qw/<settings <utilize_percent <min_free <min_concurrent +in_flight +assigned/;

sub new {
    my $class = shift;
    my $self = bless({@_}, $class);
    $self->init;
    return $self;
}

sub init {
    my $self = shift;

    croak "Resource::Memory requires Linux (this is $^O)" unless $^O eq 'linux';

    my $settings = $self->{+SETTINGS};

    my $u = $self->{+UTILIZE_PERCENT};
    $u //= $settings->utilization->utilize if $settings && $settings->check_prefix('utilization');
    if (defined $u) {
        croak "Resource::Memory: utilize_percent must be > 0 and < 100"
            unless $u =~ m/^[0-9]+(?:\.[0-9]+)?\z/ && $u > 0 && $u < 100;
        $self->{+UTILIZE_PERCENT} = $u + 0;
    }

    my $mf = $self->{+MIN_FREE};
    if (!$mf && $settings && $settings->check_prefix('utilization')) {
        my $raw = $settings->utilization->memory_min_free;
        $mf = parse_size_or_pct($raw, name => 'memory_min_free') if defined $raw && length $raw;
    }
    $mf //= {kind => 'pct', value => 5};

    croak "Resource::Memory: min_free.kind must be 'pct' or 'bytes'"
        unless ref($mf) eq 'HASH' && defined $mf->{kind} && ($mf->{kind} eq 'pct' || $mf->{kind} eq 'bytes');
    croak "Resource::Memory: min_free.value must be > 0"
        unless defined $mf->{value} && $mf->{value} > 0;
    croak "Resource::Memory: min_free.value (pct) must be < 100"
        if $mf->{kind} eq 'pct' && $mf->{value} >= 100;

    $self->{+MIN_FREE}       = $mf;
    $self->{+MIN_CONCURRENT} //= 1;
    $self->{+IN_FLIGHT}      //= 0;
}

sub _read_meminfo { [read_file_lines('/proc/meminfo')] }

sub _sample {
    my $self = shift;
    my $lines = $self->_read_meminfo;

    my %vals;
    for my $line (@$lines) {
        if ($line =~ m/^(\w+):\s*([0-9]+)\s*kB\s*\z/) {
            $vals{$1} = $2 * 1024;
        }
    }

    croak "Resource::Memory: missing MemTotal in /proc/meminfo" unless defined $vals{MemTotal};
    croak "Resource::Memory: missing MemAvailable in /proc/meminfo" unless defined $vals{MemAvailable};

    return ($vals{MemTotal}, $vals{MemAvailable});
}

sub _effective_min_free_bytes {
    my ($self, $total) = @_;

    my $mf = $self->{+MIN_FREE};
    my $explicit = $mf->{kind} eq 'bytes' ? $mf->{value} : int($total * $mf->{value} / 100);

    my $utilize = 0;
    if (defined $self->{+UTILIZE_PERCENT}) {
        $utilize = int($total * (100 - $self->{+UTILIZE_PERCENT}) / 100);
    }

    return $explicit > $utilize ? $explicit : $utilize;
}

sub available {
    my $self = shift;
    my ($task) = @_;

    return 1 if $self->{+IN_FLIGHT} < $self->{+MIN_CONCURRENT};

    my ($total, $avail) = $self->_sample;
    my $thr = $self->_effective_min_free_bytes($total);
    return $avail < $thr ? 0 : 1;
}

sub assign {
    my $self = shift;
    my ($task, $state) = @_;
    $state->{record} = {mem_assign => 1};
}

sub record {
    my $self = shift;
    my ($job_id, $info) = @_;
    return unless $info && $info->{mem_assign};
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

    my ($total, $avail) = eval { $self->_sample };
    my $thr = ($total) ? $self->_effective_min_free_bytes($total) : 0;

    return [
        {
            title  => 'Memory',
            tables => [
                {
                    header => [qw/utilize_percent min_free mem_total mem_avail effective_min_free in_flight/],
                    rows   => [[
                        $self->{+UTILIZE_PERCENT} // '--',
                        $self->{+MIN_FREE}->{kind} . '=' . $self->{+MIN_FREE}->{value},
                        $total // '--',
                        $avail // '--',
                        $thr,
                        $self->{+IN_FLIGHT} // 0,
                    ]],
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

Test2::Harness::Runner::Resource::Memory - Throttle jobs when free memory is low.

=head1 SYNOPSIS

    yath test -R Memory                       # default min_free=5%
    yath test -R Memory --memory-min-free 20%
    yath test -R Memory --memory-min-free 512mb -U 80

=head1 DESCRIPTION

Defers new test starts when free memory drops below a threshold.
Samples C</proc/meminfo> per-call (no cache).

The threshold can be expressed as a percent of C<MemTotal> (C<25%>)
or absolute byte size (C<512mb>, C<2gb>). When C<--utilize PCT> is
also set, both thresholds apply and the more conservative wins.

=head1 LIMITATIONS

Linux only.

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
