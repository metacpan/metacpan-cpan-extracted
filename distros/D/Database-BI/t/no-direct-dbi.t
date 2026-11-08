#!/usr/bin/env perl

# The application reads and describes its data through Database::Join and
# Database::Abstraction, which own the database drivers: listing a file's
# tables, a table's columns and key, and writing a SQLite file all go through
# Database::Join::Catalog.  This fails if the code under lib/ or script/ starts
# talking to DBI, or loading a DBD driver, itself again.  Building a DSN
# string for Database::Abstraction is fine; connecting with it is not.
#
#   prove -l t/no-direct-dbi.t

use strict;
use warnings;

use Test::Most;
use File::Find;

my @files;
find({ no_chdir => 1, wanted => sub { push @files, $_ if -f && (/\.pm\z/ || m{\Ascript/}) } }, 'lib', 'script');
ok @files > 5, 'found the code' or diag explain \@files;

my %FORBIDDEN = (
	'DBI->connect or another DBI class method' => qr/\bDBI\s*->\s*\w/,
	'use DBI or require DBI'                    => qr/\b(?:use|require)\s+DBI\b/,
	'loading a DBD driver'                      => qr/\b(?:use|require)\s+DBD::|["']DBD\/\w+\.pm["']|"DBD\/\$/,
	'a DBI error variable'                      => qr/\$DBI::(?:errstr|err|state)\b/,
);

for my $file (sort @files) {
	open my $fh, '<', $file or BAIL_OUT("$file: $!");
	my ($pod, @hits) = (0);
	while (my $line = <$fh>) {
		$pod = 1 if $line =~ /^=[a-z]/;
		if ($line =~ /^=cut/) { $pod = 0; next }
		next if $pod || $line =~ /^\s*#/;
		last if $line =~ /^__(?:END|DATA)__/;
		(my $code = $line) =~ s/\s#\s.*//;
		for my $what (sort keys %FORBIDDEN) {
			push @hits, "line $.: $what: $line" if $code =~ $FORBIDDEN{$what};
		}
	}
	close $fh;
	ok !@hits, "$file talks to no database driver itself" or diag join '', @hits;
}

done_testing();
