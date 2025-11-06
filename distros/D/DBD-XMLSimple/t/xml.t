#!/usr/bin/env perl
use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::Most;
use FindBin qw($Bin);
use DBI;

# Ensure DBD::XMLSimple loads
use_ok('DBD::XMLSimple');

# Temporary XML samples for testing
my ($fh_empty, $xml_empty) = tempfile(SUFFIX => '.xml');
my ($fh_simple, $xml_simple) = tempfile(SUFFIX => '.xml');
my ($fh_duplicate, $xml_duplicate) = tempfile(SUFFIX => '.xml');

# Write test XML files
open my $fh, '>', $xml_empty or die $!;
print $fh <<"EOF";
<table>
</table>
EOF
close $fh;

open $fh, '>', $xml_simple or die $!;
print $fh <<"EOF";
<table>
	<row id="1">
		<name>Alice</name>
		<email>alice\@example.com</email>
	</row>
	<row id="2">
		<name>Bob</name>
		<email>bob\@example.com</email>
	</row>
</table>
EOF
close $fh;

open $fh, '>', $xml_duplicate or die $!;
print $fh <<"EOF";
<table>
	<row id="1">
		<name>Carol</name>
		<email>carol\@example.com</email>
		<email>c.carol\@example.com</email>
	</row>
</table>
EOF
close $fh;

# Connect to DBD::XMLSimple
my $dbh = DBI->connect('dbi:XMLSimple(RaiseError => 1):');
ok($dbh, 'Connected to DBD::XMLSimple');

# ---------------------------------------------------------------------
# Empty table
# ---------------------------------------------------------------------
$dbh->func('empty', 'XML', $xml_empty, 'xmlsimple_import');
my $sth = $dbh->prepare('SELECT * FROM empty');
$sth->execute();

my $rows = $sth->fetchall_arrayref();
ok((!defined $rows) || (scalar(@{$rows}) == 0), 'Empty table returns undef from fetchall_arrayref');

# ---------------------------------------------------------------------
# Simple SELECT, WHERE works
# ---------------------------------------------------------------------
$dbh->func('simple', 'XML', $xml_simple, 'xmlsimple_import');
$sth = $dbh->prepare("SELECT name FROM simple WHERE email = 'bob\@example.com'");
$sth->execute();
$rows = $sth->fetchall_arrayref();
is(scalar @$rows, 1, 'One row matches WHERE clause');
is($rows->[0][0], 'Bob', 'Correct name returned for Bob');

# ---------------------------------------------------------------------
# SELECT with repeated leaves (concatenation)
# ---------------------------------------------------------------------
$dbh->func('duplicate', 'XML', $xml_duplicate, 'xmlsimple_import');

# SELECT from duplicate table
$sth = $dbh->prepare('SELECT email FROM duplicate');
$sth->execute();
$rows = $sth->fetchall_arrayref();
is(scalar @$rows, 1, 'One row returned for duplicate XML');
is($rows->[0][0], 'carol@example.com,c.carol@example.com', 'Repeated leaves concatenated correctly');

$sth = $dbh->prepare('SELECT name FROM simple ORDER BY id');
$sth->execute();

my $row = $sth->fetchrow_arrayref();
is_deeply($row, ['Alice'], 'fetchrow_arrayref returns first row correctly');

$row = $sth->fetchrow_arrayref();
is_deeply($row, ['Bob'], 'fetchrow_arrayref returns second row correctly');

$row = $sth->fetchrow_arrayref();
ok(!defined $row, 'fetchrow_arrayref returns undef at end');

done_testing();
