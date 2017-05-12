
# Cz::Sort.pm

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded_czsort;}

my $testnum = 1;
sub test
	{
	my $result = shift;
	print "not " if not defined $result or not $result;
	print "ok $testnum\n";
	$testnum++;
	}

BEGIN { print "Loading module Cz::Sort\n"; }

use Cz::Sort;
$loaded_czsort = 1;
test(1);

print "Testing czcmp\n";

my $sorttab = 'sort.tab';
$sorttab = 't/' . $sorttab if -d 't';

open FILE, $sorttab or die "Error reading $sorttab: $!\n";
my (@in, @goodout);
my $in = 0;
while (<FILE>)
	{
	chomp;
	if (/^---INPUT---$/)	{ @in = (); $in = 1; }
	elsif (/^---OUTPUT---$/)	{ @goodout = (); $in = 0; }
	elsif (/^---DONE---$/)
		{
		my $sorted = join "; ", czsort @in;
		my $expect = join "; ", @goodout;
		print "Expecting $expect\nGot $sorted\n";
		test($sorted eq $expect);
		$in = 1;
		}
	elsif ($in)
		{ push @in, $_; }
	else
		{ push @goodout, $_; }
	}

close FILE;


use ExtUtils::testlib;

my $libs = join ' ', map { '-I' . $_ } @INC;
my $TSTFILE = 'out.tst';
$TSTFILE = 't/' . $TSTFILE if -d 't';

print "Calling the external cssort program\n";
print "Will be starting $^X $libs blib/script/cssort > $TSTFILE\n";

open FILE, $sorttab or die "Error reading $sorttab: $!\n";
$in = 0;
while (<FILE>)
	{
	### chomp;
	if (/^---INPUT---$/)	{ @in = (); $in = 1; }
	elsif (/^---OUTPUT---$/)	{ @goodout = (); $in = 0; }
	elsif (/^---DONE---$/)
		{
		open PROCESS, "| $^X $libs blib/script/cssort > $TSTFILE"
			or do { print "Running cssort failed.\n"; last; };
		print PROCESS @in;
		close PROCESS;

		open READ, $TSTFILE
			or do { print "Output file was not created\n"; last; };
		my $sorted = join "; ", <READ>;
		my $expect = join "; ", @goodout;
		close READ;

		unlink $TSTFILE;

		print "Expecting $expect\nGot $sorted\n";
		test($sorted eq $expect);
		$in = 1;
		}
	elsif ($in)
		{ push @in, $_; }
	else
		{ push @goodout, $_; }
	}

close FILE;


