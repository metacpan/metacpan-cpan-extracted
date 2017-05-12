use strict;
use Test;
BEGIN { plan tests => 27 }
use Config::Natural;
use File::Spec;
Config::Natural->options(-quiet => 1);
my $obj = new Config::Natural;

$obj->read_source(File::Spec->catfile('t','nerv.txt'));

# first, we check that the different forms of the syntax 
# all work as expected
ok( $obj->value_of("/nerv/First_Children"),       "Ayanami Rei"   );  #01
ok( $obj->value_of("/nerv[0]/First_Children"),    "Ayanami Rei"   );  #02
ok( $obj->value_of("/nerv/First_Children[0]"),    "Ayanami Rei"   );  #03
ok( $obj->value_of("/nerv[0]/First_Children[0]"), "Ayanami Rei"   );  #04

# then we check that these values really doesn't exist
ok( $obj->value_of("/nerv[1]/First_Children"),    undef           );  #05

# now we check with real lists
ok( $obj->value_of("/nerv/magi/name"),            "MAGI"          );  #06
ok( $obj->value_of("/nerv/magi/brain/name"),      "Melchior-1"    );  #07
ok( $obj->value_of("/nerv/magi/brain[0]/name"),   "Melchior-1"    );  #08
ok( $obj->value_of("/nerv/magi/brain[1]/name"),   "Balthasar-2"   );  #09
ok( $obj->value_of("/nerv/magi/brain[2]/name"),   "Casper-3"      );  #10

# next we want value_of() to return the arrayref
my $brains = $obj->value_of("/nerv/magi/brain[*]");
ok( ref $brains, 'ARRAY'                                          );  #11
ok( $brains->[0]{'name'}, "Melchior-1"                            );  #12
ok( $brains->[1]{'name'}, "Balthasar-2"                           );  #13
ok( $brains->[2]{'name'}, "Casper-3"                              );  #14

my $staff = $obj->value_of("/nerv/staff[*]");
ok( ref $staff, 'ARRAY'                                           );  #15
for my $person (@$staff) {                                            #16,17,18,19
    ok( $person->{role}, "Nerv director and commander" )
        if $person->{name} eq "Ikari Gendo";
    ok( $person->{role}, "Nerv second commander" )
        if $person->{name} eq "Fuyutsuki Kozo";
    ok( $person->{role}, "Project E director" )
        if $person->{name} eq "Akagi Ritsuko";
    ok( $person->{role}, "executive officer" )
        if $person->{name} eq "Katsuragi Misato";
}

# then we check that we can use negative indexes
ok( $obj->value_of("/nerv[-1]/First_Children"),     "Ayanami Rei" );  #20
ok( $obj->value_of("/nerv/First_Children[-1]"),     "Ayanami Rei" );  #21
ok( $obj->value_of("/nerv[-1]/First_Children[-1]"), "Ayanami Rei" );  #22
ok( $obj->value_of("/nerv[-2]/First_Children"),     undef         );  #23

ok( $obj->value_of("/nerv/magi/brain[-1]/name"),    "Casper-3"    );  #24
ok( $obj->value_of("/nerv/magi/brain[-2]/name"),    "Balthasar-2" );  #25
ok( $obj->value_of("/nerv/magi/brain[-3]/name"),    "Melchior-1"  );  #26
ok( $obj->value_of("/nerv/magi/brain[-4]/name"),    undef         );  #27
