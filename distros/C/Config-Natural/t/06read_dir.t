use strict;
use Test;
BEGIN { plan tests => 30 }
use Config::Natural;
Config::Natural->options(-quiet => 1);
my $obj = new Config::Natural;

# read the data from a directory
$obj->read_source(File::Spec->catdir('t','nerv'));

# check that information about MAGI is present
ok( defined $obj->param('magi') );                    #01
my $magi = $obj->param('magi');
ok( $magi->[0]{name}, 'MAGI' );                       #02
ok( $magi->[0]{brain}[0]{name}, 'Melchior-1' );       #03
ok( $magi->[0]{brain}[0]{personality}, 'scientist' ); #04
ok( $magi->[0]{brain}[1]{name}, 'Balthasar-2' );      #05
ok( $magi->[0]{brain}[1]{personality}, 'mother' );    #06
ok( $magi->[0]{brain}[2]{name}, 'Casper-3' );         #07
ok( $magi->[0]{brain}[2]{personality}, 'woman' );     #08

# check that the information about Nerv staff is present
ok( defined $obj->param('staff') );            #09
my $staff = $obj->param('staff');
ok( scalar @$staff, 4 );                       #10
for my $person (@$staff) {                     #11,12,13,14
    ok( $person->{role}, "Nerv director and commander" )
        if $person->{name} eq "Ikari Gendo";
    ok( $person->{role}, "Nerv second commander" )
        if $person->{name} eq "Fuyutsuki Kozo";
    ok( $person->{role}, "Project E director" )
        if $person->{name} eq "Akagi Ritsuko";
    ok( $person->{role}, "executive officer" )
        if $person->{name} eq "Katsuragi Misato";
}

# check that a hidden file was *not* read
ok( $obj->param('Marduk'), $obj->read_hidden_files ? 'Nerv' : undef );  #15


# now re-read everything but with read_hidden_files enabled
undef $obj;
$obj = new Config::Natural;
$obj->read_hidden_files(1);
$obj->read_source(File::Spec->catdir('t','nerv'));

# check that information about MAGI is still present
ok( defined $obj->param('magi') );                    #16
$magi = $obj->param('magi');
ok( $magi->[0]{name}, 'MAGI' );                       #17
ok( $magi->[0]{brain}[0]{name}, 'Melchior-1' );       #18
ok( $magi->[0]{brain}[0]{personality}, 'scientist' ); #19
ok( $magi->[0]{brain}[1]{name}, 'Balthasar-2' );      #20
ok( $magi->[0]{brain}[1]{personality}, 'mother' );    #21
ok( $magi->[0]{brain}[2]{name}, 'Casper-3' );         #22
ok( $magi->[0]{brain}[2]{personality}, 'woman' );     #23

# check that the information about Nerv staff is still present
ok( defined $obj->param('staff') );            #24
$staff = $obj->param('staff');
ok( scalar @$staff, 4 );                       #25
for my $person (@$staff) {                     #26,27,28,29
    ok( $person->{role}, "Nerv director and commander" )
        if $person->{name} eq "Ikari Gendo";
    ok( $person->{role}, "Nerv second commander" )
        if $person->{name} eq "Fuyutsuki Kozo";
    ok( $person->{role}, "Project E director" )
        if $person->{name} eq "Akagi Ritsuko";
    ok( $person->{role}, "executive officer" )
        if $person->{name} eq "Katsuragi Misato";
}

# check that the hidden file *was* read
ok( $obj->param('Marduk'), 'Nerv' );  #30
