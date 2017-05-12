#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;
use Test::Refcount;

use Config::XPath::Reloadable;

use File::Temp qw( tempfile );
use IO::Handle;

sub write_file
{
   my ( $fh, $content ) = @_;

   truncate $fh, 0;
   seek $fh, 0, 0;

   print $fh $content;
}

my ( $conffile, $conffilename ) = tempfile( UNLINK => 1 );
defined $conffile or die "Could not open a tempfile for testing - $!";
$conffile->autoflush( 1 );

write_file $conffile, <<EOC;
<config>
  <key>value here</key>
</config>
EOC

my $c;

$c = Config::XPath::Reloadable->new( filename => $conffilename );
ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath::Reloadable", 'ref $c' );

is_oneref( $c, '$c has one reference' );

my $s;

$s = $c->get_string( "/config/key" );
is( $s, "value here", 'initial content' );

write_file $conffile, <<EOC;
<config>
  <key>new value here</key>
</config>
EOC

$s = $c->get_string( "/config/key" );
is( $s, "value here", 'reread content' );

$c->reload();

$s = $c->get_string( "/config/key" );
is( $s, "new value here", 'changed content' );

is_oneref( $c, '$c has one reference at EOF' );
