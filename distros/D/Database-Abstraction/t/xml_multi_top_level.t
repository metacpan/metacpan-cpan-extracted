#!/usr/bin/env perl

# An XML document with several top-level elements (a DMARC report has
# version, report_metadata, policy_published and a repeating record) used to
# be read from whichever key Perl listed first: with no_entry it croaked
# "XML slurp: cannot handle HASH structure" on some runs and not others.
# The repeating element is now always the one read as rows.

use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::Most;

package Database::report;
use parent 'Database::Abstraction';
package main;

my $xml = <<'XML';
<?xml version="1.0" encoding="UTF-8" ?>
<feedback>
  <version>1.0</version>
  <report_metadata><org_name>example.com</org_name></report_metadata>
  <policy_published><domain>example.org</domain></policy_published>
  <record><source_ip>192.0.2.1</source_ip><count>8</count></record>
  <record><source_ip>192.0.2.2</source_ip><count>10</count></record>
  <record><source_ip>192.0.2.3</source_ip><count>1</count></record>
</feedback>
XML

sub dir_with {
	my ($text) = @_;
	my $dir = tempdir(CLEANUP => 1);
	open my $fh, '>', "$dir/report.xml" or die "$dir/report.xml: $!";
	print {$fh} $text;
	close $fh;
	return $dir;
}

sub open_db {
	my ($dir) = @_;
	return Database::report->new(directory => $dir, no_entry => 1, max_slurp_size => 1_000_000);
}

# Hash order differs from one process to the next, and XML::Simple builds a
# new hash on every parse, so trying the same file repeatedly catches the
# old behaviour in-process.
subtest 'the repeating element is the rows, whatever order Perl lists the keys' => sub {
	my $dir = dir_with($xml);
	for my $try (1 .. 20) {
		my $db = open_db($dir);
		my $rows;
		lives_ok { $rows = $db->selectall_arrayref() } "try $try reads";
		is scalar(@{ $rows || [] }), 3, "try $try: three records" or last;
	}
	my @ips = sort map { $_->{source_ip} } @{ open_db($dir)->selectall_arrayref() };
	is_deeply \@ips, [qw(192.0.2.1 192.0.2.2 192.0.2.3)], 'the records, not the report metadata';
};

subtest 'the element with most occurrences wins, then the name' => sub {
	my $dir = dir_with(<<'XML');
<?xml version="1.0"?>
<r>
  <a><x>1</x></a><a><x>2</x></a>
  <b><x>3</x></b><b><x>4</x></b><b><x>5</x></b>
  <c><x>6</x></c>
</r>
XML
	is_deeply [ sort map { $_->{x} } @{ open_db($dir)->selectall_arrayref() } ], [3, 4, 5], 'b, the most repeated';

	$dir = dir_with(<<'XML');
<?xml version="1.0"?>
<r>
  <b><x>3</x></b><b><x>4</x></b>
  <a><x>1</x></a><a><x>2</x></a>
</r>
XML
	is_deeply [ sort map { $_->{x} } @{ open_db($dir)->selectall_arrayref() } ], [1, 2], 'a tie goes to the first name';
};

subtest 'no repeating element still says so' => sub {
	my $dir = dir_with(<<'XML');
<?xml version="1.0"?>
<r><version>1</version><name>x</name></r>
XML
	throws_ok { open_db($dir)->selectall_arrayref() } qr/no repeating element/,
		'a clear message, not "cannot handle HASH"';
};

subtest 'a flat list of rows is read as before' => sub {
	my $dir = dir_with(<<'XML');
<?xml version="1.0"?>
<rows><row><k>1</k></row><row><k>2</k></row></rows>
XML
	is scalar @{ open_db($dir)->selectall_arrayref() }, 2, 'two rows';
};

done_testing();
