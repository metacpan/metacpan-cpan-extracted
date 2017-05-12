#!perl

####################
# LOAD CORE MODULES
####################
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Deep;

use File::Temp;
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

# Init object
my $cpc = Config::Properties::Commons->new();

my %props_set = (
    key   => 'value',
    foo   => [qw(bar baz)],
    long  => 'a' x 55 . "\n" . 'A' x 55,
    blank => '',
);

# set
foreach ( keys %props_set ) {
    $cpc->set_property(
        $_ => $props_set{$_},
    );
} ## end foreach ( keys %props_set )

# Get tempfile
my $temp = File::Temp->new(
    DIR => $data_dir,
);
my $tempfile = $temp->filename();

# Save
$cpc->save($tempfile);

# Reload
my $cpc2 = Config::Properties::Commons->new( load_file => $tempfile );
my %props_got = $cpc2->properties();

# $temp->unlink_on_destroy(0);
# p %props_got;

# Verify
cmp_deeply( {%props_got}, {%props_set} );

####################
# DONE
####################
done_testing();
exit 0;
