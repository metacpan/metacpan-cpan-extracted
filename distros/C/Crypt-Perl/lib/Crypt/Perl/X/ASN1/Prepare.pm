package Crypt::Perl::X::ASN1::Prepare;

#This shouldn’t happen as long as the templates come from this library.
#But, for completeness …

use strict;
use warnings;

use parent 'Crypt::Perl::X::Base';

sub new {
    my ($class, $template, $error) = @_;

    my $tfrag = substr( $template, 0, 32 );
    $tfrag =~ tr<\r\n>< >s;

    return $class->SUPER::new( "Failed to prepare ASN.1 template ($tfrag): $error", { asn => $template, error => $error } );
}

1;
