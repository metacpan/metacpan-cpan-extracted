#!/usr/bin/perl
use lib qw (lib ../lib);
use warnings;
use strict;
use Test::More tests => 12;
use Config::Mini;

package Foo;

sub new { my $class = shift; return bless { @_ }, $class };


package Bar;

sub new { my $class = shift; return bless { @_ }, $class };


package main;

$SIG{__WARN__} = sub {};

my $data = <<EOF;
  foo = bar
  baz = buz

  [obj:foo]
  package = Foo
  key1 = val1
  key2 = val2

  [obj:bar]
  package = Bar
  key1 = val1
  key2 = val2

EOF

Config::Mini::parse_data ($data);
my @obj   = Config::Mini::select ('^obj:');

my ($foo) = map { $_->isa ('Foo') ? $_ : () } @obj;
my ($bar) = map { $_->isa ('Bar') ? $_ : () } @obj;

ok (defined $foo);
is ($foo->{'package'} => 'Foo');
ok (defined $foo->{'__package'});
is ($foo->{'__package'}->[0] => 'Foo');
is ($foo->{'key1'} => 'val1');
is ($foo->{'key2'} => 'val2');

ok (defined $bar);
is ($bar->{'package'} => 'Bar');
ok (defined $bar->{'__package'});
is ($bar->{'__package'}->[0] => 'Bar');
is ($bar->{'key1'} => 'val1');
is ($bar->{'key2'} => 'val2');

