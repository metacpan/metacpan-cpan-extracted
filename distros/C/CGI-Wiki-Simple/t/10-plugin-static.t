#!/usr/bin/perl -w
use strict;
use Test::More;

BEGIN {
  plan( tests => 8 );
  use_ok('CGI::Wiki::Simple');
  use_ok('CGI::Wiki::Simple::Plugin::Static',
           'Test node' => 'Hello World',
           'Test node 2' => 'Foo bar',
           'Test node 3' => 'Escape test <>' );
};

check_node("Test node",'Hello World',0,'');
check_node("Test node 2",'Foo bar',0,'');
check_node("Test node 3",'Escape test <>',0,'');

sub check_node {
  my ($name,@expected) = @_;
  ok(exists $CGI::Wiki::Simple::magic_node{"Test node"},"Node '$name' exists in magic nodes");
  my @args = CGI::Wiki::Simple::Plugin::Static::retrieve_node( name => $name );
  is_deeply([@args],[@expected],"Correct content for node $name");
};
