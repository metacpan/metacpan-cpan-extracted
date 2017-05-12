use strict;
use warnings;
use Test::More tests => 1;

package MyApp;
use Catalyst;

package MyApp::Component;
use Moose;
BEGIN { extends 'Catalyst::Component' };
use CatalystX::MooseComponent;

package main;
my $meta = Moose::Util::find_meta('MyApp::Component');
is_deeply(
  [ $meta->superclasses ],
  [ 'Moose::Object', 'Catalyst::Component' ],
);
