#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The dependency rules of App::FuguWeb.
#
# App::FuguWeb sits in the application layer: it uses Fugu:: and core
# Perl, and nothing else. It never uses another App:: namespace,
# because a sibling application is not a library.
#
# The tool is also not a protocol implementation. A Protocol:: import
# would make a documentation builder depend on a protocol library,
# which no site build needs.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use File::Find ();
use Module::CoreList;

my $ROOT = "$RealBin/../..";

# perl_files($dir):
#	Return every .pm file under $dir, sorted.
sub perl_files ($dir)
{
	my @files;
	File::Find::find(
		sub { push @files, $File::Find::name if /\.pm$/ }, $dir );

	return sort @files;
}

# imports_in($file):
#	Return the modules that the use and require lines of $file
#	name, as [$line_number, $module] pairs. A version declaration
#	such as 'use v5.36' is not a module and does not appear.
sub imports_in ($file)
{
	open my $fh, '<', $file or die "Cannot read $file: $!";

	my @imports;
	while ( my $line = <$fh> ) {
		last if $line =~ /^__(?:END|DATA)__/;
		next
		    unless $line
		    =~ /^\s*(?:use|require)\s+([A-Za-z_][A-Za-z0-9_:]*)/;
		my $module = $1;
		next if $module =~ /^v\d/;
		push @imports, [ $., $module ];
	}
	close $fh;

	return @imports;
}

# The tool uses Fugu::, itself, and core Perl. It adds
# no CPAN dependency, because a documentation builder that a project
# cannot install is a documentation builder nobody installs.
subtest 'App::FuguWeb uses only Fugu and core Perl' => sub {
	my @files = perl_files("$ROOT/lib/App/FuguWeb");
	push @files, "$ROOT/lib/App/FuguWeb.pm";
	ok( @files, 'found modules under lib/App/FuguWeb/' );

	my @violations;
	for my $file ( sort @files ) {
		my $name = $file =~ s{^\Q$ROOT\E/}{}r;
		for my $import ( imports_in($file) ) {
			my ( $line, $module ) = @$import;

			if ( $module =~ /^App\b/
				&& $module !~ /^App::FuguWeb\b/ )
			{
				push @violations,
				    "$name:$line uses $module;"
				    . ' a sibling application is not'
				    . ' a library';
				next;
			}
			if ( $module =~ /^Protocol\b/ ) {
				push @violations,
				    "$name:$line uses $module;"
				    . ' a site build speaks no protocol';
				next;
			}
			next if $module =~ /^App::FuguWeb\b/;
			next if $module =~ /^Fugu::/;
			next if Module::CoreList::is_core($module);

			push @violations,
			    "$name:$line uses undeclared CPAN module"
			    . " $module";
		}
	}

	is( scalar @violations, 0, 'no boundary violation' )
	    or diag( join "\n", @violations );
};

done_testing();
