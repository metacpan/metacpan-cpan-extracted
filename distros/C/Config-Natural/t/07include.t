use strict;
use Test;
BEGIN { plan tests => 32 }
use Config::Natural;
Config::Natural->options(-quiet => 1);
my $obj = new Config::Natural;

# read the data from a file which contains an 'include' statement
$obj->read_source(File::Spec->catfile('t','pilots.txt'));

# check the internal filename
ok( $obj->{'state'}{'filename'}, File::Spec->catfile('t','children.txt') );  #01
# check the number of actual parameters
ok( scalar $obj->param, 5 );  #02

# check that the information about the Children is present
ok( $obj->param('First_Children' ), 'Ayanami Rei'         );  #03
ok( $obj->param('Second_Children'), 'Soryu Asuka Langley' );  #04
ok( $obj->param('Third_Children' ), 'Ikari Shinji'        );  #05
ok( $obj->param('Fourth_Children'), 'Suzuhara Toji'       );  #06
ok( $obj->param('Fifth_Children' ), 'Nagisa Kaoru'        );  #07


# idem, but pilots.txt is now in the nerv/ subdirectory
undef $obj;
$obj = new Config::Natural File::Spec->catfile('t','nerv','pilots.txt');

# check the number of actual parameters
ok( scalar $obj->param, 5 );  #08

# check that the information about the Children is present
ok( $obj->param('First_Children' ), 'Ayanami Rei'         );  #09
ok( $obj->param('Second_Children'), 'Soryu Asuka Langley' );  #10
ok( $obj->param('Third_Children' ), 'Ikari Shinji'        );  #11
ok( $obj->param('Fourth_Children'), 'Suzuhara Toji'       );  #12
ok( $obj->param('Fifth_Children' ), 'Nagisa Kaoru'        );  #13


# now reading a file that includes a directory
undef $obj;
$obj = new Config::Natural File::Spec->catdir('t','nerv.txt');

# check that the information about the Nerv is present
my $nerv = $obj->param('nerv');
ok( $nerv->[0]{name}, 'Nerv' );  #14

ok( $nerv->[0]{First_Children},  'Ayanami Rei'         );  #15
ok( $nerv->[0]{Second_Children}, 'Soryu Asuka Langley' );  #16
ok( $nerv->[0]{Third_Children},  'Ikari Shinji'        );  #17
ok( $nerv->[0]{Fourth_Children}, 'Suzuhara Toji'       );  #18
ok( $nerv->[0]{Fifth_Children},  'Nagisa Kaoru'        );  #19

ok( $nerv->[0]{magi}[0]{name}, 'MAGI' );  #20
ok( $nerv->[0]{magi}[0]{brain}[0]{name}, 'Melchior-1' );       #21
ok( $nerv->[0]{magi}[0]{brain}[0]{personality}, 'scientist' ); #22
ok( $nerv->[0]{magi}[0]{brain}[1]{name}, 'Balthasar-2' );      #23
ok( $nerv->[0]{magi}[0]{brain}[1]{personality}, 'mother' );    #24
ok( $nerv->[0]{magi}[0]{brain}[2]{name}, 'Casper-3' );         #25
ok( $nerv->[0]{magi}[0]{brain}[2]{personality}, 'woman' );     #26

ok( defined $nerv->[0]{staff} );               #27
my $staff = $nerv->[0]{staff};
ok( scalar @$staff, 4 );                       #28
for my $person (@$staff) {                     #29,30,31,32
    ok( $person->{role}, "Nerv director and commander" )
        if $person->{name} eq "Ikari Gendo";
    ok( $person->{role}, "Nerv second commander" )
        if $person->{name} eq "Fuyutsuki Kozo";
    ok( $person->{role}, "Project E director" )
        if $person->{name} eq "Akagi Ritsuko";
    ok( $person->{role}, "executive officer" )
        if $person->{name} eq "Katsuragi Misato";
}

