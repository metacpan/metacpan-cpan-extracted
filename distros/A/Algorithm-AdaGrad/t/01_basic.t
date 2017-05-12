use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Algorithm::AdaGrad;

subtest 'simple' => sub {

    my $ag = Algorithm::AdaGrad->new(0.1);

    $ag->update( [ { label => 1, features => { "a" => 1.0, } }, { label => -1, features => { "b" => 1.5, } }, ] );

    is $ag->classify( { "a" => 1.0 } ), 1;
    is $ag->classify( { "b" => 1.0 } ), -1;
};

subtest 'multi-feature' => sub {
    my $testdata = [
        { "label" => 1,  "features" => { "R" => 1.0, "G" => 0.0, "B" => 0.0 } },
        { "label" => -1, "features" => { "R" => 0.0, "G" => 1.0, "B" => 0.0 } },
        { "label" => -1, "features" => { "R" => 0,   "G" => 0,   "B" => 1 } },
        { "label" => -1, "features" => { "R" => 0.0, "G" => 1.0, "B" => 1.0 } },
        { "label" => 1,  "features" => { "R" => 1.0, "G" => 0.0, "B" => 1.0 } },
        { "label" => 1,  "features" => { "R" => 1.0, "G" => 1.0, "B" => 0.0 } }
    ];

    my $ag = Algorithm::AdaGrad->new(1);

    $ag->update($testdata);

    is $ag->classify( { "R" => 1.0, "G" => 0.0, "B" => 0.0 } ), 1;
    is $ag->classify( { "R" => 0,   "G" => 1,   "B" => 0 } ),   -1;
    is $ag->classify( { "R" => 0.0, "G" => 0.0, "B" => 1.0 } ), -1;
    is $ag->classify( { "R" => 0.0, "G" => 1.0, "B" => 1.0 } ), -1;
    is $ag->classify( { "R" => 1.0, "G" => 0.0, "B" => 1.0 } ), 1;
    is $ag->classify( { "R" => 1.0, "G" => 1.0, "B" => 0.0 } ), 1;
};

subtest 'exception' => sub {
    like exception { my $ag = Algorithm::AdaGrad->new('test'); }, qr/Parameter must be a number./;

    my $ag = Algorithm::AdaGrad->new();
    like exception { $ag->update( ['test'] ) }, qr/Invalid parameter: parameter must be HASH-reference/;
    like exception { $ag->update( [ { features => { "a" => 1.0, } } ] ); },
        qr/Invalid parameter: \"label\" does not exist\./;
    like exception { $ag->update( [ { label => 0, features => { "a" => 1.0, } } ] ); },
        qr/Invalid parameter: \"label\" must be 1 or -1\./;
    like exception { $ag->update( [ { label => 1.0, features => { "a" => 1.0, } } ] ); },
        qr/Invalid parameter: \"label\" must be 1 or -1\./;

    like exception { $ag->update( [ { label => 1, dat => { "a" => 1.0, } } ] ); },
        qr/Invalid parameter: \"features\" does not exist\./;
    like exception { $ag->update( [ { label => 1, features => '' } ] ); },
        qr/Invalid parameter: \"features\" must be HASH-reference\./;
    like exception { $ag->update( [ { label => 1, features => { a => 'test' } } ] ); },
        qr/Invalid parameter: type of internal \"features\" must be number\./;

    $ag->update( [ { label => 1, features => { "a" => 1.0, } }, ] );

    like exception { $ag->classify( [] ); }, qr/Invalid parameter: Parameter must be HASH-reference\./;
    like exception { $ag->classify( { a => 'test' } ); }, qr/Invalid parameter: type of parameter must be number\./;
};

done_testing();
