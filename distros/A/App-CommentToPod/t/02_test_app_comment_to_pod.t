use Test::More;
use Data::Printer;
use strict;
use warnings;

require_ok('App::CommentToPod');
my $pm = App::CommentToPod->new;
ok $pm , "ok initialization";

my $testfile = '#test
package Foo::Bar

# function description
sub myFunction {';

$pm->addPod($testfile);
ok $pm->package eq 'Foo::Bar', "Found correct package name";

testPOD($testfile, '=head1 NAME\s+Foo', "found corrrect Pod section", "Foo::Bar");
testPOD($testfile, '=item C<myFunction>\s+function', "God function section", "Foo::Bar");

testPOD('#

package Foo::Bar
use foo

=pod

=head1 NAME

Baz::Bar

sub myFunction {',
	'', "Podheader", "Foo::Bar");

testPOD('#test
package Foo::Bar
', '=head1 NAME\s+Foo', "Podheader", "Foo::Bar");

testPOD('#test

# test
package Foo::Bar
', '=head1 NAME\s+Foo', "Podheader", "Foo::Bar");

sub testPOD {
	my ($file, $match, $desc, $package) = @_;

	my $pm = App::CommentToPod->new;
	$pm->addPod($file);

	ok $pm->package eq $package, "Found correct package name: $package (got " . $pm->package . ")";

	if ($pm->podfile =~ m/$match/) {
		ok 1, $desc;
		return;
	}
	ok 0, "test failed. expected to find; '$match' in :" . $pm->podfile;
}

done_testing;
