#!/usr/bin/perl -w

#
#
# FormMagick (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.
#
# $Id: Business.pm,v 1.10 2003/02/05 17:18:39 anoncvs_gtkglext Exp $
#

package    CGI::FormMagick::Validator;

=pod

=head1 NAME

CGI::FormMagick::Validator::Business - business-related validation routines

=head1 SYNOPSIS

use CGI::FormMagick;

=head1 DESCRIPTION

See CGI::FormMagick::Validator for a general description.

=begin testing
BEGIN: {
    use CGI::FormMagick::Validator;
}


=end testing

=head2 Validation routines provided:

=over 4



=item credit_card_number

The data looks like a valid credit card number.  Checks the input for
    * numeric characters, spaces, and dashes, only
    * length
    * and a checksum algorithm used by most (all?) credit cards.

=for testing
ok( credit_card_number()    ne "OK" , "undef is not a credit card number");
ok( credit_card_number(undef, "")  ne "OK" , "empty string is not a credit card number");
ok( credit_card_number(undef, "a") ne "OK" , "a is not a credit card number");
ok( credit_card_number(undef, "12")ne "OK" , "12 is not a credit card number");
ok( credit_card_number(undef, "4111 1111 1111 1111")
                            eq "OK" , "4111 1111 1111 1111 is a credit card numer");
ok( credit_card_number(undef, "4111-1111-1111-1111")
                            eq "OK" , "4111-1111-1111-1111 is a credit card number");
ok( credit_card_number(undef, "4111111111111111")
                        eq "OK" , "4111111111111111 is a credit card number");
ok( credit_card_number(undef, "4111111111111112")
                            ne "OK" , "4111111111111112 is not a credit card number (Bad checksum)");
ok( credit_card_number(undef, "411111111111111")
                            ne "OK" , "411111111111111 is not a credit card number (Too short)");

=cut

sub credit_card_number {
    my ($fm, $number) = @_;
    my ($i, $sum, $weight);

    return "You must enter a credit card number" unless $number;

    return "Credit card numbers shouldn't have anything but "
            . "numbers, spaces or dashes" if $number =~ /[^\d\s-]/;

    $number =~ s/\D//g;

    return "Must be at least 14 characters in length" 
        unless length($number) >= 13 && 0+$number;

    for ($i = 0; $i < length($number) - 1; $i++) {
        $weight = substr($number, -1 * ($i + 2), 1) * (2 - ($i % 2));
        $sum += (($weight < 10) ? $weight : ($weight - 9));
    }

    return "OK" if substr($number, -1) == (10 - $sum % 10) % 10;
    return "Doesn't appear to be a valid credit card number";

}

=pod

=item credit_card_expiry

The data looks like a valid credit card expiry date.  Checks MM/YY and 
MM/YYYY format dates and fails if the date is in the past or is more than 
ten years in the future.

=begin testing

my ($m, $y) = (localtime)[4,5];
$m++;
$y += 1900;

sub current_m_y_plus {
    return sprintf "%02d/%d", ($m + $_[0]), ($y + $_[1]);
}

my @four_digit_year_expecations = (
    { is_valid => 1, input => current_m_y_plus(1,0) },
    { is_valid => 1, input => current_m_y_plus(0,1) },
    { is_valid => 1, input => current_m_y_plus(1,1) },
    { is_valid => 0, input => current_m_y_plus(-1,0),
        reason => 'Expired already' },
    { is_valid => 1, input => current_m_y_plus(0,0),
        reason => 'Doesn\'t expire until next month after' },
    { is_valid => 0, input => current_m_y_plus(0,10),
        reason => 'Ten years is too far in the future' },
);

my @two_digit_year_expectations;
foreach (@four_digit_year_expecations) {
    my %two_digit = %$_;
    $two_digit{input} =~ s/..(..)$/$1/;
    push @two_digit_year_expectations, \%two_digit;
}

(my $three_digit_year = "$m/$y") =~ s/.(...)$/$1/;
(my $one_digit_year = "$m/$y") =~ s/(...).$/$1/;

foreach my $case (
        @four_digit_year_expecations,
        @two_digit_year_expectations,
        { is_valid => 0, input => $three_digit_year,
            reason => 'Three digits in the year?' },
        { is_valid => 0, input => $one_digit_year,
            reason => 'One digit in the year?' },
        { is_valid => 0, input => '' },
) {
    my ($expected, $input, $reason) = @{$case}{qw(is_valid input reason)};
    my $actual = 'OK' eq credit_card_expiry(undef, $input);
    my $should = 'should' . ($expected ? '' : "n't");
    my $description = "credit_card_expiry('$input') $should be valid";
    $description .= " ($reason)" if defined $reason;
    ok($actual == $expected, $description);
}

ok(credit_card_expiry(), "credit_card_expiry(undef) shouldn't be valid.");

=end testing

=cut

sub credit_card_expiry {
    my ($fm, $data) = @_;

    return "No expiry date entered." unless defined $data;

    my ($m, $y) = split(/\D/, $data); # split on first non-numeric char

    return "Expiry date must be in the format MM/YY or MM/YYYY"
        unless (
            defined ($y)
            and defined($m)
            and $y =~ /\d{2}|\d{4}/
            and $m =~ /\d{2}/
        );

    my ($this_m, $this_y) = (localtime())[4,5];
    $this_m++;
    $this_y += 1900;

    $this_y =~ s/^..// if ($y =~ /^..$/);

    return "This expiry date appears to have already passed"
        if (
            $y < $this_y
            or ($y == $this_y and $m < $this_m)
        );

    return "This expiry date appears to be too far in the future"
        if (($y - 10) >= $this_y);

    return "OK";
}


=pod

=head1 SEE ALSO

The main perldoc for CGI::FormMagick

=head1 AUTHOR

Kirrily "Skud" Robert <skud@infotrope.net>

More information about FormMagick may be found at 
http://sourceforge.net/projects/formmagick/

=cut

return 1;
