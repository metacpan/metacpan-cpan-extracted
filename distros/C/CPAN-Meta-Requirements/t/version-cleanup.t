use strict;
use warnings;

use CPAN::Meta::Requirements;
use version;

use Test::More 0.88;

my @cases = (
    [ "2-part literal v-string" => v1.2 => "v1.2.0" ],
    [ "1-part literal v-string" => v1 => "v1.0.0" ],
    [ "1-part literal v-string (0)" => v0 => "v0.0.0" ],
);

for my $c (@cases) {
    my ($label, $input, $expect) = @$c;
    my $req = CPAN::Meta::Requirements->new();
    $req->add_minimum('Foo::Baz' => $input );
    is( $req->requirements_for_module('Foo::Baz'), $expect, $label );
}


done_testing;
