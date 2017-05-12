use strict;
use warnings;
use Test::More;
use Test::Fatal qw(exception lives_ok);
use File::Temp;

use Algorithm::AdaGrad;

subtest 'save_and_load' => sub {
    my $testdata = [
        { "label" => 1,  "features" => { "R" => 1.0, "G" => 0.0, "B" => 0.0 } },
        { "label" => -1, "features" => { "R" => 0.0, "G" => 1.0, "B" => 0.0 } },
        { "label" => -1, "features" => { "R" => 0,   "G" => 0,   "B" => 1 } },
        { "label" => -1, "features" => { "R" => 0.0, "G" => 1.0, "B" => 1.0 } },
        { "label" => 1,  "features" => { "R" => 1.0, "G" => 0.0, "B" => 1.0 } },
        { "label" => 1,  "features" => { "R" => 1.0, "G" => 1.0, "B" => 0.0 } }
    ];

    my $ag = Algorithm::AdaGrad->new(0.1);

    $ag->update($testdata);
    
    my $dumpfile = File::Temp->new();
    
    #lives_ok {
        $ag->save( $dumpfile->filename );
    #};
    
    my $ag2 = Algorithm::AdaGrad->new();
    lives_ok {
        $ag2->load( $dumpfile->filename );
    };
    
    is $ag->classify( { "R" => 1.0, "G" => 0.0, "B" => 0.0 } ), 1;
    is $ag->classify( { "R" => 0,   "G" => 1,   "B" => 0 } ),   -1;
    is $ag->classify( { "R" => 0.0, "G" => 0.0, "B" => 1.0 } ), -1;
    is $ag->classify( { "R" => 0.0, "G" => 1.0, "B" => 1.0 } ), -1;
    is $ag->classify( { "R" => 1.0, "G" => 0.0, "B" => 1.0 } ), 1;
    is $ag->classify( { "R" => 1.0, "G" => 1.0, "B" => 0.0 } ), 1;
};

done_testing();