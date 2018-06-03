package Data::Random::NL;
use warnings;
use strict;

# ABSTRACT: Tools for generating random Dutch numbers
our $VERSION = '1.2';

use Exporter qw(import);
use Carp qw(croak);

our @EXPORT_OK = (
    qw(
        generate_bsn
        generate_rsin
        generate_kvk
    ),
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

sub generate_bsn {
    my $begin = shift;
    my @bsn;

    eval { _starts_with(\@bsn, $begin) };
    croak "$@" if $@;

    while(@bsn < 9) {
        push(@bsn, int(rand(10)));
    }

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
    my @kvk;

    push(@kvk, 0); # first number is always a 0

    eval { _starts_with(\@kvk, $begin) };
    croak "$@" if $@;

    while(@kvk < 9) {
        push(@kvk, int(rand(10)));
    }

    @kvk = _get_last_number(@kvk);
    if (@kvk) {
        shift @kvk;
        return join("", @kvk);
    }
    return generate_kvk($begin);
}

sub generate_rsin {
    my $begin = shift;
    my @rsin;

    eval { _starts_with(\@rsin, $begin) };
    croak "$@" if $@;

    while(@rsin < 9) {
        push(@rsin, int(rand(10)));
    }

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

version 1.2

=head1 SYNOPSIS

    use Data::Random::NL qw(generate_bsn);

    my $fake_bsn  = generate_bsn();
    my $fake_kvk  = generate_kvk();
    my $fake_rsin = generate_rsin();

=head1 DESCRIPTION

This module provides methods to generate fake and/or random data used
for spoofing and/or faking data such as BSN numbers and KvK numbers.

=head1 EXPORT_OK

=over

=item generate_bsn

=item generate_rsin

=item generate_kvk

=back

=head1 EXPORT_TAGS

=over

=item :all

Get all the generate functions

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
