#!perl

####################
# LOAD CORE MODULES
####################
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Deep;

use FindBin qw($RealBin);

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

my $data_dir = "$RealBin/data";
my $file1    = "${data_dir}/00/prop1";
my $file2    = "${data_dir}/00/prop2";

# Init object
my $cpc = Config::Properties::Commons->new();

# Load file
$cpc->load("${data_dir}/00/prop1");
my %prop1         = $cpc->properties();
my @loaded_files1 = $cpc->get_files_loaded();

# p %prop1;

# Verify Files loaded
cmp_deeply(

    # Got
    \@loaded_files1,

    # Expected
    [ $file1, $file2, ],

    'Files Loaded #1',
);

# Verify Properties Loaded
cmp_deeply(

    # Got
    {%prop1},

    # Expected
    {
        # From prop1
        'key1'      => 'value1',
        'key2'      => 'value2',
        'key3'      => 'value3',
        'key\:foo'  => 'bar',
        'blank_key' => '',

        # From prop2
        'key' => 'value',
        'longvalue' =>
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'tokens_on_a_line'         => [ 'first token', 'second token' ],
        'tokens_on_multiple_lines' => [ 'first token', 'second token' ],
        'commas.escaped'           => q{Hi, what'up?},
        'base.prop'                => '/base',
        'first.prop'               => '/base/first',
        'second.prop'              => '/base/first/second',
    },
    'Properties Loaded #1',
);

# Load from a different basedir
#  using a handle

my $file3 = "${data_dir}/00/prop3";
my $file4 = "${data_dir}/01/prop4";

open( my $fh3, '<', $file3 ) or die "Failed to open $file3 : $!\n";
$cpc->load(
    $fh3,
    includes_basepath => "${data_dir}/01",
);
close($fh3);

my %prop2         = $cpc->properties();
my @loaded_files2 = $cpc->get_files_loaded();

# Verify Files loaded
cmp_deeply(

    # Got
    \@loaded_files2,

    # Expected
    [
        @loaded_files1,  # From #1
                         # $file3, # Oops, file3 is loaded via handle
        $file4,
    ],

    'Files Loaded #2',
);

# Verify Properties Loaded
cmp_deeply(

    # Got
    {%prop2},

    # Expected
    {
        %prop1,  # From #1
        'key' => [ $prop1{key}, 'This property', 'has multiple', 'values' ],
    },
    'Properties Loaded #2',
);

# Load without includes
#   and force array
$cpc->clear_properties();
$cpc->load(
    $file3, {
        process_includes     => 0,
        force_value_arrayref => 1,
    }
);

my %prop3         = $cpc->properties();
my @loaded_files3 = $cpc->get_files_loaded();

# Verify Files loaded
cmp_deeply(

    # Got
    \@loaded_files3,

    # Expected
    [ $file3, ], 'Files loaded #3',
);

# Verify Properties Loaded
cmp_deeply(

    # Got
    {%prop3},

    # Expected
    {
        include => [ 'prop4', ],
    },
    'Properties Loaded #3',
);

####################
# DONE
####################
done_testing();
exit 0;
