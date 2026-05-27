package Test2::Harness::Resource::Utilization::Throttle;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak/;
use POSIX qw/floor/;
use Time::HiRes qw/time/;

use Test2::Harness::Resource::Utilization::Util qw/read_file_lines maybe_read_file_lines/;
use App::Yath::Plugin::Utilization::Units qw/parse_duration parse_byte_size/;

use parent 'Test2::Harness::Runner::Resource';
use Test2::Harness::Util::HashBase qw{
    <settings <cap <window <bases <core_count <assignments
};

our $DETECT_CORE_COUNT  = undef;
our $READ_MEMINFO_AVAIL = undef;

sub new {
    my $class = shift;
    my $self = bless({@_}, $class);
    $self->init;
    return $self;
}

sub init {
    my $self = shift;

    $self->{+ASSIGNMENTS} //= {};

    my $settings = $self->{+SETTINGS};

    if ($settings && $settings->check_prefix('utilization')) {
        my $raw = $settings->utilization->throttle;
        if (defined $raw && length $raw && !defined $self->{+CAP}) {
            my $rule = $self->_parse_rule_entry($raw);
            $self->{+CAP}    = $rule->{cap};
            $self->{+WINDOW} = $rule->{window};
            $self->{+BASES}  = $rule->{bases} if $rule->{bases};
        }
    }

    $self->{+CAP}    //= 1;
    $self->{+WINDOW} //= 1;
    $self->{+BASES}  //= [];

    croak "Resource::Throttle: 'cap' must be a positive integer"
        unless defined $self->{+CAP} && $self->{+CAP} =~ m/^[0-9]+\z/ && $self->{+CAP} > 0;

    croak "Resource::Throttle: 'window' must be a positive number"
        unless defined $self->{+WINDOW} && $self->{+WINDOW} =~ m/^[0-9]+(?:\.[0-9]+)?\z/ && $self->{+WINDOW} > 0;

    my $bases = $self->{+BASES};
    croak "Resource::Throttle: 'bases' must be an arrayref" unless ref($bases) eq 'ARRAY';
    for my $b (@$bases) {
        croak "Resource::Throttle: each basis must be a hashref" unless ref($b) eq 'HASH';
        croak "Resource::Throttle: basis 'type' must be 'core' or 'ram'"
            unless $b->{type} && ($b->{type} eq 'core' || $b->{type} eq 'ram');
        croak "Resource::Throttle: RAM basis must have 'bytes'"
            if $b->{type} eq 'ram' && !$b->{bytes};
    }

    my $has_ram_basis = grep { $_->{type} eq 'ram' } @$bases;
    if ($has_ram_basis && !defined $READ_MEMINFO_AVAIL) {
        croak "Resource::Throttle: RAM basis requires Linux (/proc/meminfo)"
            unless -e '/proc/meminfo';
    }

    $self->{+CORE_COUNT} //= _detect_core_count();
}

sub _detect_core_count {
    return $DETECT_CORE_COUNT->() if defined $DETECT_CORE_COUNT;

    my $loaded = eval { require System::Info; 1 };
    if ($loaded) {
        my $n;
        my $ok = eval { $n = System::Info->new->ncore; 1 };
        return $n if $ok && $n && $n > 0;
    }

    my $count = grep { /^processor\s*:/ } maybe_read_file_lines('/proc/cpuinfo');
    return $count if $count > 0;

    return 1;
}

sub _read_meminfo_available {
    return $READ_MEMINFO_AVAIL->() if defined $READ_MEMINFO_AVAIL;

    for my $line (read_file_lines('/proc/meminfo')) {
        return $1 * 1024 if $line =~ /^MemAvailable:\s+(\d+)\s+kB/;
    }
    croak "Resource::Throttle: MemAvailable not found in /proc/meminfo";
}

sub _parse_rule_entry {
    my ($class, $arg) = @_;

    if ($arg =~ m{^([0-9]+)/([^/]+)/(.+)\z}) {
        my ($cap, $basis_str, $duration) = ($1, $2, $3);
        croak "Resource::Throttle: cap in '$arg' must be a positive integer" unless $cap > 0;
        my $bases = $class->_parse_bases($basis_str, $arg);
        my $secs;
        eval { $secs = parse_duration($duration, name => 'window'); 1 }
            or croak "Resource::Throttle: bad window in entry '$arg': $@";
        return {cap => $cap + 0, window => $secs, bases => $bases};
    }

    if ($arg =~ m{^([0-9]+)/(.+)\z}) {
        my ($cap, $duration) = ($1, $2);
        croak "Resource::Throttle: cap in '$arg' must be a positive integer" unless $cap > 0;
        my $secs;
        eval { $secs = parse_duration($duration, name => 'window'); 1 }
            or croak "Resource::Throttle: bad window in entry '$arg': $@";
        return {cap => $cap + 0, window => $secs};
    }

    if ($arg =~ m{^([0-9]+)\z}) {
        my $cap = $1;
        croak "Resource::Throttle: cap in '$arg' must be a positive integer" unless $cap > 0;
        return {cap => $cap + 0, window => 1};
    }

    croak "Resource::Throttle: unrecognised rule entry '$arg' (expected CAP, CAP/DURATION, or CAP/BASIS[,BASIS...]/DURATION)";
}

sub _parse_bases {
    my ($class, $basis_str, $orig_entry) = @_;

    croak "Resource::Throttle: empty basis in '$orig_entry'"
        unless defined $basis_str && length $basis_str;

    my @parts = split /,/, $basis_str;
    my @bases;

    for my $part (@parts) {
        $part =~ s/^\s+|\s+$//g;
        croak "Resource::Throttle: empty basis component in '$orig_entry'" unless length $part;

        if ($part =~ m{^cores?\z}i) {
            push @bases => {type => 'core'};
        }
        elsif ($part =~ m{^[0-9]+(?:\.[0-9]+)?(?:kb|mb|gb|tb)\z}i) {
            my $bytes;
            eval { $bytes = parse_byte_size($part); 1 }
                or croak "Resource::Throttle: invalid byte-size basis '$part' in '$orig_entry': $@";
            push @bases => {type => 'ram', bytes => $bytes};
        }
        else {
            croak "Resource::Throttle: unknown basis unit '$part' in '$orig_entry' (expected 'core' or byte size like '100mb')";
        }
    }

    croak "Resource::Throttle: no bases parsed from '$basis_str' in '$orig_entry'" unless @bases;

    return \@bases;
}

sub _token_count {
    my $self = shift;

    my $bases = $self->{+BASES};
    return ($self->{+CAP}, $self->{+WINDOW}) unless @$bases;

    my $free_ram     = undef;
    my $max_win_mult = 1;
    my @basis_tokens;

    for my $b (@$bases) {
        if ($b->{type} eq 'core') {
            push @basis_tokens => floor($self->{+CORE_COUNT});
        }
        elsif ($b->{type} eq 'ram') {
            $free_ram //= _read_meminfo_available();

            my $basis_unit  = $b->{bytes};
            my $window_mult = 1;
            my $halvings    = 0;

            while ($basis_unit > $free_ram && $halvings < 2) {
                $basis_unit  /= 2;
                $window_mult *= 2;
                $halvings++;
            }

            $max_win_mult = $window_mult if $window_mult > $max_win_mult;

            my $tokens = ($basis_unit > $free_ram) ? 0 : floor($free_ram / $basis_unit);
            push @basis_tokens => $tokens;
        }
    }

    my $min_tokens = $basis_tokens[0];
    for my $t (@basis_tokens) { $min_tokens = $t if $t < $min_tokens; }

    return ($self->{+CAP} * $min_tokens, $self->{+WINDOW} * $max_win_mult);
}

sub _in_window_count {
    my ($self, $win) = @_;
    $win //= $self->{+WINDOW};
    my $now   = time;
    my $count = 0;
    for my $entry (values %{$self->{+ASSIGNMENTS}}) {
        $count++ if ($now - $entry->{assigned_at}) < $win;
    }
    return $count;
}

sub available {
    my $self = shift;
    my ($task) = @_;

    my ($tokens, $eff_window) = $self->_token_count;
    return $self->_in_window_count($eff_window) < $tokens ? 1 : 0;
}

sub assign {
    my $self = shift;
    my ($task, $state) = @_;
    $state->{record} = {throttle_assign => 1, assigned_at => time, file => $task->{rel_file}};
}

sub record {
    my $self = shift;
    my ($job_id, $info) = @_;
    return unless $info && $info->{throttle_assign};
    $self->{+ASSIGNMENTS}->{$job_id} = {
        assigned_at => $info->{assigned_at},
        file        => $info->{file},
    };
}

sub release {
    my $self = shift;
    my ($job_id) = @_;
    delete $self->{+ASSIGNMENTS}->{$job_id};
}

sub status_data {
    my $self = shift;
    my ($tokens, $eff_window) = $self->_token_count;
    my $in_window = $self->_in_window_count($eff_window);

    my @rows;
    my $now = time;
    for my $id (sort { $self->{+ASSIGNMENTS}->{$a}->{assigned_at} <=> $self->{+ASSIGNMENTS}->{$b}->{assigned_at} } keys %{$self->{+ASSIGNMENTS}}) {
        my $a = $self->{+ASSIGNMENTS}->{$id};
        my $age = $now - $a->{assigned_at};
        push @rows => [
            sprintf('%.2f', $age),
            ($age < $eff_window) ? 'in_window' : 'aged_out',
            $a->{file} // '--',
        ];
    }

    return [
        {
            title  => 'Throttle',
            tables => [
                {
                    title  => "cap=$self->{+CAP} window=$self->{+WINDOW}s eff_window=${eff_window}s tokens=$tokens in_window=$in_window",
                    header => [qw/age state file/],
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

Test2::Harness::Runner::Resource::Throttle - Limit how many tests can be in their just-spawned phase at once.

=head1 SYNOPSIS

    yath test -R Throttle --throttle 5/2s
    yath test -R Throttle --throttle 5
    yath test -R Throttle --throttle 10/500ms
    yath test -R Throttle --throttle 1/core/1s
    yath test -R Throttle --throttle 1/core,100mb/1s

=head1 DESCRIPTION

A "slot" is occupied from when a test starts (C<assign>) until either
the test releases or C<window> seconds elapse, whichever comes first.
Cap is C<N> slots per window.

=head1 OPTIONS

C<--throttle SPEC>:

=over 4

=item C<CAP/DURATION>

Positive integer cap. Duration accepts C<ms>/C<s>/C<m>; bare number is
seconds. e.g. C<5/2s>, C<10/500ms>, C<3/1m>.

=item C<CAP>

Shorthand for C<CAP/1s>.

=item C<CAP/BASIS[,BASIS...]/DURATION>

BASIS is C<core>/C<cores> (system core count) or a byte size
(C<100mb>, C<1gb>) giving free-RAM-divided tokens.

=back

=head1 ADAPTIVE SCALING

When a RAM basis is configured and free RAM falls below the basis
unit, the unit halves and the window doubles (up to twice). After two
halvings the RAM basis contributes zero tokens and the throttle
defers all new launches.

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
