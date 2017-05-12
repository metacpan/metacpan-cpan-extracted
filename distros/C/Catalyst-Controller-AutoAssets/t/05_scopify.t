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
      include => [ "$FindBin::Bin/var/eg_src/scopify.css" ],
      type => 'css',
      minify => 0,
      scopify => ['div.mywrap', merge => ['html','body']],
      work_dir => $work_dir,
      sha1_string_length => 10
    },
  );

  __PACKAGE__->setup();  
  1;
}

use Test::More;
use Catalyst::Test 'TestApp';


action_ok(
  '/assets/535e0a6e99.css',
  "Expected built asset SHA-1 path (scoped css)"
);


done_testing;