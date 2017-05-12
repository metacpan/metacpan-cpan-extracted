use Test::More 'no_plan';
use strict;

BEGIN {
    chdir 't' if -d 't';

    use File::Spec;
    use lib File::Spec->catdir(qw[.. lib]), 'inc';

    require 'conf.pl';
}

### dummy package declaration to return some
{   package DBIx::Simple::OO::Mock;

    ### make it use these methods instead, for testing purposes
    unshift @DBIx::Simple::Result::ISA, __PACKAGE__;


    ### declare the DBIx::Simple::Result methods
    sub hash    { return { a => 1, b => 2 } }
    sub hashes  { return { a => 1 }, { b => 2 } }
}


my $Class   = 'DBIx::Simple::OO';
my $OClass  = $Class . '::Item';
my $RClass  = 'DBIx::Simple::Result';

use_ok( $Class );

{   my %meth = (            # amount of objects returned
        object      => 1,
        objects     => 2,
    );

    while (my ($meth,$cnt) = each %meth) {

        can_ok( $RClass,         $meth );

        my @res = $RClass->$meth( );
        is( scalar(@res), $cnt, "   Got $cnt results for '$meth'" );

        for my $obj (@res) {
            ok( $obj,           "   Retrieved object" );

            ### ... isa foo will be added by Test::More
            isa_ok( $obj, $OClass,
                                "       Object" );

            my @acc = $obj->ls_accessors;
            ok( scalar(@acc),   "       Accessors retrieved" );
        }
    }
}
