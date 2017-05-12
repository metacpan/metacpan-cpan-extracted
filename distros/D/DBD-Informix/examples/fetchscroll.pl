#!/usr/bin/perl -w
#
# @(#)$Id: fetchscroll.pl,v 1.4 2003/01/13 23:58:53 jleffler Exp $
#
# Simulate proposed scroll cursor support for Perl DBI

use strict;
use DBI;
use Carp;

my $debug = 0;

sub fetchrow_scroll_arrayref($$$$)
{
	my($sth, $ctl, $key, $val) = @_;
	my($cur, $max, $done, $aref) = ($$ctl{currow}, $$ctl{maxrow}, $$ctl{finished}, $$ctl{array});
	my(@arr) = @$aref;
	my($inc, $abs) = (0, $cur);
	$key = lc $key;
	if    ($key eq 'first')    { $abs = 1; }
	elsif ($key eq 'next')     { $inc = +1; }
	elsif ($key eq 'prev')     { $inc = -1; }
	elsif ($key eq 'relative') { $inc = $val; }
	elsif ($key eq 'current')  { $inc = 0; }
	elsif ($key eq 'absolute') { $abs = $val; }
	elsif ($key eq 'last')     { $abs = $max + 1; }
	else { confess "fetchrow_scroll_arrayref: invalid scroll fetch key $key"; }
	my $new = $abs + $inc;
	$new = 0 if $new < 0;
	print "new = $new; " if $debug;
	if (!$done)
	{
		my $ref;
		while ($max < $new && ($ref = $sth->fetchrow_arrayref()))
		{
			my(@row) = @$ref; # Have to copy array because DBI reuses it.
			$arr[++$max] = \@row;
			$new++ if ($key eq 'last');
			print "(n=$new, m=$max) " if $debug;
		}
		if ($max < $new)
		{
			$done = 1;
			$arr[$max+1] = undef;
			print "-- finish --" if $debug;
		}
	}
	$new = $max + 1 if $done && $new > $max;
	$new = $max if $key eq 'last';
	print "new = $new, max = $max\n" if $debug;
	$$ctl{maxrow} = $max;
	$$ctl{currow} = $new;
	$$ctl{finished} = $done;
	$$ctl{array} = \@arr;
	return $arr[$new];
}

sub pr_hash
{
	my(%hash) = @_;
	my($pad) = "# ";
	foreach my $key (sort keys %hash)
	{
		if ($key ne 'array')
		{
			my ($val) = $hash{$key};
			printf "%s%s => %s", $pad, $key, $val;
			$pad = ", ";
		}
		else
		{
			print "array => ";
			foreach my $ref (@{$hash{$key}})
			{
				if (defined $ref)
				{
					my(@arr) = @$ref; 
					print "(@arr) ";
				}
				else
				{
					print "undef ";
				}
			}
			print "\n";
		}
	}
	print "\n";
}

# Defined here since referenced in test_scroll_query_sequence()
my @data =  sort "systables", "syscolumns", "sysindexes", "sysconstraints", "syschecks", "syscolauth",
            "systabauth", "syssynonyms", "sysdefaults", "sysprocedures", "sysprocauth", "sysviews",
            "sysroles", "sysroleauth", "sysusers", "systriggers", "sysprocbody", "systrigbody",
            "sysxtdtypes", "sysxtdtypeauth", "sysxtddesc", "sysreferences", "syscoldepends", "sysdepends";

sub test_scroll_query_sequence($%)
{
	my ($sth, %ops) = @_;
	my $ctl = { array => [ undef ], maxrow => 0, currow => 0, finished => 0 }; 
	my $i = 0;
	my $fail = 0;
	pr_hash(%$ctl) if $debug;
	foreach my $seq (sort { $a <=> $b } keys %ops)
	{
		my(@tst) = @{$ops{$seq}};
		my($key) = $tst[0];
		my($val) = $tst[1];
		my($xtabid) = $tst[2];
		# pxtab?? - printable expected values
		my($pxtabid) = (defined $xtabid) ? $xtabid : 'undef';
		my($pxtabnm) = (defined $xtabid) ? $data[$xtabid] : 'undef';
		printf "-- Fetch: %2d, key = %-12s, val = %2d, expected = (%s, %s)\n",
				$seq, $key, $val, $pxtabid, $pxtabnm if $debug;
		my $ref = fetchrow_scroll_arrayref($sth, $ctl, $key, $val);
		pr_hash(%$ctl) if $debug;
		if ((defined $xtabid && (${$ref}[0] == $xtabid && ${$ref}[1] eq $data[$xtabid])) ||
			(!defined $xtabid && !defined ${$ref}[0]))
		{
			printf "-- OK: fetch %2d ($pxtabid, $pxtabnm)\n", $i;
		}
		else
		{
			$fail++;
			my($pgtabid) = defined $$ref[0] ? $$ref[0] : "undef";
			my($pgtabnm) = defined $$ref[1] ? $$ref[1] : "undef";
			printf "** Error: fetch %2d - got ($pgtabid, $pgtabnm), wanted ($pxtabid, $pxtabnm)\n", $i;
		}
		$i++;
	}
	print (($fail > 0) ? "## FAIL $fail (of $i)\n" : "== OK ($i pass) ==\n");
	return ($i, $fail);
}

# Connect, create and load test table
my $dbh = DBI->connect('dbi:Informix:stores','','',
				{RaiseError=>1, AutoCommit=>1, ChopBlanks=>1});
my $tab = "dbd_scroll";
$dbh->{PrintError} = 0;
$dbh->{RaiseError} = 0;
$dbh->do(qq{drop table $tab});
$dbh->{RaiseError} = 1;
$dbh->do(qq{create table $tab(tabid integer not null primary key, tabname char(18) not null unique)});

my $i = 1;
foreach my $tabname (@data)
{
	$dbh->do(qq{insert into $tab values($i, '$tabname')});
	$i++;
}

# Align with 1-based indexing.
unshift @data, "dummy";

# NB: Test sequences (%op1, %op2) assume that total entries in $table is 24.
my %op1 = (
			1  => [ 'absolute',  20, 20 ],
			2  => [ 'current',    0, 20 ],
			3  => [ 'first',      0,  1 ],
			4  => [ 'relative',  +3,  4 ],
			5  => [ 'next',       0,  5 ],
			6  => [ 'next',       0,  6 ],
		    7  => [ 'relative',  -3,  3 ],
		    8  => [ 'prev',       0,  2 ],
		    9  => [ 'last',       0,  24 ],
		    10 => [ 'absolute',  -1,  undef ],
		    11 => [ 'absolute',   7,  7 ],
		    12 => [ 'relative', +23,  undef ]
		   );

my %op2 = (
			1  => [ 'next',       0,  1 ],
			2  => [ 'next',       0,  2 ],
			3  => [ 'next',       0,  3 ],
			4  => [ 'relative',  +3,  6 ],
			5  => [ 'next',       0,  7 ],
			6  => [ 'next',       0,  8 ],
		    7  => [ 'relative',  -3,  5 ],
		    8  => [ 'prev',       0,  4 ],
			9  => [ 'next',       0,  5 ],
			10 => [ 'next',       0,  6 ],
			11 => [ 'next',       0,  7 ],
			12 => [ 'next',       0,  8 ],
			13 => [ 'next',       0,  9 ],
			14 => [ 'next',       0, 10 ],
			15 => [ 'next',       0, 11 ],
			16 => [ 'next',       0, 12 ],
			17 => [ 'next',       0, 13 ],
			18 => [ 'next',       0, 14 ],
			19 => [ 'next',       0, 15 ],
			20 => [ 'next',       0, 16 ],
			21 => [ 'next',       0, 17 ],
			22 => [ 'next',       0, 18 ],
			23 => [ 'next',       0, 19 ],
			24 => [ 'next',       0, 20 ],
			25 => [ 'next',       0, 21 ],
			26 => [ 'next',       0, 22 ],
			27 => [ 'next',       0, 23 ],
			28 => [ 'next',       0, 24 ],
			29 => [ 'next',       0, undef ],
			30 => [ 'prev',       0, 24 ],
			31 => [ 'prev',       0, 23 ],
			32 => [ 'prev',       0, 22 ],
			33 => [ 'prev',       0, 21 ],
			34 => [ 'prev',       0, 20 ],
		    35 => [ 'first',      0,  1 ],
			36 => [ 'next',       0,  2 ],
			37 => [ 'prev',       0,  1 ],
			38 => [ 'prev',       0, undef ],
		   );

my @ops = (\%op1, \%op2);

my $sth = $dbh->prepare(qq{SELECT tabid, tabname FROM $tab});

my($nseqs, $ttest, $tfail, $ttwf) = (0, 0, 0, 0, 0);

foreach my $opset (@ops)
{
	$nseqs++;
	print "== Test Sequence $nseqs\n";
	$sth->execute;
	my ($test, $fail) = test_scroll_query_sequence($sth, %$opset);
	$ttest += $test;
	$tfail += $fail;
	$ttwf++ if $fail;
}

print "== Test Sequences $nseqs";
print " ($ttwf with failures)" if $ttwf;
print " Fetch Tests $ttest";
print " (with $tfail failures)" if $tfail;
print "\n";
print (($tfail) ? "== FAILED ==\n" : "== PASSED ==\n");

$dbh->do(qq{drop table $tab});
$dbh->disconnect;

__END__

=head2 "Scroll cursors"

	$sth->setattr(SQL_STMT_CURSOR_ATTR, SQL_CURSOR_SCROLL);
	$sth->execute([@vals]);

The $sth->execute method is the familiar function, but the $sth->setattr
function (which is modelled after the ODBC function SQLStmtSetAttr()) is
new.  If the DBMS being accessed by the driver does not support scroll
cursors (determined via $dbh->getinfo(...)) or the driver has not
implemented the interface to the feature, then you will get a default
implementation (emulation) of scroll cursors shown above.  When
$sth->setattr() is called, it ensures that $sth->execute creates a
scroll cursor for the statement, which must be one that returns values
($sth->{NUM_OF_FIELDS} > 0).

    $row = $sth->fetchrow_scroll_arrayref($move, $offset);
    @row = $sth->fetchrow_scroll_array($move, $offset);
	$ref = $sth->fetchrow_scroll_hashref($move, $offset);

These methods can be used to fetch rows of data via a statement that was
executed with $sth->execute_scroll.  (Optionally: if the $move is
'next', then the fetchrow_scroll_* methods map to the corresponding
regular fetchrow_* method;any $move other than 'next' is rejected.)  The
acceptable values of $move are:

    'next'      == equivalent to 'relative' +1
    'prev'      == equivalent to 'relative' -1
    'current'   == equivalent to 'relative'  0
    'first'     == equivalent to 'absolute'  1
    'last'      == equivalent to 'absolute'  N (N = total rows)
    'relative'  == equivalent to 'absolute'  C + $offset (C = current)
    'absolute'

The value of $offset is only relevant for 'relative' and 'absolute'; it
is ignored for other $move values, but should be set to zero.  For $move
of 'absolute', the value of $offset should be a positive (non-negative)
number, and it should be smaller than the number of rows in the result
set.  For $move of 'relative', the value of $offset can be positive or
negative or zero and the magnitude should be smaller than the number of
rows in the result set.

Previously fetched rows are cached (possibly in the server, possibly in
the client).  When a row is to be fetched, if it is already in the
cache, it is returned from the cache.  If it is not already in the
cache, then the row is fetched from the database (caching result rows as
necessary).  If the row turns out not to exist, then 'undef' is
returned.  Fetches before the first row return undef; fetches after the
last row return undef.  The current position is then one space out of
range, and an appropriate relative fetch (or an absolute fetch) is
needed to collect values again.

=end
