#! perl

use Test::Simple tests => 3;

use Data::Dimensions qw(&units extended);

my $foo = units({m=>1});
my $bar = Data::Dimensions->new({m=>1});

eval {
    $bar->set = 3;
    $foo->set = $bar;
};
ok(!$@, "importing '&units' works");

# Check SYNOPSIS section of pod

my $energy = Data::Dimensions->new( {joule => 1} );
# or, more simply...
my $mass   = units( {kg =>1 } );
my $c      = units( {m=>1, s=>-1} );

$mass->set = 10;
$c->set = 299_792_458;
    
eval {
# checks that units of mc^2 same as energy
   $energy->set = $mass * $c**2;
};

ok(!$@, "SYNOPSIS working");

eval {
# made a mistake on right, so dies with error
    $energy->set = $mass * $c**3;
};
ok($@, " 'mistake' in SYNOPSIS detected");
