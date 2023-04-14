package Business::IBAN::Util;
use warnings;
use strict;

use Exporter 'import';
our @EXPORT_OK = qw( numify_iban mod97 );

my %lettermap = do {
    my $i = 10;
    map +($_ => $i++), 'A'..'Z';
};

sub numify_iban {
    my ($iban) = @_;

    my $to_check = substr($iban, 4) . substr($iban, 0, 4);
    $to_check =~ s/([A-Za-z])/$lettermap{uc($1)}/g;

    return $to_check;
}

sub mod97 {
    my ($number) = @_;

    # Max 9 digits, safe for 32bit INT
    my ($r, $l) = (0, 9);
    while ($number =~ s/^([0-9]{1,$l})//) {
        $r = $r . $1;
        $r %= 97;
        $l = 9 - length($r);
    }
    return $r;
}

1;

=head1 NAME

Business::IBAN::Util - Helpers for the IBAN 97-test.

=head1 SYNOPSIS

    #! /usr/bin/perl -w
    use v5.14.0; # strict + feature

    use Business::IBAN::Util qw( numify_iban mod97 );

    print "IBAN: "; chomp(my $iban = <>);
    my $as_num = numify_iban($iban);
    my ($old_check) = $as_num =~ s{ (..) $}{00}x;
    my $rest = mod97($as_num);
    my $new_check = 98 - $rest;
    if ($old_check != $new_check) {
        my $new_iban = $iban; substr($new_iban, 2, 2, sprintf("%02u", $new_check));
        say "Checksum not ok, should be $new_check: $new_iban"
    }
    else {
        say "Checksum ok: $iban";
    }

=head1 DESCRIPTION

These are helper functions to execute the 97-check on IBANs.

=head2 numify_iban($iban)

Put the first four characters at the end of the string. Transform all letters
into numbers ([Aa] => 10 .. [Zz] => 35). This results in a string of digits
[0-9] that will be used as a number for the 97-check.

=head2 mod97($number)

Returns the remainder of division by 97 (for a valid IBAN that should be 1).

=head1 COPYRIGHT

E<copy> MMXIII - Abe Timmerman <abeltje@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
