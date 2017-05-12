#!/usr/bin/perl

=head1 NAME

passfile.t - test

=head1 DESCRIPTION

Check we can use the 'passfile' option.

=cut

use strict;
use warnings;

use Test::More tests => 6;

sub make_tmpfile {
	my ($file, $data) = @_;
	open my $io, ">$file" or return;
	print {$io} $data;
	close $io;
}

make_tmpfile(foo => "qwerty");
make_tmpfile(bar => "asdfgh");
make_tmpfile(baz => "qwerty");
END { unlink qw/foo bar baz/ }

require_ok('Crypt::Simple');

{
	package Foo;
	Crypt::Simple->import(passfile => "foo");
}

{
	package Bar;
	Crypt::Simple->import(passfile => "bar");
}

{
	package Baz;
	Crypt::Simple->import(passfile => "baz");
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

