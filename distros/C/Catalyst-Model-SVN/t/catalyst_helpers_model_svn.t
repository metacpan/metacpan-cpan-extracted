#!perl -w
# $Id: /mirror/claco/Catalyst-Model-SVN/branches/devel-0.07-t0m/t/catalyst_helpers_model_svn.t 739 2007-12-02T17:46:38.562424Z bobtfish  $
use strict;
use warnings;
use Test::More;
use Cwd;
use File::Path;
use File::Spec::Functions;
use FindBin ();

BEGIN {
    eval 'use Catalyst 5';
    plan(skip_all =>
        'Catalyst 5 not installed') if $@;

    eval 'use Test::File 1.10';
    plan(skip_all =>
        'Test::File 1.10 not installed') if $@;

    eval 'use Test::File::Contents 0.02';
    plan(skip_all =>
        'Test::File::Contents 0.02 not installed') if $@;

    plan tests => 4;

    use_ok('Catalyst::Helper');
};

my $helper = Catalyst::Helper->new({short => 1});
my $app = 'TestApp';


## create the test app
{
    chdir('t');
    rmtree('TestApp');

    $helper->mk_app($app);
    $FindBin::Bin = catdir(cwd, $app, 'lib');
};


## create the default model
{
    my $module = catfile($app, 'lib', $app, 'M', 'SVN.pm');
    $helper->mk_component($app, 'model', 'SVN', 'SVN', 'testrepo', 'testrev');
    file_exists_ok($module);
    file_contents_like($module, qr/'testrepo'/);
    file_contents_like($module, qr/'testrev'/);
};
