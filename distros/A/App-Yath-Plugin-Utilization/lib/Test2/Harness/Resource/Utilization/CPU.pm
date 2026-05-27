package Test2::Harness::Resource::Utilization::CPU;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak/;
use Time::HiRes qw/time/;

use Test2::Harness::Resource::Utilization::Util qw/read_file_lines/;

use parent 'Test2::Harness::Runner::Resource';
use Test2::Harness::Util::HashBase qw/<settings <utilize_percent <min_concurrent <ema_alpha <min_dt +prev_stat +last_busy_pct +have_sample +in_flight +assigned/;

sub new {
    my $class = shift;
    my $self = bless({@_}, $class);
    $self->init;
    return $self;
}

sub init {
    my $self = shift;

    croak "Resource::CPU requires Linux (this is $^O)" unless $^O eq 'linux';

    my $settings = $self->{+SETTINGS};
    my $u = $self->{+UTILIZE_PERCENT};
    $u //= $settings->utilization->utilize if $settings && $settings->check_prefix('utilization');
    $u //= 75;

    croak "Resource::CPU: utilize_percent must be > 0 and < 100"
        unless defined $u && $u =~ m/^[0-9]+(?:\.[0-9]+)?\z/ && $u > 0 && $u < 100;

    $self->{+UTILIZE_PERCENT} = $u + 0;
    $self->{+MIN_CONCURRENT}  //= 1;
    $self->{+EMA_ALPHA}       //= 0.3;
    $self->{+MIN_DT}          //= 10;     # jiffies; ~100ms on HZ=100
    $self->{+LAST_BUSY_PCT}   //= 0;
    $self->{+HAVE_SAMPLE}     //= 0;
    $self->{+IN_FLIGHT}       //= 0;

    # Prime PREV_STAT now so the first runtime sample has something to
    # diff against rather than returning 0% busy.
    $self->_read_and_record;
}

sub _read_and_record {
    my $self = shift;

    my $line = $self->_read_stat_first_line;
    chomp $line;
    my @fields = split /\s+/, $line;
    shift @fields;
    croak "Resource::CPU: malformed /proc/stat line '$line'"
        unless @fields >= 5;

    my $idle  = $fields[3] + $fields[4];
    my $total = 0;
    $total += $_ for @fields;

    $self->{+PREV_STAT} = {total => $total, idle => $idle};
    return ($total, $idle);
}

sub _read_stat_first_line { scalar read_file_lines('/proc/stat') }

sub _sample {
    my $self = shift;

    my $line = $self->_read_stat_first_line;
    chomp $line;
    my @fields = split /\s+/, $line;
    shift @fields;    # 'cpu' label
    croak "Resource::CPU: malformed /proc/stat line '$line'"
        unless @fields >= 5;

    my $idle  = $fields[3] + $fields[4];    # idle + iowait
    my $total = 0;
    $total += $_ for @fields;

    my $prev = $self->{+PREV_STAT};
    return $self->{+LAST_BUSY_PCT} unless $prev;

    my $dt = $total - $prev->{total};

    # Require a minimum jiffy window before consuming PREV_STAT. Without
    # this, a 1-jiffy window where the kernel happened to record an idle
    # tick returns 0% busy on a fully loaded box -- pure noise. We let
    # PREV_STAT keep accumulating until we have a wide enough window for
    # a stable reading.
    return $self->{+LAST_BUSY_PCT} if $dt < $self->{+MIN_DT};

    my $di = $idle - $prev->{idle};
    my $sample = 100 * (1 - $di / $dt);
    $sample = 0   if $sample < 0;
    $sample = 100 if $sample > 100;

    # Exponential moving average across samples to dampen residual noise.
    # First real sample seeds the EMA directly.
    my $smoothed = $self->{+HAVE_SAMPLE}
        ? ($self->{+EMA_ALPHA} * $sample + (1 - $self->{+EMA_ALPHA}) * $self->{+LAST_BUSY_PCT})
        : $sample;

    $self->{+PREV_STAT}     = {total => $total, idle => $idle};
    $self->{+LAST_BUSY_PCT} = $smoothed;
    $self->{+HAVE_SAMPLE}   = 1;
    return $smoothed;
}

sub available {
    my $self = shift;
    my ($task) = @_;

    return 1 if $self->{+IN_FLIGHT} < $self->{+MIN_CONCURRENT};

    my $busy = $self->_sample;
    return $busy >= $self->{+UTILIZE_PERCENT} ? 0 : 1;
}

sub assign {
    my $self = shift;
    my ($task, $state) = @_;
    $state->{record} = {cpu_assign => 1};
}

sub record {
    my $self = shift;
    my ($job_id, $info) = @_;
    return unless $info && $info->{cpu_assign};
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
    return [
        {
            title => 'CPU',
            tables => [
                {
                    header => [qw/utilize_percent busy_pct in_flight/],
                    rows => [[
                        $self->{+UTILIZE_PERCENT},
                        sprintf('%.1f', $self->{+LAST_BUSY_PCT} // 0),
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

Test2::Harness::Runner::Resource::CPU - Throttle jobs against aggregate CPU usage.

=head1 SYNOPSIS

    yath test -R CPU                 # uses --utilize (default 75)
    yath test -R CPU -U 80           # explicit utilize

=head1 DESCRIPTION

Defers new test starts when aggregate CPU usage meets the C<--utilize>
percentage. Samples C</proc/stat>; multi-core systems handled by the
aggregate jiffies in the first C<cpu> row.

Until C<min_concurrent> tests (default 1) are in flight, the resource
never defers -- the scheduler always gets to start at least one test
even if CPU is already saturated by other workloads.

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
