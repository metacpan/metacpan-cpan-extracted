#!/usr/bin/perl -w

use strict;

use Test::More tests => 13;
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
  <key name="1">value here</key>
</config>
EOC

my $c;

$c = Config::XPath::Reloadable->new( filename => $conffilename );
ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath::Reloadable", 'ref $c' );

is_oneref( $c, '$c has one reference' );

my %events;
my %nodes;

$c->associate_nodeset( '/config/key', '@name',
   add    => sub { $events{$_[0]} = 'add';
                   $nodes{$_[0]} = $_[1];
                   undef $_; # be evil and test for callers using this in loop iterators
                 },
   keep   => sub { $events{$_[0]} = 'keep';
                   $nodes{$_[0]} = $_[1];
                   undef $_; # be evil and test for callers using this in loop iterators
                 },
   remove => sub { $events{$_[0]} = 'remove';
                   delete $nodes{$_[0]};
                 },
);

is_oneref( $c, '$c has one reference after associate_nodeset' );

is_deeply( \%events, { 1 => 'add' }, 'initial events' );

my %orig_nodes = %nodes;
%events = ();

write_file $conffile, <<EOC;
<config>
  <key name="1">value here</key>
  <key name="2">value here</key>
</config>
EOC

$c->reload();

is_oneref( $c, '$c has one reference after reload' );

is_deeply( \%events, { 1 => 'keep', 2 => 'add' }, '1st reload events' );
is( $nodes{1}, $orig_nodes{1}, '1st reload node equality' );

%orig_nodes = %nodes;
%events = ();

write_file $conffile, <<EOC;
<config>
  <key name="2">value here</key>
</config>
EOC

$c->reload();

is_deeply( \%events, { 1 => 'remove', 2 => 'keep' }, '2nd reload events' );
is( $nodes{2}, $orig_nodes{2}, '2nd reload node equality' );

%events = ();

$c->reload();

is_deeply( \%events, { 2 => 'keep' }, '3rd reload events' );

%events = ();

$c->reload();

is_deeply( \%events, { 2 => 'keep' }, '4th reload events' );

is_oneref( $c, '$c has one reference at EOF' );
