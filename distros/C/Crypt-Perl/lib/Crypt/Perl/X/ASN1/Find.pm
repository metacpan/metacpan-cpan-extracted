package Crypt::Perl::X::ASN1::Find;

#This shouldn’t happen as long as the commands come from this library.
#But, for completeness …

use strict;
use warnings;

use parent 'Crypt::Perl::X::Base';

sub new {
    my ($class, $macro, $error) = @_;

    my %attrs = (
        macro => $macro,
        error => $error,
    );

    if ($error) {
        return $class->SUPER::new( "Failed to find ASN.1 macro “$macro”: $error", \%attrs );
    }

    return $class->SUPER::new( "Failed to find ASN.1 macro “$macro”!", \%attrs );
}

1;
