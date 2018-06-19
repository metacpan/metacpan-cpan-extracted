package Crypt::Perl::ASN1::BitString;

use strict;
use warnings;

use Crypt::Perl::X ();

sub encode {
    my ($field_ar, $flags_ar) = @_;

    my @unknown;
    for my $fl ( @$flags_ar ) {
        push @unknown, $fl if !grep { $_ eq $fl } @$field_ar;
    }

    if (@unknown) {
        die Crypt::Perl::X::create('Generic', "Unknown flag(s): [@unknown] (Accepted values: [@$field_ar])");
    }

    my $str = q<>;

    for my $f ( 0 .. $#$field_ar ) {
        $str .= (grep { $_ eq $field_ar->[$f] } @$flags_ar) ? 1 : 0;
    }

    return pack 'B*', $str;
}

1;
