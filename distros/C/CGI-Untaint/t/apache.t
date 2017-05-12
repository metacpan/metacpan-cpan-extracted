#!/usr/bin/perl -w

use strict;
use CGI;
use CGI::Untaint;

use Test::More tests => 20;

my $data = {
	name => "Tony Bowden",
	age  => 110,
};

package My::Apache::Table;
sub new   { bless $data, shift }
sub name  { shift->{name} }
sub age   { shift->{name} }
sub parms { shift; }

package main;

my %type = (
  name => 'printable',
  age  => 'integer',
);

{
  my $apr = My::Apache::Table->new();
	my %h = (
		args   => CGI::Untaint->new( {}, $apr ),
		noargs => CGI::Untaint->new( $apr ),
	);
	for my $type (sort keys %h) {
		ok my $h = $h{$type}, "*** handler for $type ***";
		isa_ok $h, "CGI::Untaint";
		foreach (keys %type) {
			ok my $res = $h->extract("-as_$type{$_}" => $_), "$type: Extract $_";
			is $res,  $data->{$_}, "$type:  - Correct value";
			is $h->error, '', "$type: No error";
		}
		my $foo = $h->extract(-as_printable => 'foo');
		ok !$foo, "$type: No Foo";
		is $h->error, "No parameter for 'foo'", "$type: No error";
	}
}
