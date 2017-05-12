#!/usr/bin/perl -wT

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;
use Scalar::Util 'tainted';

use Test::More tests => 13;

use CGI::Untaint;

my $module = 'CGI::Untaint::boolean';
my $parent = 'CGI::Untaint::object' ;

use_ok( $module ) or exit;
ok( $module->isa( $parent ), "$module should extend $parent" );

can_ok( $module, '_new' );

my $bool = $module->_new( {} );
isa_ok( $bool, $module );

SKIP:
{
	my $tcu = 'Test::CGI::Untaint';

	skip( "Test::CGI::Untaint missing, skipping tests" ,3 )
		unless eval { require Test::CGI::Untaint; $tcu->import(); 1 };

	is_extractable( 'on',   1, 'boolean' );
	is_extractable(   '',   0, 'boolean' );

	unextractable( 'wibbly',  'boolean' );
}

my $tainted_on = substr( 'on' .  $ENV{PATH}, 0, 2 );
my $on         = $bool->_untaint_re( $tainted_on );
ok(   tainted( $tainted_on ), 'insecure strings should be tainted (sanity)' );
ok( ! tainted( $on ), '_untaint_re() should untaint them' );

my $tainted_off = substr( 'off' .  $ENV{PATH}, 0, 3 );
my $off         = $bool->_untaint_re( $tainted_off );
ok( ! tainted( $off ), '... for both allowed checkbox values' );

can_ok( $bool, 'is_valid' );
my $untaint = CGI::Untaint->new( { foo => 'on', bar => 'foo' } );
my $foo     = $untaint->extract( -as_boolean => 'foo' );
my $bar     = $untaint->extract( -as_boolean => 'bar' );

ok(   $foo, 'value should be true if checkbox is on' );
ok( ! $bar, '... false otherwise' );
