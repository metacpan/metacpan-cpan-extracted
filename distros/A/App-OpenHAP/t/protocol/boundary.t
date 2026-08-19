#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The dependency rules of the Protocol::HAP library.
#
# Protocol::HAP is self-contained: core Perl plus the declared Crypt::*
# modules, and nothing else. It never uses Fugu or App. The test
# parses the use and require lines and fails on a line that breaks the
# rule.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use File::Find ();
use Module::CoreList;

my $ROOT = "$RealBin/../..";

# The CPAN modules that Protocol::HAP declares. Everything else must
# be core Perl or another Protocol::HAP module.
my %DECLARED = map { $_ => 1 } qw(
    Crypt::Ed25519
    Crypt::Curve25519
    Crypt::KeyDerivation
    Crypt::AuthEnc::ChaCha20Poly1305
);

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
#	name, as [$line_number, $module] pairs. Version declarations
#	such as 'use v5.36' are not modules and do not appear.
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

# Direction one: Protocol::HAP uses core Perl, the declared list, and
# itself. A Fugu or App import is a boundary violation.
# So is an undeclared CPAN module.
subtest 'Protocol::HAP is self-contained' => sub {
	my @files = perl_files("$ROOT/lib/Protocol");
	ok( @files, 'found modules under lib/Protocol/' );

	my @violations;
	for my $file (@files) {
		my $name = $file =~ s{^\Q$ROOT\E/}{}r;
		for my $import ( imports_in($file) ) {
			my ( $line, $module ) = @$import;

			if ( $module =~ /^(?:Fugu|App)\b/ ) {
				push @violations,
				    "$name:$line uses $module";
				next;
			}
			next if $module =~ /^Protocol::HAP\b/;
			next if $DECLARED{$module};
			next if Module::CoreList::is_core($module);

			push @violations,
			    "$name:$line uses undeclared CPAN module $module";
		}
	}

	is( scalar @violations, 0, 'no boundary violation' )
	    or diag( join "\n", @violations );
};

done_testing();
