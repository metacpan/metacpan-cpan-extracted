# -*- cperl -*-

use warnings FATAL => qw(all);

package Y;

sub new { bless {}, shift; }
sub foo { $_[0]->{foo} = $_[1] if $#_; $_[0]->{foo} }

package X;


use lib qw ( ./t );

use Test::More tests => 10 ;

use Tie::RefHash;

use Class::IntrospectionMethods qw/make_methods set_obsolete_behavior/;
set_obsolete_behavior('skip',1) ;

make_methods
  (
  tie_hash => [
	       a => {
		     'tie'	=> qw/ Tie::RefHash /,
		     'args' => [],
		    },
	       b => {
		     'tie'	=> qw/ Tie::RefHash /,
		     'args' => [],
		    },
	      ]
  );

sub new { bless {}, shift; }
my $o = new X;

ok( 1 ,"start");
ok( ! scalar keys %{$o->a} ,"no keys");
ok( ! defined $o->a('foo') );

ok( $o->a('foo', 'baz') );
is( $o->a('foo') , 'baz' );
ok( $o->a('bar', 'baz2') );

$o->a(qw/a b/);
$o->a(qw/c d/);

is_deeply( [sort keys %{$o->a}], 
	   [qw/a bar c foo/] , "test keys op");

is_deeply([sort $o->a_keys],
	   [qw/a bar c foo/] , "test keys method");

is_deeply([sort $o->a_values], 
	  [qw/b baz baz2 d/], "test value method");

# Test use of tie...
my $y1 = new Y;
my $y2 = new Y;

$y2->foo ("test");
$o->b ( $y1 => $y2 );

is($o->b ($y1)->foo , "test", "test use of tie" );



