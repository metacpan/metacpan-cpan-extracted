# -*- perl -*-

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use Path::Class 0.32 qw( dir file );
my $work_dir = dir("$Bin/var/tmp/work_dir");
$work_dir->rmtree;
$work_dir->mkpath;

my $content = join('','/* some arbitrary content */',"\n");

{
  package TestApp;
  use Moose;
  
  use Catalyst;
  extends 'Catalyst';
  
  __PACKAGE__->config(
    name => __PACKAGE__,
    'Controller::Assets' => {
      include => [ \$content ],
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
  '/assets/e95d7a1d79581d80bf68b62448ef509752c737f6.css',
  "Expected built asset SHA-1 path"
);


done_testing;
