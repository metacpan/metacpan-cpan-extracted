#!/usr/local/bin/perl

use Test;
BEGIN { plan tests => 5 }

package X;

use Class::MakeMethods::Template::Ref 'clone' => 'duplicate';

sub new { my $class = shift; bless { @_ }, $class; }

package main;

my $o = X->new('foo' => 'bar');

ok( 1 );
ok( defined $o );
my $n;
ok( $n = $o->duplicate );
ok( $n->{'foo'} eq 'bar' );
ok( $n ne $o );

exit 0;

