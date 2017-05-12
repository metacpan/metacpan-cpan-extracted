#!/usr/bin/perl -w

use strict;
use Test::More;
use CGI;
use CGI::Untaint;

plan tests => 2;

package CGI::Untaint::bigint;

use base 'CGI::Untaint::integer';
use Math::BigInt;

sub is_valid    { 
	my $self = shift;
	$self->value(Math::BigInt->new($self->value));
}

package main;

my $q = CGI->new( { num => 6091 });

my $h = CGI::Untaint->new($q->Vars);

my $val = $h->extract(-as_bigint => "num");

ok $val == 6091, "Extract a big int";
isa_ok $val, "Math::BigInt", "as an object";

