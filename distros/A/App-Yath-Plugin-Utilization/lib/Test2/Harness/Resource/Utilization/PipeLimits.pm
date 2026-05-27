package Test2::Harness::Resource::Utilization::PipeLimits;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak/;

use Test2::Harness::Resource::Utilization::Util qw/maybe_read_file_lines/;
use App::Yath::Plugin::Utilization::Units qw/parse_count_or_pct/;

use parent 'Test2::Harness::Runner::Resource';
use Test2::Harness::Util::HashBase qw{
    <settings <utilize_percent
    <pipes_per_test <pipes_per_service <service_count <pages_per_pipe <cap_pages <headroom
    <min_concurrent +in_flight +assigned
};

use constant DEFAULT_USER_PIPE_PAGES_SOFT => 16384;
use constant DEFAULT_PAGES_PER_PIPE       => 16;
use constant PAGE_SIZE_BYTES              => 4096;

sub new {
    my $class = shift;
    my $self = bless({@_}, $class);
    $self->init;
    return $self;
}

sub init {
    my $self = shift;

    croak "Resource::PipeLimits requires Linux (this is $^O)" unless $^O eq 'linux';

    my $settings = $self->{+SETTINGS};

    my $u = $self->{+UTILIZE_PERCENT};
    $u //= $settings->utilization->utilize if $settings && $settings->check_prefix('utilization');
    if (defined $u) {
        croak "Resource::PipeLimits: utilize_percent must be > 0 and < 100"
            unless $u =~ m/^[0-9]+(?:\.[0-9]+)?\z/ && $u > 0 && $u < 100;
        $self->{+UTILIZE_PERCENT} = $u + 0;
    }

    if ($settings && $settings->check_prefix('utilization')) {
        my $r = $settings->utilization;
        $self->{+PIPES_PER_TEST}    //= $r->pipes_per_test;
        $self->{+PIPES_PER_SERVICE} //= $r->pipes_per_service;
        $self->{+SERVICE_COUNT}     //= $r->pipe_service_count;

        my $h = $self->{+HEADROOM};
        if (!$h) {
            my $raw = $r->pipe_headroom;
            $h = parse_count_or_pct($raw, name => 'pipe_headroom') if defined $raw && length $raw;
        }
        $self->{+HEADROOM} //= $h if $h;
    }

    $self->{+PIPES_PER_TEST}    //= 2;
    $self->{+PIPES_PER_SERVICE} //= 2;
    $self->{+SERVICE_COUNT}     //= 0;
    $self->{+HEADROOM}          //= {kind => 'pct', value => 10};

    for my $pair ([pipes_per_test => PIPES_PER_TEST], [pipes_per_service => PIPES_PER_SERVICE], [service_count => SERVICE_COUNT]) {
        my ($k, $key) = @$pair;
        my $v = $self->{$key};
        croak "Resource::PipeLimits: $k must be a non-negative integer"
            unless defined $v && $v =~ m/^[0-9]+\z/;
    }

    $self->{+PAGES_PER_PIPE} //= $self->_read_pages_per_pipe;
    $self->{+CAP_PAGES}      //= $self->_read_cap_pages;

    my $h = $self->{+HEADROOM};
    croak "Resource::PipeLimits: headroom is required"
        unless ref($h) eq 'HASH'
        && defined $h->{kind}
        && ($h->{kind} eq 'count' || $h->{kind} eq 'pct')
        && defined $h->{value}
        && $h->{value} > 0;

    $self->{+MIN_CONCURRENT} //= 1;
    $self->{+IN_FLIGHT}      //= 0;
}

sub _read_cap_pages {
    my $line = scalar maybe_read_file_lines('/proc/sys/fs/pipe-user-pages-soft');
    return DEFAULT_USER_PIPE_PAGES_SOFT unless defined $line && $line =~ m/^([0-9]+)/;
    return $1 + 0;
}

sub _read_pages_per_pipe {
    my $line = scalar maybe_read_file_lines('/proc/sys/fs/pipe-max-size');
    return DEFAULT_PAGES_PER_PIPE unless defined $line && $line =~ m/^([0-9]+)/;
    my $pages = int(($1 + 0) / PAGE_SIZE_BYTES);
    return $pages > 0 ? $pages : DEFAULT_PAGES_PER_PIPE;
}

sub _effective_min_free_pages {
    my $self = shift;
    my $cap  = $self->{+CAP_PAGES};

    my $h = $self->{+HEADROOM};
    my $explicit = $h->{kind} eq 'count' ? $h->{value} : int($cap * $h->{value} / 100);

    my $utilize = 0;
    if (defined $self->{+UTILIZE_PERCENT}) {
        $utilize = int($cap * (100 - $self->{+UTILIZE_PERCENT}) / 100);
    }

    return $explicit > $utilize ? $explicit : $utilize;
}

sub _usage_pages {
    my $self = shift;
    my $svc = $self->{+SERVICE_COUNT} * $self->{+PIPES_PER_SERVICE} * $self->{+PAGES_PER_PIPE};
    my $tst = $self->{+IN_FLIGHT}     * $self->{+PIPES_PER_TEST}    * $self->{+PAGES_PER_PIPE};
    return ($svc, $tst);
}

sub available {
    my $self = shift;
    my ($task) = @_;

    return 1 if $self->{+IN_FLIGHT} < $self->{+MIN_CONCURRENT};

    my ($svc, $tst) = $self->_usage_pages;
    my $free = $self->{+CAP_PAGES} - $svc - $tst;
    my $next = $self->{+PIPES_PER_TEST} * $self->{+PAGES_PER_PIPE};
    my $thr  = $self->_effective_min_free_pages;

    return (($free - $next) < $thr) ? 0 : 1;
}

sub assign {
    my $self = shift;
    my ($task, $state) = @_;
    $state->{record} = {pl_assign => 1};
}

sub record {
    my $self = shift;
    my ($job_id, $info) = @_;
    return unless $info && $info->{pl_assign};
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
    my ($svc, $tst) = $self->_usage_pages;
    my $free = $self->{+CAP_PAGES} - $svc - $tst;
    my $thr  = $self->_effective_min_free_pages;

    return [
        {
            title  => 'PipeLimits',
            tables => [
                {
                    header => [qw/cap_pages free_pages effective_min_free service_pages test_pages in_flight/],
                    rows   => [[
                        $self->{+CAP_PAGES},
                        $free,
                        $thr,
                        $svc,
                        $tst,
                        $self->{+IN_FLIGHT},
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

Test2::Harness::Runner::Resource::PipeLimits - Throttle jobs when per-user pipe budget is close to exhausted.

=head1 SYNOPSIS

    yath test -R PipeLimits
    yath test -R PipeLimits --pipe-headroom 15% --pipe-service-count 5

=head1 DESCRIPTION

The Linux per-user pipe page budget
(C</proc/sys/fs/pipe-user-pages-soft>) caps how many memory pages
across all pipes one user may hold open. Exceeding it makes new
C<pipe(2)> calls fail.

PipeLimits computes pipe-page usage from in-flight tests: each test
consumes C<pipes_per_test> pipes, plus a fixed
C<service_count * pipes_per_service> baseline. Defers new starts when
launching another would push usage past the configured headroom.

C<--pipe-headroom> may be a count of pages or a percent of the cap.
C<--utilize PCT> layers on top; effective threshold is the more
conservative of the two.

=head1 LIMITATIONS

Linux only. Counts only pipes opened by tests this resource has been
told about via assign/release; system-wide use is reflected in the
cap reading.

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
