# -*- perl -*-

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
eval "use JavaScript::Minifier";
plan skip_all => "JavaScript::Minifier required for testing minify" if $@;

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
      include => [ "$FindBin::Bin/var/eg_src/js" ],
      type => 'js',
      minify => 1,
      work_dir => $work_dir
    },
  );

  __PACKAGE__->setup();
  1;
}

use Catalyst::Test 'TestApp';

action_redirect(
  '/assets/current.js',
  "Current redirect"
);

contenttype_is(
  TestApp->controller('Assets')->asset_path,
  'text/javascript',
  "Expected JavaScript Content-Type"
);

done_testing;