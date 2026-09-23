#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The manuals (TEST-MANUAL). mandoc -Tlint must report nothing on
# each page under man, and it must exit 0 (TEST-MANUAL-1). The
# pages are hand-written mdoc (D-13), so a defect of a macro shows
# here and not in a terminal of a person.
#
# mandoc resolves an Xr cross reference in the working directory
# alone. The tree holds one directory for each page, so no cross
# reference resolves from the root, and each one reports a style
# message. The lint therefore runs in a flat copy of the tree. A
# cross reference to a page that the tree does not hold still
# reports.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use File::Copy qw(copy);
use File::Find ();
use File::Spec ();
use File::Temp ();
use IPC::Open3 qw(open3);
use Symbol     qw(gensym);
use FindBin    qw($RealBin);

my $root = "$RealBin/../..";
chdir $root or BAIL_OUT("chdir $root: $!");

# mandoc is a test dependency of the Linux runner. Without it, no
# page can be linted here.
my ($mandoc) = grep { -x } map { "$_/mandoc" } split /:/, $ENV{PATH} // q{};
plan skip_all => 'mandoc is absent' unless defined $mandoc;

my @pages;
File::Find::find(
	sub {
		push @pages, $File::Find::name if -f && /\.[1-9]\z/;
		return;
	},
	'man'
);
@pages = sort @pages;

ok( scalar @pages, 'the tree holds at least one manual' );

# The flat copy. Each page keeps its file name, so an Xr of one page
# finds another page of this tree. mandoc reads the working
# directory, so the lint runs in that copy.
my $flat = File::Temp->newdir;
my %name;
for my $page (@pages) {
	( $name{$page} ) = $page =~ m{([^/]+)\z};
	copy( $page, File::Spec->catfile( $flat, $name{$page} ) )
	    or BAIL_OUT("copy $page: $!");
}
chdir $flat or BAIL_OUT("chdir $flat: $!");

for my $page (@pages) {
	my $fault = gensym;
	my $pid =
	    open3( my $in, my $out, $fault, $mandoc, '-Tlint', $name{$page} );
	close $in;

	local $/ = undef;
	my $output = <$out>;
	my $report = <$fault>;
	waitpid $pid, 0;
	my $status = $? >> 8;
	close $out;
	close $fault;

	is( ( $output // q{} ) . ( $report // q{} ),
		q{}, "mandoc -Tlint reports nothing on $page" );
	is( $status, 0, "mandoc -Tlint exits 0 on $page" );
}

chdir $root or BAIL_OUT("chdir $root: $!");

done_testing();
