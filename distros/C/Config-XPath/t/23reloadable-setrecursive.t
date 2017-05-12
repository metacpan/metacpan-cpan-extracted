#!/usr/bin/perl -w

use strict;

use Test::More tests => 14;
use Test::Exception;
use Test::Refcount;

use Config::XPath::Reloadable;

use File::Temp qw( tempfile );
use IO::Handle;

sub add_item
{
   my ( $grouphash, $itemname, $node ) = @_;
   $grouphash->{$itemname} = $node->get_string( "." );
}

sub keep_item
{
   my ( $grouphash, $itemname, $node ) = @_;
   $grouphash->{$itemname} = $node->get_string( "." );
}

sub remove_item
{
   my ( $grouphash, $itemname ) = @_;
   delete $grouphash->{$itemname};
}

my %groups;

sub add_group
{
   my ( $name, $node ) = @_;

   my $grouphash = $groups{$name} = {};

   $node->associate_nodeset( 'item', '@name',
      add    => sub { add_item( $grouphash, @_ )    },
      keep   => sub { keep_item( $grouphash, @_ )   },
      remove => sub { remove_item( $grouphash, @_ ) },
   );
}

sub keep_group
{
   my ( $name, $node ) = @_;

   $node->reload;
}

sub remove_group
{
   my ( $name ) = @_;

   delete $groups{$name};
}

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
  <group name="a"></group>
</config>
EOC

my $c;

$c = Config::XPath::Reloadable->new( filename => $conffilename );
ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath::Reloadable", 'ref $c' );

is_oneref( $c, '$c has one reference' );

$c->associate_nodeset( '/config/group', '@name',
   add    => \&add_group,
   keep   => \&keep_group,
   remove => \&remove_group,
);

is_oneref( $c, '$c has one reference after associate_nodeset' );

is_deeply( \%groups, { a => {} }, 'initial' );

write_file $conffile, <<EOC;
<config>
  <group name="a">
    <item name="foo">FOO</item>
  </group>
</config>
EOC

$c->reload();

is_oneref( $c, '$c has one reference after reload' );

is_deeply( \%groups, 
           { a => { foo => 'FOO' } },
           '1st reload' );

write_file $conffile, <<EOC;
<config>
  <group name="a">
    <item name="foo">FOO the second</item>
    <item name="bar">BAR</item>
  </group>
  <group name="b">
    <item name="baz">BAZ</item>
  </group>
</config>
EOC

$c->reload();

is_deeply( \%groups, 
           { a => { foo => 'FOO the second', bar => 'BAR' }, 
             b => { baz => 'BAZ' } },
           '2nd reload' );

write_file $conffile, <<EOC;
<config>
  <group name="b">
    <item name="baz">BAZ 2nd</item>
  </group>
  <group name="a">
    <item name="bar">BAR 2nd</item>
  </group>
</config>
EOC

$c->reload();

is_deeply( \%groups, 
           { a => { bar => 'BAR 2nd' }, 
             b => { baz => 'BAZ 2nd' } },
           '3rd reload' );

write_file $conffile, <<EOC;
<config>
  <group name="b">
    <item name="baz">BAZ 2nd</item>
  </group>
</config>
EOC

$c->reload();

is_deeply( \%groups, 
           { b => { baz => 'BAZ 2nd' } },
           '4th reload' );

# Now again with all relative paths

%groups = ();

write_file $conffile, <<EOC;
<config>
  <group name="a"></group>
</config>
EOC

$c = Config::XPath::Reloadable->new( filename => $conffilename );

$c->associate_nodeset( 'config/group', '@name',
   add    => \&add_group,
   keep   => \&keep_group,
   remove => \&remove_group,
);

is_deeply( \%groups, { a => {} }, 'initial' );

write_file $conffile, <<EOC;
<config>
  <group name="a">
    <item name="foo">FOO</item>
  </group>
</config>
EOC

$c->reload();

is_deeply( \%groups, 
           { a => { foo => 'FOO' } },
           '1st reload' );

$c->reload();

is_deeply( \%groups, 
           { a => { foo => 'FOO' } },
           '2nd reload' );

is_oneref( $c, '$c has one reference at EOF' );
