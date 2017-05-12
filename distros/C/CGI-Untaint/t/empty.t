#!/usr/bin/perl

use CGI::Untaint;
use Test::More tests => 4;

my %params = ( foo => '', bar => undef);
my $h = CGI::Untaint->new({ %params });

{
	my $foo = $h->extract(-as_printable => 'foo');
	is $foo, '', "Extract empty text";
	ok !$h->error, "No error";
}

{
	my $bar = $h->extract(-as_printable => 'bar');
	is $bar, undef, "Extract undef";
	like $h->error, qr/No param/, "No parameter with undef";
}
