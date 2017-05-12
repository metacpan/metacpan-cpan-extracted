use strict;
use warnings;

use Test::More tests => 7;
use Arepa::Builder::Sbuildfake;
use Arepa::Config;
use File::Path;
use File::Spec;

use constant TEST_CONFIG_FILE         => 't/config-test.yml';

eval {
    Arepa::Builder->ui_module("Arepa::UI::IDontExist");
};
ok($@, "You shouldn't be able to set an invalid UI module");

my $conf = Arepa::Config->new(TEST_CONFIG_FILE,
                              builder_config_dir =>
                                          't/builders-sbuildfake');
my %builder_conf = $conf->get_builder_config('lenny32');
my $builder = Arepa::Builder::Sbuildfake->new(%builder_conf);
is($builder->name, 'lenny32');

my $tmp_dir = 't/tmp';
rmtree($tmp_dir);
mkpath($tmp_dir);
ok($builder->compile_package_from_dsc('t/fixtures/qux_1.0-1.dsc',
                                      output_dir => $tmp_dir),
   "Fake compilation should succeed");
ok(-r File::Spec->catfile($tmp_dir, "qux_1.0-1_i386.deb"),
   "After 'compiling', the result should be in the current directory");



# Try to compile non-existing package
rmtree($tmp_dir);
mkpath($tmp_dir);

my %builder2_conf = $conf->get_builder_config('etch32');
my $builder2 = Arepa::Builder::Sbuildfake->new(%builder2_conf);
is($builder2->name, 'etch32');

ok(! $builder2->compile_package_from_dsc('t/fixtures/qux_1.0-1.dsc',
                                         output_dir => $tmp_dir),
   "Fake compilation should NOT succeed when there isn't a build result");
ok(!-r File::Spec->catfile($tmp_dir, "qux_1.0-1_i386.deb"),
   "After failing to compile, there should NOT be any results");
