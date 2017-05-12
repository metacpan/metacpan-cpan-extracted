package Business::CUSIP::Random;

use strict;
use warnings;
use Business::CUSIP;

our $VERSION = '0.01';

=head1 NAME

Business::CUSIP::Random - Generate random CUSIP numbers for testing

=head1 SYNOPSIS

use Business::CUSIP::Random;

my $cusip;

$cusip = Business::CUSIP::Random->generate; # returns a Business::CUSIP object

# or...

$cusip = Business::CUSIP::Random->generate_string; # returns a string

=head1 DESCRIPTION

Generates a random CUSIP (Committee on Uniform Security Identification Procedures) number for use in testing.

=head1 METHODS

=head2 generate

=head2 generate_string

Returns a randomly-generated, valid CUSIP number.

generate() returns a Business::CUSIP object, while generate_string() returns a string.

Takes the following optional parameter as a hash:

=over 4

=item * B<fixed_income>

If true, the CUSIP generated will follow the format defined for fixed-income securities.

=back

=cut

sub generate {
    my ($class, %params) = @_;

    my $cusip = $class->rand_issuer_number(%params) .
                $class->rand_issue_number(%params);
    my $cusip_obj = Business::CUSIP->new($cusip, $params{fixed_income});
    $cusip .= $cusip_obj->check_digit;
    $cusip_obj->cusip($cusip);
    return $cusip_obj;
}

sub generate_string {
    my $class = shift;
    return $class->generate(@_)->cusip;
}

=head2 rand_issuer_number

Returns a random CUSIP issuer number

Takes the following optional parameter as a hash:

=over 4

=item * B<fixed_income>

If true, the issuer number generated will follow the format defined for fixed-income securities.

=back

=cut

sub rand_issuer_number {
    my ($class, %params) = @_;
    return $class->_pick(3, 0..9) . $class->_pick(3, 0..9, 'A'..'Z');
}

=head2 rand_issue_number

Generates a random CUSIP issue number.

Takes the following optional parameter as a hash:

=over 4

=item * B<fixed_income>

If true, the issue number generated will follow the format defined for fixed-income securities.

=back

=cut

sub rand_issue_number {
    my ($class, %params) = @_;
    return $params{fixed_income} ? $class->_pick(2, 'A'..'H', 'J'..'N', 'P'..'Z', 2..9)
                                 : $class->_pick(1, 10..88);
}

sub _pick {
    my ($class, $count, @chars) = @_;
    my $res  = '';
       $res .= $chars[rand @chars] for (1..$count);
    return $res;
}

=head1 DEPENDENCIES

Business::CUSIP

=head1 AUTHORS

Michael Aquilina <aquilina@cpan.org>

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 Michael Aquilina.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

