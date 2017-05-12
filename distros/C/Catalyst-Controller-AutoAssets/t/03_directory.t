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
      include => [ "$FindBin::Bin/var/eg_src/" ],
      type => 'directory',
      work_dir => $work_dir
    },
  );

  __PACKAGE__->setup();  
  1;
}

use Test::More;
use Catalyst::Test 'TestApp';

is(
  TestApp->controller('Assets')->asset_path,
  "/assets/93aeb889be0b221d10a9fd5947cc106cc8176051",
  "Expected directory SHA1 asset path"
);

action_redirect(
  '/assets/current/stylesheets/ie.css',
  "Current redirect to sub-file"
);

action_ok(
  TestApp->controller('Assets')->asset_path('stylesheets/ie.css'),
  "Controller asset_path() method with subpath"
);

contenttype_is(
  TestApp->controller('Assets')->asset_path('stylesheets/ie.css'),
  'text/css',
  "Expected CSS Content-Type of sub-file"
);


done_testing;