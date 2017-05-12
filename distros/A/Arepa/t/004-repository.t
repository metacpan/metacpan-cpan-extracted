use strict;
use warnings;

use Test::More;

if (exists $ENV{REPREPRO4PATH} and -x $ENV{REPREPRO4PATH}) {
    plan tests => 42;
}
else {
    plan skip_all => "Please specify the path to reprepro 4 in \$REPREPRO4PATH";
}

use Test::Deep;
use File::Path;
use IO::Zlib;

use Arepa::Repository;

use constant TEST_CONFIG_FILE          => 't/config-test.yml';
use constant TEST_REPO_ADD_CONFIG_FILE => 't/config-repo-test.yml';

# Always start fresh
my $test_repo_path = 't/repo-test';
my $test_db_path   = 't/test-package.db';
foreach my $subdir (qw(db dists pool)) {
    rmtree "$test_repo_path/$subdir";
}
unlink $test_db_path;

my $r = Arepa::Repository->new(TEST_CONFIG_FILE);
is($r->get_config_key('package_db'),
   "t/test-package.db",
   "Simple configuration keys should work");
is($r->get_config_key('upload_queue:path'),
   '/home/zoso/src/apt-web/incoming',
   "Nested configuration key should work");

ok($r->config_key_exists('package_db'),
   "Existing config keys should be recognised");
ok(!$r->config_key_exists('i_dont_exist'),
   "Non-existing config keys should NOT be recognised");

my $expected_distributions = [{ codename      => 'lenny-opera',
                                components    => 'main',
                                architectures => 'source i386 amd64',
                                suite         => 'Lenny',
                                version       => '5.0'},
                              { codename      => 'etch-opera',
                                components    => 'main',
                                architectures => 'i386',
                                origin        => 'Opera'}];
cmp_deeply([ $r->get_distributions ],
           $expected_distributions,
           "Distribution information should be correct");
cmp_deeply([ $r->get_architectures ],
           [ qw(source i386 amd64) ],
           "The architectures should be complete and not duplicated");


# Insert a new source package into the repository ----------------------------
ok($r->insert_source_package('t/upload_queue/dhelp_0.6.15.dsc', 'lenny-opera'),
   "Inserting a new source package should succeed");
ok($r->{package_db}->get_source_package_id('dhelp', '0.6.15'),
   "After inserting the source package, it should be in the package db");

my %dhelp_0615_props = $r->get_source_package_information('dhelp',
                                                          'lenny-opera');
ok(scalar %dhelp_0615_props,
   "Source package dhelp should be in the repository");
is($dhelp_0615_props{version}, '0.6.15',
   "Source package dhelp should be in the repository w/ correct version");



# Insert a new binary package into the repository ----------------------------
ok($r->insert_binary_package('t/upload_queue/dhelp_0.6.15_all.deb',
                             'lenny-opera'),
   "Inserting a new binary package should succeed");

my %dhelp_0615_bin_props = $r->get_binary_package_information('dhelp',
                                                              'lenny-opera',
                                                              'i386');
ok(scalar %dhelp_0615_bin_props,
   "Binary package dhelp should be in the repository");
is($dhelp_0615_bin_props{version}, '0.6.15',
   "Binary package dhelp should be in the repository w/ correct version");


# Insert a new source package into the repository, with comments -------------
my $comments = "Now with comments";
ok($r->insert_source_package('t/upload_queue/foobar_1.0-1.dsc', 'lenny-opera',
                             comments => $comments),
   "Inserting a new source package (w/ comments) should succeed");
my $id_w_comments = $r->{package_db}->get_source_package_id('foobar', '1.0-1');
ok($id_w_comments,
   "After inserting the source package, it should be in the package db");
my %source_pkg_w_comments =
            $r->{package_db}->get_source_package_by_id($id_w_comments);
is($source_pkg_w_comments{comments}, $comments,
   "The source package should keep its comments, if any");

my %foobar_101_props = $r->get_source_package_information('foobar',
                                                          'lenny-opera');
ok(scalar %foobar_101_props,
   "Source package foobar should be in the repository");
is($foobar_101_props{version}, '1.0-1',
   "Source package foobar should be in the repository w/ correct version");


# Package list ---------------------------------------------------------------
cmp_deeply({ $r->get_package_list },
          {
              foobar => { "lenny-opera/main" => { "1.0-1"  => ['source'] } },
              dhelp  => { "lenny-opera/main" => { "0.6.15" => set(qw(i386
                                                                     amd64
                                                                     source)),
                                                } },
          },
          "The final package list should be correct");

# Insert mixed versions of a new package
$r->insert_source_package('t/upload_queue/qux_1.0-1.dsc', 'lenny-opera');
$r->insert_binary_package('t/upload_queue/qux_1.0-1_i386.deb',  'lenny-opera');
$r->insert_binary_package('t/upload_queue/qux_1.0-1_amd64.deb', 'lenny-opera');
$r->insert_binary_package('t/upload_queue/qux_1.0-2_i386.deb',  'lenny-opera');

# Now check the package list
cmp_deeply({ $r->get_package_list },
           {
               foobar => { "lenny-opera/main" => { "1.0-1" => ['source'] } },
               qux    => { "lenny-opera/main" => { "1.0-1" => set(qw(amd64
                                                                     source)),
                                                   "1.0-2" => ['i386'],
                                                 } },
               dhelp  => { "lenny-opera/main" => { "0.6.15" => set(qw(i386
                                                                      amd64
                                                                      source)),
                                                 } },
           },
           "The final package list should be correct");


# Insert a source package with non-canonical distribution --------------------
ok(! $r->insert_source_package('t/upload_queue/experimental-package_1.0.dsc',
                               'experimental'),
   "Inserting source package w/ non-canonical distro should fail");

ok($r->insert_source_package('t/upload_queue/experimental-package_1.0.dsc',
                             'experimental',
                             canonical_distro => 'lenny-opera'),
   "Inserting non-canonical distro source package w/ canonical distro hint");
# Ugly way of checking that the source package is correctly inserted
my $id = $r->{package_db}->get_source_package_id('experimental-package',
                                                 '1.0');
my %source_package_attrs = $r->{package_db}->get_source_package_by_id($id);
is($source_package_attrs{distribution}, 'experimental',
   "When inserting a non-canonical distro package, the distro is correct");

my %experimental_pkg_10_props =
    $r->get_source_package_information('experimental-package', 'lenny-opera');
ok(scalar %experimental_pkg_10_props,
   "Source package w/ non-canonical distro should be present");


# Try to add new distributions -----------------------------------------------
my $tmp_repo = 't/repo-add-test';
mkpath "$tmp_repo/conf";
open F, ">$tmp_repo/conf/distributions";
print F <<EOD;
Codename: initial
Components: main
Architectures: i386
Suite: unstable
AlsoAcceptFor: lenny

Codename: another
Components: main
Architectures: i386
Suite: ubuntu
AlsoAcceptFor: lucid lucidlynx
EOD
close F;
my @initial_distro_list = ({ codename      => 'initial',
                             components    => 'main',
                             architectures => 'i386',
                             suite         => 'unstable',
                             alsoacceptfor => 'lenny' },
                           { codename      => 'another',
                             components    => 'main',
                             architectures => 'i386',
                             suite         => 'ubuntu',
                             alsoacceptfor => 'lucid lucidlynx' });

my $r2 = Arepa::Repository->new(TEST_REPO_ADD_CONFIG_FILE);
cmp_deeply([ $r2->get_distributions ], \@initial_distro_list,
           "Distribution information should be correct");

# Duplicate codename
ok(! $r2->add_distribution(codename      => 'initial',
                           components    => 'main',
                           architectures => 'i386'),
   "Shouldn't be able to add a duplicate codename");
cmp_deeply([ $r2->get_distributions ], \@initial_distro_list,
           "Distribution information should be correct");

# Duplicate suite
ok(! $r2->add_distribution(codename      => 'new',
                           components    => 'main',
                           architectures => 'i386',
                           suite         => 'ubuntu'),
   "Shouldn't be able to add a duplicate distribution alias");
cmp_deeply([ $r2->get_distributions ], \@initial_distro_list,
           "Distribution information should be correct");

# "Cross duplicates" (a suite shouldn't be already there as codename)
ok(! $r2->add_distribution(codename      => 'new',
                           components    => 'main',
                           architectures => 'i386',
                           suite         => 'another'),
   "Shouldn't be able to add a suite that existed as a codename");
cmp_deeply([ $r2->get_distributions ], \@initial_distro_list,
           "Distribution information should be correct");

# "Cross duplicates" (codename as suite this time)
ok(! $r2->add_distribution(codename      => 'ubuntu',
                           components    => 'main',
                           architectures => 'i386',
                           suite         => 'newone'),
   "Shouldn't be able to add a codename that existed as a suite");
cmp_deeply([ $r2->get_distributions ], \@initial_distro_list,
           "Distribution information should be correct");

# Add a distribution (repeating AlsoAcceptFor is ok though)
my %new_distro = (codename      => 'new',
                  components    => 'main',
                  architectures => 'i386',
                  suite         => 'lucidlynx');
ok($r2->add_distribution(%new_distro),
   "Should be able to add a new distribution");
cmp_deeply([ $r2->get_distributions ],
           [ @initial_distro_list, \%new_distro ],
           "Distribution information should be correct");

# Check that after adding a distribution, the repository is updated
ok(-d "$tmp_repo/dists/new",
   "After adding distribution 'new', '$tmp_repo/dists/new' should exist");

rmtree($tmp_repo);


# Insert a source package with more than one architecture --------------------
ok($r->insert_source_package('t/upload_queue/multiarch_1.0-1.dsc',
                             'lenny-opera'),
   "Inserting a multiarch source package should succeed");
ok($r->{package_db}->get_source_package_id('multiarch', '1.0-1'),
   "After inserting the multiarch package, it should be in the package db");
my %multiarch_props = $r->get_source_package_information('multiarch',
                                                         'lenny-opera');
ok(scalar %multiarch_props,
   "Source package w/ multiple architectures should be present");

ok($r->insert_source_package('t/upload_queue/multiarch2_1.0-1.dsc',
                             'lenny-opera'),
   "Inserting a multiarch source package should succeed (2)");
ok($r->{package_db}->get_source_package_id('multiarch2', '1.0-1'),
   "After inserting the multiarch package, it should be in the package db (2)");
my %multiarch2_props = $r->get_source_package_information('multiarch2',
                                                          'lenny-opera');
ok(scalar %multiarch2_props,
   "Source package w/ multiple architectures should be present (2)");
