package t::foobar;

use strict;
use warnings;
use Test::More;
use Attribute::Universal ();

sub ATTRIBUTE {
    my (
        $package, $symbol, $referent, $attr,
        $data,    $phase,  $filename, $linenum
    ) = @_;
    is( $package       => 'main',  "package" );
    is( ref($referent) => 'CODE',  "referent type" );
    is( $attr          => 'Test',  "attribute name" );
    is( $phase         => 'CHECK', "phase" );
}

sub import {
    my $caller = scalar caller;
    is( $caller => 'main', 'caller' );
    Attribute::Universal->import_into( $caller, Test => '' );
}

1;
