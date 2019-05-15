#########################

use strict;
use warnings;

use Test::More tests => 3;
use Data::Dumper; $Data::Dumper::Sortkeys=1; $Data::Dumper::Useqq=1;
BEGIN { use_ok('Algorithm::MinPerfHashTwoLevel') };

#########################

my $class= "Algorithm::MinPerfHashTwoLevel";
my $o= $class->new("seed"=>"1234567812345678",debug=>$ENV{TEST_VERBOSE},variant=>1);
my (%bad,$data);

%bad= ("x"=>"whatever","y"=>"z","p"=>"q");

for my $bad_tuple (
    [ [],               "value too long",   qr/Error: Not expecting a reference value/  ],
    [ "x" x 0x10000,    "ref value",        qr/Error: String in source hash is too long to store/  ]
) {
    my ($val,$name,$like)= @$bad_tuple;
    my $ok= eval {
        $bad{x}= $val;
        $data= $o->compute(\%bad);
        1;
    };
    my $msg= $ok ? "ok" : $@ || "Zombie Error";
    like($msg, $like, $name);
}

