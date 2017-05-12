#!perl -w

use strict;
use warnings;
use Test::More;

if ($ENV{DEV}) {
	plan tests => 4;
} else {
	plan skip_all => "Test for coders :)";
};
	


=head1 NAME

This test intends to find the presence of particular strings in the source code.
This test is for developpers only.
A problem in this test won't say the application won't run.


=cut

use Catalyst::Test;
use App::CamelPKI;
use Test::Group;
use Catalyst::Utils;
use File::Slurp;
use File::Find;
use File::Spec;
use Cwd;


test "still some work" => sub {
	testStringPresent("todo");
};

test "FIXME" => sub {
	testStringPresent("fixme");
};

test "XXX" => sub {
	testStringPresent("xxx");
};

test "Refactor" => sub {
	testStringPresent("refactor");
};

exit;

=head2 I<testStringPresent($string)>

Test all files recursively for $string in current directory.
The test is case-insensitive.

=cut

sub testStringPresent {
	push my @directories, cwd;
	my $stringToSeek = $_[0];
	find(sub {
		my $file = $File::Find::name;
		return unless -f $file;
		my ($volume, $directories, $filename) = File::Spec->splitpath( $file );
		return if ($directories =~ qr/\/t\// && $filename=~ qr/TODO.t/);
		return if ($filename =~ qr/manifest/i or $filename=~ qr/ico$/ or $filename=~ qr/png$/) ;
		return if ($directories =~ qr/blib/);
		return if ($directories =~ qr/support/);
		return if ($directories =~ qr/svn/);
		return if ($filename =~ qr/tar.gz/i);
		my $text = read_file( $file );
		unlike($text, qr/$stringToSeek/i, " $stringToSeek trouvé dans $file");		
	}, @directories);
}
;