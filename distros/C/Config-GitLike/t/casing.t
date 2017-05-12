use strict;
use warnings;

use Test::More;
use File::Spec;
use Cwd;
use File::Temp qw/tempdir/;
use lib 't/lib';
use TestConfig;

my $config_dirname = Cwd::abs_path( tempdir( CLEANUP => !$ENV{CONFIG_GITLIKE_DEBUG} ) );
my $config_filename = File::Spec->catfile( $config_dirname, 'config' );

diag "config file is: $config_filename" if $ENV{TEST_VERBOSE};

my $config = TestConfig->new(
    confname => 'config',
    tmpdir => $config_dirname,
);
$config->load;

$config->set(
    key      => 'core.FooBar',
    value    => 'baz',
    filename => $config_filename,
);

my $expect = qq{[core]\n\tFooBar = baz\n};
is( $config->slurp, $expect, 'mixed-case key is preserved when written' );

$config->load;
is $config->get( key => 'core.FooBar' ), "baz", "Can be referenced with original case";
is $config->get( key => 'core.foobar' ), "baz", "Can be referenced with lower case";
is $config->get( key => 'core.FOObar' ), "baz", "Can be referenced with different case";

is $config->original_key( 'core.FooBar' ), "core.FooBar",
    "Find original case when asked in original case";
is $config->original_key( 'core.foobar' ), "core.FooBar",
    "Find original case when asked in lower case";
is $config->original_key( 'core.FOObar' ), "core.FooBar",
    "Find original case when asked in different case";


my $other_filename = File::Spec->catfile( $config_dirname, 'other' );
$config->set(
    key      => 'core.fooBAR',
    value    => 'troz',
    filename => $other_filename,
);
is $config->get( key => 'core.FooBar' ), "baz",
    "->set without ->load does not alter value in ->get";
$config->load_file( $other_filename );

is $config->origins->{'core.foobar'}, $other_filename,
    "Found definition from second file";
is $config->get( key => 'core.foobar' ), "troz",
    "Loaded value from second file";

is $config->original_key( 'core.foobar' ), "core.fooBAR",
    "Find new case in second file";

$config->set_multiple( "core.FOOBAR" );
is $config->is_multiple( "core.FoObAr" ), 1,
    "multiple respects any case";

$config->set(
    key      => 'core.fOObAR',
    value    => 'zort',
    filename => $other_filename,
);

$config->set(
    key      => 'core.fOobAr',
    value    => 'poit',
    filename => $other_filename,
);

$expect = qq{[core]\n\tfooBAR = troz\n\tfOObAR = zort\n\tfOobAr = poit\n};
is( $config->slurp($other_filename), $expect, 'mixed-case key is preserved when written as multiple' );

# Since we cache which files are loaded, so we can't just call
# ->load_file( $other_filename ) again to get the updated value.
# Instead, re-create the object and load each file again.
$config = TestConfig->new(
    confname => 'config',
    tmpdir => $config_dirname,
);
$config->load;
is $config->get( key => 'core.FooBar' ), "baz", "Got original value";
is $config->original_key( 'core.FooBar' ), "core.FooBar", "Got original case";

ok $config->load_file( $other_filename ), "Loaded second file";
is $config->is_multiple( "core.foobar" ), 1, "Is marked as multiple";
is_deeply scalar $config->get_all( key => 'core.foobar' ), ["troz", "zort", "poit"],
    "Got all three new values";
is_deeply $config->original_key( 'core.foobar' ), ["core.fooBAR", "core.fOObAR", "core.fOobAr" ],
    "Got all three new casings";

done_testing;
