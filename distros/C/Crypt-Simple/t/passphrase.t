#!/usr/bin/perl

=head1 NAME

passphrase.t - test

=head1 DESCRIPTION

Check we can use the 'passphrase' option.

=cut

use strict;
use warnings;

use Test::More tests => 6;

require_ok('Crypt::Simple');

{
	package Foo;
	Crypt::Simple->import(passphrase => "qwerty");
}

{
	package Bar;
	Crypt::Simple->import(passphrase => "asdfg");
}

{
	package Baz;
	Crypt::Simple->import(passphrase => "qwerty");
}

my $plaintext = "hello world";
my $footext = Foo::encrypt($plaintext);
my $bartext = Bar::encrypt($plaintext);
my $baztext = Baz::encrypt($plaintext);

isnt $footext, $bartext, "Foo and Bar are different";
is $footext, $baztext, "Foo and Baz are the same";
is Foo::decrypt($footext), $plaintext, "Foo encryption";
is Bar::decrypt($bartext), $plaintext, "Bar encryption";
is Baz::decrypt($baztext), $plaintext, "Baz encryption";

