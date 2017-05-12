use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;
use Test::Deep;

use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

# This is bug #34819, reported by EJS
{
    my $dbm_factory = new_dbm();
    while ( my $dbm_maker = $dbm_factory->() ) {
        my $db = $dbm_maker->();

        my $bar = bless { foo => 'ope' }, 'Foo';

        eval {
            $db->{bar} = $bar;
            $db->{bar} = $bar;
        }; if ( $@ ) { warn $@ }

        ok(!$@, "repeated object assignment");
        isa_ok($db->{bar}, 'Foo');
    }
}
done_testing;
__END__
# This is bug #29957, reported by HANENKAMP
{
    my $dbm_factory = new_dbm();
    while ( my $dbm_maker = $dbm_factory->() ) {
        my $db = $dbm_maker->();

        $db->{foo} = [];

        for my $value ( 1 .. 3 ) {
            lives_ok {
                my $ref = $db->{foo};
                push @$ref, $value;
                $db->{foo} = $ref;
            } "Successfully added value $value";
        }

        cmp_deeply( [1,2,3], noclass($db->{foo}), "Everything looks ok" );
    }
}

# This is bug #33863, reported by PJS
{
    my $dbm_factory = new_dbm();
    while ( my $dbm_maker = $dbm_factory->() ) {
        my $db = $dbm_maker->();

        $db->{foo} = [ 42 ];
        my $foo = shift @{ $db->{foo} };
        cmp_ok( @{ $db->{foo} }, '==', 0, "Shifting a scalar leaves no values" );
        cmp_ok( $foo, '==', 42, "... And the value is correct." );

        $db->{bar} = [ [] ];
        my $bar = shift @{ $db->{bar} };
        cmp_ok( @{ $db->{bar} }, '==', 0, "Shifting an arrayref leaves no values" );

        $db->{baz} = { foo => [ 1 .. 3 ] };
        $db->{baz2} = [ $db->{baz} ];
        my $baz2 = shift @{ $db->{baz2} };
        cmp_ok( @{ $db->{baz2} }, '==', 0, "Shifting an arrayref leaves no values" );
        ok( exists $db->{baz}{foo} );
        ok( exists $baz2->{foo} );
    }
}

done_testing;
