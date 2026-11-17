#!/usr/bin/perl

# A Database::Abstraction table read from an XML document with several
# top-level elements (a report: version, a header, and a repeating record)
# joins like any other.  Database::Abstraction before 0.57 read such a file
# from whichever key Perl listed first, so the join failed on some runs with
# "XML slurp: cannot handle HASH structure".
#
#   prove -l t/xml-document.t

use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::Most;

BEGIN {
	eval { require Database::Abstraction; require XML::Simple; 1 }
		or plan skip_all => 'Database::Abstraction and XML::Simple required';
	plan skip_all => 'Database::Abstraction 0.57 or later reads a multi-element XML document'
		unless eval { Database::Abstraction->VERSION('0.57'); 1 };
}

use_ok('Database::Join');

package Database::djxml_report;
use parent 'Database::Abstraction';
package Database::djxml_hosts;
use parent 'Database::Abstraction';
package main;

my $dir = tempdir(CLEANUP => 1);

sub write_file {
	my ($name, $text) = @_;
	open my $fh, '>', "$dir/$name" or die "$dir/$name: $!";
	print {$fh} $text;
	close $fh;
}

write_file('djxml_report.xml', <<'XML');
<?xml version="1.0" encoding="UTF-8" ?>
<feedback>
  <version>1.0</version>
  <report_metadata><org_name>example.com</org_name></report_metadata>
  <policy_published><domain>example.org</domain></policy_published>
  <record><entry>h1</entry><count>8</count></record>
  <record><entry>h2</entry><count>10</count></record>
  <record><entry>h3</entry><count>1</count></record>
</feedback>
XML

write_file('djxml_hosts.csv', "entry,owner\nh1,alice\nh2,bob\n");

for my $try (1 .. 10) {
	my $report = Database::djxml_report->new(directory => $dir, max_slurp_size => 1_000_000);
	my $hosts  = Database::djxml_hosts->new(directory => $dir, sep_char => ',', max_slurp_size => 1_000_000);

	my $join = Database::Join->new(
		databases   => [ $report, $hosts ],
		join_column => 'entry',
	);

	my $rows;
	lives_ok { $rows = $join->selectall_arrayref() } "try $try: the join reads the XML document";
	is scalar @{ $rows || [] }, 3, "try $try: one row per record" or next;

	my %by = map { $_->{entry} => $_ } @{$rows};
	is $by{h1}{count}, 8,       "try $try: a count from the XML";
	is $by{h1}{owner}, 'alice', "try $try: an owner from the CSV";
	ok !defined $by{h3}{owner}, "try $try: no owner for a record the CSV lacks";
}

done_testing();
