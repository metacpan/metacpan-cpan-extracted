#!perl

use Test::More tests => 4;

END { done_testing }

use Attribute::Universal Test => '';

sub ATTRIBUTE {
    my (
        $package, $symbol, $referent, $attr,
        $data,    $phase,  $filename, $linenum
    ) = @_;
    is( $package       => __PACKAGE__, "package" );
    is( ref($referent) => 'CODE',      "referent type" );
    is( $attr          => 'Test',      "attribute name" );
    is( $phase         => 'CHECK',     "phase" );
}

sub test : Test;
