#!/usr/bin/perl -w
#
#   @(#)$Id: dtgen.pl,v 2003.1 2003/01/03 19:02:36 jleffler Exp $
#
#   Create exhaustive list of DATETIME & INTERVAL types for DBD::Informix
#
# Copyright 1997    Jonathan Leffler
# Copyright 2000    Informix Software Inc
# Copyright 2002-03 IBM

# Enumerate the DATETIME types
$i = 0;
$dtqual1{$i++} = 'year';
$dtqual1{$i++} = 'month';
$dtqual1{$i++} = 'day';
$dtqual1{$i++} = 'hour';
$dtqual1{$i++} = 'minute';
$dtqual1{$i++} = 'second';
$dtqual1{$i++} = 'fraction';
$ndtqual1 = $i;

$j = 0;
$dtqual2{$j++} = 'year';
$dtqual2{$j++} = 'month';
$dtqual2{$j++} = 'day';
$dtqual2{$j++} = 'hour';
$dtqual2{$j++} = 'minute';
$dtqual2{$j++} = 'second';
$dtqual2{$j++} = 'fraction(1)';
$dtqual2{$j++} = 'fraction(2)';
$dtqual2{$j++} = 'fraction(3)';
$dtqual2{$j++} = 'fraction(4)';
$dtqual2{$j++} = 'fraction(5)';
$ndtqual2 = $j;

printf ("\n-- DATETIME types.\n");
print "CREATE TEMP TABLE dbd_ix_datetime\n(\n";
print "    Col000  SERIAL NOT NULL {PRIMARY KEY}{XPS 8.30 rejects PK},\n";
$ndtime = 0;
$colno = 1;
for ($i = 0; $i < $ndtqual1; $i++)
{
    for ($j = $i; $j < $ndtqual2; $j++)
	{
		printf "    dt%03d  datetime %s to %s,\n",
				$colno++, $dtqual1{$i}, $dtqual2{$j};
		$ndtime++;
    }
}
printf "-- %d DATETIME types.\n", $ndtime;

# Enumerate the DATETIME synonyms
$i = 0;
$dtqual1{$i++} = 'year';
$dtqual1{$i++} = 'month';
$dtqual1{$i++} = 'day';
$dtqual1{$i++} = 'hour';
$dtqual1{$i++} = 'minute';
$dtqual1{$i++} = 'second';
$dtqual1{$i++} = 'fraction';
$ndtqual1 = $i;

$j = 0;
$dtqual2{$j++} = 'fraction';
$ndtqual2 = $j;

printf ("\n-- DATETIME synonyms.\n");
$ndtime = 0;
for ($i = 0; $i < $ndtqual1; $i++)
{
    for ($j = 0; $j < $ndtqual2; $j++)
	{
		printf "    dt%03d  datetime %s to %s,\n",
			$colno++, $dtqual1{$i}, $dtqual2{$j};
		$ndtime++;
    }
}
printf "-- %d DATETIME synonyms.\n", $ndtime;
print "    Dummy   CHAR(1)\n) WITH NO LOG;\n\n";

# Enumerate the INTERVAL types based on YEAR..MONTH
print "CREATE TEMP TABLE dbd_ix_interval\n(\n";
print "    Col000  SERIAL NOT NULL {PRIMARY KEY}{XPS 8.30 rejects PK},\n";
$colno = 1;
$i = 0;
$ivqual1{$i++} = 'year';
$ivqual1{$i++} = 'month';
$nivqual1 = $i;

$j = 0;
$ivqual2{$j++} = 'year';
$ivqual2{$j++} = 'month';
$nivqual2 = $j;

printf ("\n-- INTERVAL types based on YEAR..MONTH.\n");
$nintvl1 = 0;
for ($i = 0; $i < $nivqual1; $i++)
{
    for ($j = $i; $j < $nivqual2; $j++)
	{
		for ($k = 9; $k > 0; $k--)
		{
			printf "    iv%03d  interval %s(%d) to %s,\n",
				$colno++, $ivqual1{$i}, $k, $ivqual2{$j};
			$nintvl1++;
		}
    }
}
printf "-- %d INTERVAL types based on YEAR..MONTH.\n", $nintvl1;

# Enumerate the INTERVAL types based on YEAR..MONTH
printf ("\n-- INTERVAL synonyms based on YEAR..MONTH.\n");
$nintvl1 = 0;
for ($i = 0; $i < $nivqual1; $i++)
{
    for ($j = $i; $j < $nivqual2; $j++)
	{
		printf "    iv%03d  interval %s to %s,\n",
				$colno++, $ivqual1{$i}, $ivqual2{$j};
		$nintvl1++;
    }
}
printf "-- %d INTERVAL synonyms based on YEAR..MONTH.\n", $nintvl1;

# Enumerate the INTERVAL types based on DAY..FRACTION
$i = 0;
$ivqual1{$i++} = 'day';
$ivqual1{$i++} = 'hour';
$ivqual1{$i++} = 'minute';
$ivqual1{$i++} = 'second';
$nivqual1 = $i;

$j = 0;
$ivqual2{$j++} = 'day';
$ivqual2{$j++} = 'hour';
$ivqual2{$j++} = 'minute';
$ivqual2{$j++} = 'second';
$ivqual2{$j++} = 'fraction(1)';
$ivqual2{$j++} = 'fraction(2)';
$ivqual2{$j++} = 'fraction(3)';
$ivqual2{$j++} = 'fraction(4)';
$ivqual2{$j++} = 'fraction(5)';
$nivqual2 = $j;

printf ("\n-- INTERVAL types based on DAY..FRACTION.\n");
$nintvl1 = 0;
for ($i = 0; $i < $nivqual1; $i++)
{
    for ($j = $i; $j < $nivqual2; $j++)
	{
		for ($k = 9; $k > 0; $k--)
		{
			printf "    iv%03d  interval %s(%d) to %s,\n",
					$colno++, $ivqual1{$i}, $k, $ivqual2{$j};
			$nintvl1++;
		}
    }
}
$i = 0;
$ivqual1{$i++} = 'fraction';
$nivqual1 = $i;

$j = 0;
$ivqual2{$j++} = 'fraction(1)';
$ivqual2{$j++} = 'fraction(2)';
$ivqual2{$j++} = 'fraction(3)';
$ivqual2{$j++} = 'fraction(4)';
$ivqual2{$j++} = 'fraction(5)';
$nivqual2 = $j;

for ($i = 0; $i < $nivqual1; $i++)
{
    for ($j = $i; $j < $nivqual2; $j++)
	{
	printf "    iv%03d  interval %s to %s,\n",
			$colno++, $ivqual1{$i}, $ivqual2{$j};
	$nintvl1++;
    }
}
printf "-- %d INTERVAL types based on DAY..FRACTION.\n", $nintvl1;

# Enumerate the INTERVAL synonyms based on DAY..FRACTION
$i = 0;
$ivqual1{$i++} = 'day';
$ivqual1{$i++} = 'hour';
$ivqual1{$i++} = 'minute';
$ivqual1{$i++} = 'second';
$nivqual1 = $i;

$j = 0;
$ivqual2{$j++} = 'day';
$ivqual2{$j++} = 'hour';
$ivqual2{$j++} = 'minute';
$ivqual2{$j++} = 'second';
$ivqual2{$j++} = 'fraction(1)';
$ivqual2{$j++} = 'fraction(2)';
$ivqual2{$j++} = 'fraction(3)';
$ivqual2{$j++} = 'fraction(4)';
$ivqual2{$j++} = 'fraction(5)';
$nivqual2 = $j;

printf ("\n-- INTERVAL synonyms based on DAY..FRACTION.\n");
$nintvl1 = 0;
for ($i = 0; $i < $nivqual1; $i++)
{
    for ($j = $i; $j < $nivqual2; $j++)
	{
	printf "    iv%03d  interval %s to %s,\n",
			$colno++, $ivqual1{$i}, $ivqual2{$j};
	$nintvl1++;
    }
}
$i = 0;
$ivqual1{$i++} = 'day';
$ivqual1{$i++} = 'hour';
$ivqual1{$i++} = 'minute';
$ivqual1{$i++} = 'second';
$ivqual1{$i++} = 'fraction';
$nivqual1 = $i;

$j = 0;
$ivqual2{$j++} = 'fraction';
$nivqual2 = $j;

for ($i = 0; $i < $nivqual1; $i++)
{
    for ($j = 0; $j < $nivqual2; $j++)
	{
		printf "    iv%03d  interval %s to %s,\n",
				$colno++, $ivqual1{$i}, $ivqual2{$j};
		$nintvl1++;
    }
}
printf "-- %d INTERVAL synonyms based on DAY..FRACTION.\n", $nintvl1;
print "    Dummy   CHAR(1)\n) WITH NO LOG;\n\n";
