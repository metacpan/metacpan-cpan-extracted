use strict;
use Test;
BEGIN { plan tests => 12 }
use Config::Natural;
Config::Natural->options(-quiet => 1);
my $obj = new Config::Natural;

# hook up an (Asuka-like) handler
$obj->set_handler('Third_Children', sub{"baka ".(split' ',$_[1])[1]."!!"});
ok( $obj->has_handler('Third_Children') );  #01

# read the data from a file
$obj->read_source(File::Spec->catfile('t','children.txt'));
ok( $obj->param('First_Children' ), 'Ayanami Rei'         );  #02
ok( $obj->param('Second_Children'), 'Soryu Asuka Langley' );  #03
ok( $obj->param('Third_Children' ), 'baka Shinji!!'       );  #04
ok( $obj->param('Fourth_Children'), 'Suzuhara Toji'       );  #05
ok( $obj->param('Fifth_Children' ), 'Nagisa Kaoru'        );  #06


# delete the handler
$obj->delete_handler('Third_Children');
ok( not $obj->has_handler('Third_Children') );  #07

# hook up an handler to update Misato's role with her grade
$obj->set_handler(role => sub {$_[1] eq "executive officer" ? $_[1] .= " (Major)" : $_[1]});
ok( $obj->has_handler('role') );  #08

# reading further data; note that the children values will
# be overwritten with the new ones
$obj->read_source(File::Spec->catfile('t','nerv.txt'));

# now Misato's role should include her grade
# but the others' role should be unchanged
my $nerv = $obj->param('nerv');
my $staff = $nerv->[0]{staff};
for my $person (@$staff) {                     #09,10,11,12
    ok( $person->{role}, "Nerv director and commander" )
        if $person->{name} eq "Ikari Gendo";
    ok( $person->{role}, "Nerv second commander" )
        if $person->{name} eq "Fuyutsuki Kozo";
    ok( $person->{role}, "Project E director" )
        if $person->{name} eq "Akagi Ritsuko";
    ok( $person->{role}, "executive officer (Major)" )
        if $person->{name} eq "Katsuragi Misato";
}

