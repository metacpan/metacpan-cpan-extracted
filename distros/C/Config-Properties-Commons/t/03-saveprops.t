#!perl

####################
# LOAD CORE MODULES
####################
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Deep;

# Autoflush ON
local $| = 1;

####################
# LOAD DIST MODULES
####################
use Config::Properties::Commons;

# use Data::Printer;

####################
# RUN TESTS
####################

# Init object
#   with defaults
my $cpc = Config::Properties::Commons->new(
    defaults => {
        foo => 'bar',
    }
);

# Add property
$cpc->add_property( key1 => 'value1' );
$cpc->add_property( key1 => 'value2' );

cmp_deeply(

    # Got
    { $cpc->properties() },

    # Expected
    {
        foo  => 'bar',
        key1 => [ 'value1', 'value2' ],
    },
);

# Set
$cpc->set_property( key2 => [ 'value1', 'value2', ] );
$cpc->set_property( key3 => 'value1' );
$cpc->set_property( key4 => 'value4.1,value4.2' );
cmp_deeply(

    # Got
    { $cpc->properties() },

    # Expected
    {
        foo  => 'bar',
        key1 => [ 'value1', 'value2' ],
        key2 => [ 'value1', 'value2' ],
        key3 => 'value1',
        key4 => 'value4.1,value4.2',
    },
);

# Save
my $str1 = $cpc->save_to_string();
my $str2 = $cpc->save_to_string(
    save_combine_tokens => 1,
    save_separator      => ' : ',
    header              => '#--',
    footer              => '#--',
);

my $str1_exp = <<'EOSTR1';
###############

foo = bar
key1 = value1
key1 = value2

key2 = value1
key2 = value2

key3 = value1
key4 = value4.1\, value4.2

###############

EOSTR1

my $str2_exp = <<'EOSTR2';
#--

foo : bar
key1 : value1, value2
key2 : value1, value2
key3 : value1
key4 : value4.1\, value4.2

#--

EOSTR2

ok( $str1 eq $str1_exp );
ok( $str2 eq $str2_exp );

####################
# DONE
####################
done_testing();
exit 0;
