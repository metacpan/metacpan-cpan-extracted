#!perl

use Test::More tests => 4;

END { done_testing }

use Attribute::Universal Test => '';

sub ATTRIBUTE {
    my (
        $package, $symbol, $referent, $attr,
        $data,    $phase,  $filename, $linenum
    ) = @_;
    my $name = *{$symbol}{NAME};
    is( uc($name), ref($referent), "type" );
}

sub Code : Test;
our $Scalar : Test;
our @Array : Test;
our %Hash : Test;
