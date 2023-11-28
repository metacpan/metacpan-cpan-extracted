use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::Sord;
use File::Which;

alien_diag 'Alien::Sord';
alien_ok 'Alien::Sord';

if( which 'sordi' ) {
  run_ok([ qw(sordi -v) ])
    ->success
    ->out_like(qr/sordi\s+([0-9.]+)/);
}

my $xs = <<'END';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "sord/sord.h"

bool test( const char* class ) {
  SordWorld* world = sord_world_new();
  SordNode* uri_a = sord_new_uri(world, "http://example.com/");
  SordNode* uri_b = sord_new_uri(world, "http://example.com/");
  return sord_node_equals(uri_a, uri_b);
}

MODULE = main PACKAGE = main

bool test(class)
  const char* class

END
xs_ok $xs, with_subtest {
  my ($module) = @_;
  ok $module->test, 'URIs are equal';
};

ffi_ok { symbols => [ qw(sord_world_new sord_new_uri sord_node_equals) ] }, with_subtest {
  my $ffi = shift;
  $ffi->type( 'opaque' => 'SordWorld' );
  $ffi->type( 'opaque' => 'SordNode' );
  my $World_new = $ffi->function( sord_world_new => [] => 'SordWorld' );
  my $Node_new_uri = $ffi->function( sord_new_uri => ['SordWorld', 'string'] => 'SordNode' );
  my $Node_equals  = $ffi->function( sord_node_equals => ['SordNode', 'SordNode'] => 'bool' );

  my $world = $World_new->();
  my $uri_a = $Node_new_uri->($world, 'http://example.com/');
  my $uri_b = $Node_new_uri->($world, 'http://example.com/');
  ok $Node_equals->($uri_a, $uri_b), 'URIs are equal';
};

done_testing;
