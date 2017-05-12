use Test::More 'no_plan';
use strict;

BEGIN {
    chdir 't' if -d 't';

    use File::Spec;
    use lib File::Spec->catdir(qw[.. lib]), 'inc';

    require 'conf.pl';
}

my $Class   = 'DBIx::Simple::OO';
my $OClass  = $Class . '::Item';
my $RClass  = 'DBIx::Simple::Result';

my $Map     = {
    foo     => 1,
    bar     => '',
    zot     => undef,
    quux    => bless( {}, 'X' ),
    xyzzy   => [],
    grue    => {},
    wibble  => $0,
};

use_ok( $Class );

my $Obj = $RClass->_href_to_obj( $Map );

### check if the object is ok
{   ok( $Obj,                   "Object created from hashref" );
    isa_ok( $Obj,               $OClass );
    isa_ok( $Obj,               "Object::Accessor" );
}

### check if all accessors match all keys and vice versa ###
{   is_deeply( [sort keys %$Map], [sort $Obj->ls_accessors],
                                "All keys present as accessors" );

    for my $acc ( $Obj->ls_accessors ) {
        is( $Obj->$acc, $Map->{$acc},
                                "   '$acc' set to proper value" );
    }
}


