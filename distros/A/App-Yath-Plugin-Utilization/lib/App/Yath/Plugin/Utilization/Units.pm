package App::Yath::Plugin::Utilization::Units;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak/;

use Importer Importer => 'import';

our @EXPORT_OK = qw/parse_quantity parse_byte_size parse_duration parse_count_or_pct parse_size_or_pct/;

sub parse_quantity {
    my ($raw, %opts) = @_;

    my $units   = $opts{units} or croak "parse_quantity: 'units' arrayref is required";
    my $default = $opts{default_unit};
    my $name    = $opts{name} // 'value';

    croak "$name is required" unless defined $raw && length $raw;

    my $s = $raw;
    $s =~ s/\s+//g;

    my $alt = join '|', map { quotemeta $_ } @$units;

    my ($num, $unit) = $s =~ m/^([0-9]+(?:\.[0-9]+)?)($alt)?\z/i
        or croak "invalid $name '$raw' (expected NUMBER[" . join('|', @$units) . "])";

    if (defined $unit) {
        $unit = lc $unit;
    }
    else {
        croak "invalid $name '$raw' (unit required: one of " . join(', ', @$units) . ")"
            unless defined $default;
        $unit = $default;
    }

    return ($num + 0, $unit);
}

sub parse_byte_size {
    my ($raw, %opts) = @_;

    my ($num, $unit) = parse_quantity(
        $raw,
        units        => [qw/kb mb gb tb/],
        default_unit => $opts{default_unit},
        name         => $opts{name} // 'size',
    );

    croak "invalid " . ($opts{name} // 'size') . " '$raw' (must be > 0)"
        unless $num > 0;

    my %mult = (
        kb => 1024,
        mb => 1024**2,
        gb => 1024**3,
        tb => 1024**4,
    );

    return int($num * $mult{$unit});
}

sub parse_duration {
    my ($raw, %opts) = @_;

    my ($num, $unit) = parse_quantity(
        $raw,
        units        => [qw/ms s m/],
        default_unit => $opts{default_unit} // 's',
        name         => $opts{name}         // 'duration',
    );

    croak "invalid " . ($opts{name} // 'duration') . " '$raw' (must be > 0)"
        unless $num > 0;

    my %mult = (
        ms => 0.001,
        s  => 1,
        m  => 60,
    );

    return $num * $mult{$unit};
}

sub parse_count_or_pct {
    my ($raw, %opts) = @_;
    my $name = $opts{name} // 'count';

    croak "$name is required" unless defined $raw && length $raw;

    my $s = $raw;
    $s =~ s/\s+//g;
    if ($s =~ m/^[0-9]+\z/) {
        croak "invalid $name '$raw' (count must be > 0)" unless $s > 0;
        return {kind => 'count', value => $s + 0};
    }

    my ($num, $unit) = parse_quantity(
        $raw,
        units        => [qw/%/],
        default_unit => undef,
        name         => $name,
    );

    croak "invalid $name '$raw' (expected NUMBER or NUMBER%)"
        unless defined $unit && $unit eq '%';

    croak "invalid $name '$raw' (pct must be > 0 and < 100)"
        unless $num > 0 && $num < 100;

    return {kind => 'pct', value => $num};
}

sub parse_size_or_pct {
    my ($raw, %opts) = @_;
    my $name    = $opts{name} // 'size';
    my $default = $opts{default_unit};

    croak "$name is required" unless defined $raw && length $raw;

    unless (defined $default) {
        my $s = $raw;
        $s =~ s/\s+//g;
        croak "invalid $name '$raw' (expected NUMBER[kb|mb|gb|tb|%])"
            if $s =~ m/^[0-9]+(?:\.[0-9]+)?\z/;
    }

    my ($num, $unit) = parse_quantity(
        $raw,
        units        => [qw/kb mb gb tb %/],
        default_unit => $default,
        name         => $name,
    );

    if ($unit eq '%') {
        croak "invalid $name '$raw' (pct must be > 0 and < 100)"
            unless $num > 0 && $num < 100;
        return {kind => 'pct', value => $num};
    }

    croak "invalid $name '$raw' (must be > 0)" unless $num > 0;

    my %mult = (
        kb => 1024,
        mb => 1024**2,
        gb => 1024**3,
        tb => 1024**4,
    );

    return {kind => 'bytes', value => int($num * $mult{$unit})};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Plugin::Utilization::Units - Parse number-with-unit strings used by yath options.

=head1 SYNOPSIS

    use App::Yath::Plugin::Utilization::Units qw/parse_quantity parse_byte_size parse_duration parse_count_or_pct parse_size_or_pct/;

    my ($n, $u) = parse_quantity('512mb', units => [qw/kb mb gb tb/]);
    my $bytes = parse_byte_size('1gb');         # 1073741824
    my $secs  = parse_duration('500ms');        # 0.5

=head1 EXPORTS

=over 4

=item ($num, $unit) = parse_quantity($raw, %opts)

Splits C<$raw> into a numeric value and a unit suffix from a caller-supplied
list. Whitespace stripped. Croaks on invalid input.

=item $bytes = parse_byte_size($raw, %opts)

Accepts C<kb>/C<mb>/C<gb>/C<tb> (case-insensitive). Returns integer bytes.

=item $secs = parse_duration($raw, %opts)

Accepts C<ms>/C<s>/C<m> (case-insensitive). Default unit C<s>. Returns float seconds.

=item $result = parse_count_or_pct($raw, %opts)

Accepts a bare positive integer or C<NUMBER%>. Returns
C<< { kind => 'count'|'pct', value => N } >>.

=item $result = parse_size_or_pct($raw, %opts)

Accepts a byte size (C<NUMmb>) or C<NUMBER%>. Returns
C<< { kind => 'bytes'|'pct', value => N } >>. Bare numbers without a unit
are rejected unless C<default_unit> is supplied.

=back

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
