# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it hsould work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 17 };
use Class::WeakSingleton;
ok(1); # If we made it this far, we're ok.

#########################

#========================================================================
#                         -- CLASS DEFINTIONS --
#========================================================================

#------------------------------------------------------------------------
# define 'DerivedSingleton', a class derived from Class::WeakSingleton 
#------------------------------------------------------------------------

package DerivedSingleton;
use base 'Class::WeakSingleton';

#------------------------------------------------------------------------
# define 'AnotherSingleton', a class derived from DerivedSingleton 
#------------------------------------------------------------------------

package AnotherSingleton;
use base 'DerivedSingleton';


#------------------------------------------------------------------------
# define 'ArraySingleton', which uses an array reference as its type
#------------------------------------------------------------------------

package ArraySingleton;
use base 'Class::WeakSingleton';

sub _new_instance { bless [], shift }


#------------------------------------------------------------------------
# define 'ConfigSingleton', which has specific configuration needs.
#------------------------------------------------------------------------

package ConfigSingleton;
use base 'Class::WeakSingleton';

sub _new_instance {
    my $class  = shift;
    my $config = shift || { };
    my $self = {
	'one' => 'This is the first parameter',
	'two' => 'This is the second parameter',
	%$config,
    };
    bless $self, $class;
}



#========================================================================
#                                -- TESTS --
#========================================================================

package main;

use warnings FATAL => 'all';

{
    my %h;
    {
        # call Class::WeakSingleton->instance() twice and expect to get the same 
        # reference returned on both occasions.
        my $s1 = Class::WeakSingleton->instance();
        my $s2 = Class::WeakSingleton->instance();
	
        ok( $s1 == $s2 ); # Test 4
	ok( $s1 == Class::WeakSingleton->instance );
        ok( $Class::WeakSingleton::_instance == $s1 ); # Test 5

        $h{test} = $s1;
    }

    ok( $Class::WeakSingleton::_instance ); # Test 6
}
ok( not defined $Class::WeakSingleton::_instance ); # Test 7

{
    {
        # call MySingleton->instance() twice and expect to get the same 
        # reference returned on both occasions.

        my $s3 = DerivedSingleton->instance();
        my $s4 = DerivedSingleton->instance();
        $s5 = DerivedSingleton->instance;

        ok( $s3 == $s4 );
        ok( $s4 == $s5 );
    }

    ok( $s5 == DerivedSingleton->instance );
    undef $s5;
    
    ok( not $DerivedSingleton::_instance );
}

{
    # call MyOtherSingleton->instance() twice and expect to get the same 
    # reference returned on both occasions.

    my $s5 = AnotherSingleton->instance();
    my $s6 = AnotherSingleton->instance();

    ok( $s5 == $s6 );
}

#------------------------------------------------------------------------
# having checked that each instance of the same class is the same, we now
# check that the instances of the separate classes are actually different 
# from each other 
#------------------------------------------------------------------------

ok( Class::WeakSingleton->instance != DerivedSingleton->instance and
    DerivedSingleton->instance     != AnotherSingleton->instance );


#------------------------------------------------------------------------
# test ArraySingleton
#------------------------------------------------------------------------

{
    my $as1 = ArraySingleton->instance();
    my $as2 = ArraySingleton->instance();
    
    ok( $as1 == $as2 );
    ok( UNIVERSAL::isa( $as1, 'ARRAY' ) );
}


#------------------------------------------------------------------------
# test ConfigSingleton
#------------------------------------------------------------------------

# create a ConfigSingleton
{
    my $config = { 'foo' => 'This is foo' };
    my $cs1 = ConfigSingleton->instance($config);
    
    # add another parameter to the config
    $config->{'bar'} = 'This is bar';

    # shouldn't call new() so changes to $config shouldn't matter
    my $cs2 = ConfigSingleton->instance($config);

    ok( $cs1 == $cs2 );
    ok( 3 == scalar keys %$cs1 );
    ok( 3 == scalar keys %$cs2 );
}





