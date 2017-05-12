#!/usr/bin/perl -w

use strict;

use Test::More tests => 11;
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
  <line>Foo</line>
  <line>Bar</line>
</config>
EOC

my $c;

$c = Config::XPath::Reloadable->new( filename => $conffilename );
ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath::Reloadable", 'ref $c' );

is_oneref( $c, '$c has one reference' );

my @lines;

$c->associate_nodelist( '/config/line',
   add    => sub { $lines[$_[0]] = $_[1]->get_string( "." );
                 },
   keep   => sub { $lines[$_[0]] = $_[1]->get_string( "." );
                 },
   remove => sub { delete $lines[$_[0]];
                 },
);

is_oneref( $c, '$c has one reference after associate_nodelist' );

is_deeply( \@lines, [ 'Foo', 'Bar' ], 'initial load' );

$c->reload();

is_deeply( \@lines, [ 'Foo', 'Bar' ], '1st reload' );

$c->reload();

is_oneref( $c, '$c has one reference after reload' );

is_deeply( \@lines, [ 'Foo', 'Bar' ], '2nd reload' );

write_file $conffile, <<EOC;
<config>
  <line>Foo</line>
  <line>Bar</line>
  <line>Splot</line>
</config>
EOC

$c->reload();

is_deeply( \@lines, [ 'Foo', 'Bar', 'Splot' ], 'reload after addition' );

write_file $conffile, <<EOC;
<config>
  <line>Bar</line>
  <line>Splot</line>
</config>
EOC

$c->reload();

is_deeply( \@lines, [ 'Bar', 'Splot' ], 'reload after delete' );

is_oneref( $c, '$c has one reference at EOF' );
