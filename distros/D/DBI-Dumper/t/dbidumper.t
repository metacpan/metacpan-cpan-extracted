#!/usr/bin/perl
# vim:ft=perl

use DBI;
use Test::More tests => 2;
use File::Temp qw(tempfile tempdir);

# make control file
my ($ctfh, $ctfn) = tempfile( UNLINK => 1 );
print $ctfh q{
	options (skip=2, export=10)
	export data
	replace into file 'data.out'
	fields terminated by TAB
	enclosed by '"' and '"'
	from
	select * from data
};
close $ctfh;

# output file
my (undef, $otfn) = tempfile( UNLINK => 1 );

# work dir
my $wdir = tempdir( CLEANUP => 1 );

# build database
my $dbh = DBI->connect('dbi:DBM:f_dir=' . $wdir, "", "", { RaiseError => 1 });

$dbh->do(q{
	CREATE TABLE data ( col1 text, col2 text )
});

for my $i (1 .. 100) {
	$dbh->do(q{
		INSERT INTO data VALUES (?, 'a')
	}, undef, $i);
}

system(
	'bin/dbidumper.pl',
	'control=' . $ctfn,
	'output=' . $otfn,
	'userid=test/test@DBM:f_dir=' . $wdir,
);
ok($? >> 8 == 0);

open my $otfh, "<", $otfn or die "Could not open file: $!";
my @rows = <$otfh>;
close $otfh;

ok(@rows == 10);

$dbh->disconnect;

exit 0;
