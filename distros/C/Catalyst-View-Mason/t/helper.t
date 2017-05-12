#!perl

use strict;
use warnings;
use Cwd;
use File::Path;
use File::Spec::Functions qw/catdir catfile/;
use Test::More;

eval 'use Test::File';
plan skip_all => 'Test::File required' if $@;

eval 'use Test::Exception';
plan skip_all => 'Test::Exception required' if $@;

eval 'use Catalyst::Helper';
plan skip_all => 'Catalyst::Helper required' if $@;

plan tests => 4;

my $app_name = 'TestApp';
my $old_cwd  = cwd();
my $test_dir = catdir(qw/t var/);

if (!-d $test_dir) {
    mkdir $test_dir or BAIL_OUT("Failed to create test directory: $!");
}
chdir $test_dir;

my $helper = Catalyst::Helper->new;

$helper->mk_app($app_name);
$FindBin::Bin = $FindBin::Bin = catdir($app_name, 'lib');

$helper->mk_component($app_name, 'view', 'Mason', 'Mason');

my $module = catfile($app_name, 'lib', $app_name, 'View', 'Mason.pm');
file_exists_ok($module, 'module created');

lives_ok(sub {
        do $module;
}, 'module compiles fine');

ok(!TestApp::View::Mason->config->{use_match}, 'module sets use_match to false');
ok(TestApp::View::Mason->isa('Catalyst::View::Mason'), 'module inherits from C::V::Mason');

END {
    if (defined $old_cwd) {
        chdir $old_cwd;
        rmtree($test_dir);
    }
}
