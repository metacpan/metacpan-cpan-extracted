package Data::Random::NL;
use warnings;
use strict;

# ABSTRACT: Tools for generating random Dutch numbers
our $VERSION = '1.6';

use Exporter qw(import);
use Carp qw(croak);


my @_export_person = qw(generate_bsn);
my @_export_kvk    = qw(generate_kvk generate_rsin generate_vestigingsnummer);

our @EXPORT_OK = (@_export_person, @_export_kvk);

our %EXPORT_TAGS = (
    all     => \@EXPORT_OK,
    person  => \@_export_person,
    company => \@_export_kvk,
);

sub generate_bsn {
    my $begin = shift;
    my @bsn = _generate_number_set(9, $begin);

    # A BSN cannot start with a 00
    while ($bsn[0] == 0 && $bsn[1] == 0) {
        $bsn[1] = int(rand(10));
    }

    @bsn = reverse(@bsn);

    my $sum = 0;
    foreach my $i (reverse(1..8)) {
        $sum += (($i + 1) * $bsn[$i]);
    }

    my $last_number = $sum % 11;
    # if the last number is 10, we have an invalid number
    return generate_bsn($begin) if $last_number > 9;

    @bsn = reverse(@bsn);

    $bsn[-1] = $last_number;
    return join("", @bsn);
}

sub generate_kvk {
    my $begin = shift;
    my @kvk = _generate_number_set(9, 0, $begin);
    $kvk[0] = 0; # we always start with a 0

    @kvk = _get_last_number(@kvk);
    if (@kvk) {
        shift @kvk;
        return join("", @kvk);
    }
    return generate_kvk($begin);
}

sub generate_rsin {
    my $begin = shift;
    my @rsin = _generate_number_set(9, $begin);

    @rsin = _get_last_number(@rsin);
    return join("", @rsin) if @rsin;
    return generate_rsin($begin);
}

sub _get_last_number {
    my @set = @_;

    @set = reverse(@set);

    my $sum = 0;
    foreach my $i (reverse(1..8)) {
        $sum += (($i + 1) * $set[$i]);
    }

    my $left = $sum % 11;
    my $last_number = abs($left - 11);

    # if the last number is 10, we have an invalid number
    return if $last_number > 9;

    $set[0] = $last_number;
    return reverse(@set);
}

sub _generate_number_set {
    my ($max, @begin) = @_;
    my @number;
    foreach (@begin) {
        eval { _starts_with(\@number, $_) };
        croak "$@" if $@;
    }

    while(@number < $max) {
        push(@number, int(rand(10)));
    }
    return @number;
}

sub generate_vestigingsnummer {
    my $begin = shift;
    return join("", _generate_number_set(12, $begin));
}

sub _starts_with {
    my ($ref, $begin) = @_;

    if (defined $begin) {
        if ($begin !~ /^[0-9]$/) {
            die("You did not provide a number", $/);
        }
        push(@$ref, $begin);
        return 1;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Random::NL - Tools for generating random Dutch numbers

=head1 VERSION

version 1.6

=head1 SYNOPSIS

    use Data::Random::NL qw(:all);

    my $bsn              = generate_bsn();
    my $kvk              = generate_kvk();
    my $rsin             = generate_rsin();
    my $vestigingsnummer = generate_vestingsnummer();

=head1 DESCRIPTION

This module provides methods to generate fake and/or random data used
for spoofing and/or faking data such as BSN numbers and KvK numbers.

None of the methods are exported by default.

=head1 A word of warning

Be aware that this module may produce numbers that are used in the real world.
BSN numbers in test situations start by convention with a C<9>.

=head1 EXPORT_OK

=over

=item generate_bsn

=item generate_rsin

=item generate_kvk

=item generate_vestigingsnummer

=back

=head1 EXPORT_TAGS

=over

=item :all

Get all the generate functions

=item :person

Imports all the numbers in use for a person

=item :company

Imports all the numbers in use for a company

=back

=head1 METHODS

=head2 generate_bsn

Generate a BSN (burgerservicenummer/social security number).

    generate_bsn(); # returns a BSN
    generate_bsn(9); # returns a BSN starting with a 9

=head2 generate_kvk

Generate a KvK (Kamer van Koophandel/Chamber of Commerce) number

    generate_kvk(); # returns a KvK number
    generate_kvk(9); # returns a KvK number starting with a 9

=head2 generate_rsin

Generate a RSIN number

    generate_rsin(); # returns a RSIN number
    generate_rsin(9); # returns a RSIN number starting with a 9

=head2 generate_vestigingsnummer

Generate a vestigings number

    generate_vestigingsnummer(); # returns a vestigings number
    generate_vestigingsnummer(9); # returns a vestigings number starting with a 9

=head1 SEE ALSO

=over

=item bsn

L<https://www.government.nl/topics/personal-data/citizen-service-number-bsn>

=item kvk

L<https://www.kvk.nl/download/De_nummers_van_het_Handelsregister_tcm109-365707.pdf>

=item rsin

L<https://www.kvk.nl/english/registration/rsin-number/>

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
