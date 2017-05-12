#!perl -w
# $Id: /local/CPAN/Catalyst-Model-NetBlogger/t/catalyst_helpers_model_netblogger.t 1382 2005-11-20T00:13:50.676340Z claco  $
use strict;
use warnings;
use Test::More;
use Cwd;
use File::Path;
use File::Spec::Functions;

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

    plan tests => 9;

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
    my $module = catfile($app, 'lib', $app, 'M', 'Blog.pm');
    $helper->mk_component($app, 'model', 'Blog', 'NetBlogger', 'testengine', 'testproxy', 'testblogid', 'testusername', 'testpassword', 'testappkey', 'testuri');
    file_exists_ok($module);
    file_contents_like($module, qr/'testengine'/);
    file_contents_like($module, qr/'testproxy'/);
    file_contents_like($module, qr/'testblogid'/);
    file_contents_like($module, qr/'testusername'/);
    file_contents_like($module, qr/'testpassword'/);
    file_contents_like($module, qr/'testappkey'/);
    file_contents_like($module, qr/'testuri'/);
};
