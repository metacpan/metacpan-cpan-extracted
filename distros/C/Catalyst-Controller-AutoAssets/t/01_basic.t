# -*- perl -*-

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use Path::Class 0.32 qw( dir file );
my $work_dir = dir("$Bin/var/tmp/work_dir");
$work_dir->rmtree;
$work_dir->mkpath;

{
  package TestApp;
  use Moose;
  
  use Catalyst;
  extends 'Catalyst';
  
  __PACKAGE__->config(
    name => __PACKAGE__,
    'Controller::Assets' => {
      include => [ "$FindBin::Bin/var/eg_src/stylesheets" ],
      type => 'css',
      minify => 0,
      work_dir => $work_dir
    },
  );

  __PACKAGE__->setup();  
  1;
}

use Test::More;
use Catalyst::Test 'TestApp';

action_ok(
  '/assets/fa7fa28ff238535ba564c1a41755bde48844deef.css',
  "Expected built asset SHA-1 path"
);

action_redirect(
  '/assets/current.css',
  "Current redirect"
);

action_ok(
  TestApp->controller('Assets')->asset_path,
  "Controller asset_path() method"
);

contenttype_is(
  '/assets/fa7fa28ff238535ba564c1a41755bde48844deef.css',
  'text/css',
  "Expected CSS Content-Type"
);


action_notfound(
  '/assets/bad_asset_name',
  "Not found asset"
);

done_testing;
