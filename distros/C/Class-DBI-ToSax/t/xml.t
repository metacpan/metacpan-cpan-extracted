#!/usr/bin/perl -w
# @(#) $Id: xml.t,v 1.7 2003/10/14 15:11:02 dom Exp $

use strict;

use lib 't';

use Test::More tests => 12;

use TestClass; # Brings in TestClass::*.
use XML::SAX::Writer;

# Set up some test objects.
my $bar = TestClass::Bar->new(
    bar_id   => 2,
    bar_name => 'barney',
);
my $foo = TestClass::Foo->new(
    foo_id   => 1,
    foo_name => 'fred',
    bar_id   => $bar,
);
my $baz = TestClass::Baz->new(
    baz_id   => 3,
    baz_name => 'wilma',
    foo_id   => $foo,
);

# Just check that our test objects look roughly like what they should...
isa_ok( $foo, 'TestClass::Foo' );
isa_ok( $bar, 'TestClass::Bar' );
isa_ok( $baz, 'TestClass::Baz' );

my $xml_str;
my $w = XML::SAX::Writer->new( Output => \$xml_str );

$bar->to_sax( $w );
is( $xml_str, "<bar id='2'><bar_name>barney</bar_name></bar>", 'basic xml' );

$foo->to_sax( $w );
is(
    $xml_str,
"<foo id='1'><foo_name>fred</foo_name><bar_id id='2'><bar_name>barney</bar_name></bar_id><baz id='3'><baz_name>wilma</baz_name></baz></foo>",
    'has_a() uses column names not table names',
);

my $zot = TestClass::Foo->new( foo_id => 4, foo_name => 'betty' );
$zot->to_sax( $w );
is(
    $xml_str,
    "<foo id='4'><foo_name>betty</foo_name><bar_id /></foo>",
    'empty has_a() looks ok [RT#2362]'
);

#---------------------------------------------------------------------
# Test MCPK support.
#---------------------------------------------------------------------

my $mcpk = TestClass::MCPK->new( id_a => 'eh', id_b => 'bee' );
$mcpk->to_sax( $w );
is(
    $xml_str,
    "<mcpk id='eh/bee' />",
    'MCPK support',
);

#---------------------------------------------------------------------
# Test that we don't propogate $wrapper.  This is really an internal
# flag...
#---------------------------------------------------------------------

$foo->to_sax( $w, wrapper => 'bimble' );
is(
    $xml_str,
    "<bimble id='1'><foo_name>fred</foo_name><bar_id id='2'><bar_name>barney</bar_name></bar_id><baz id='3'><baz_name>wilma</baz_name></baz></bimble>",
    'do not propogate non-standard wrapper name to has_many elements',
);

#---------------------------------------------------------------------
# Test norecurse support.
#---------------------------------------------------------------------

# No recursion at all.
$foo->to_sax( $w, norecurse => 1 );
# pathetic attempt to normalise xml -- should use Test::XML.
$xml_str =~ s/' \/>/'\/>/g;
is(
    $xml_str,
    "<foo id='1'><foo_name>fred</foo_name><bar_id id='2'/><baz id='3'/></foo>",
    'norecurse => 1',
);

# Some stopping of recursion.
$foo->to_sax( $w, norecurse => { baz => 1 } );
$xml_str =~ s/' \/>/'\/>/g;     # bad normalisation.
is(
    $xml_str,
    "<foo id='1'><foo_name>fred</foo_name><bar_id id='2'><bar_name>barney</bar_name></bar_id><baz id='3'/></foo>",
    'norecurse => { baz => 1 }',
);

# Test that we actually get called.
my $called = 0;
$foo->to_sax( $w, norecurse => sub { $called++; 1; } );
is( $called, 2, 'norecurse => sub { called++ }' );

# Test that we get called with the correct arguments.  Note that we
# don't get called at the top level.
my @expected = (
    [qw( foo-1 bar-2 )],
    [qw( foo-1 baz-3 )],
);
my @got;
my $record = sub { push @got, [ map { $_->table . '-' . $_->id } @_ ]; 1 };
$foo->to_sax( $w, norecurse => $record );
is_deeply( \@got, \@expected, 'norecurse => sub{} has correct args' );

# vim: set ai et sw=4 syntax=perl :
