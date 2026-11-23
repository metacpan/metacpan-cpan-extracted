#!/usr/bin/env perl

# An XML file that is a document (a DMARC report: version, report_metadata,
# policy_published and a repeating record) is a table of its repeating
# element, each row carrying the report's one-off values.  Database::Abstraction
# reads one repeating element of a flat document and used to croak, depending
# on Perl's key order, with "XML slurp: cannot handle HASH structure", so
# DataSource writes a flat copy for it, as it does for JSON.
#
#   prove -l t/xml-document.t

use strict;
use warnings;

use Test::Most;
use Test::Mojo;
use File::Spec;
use File::Temp qw(tempdir);
use Mojo::File;
use Mojo::Util qw(url_escape);

plan skip_all => 'XML::Simple is not installed' unless eval { require XML::Simple; 1 };

my $t = Test::Mojo->new('Database::BI');
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

require Database::BI::Model::DataSource;
my $DS = 'Database::BI::Model::DataSource';

my $REPORT = <<'XML';
<?xml version="1.0" encoding="UTF-8" ?>
<feedback>
  <version>1.0</version>
  <report_metadata>
    <org_name>google.com</org_name>
    <report_id>9250231420970591661</report_id>
    <date_range>
      <begin>1794355200</begin>
      <end>1794441599</end>
    </date_range>
  </report_metadata>
  <policy_published>
    <domain>bandsman.co.uk</domain>
    <p>none</p>
  </policy_published>
  <record>
    <row>
      <source_ip>164.92.141.245</source_ip>
      <count>8</count>
      <policy_evaluated>
        <disposition>none</disposition>
        <dkim>fail</dkim>
      </policy_evaluated>
    </row>
    <identifiers><header_from>bandsman.co.uk</header_from></identifiers>
    <auth_results>
      <spf><domain>bandsman.co.uk</domain><result>softfail</result></spf>
    </auth_results>
  </record>
  <record>
    <row>
      <source_ip>213.124.56.170</source_ip>
      <count>10</count>
      <policy_evaluated>
        <disposition>none</disposition>
        <dkim>pass</dkim>
      </policy_evaluated>
    </row>
    <identifiers><header_from>bandsman.co.uk</header_from></identifiers>
    <auth_results>
      <dkim><domain>bandsman.co.uk</domain><result>pass</result></dkim>
      <dkim><domain>other.example</domain><result>fail</result></dkim>
      <spf><domain>bandsman.co.uk</domain><result>pass</result></spf>
    </auth_results>
  </record>
</feedback>
XML

# xml_file($name, $text) -> ($dir, $stem, $path), each in a folder of its own.
sub xml_file {
	my ($name, $text) = @_;
	my $dir  = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($dir, $name);
	Mojo::File->new($path)->spew($text);
	(my $stem = $name) =~ s/\.[^.]+\z//;
	return ($dir, $stem, $path);
}

sub open_xml {
	my ($name, $text) = @_;
	my ($dir, $stem) = xml_file($name, $text);
	return $DS->new(directory => $dir, table => $stem);
}

subtest 'a DMARC report: a row a record, with the report beside it' => sub {
	# The file name has dots and bangs, as the reports Google sends do.
	my $ds   = open_xml('google.com!bandsman.co.uk!1794355200!1794441599.xml', $REPORT);
	my $rows = $ds->fetch_all;
	is scalar @{$rows}, 2, 'one row a record, not the report header';
	my ($first) = grep { $_->{row_source_ip} eq '164.92.141.245' } @{$rows};
	is $first->{row_count},                       8,                'a record value';
	is $first->{row_policy_evaluated_dkim},       'fail',           'a nested value, its names joined';
	is $first->{identifiers_header_from},         'bandsman.co.uk', 'a sibling of the row element';
	is $first->{auth_results_spf_result},         'softfail',       'two levels down';
	is $first->{report_metadata_org_name},        'google.com',     'the report says whose it is';
	is $first->{report_metadata_date_range_begin}, 1794355200,      'and when';
	is $first->{policy_published_domain},         'bandsman.co.uk', 'and the policy';
	is $first->{version},                         '1.0',            'a bare top-level value';
	ok !exists $first->{record}, 'the row element is not a column of itself';
};

subtest 'the columns come in the order of the file, the same each time' => sub {
	my @want = qw(
		version report_metadata_org_name report_metadata_report_id
		report_metadata_date_range_begin report_metadata_date_range_end
		policy_published_domain policy_published_p
		row_source_ip row_count row_policy_evaluated_disposition row_policy_evaluated_dkim
		identifiers_header_from auth_results_spf_domain auth_results_spf_result
		auth_results_dkim
	);
	for my $try (1 .. 5) {
		my $ds = open_xml('report.xml', $REPORT);
		is_deeply $ds->columns, \@want, "try $try: columns as the file first names them";
	}
};

subtest 'a repeated element inside a record is one cell' => sub {
	my $rows = open_xml('report.xml', $REPORT)->fetch_all;
	my ($second) = grep { $_->{row_source_ip} eq '213.124.56.170' } @{$rows};
	like $second->{auth_results_dkim}, qr/^\[\{.*other\.example.*\}\]$/, 'elements with parts are their JSON text';
	is $second->{auth_results_spf_result}, 'pass', 'the single ones stay plain';
	my ($first) = grep { $_->{row_source_ip} eq '164.92.141.245' } @{$rows};
	is $first->{auth_results_dkim}, '', 'and empty where a record has none';
};

subtest 'a report with one record is still a table' => sub {
	(my $one = $REPORT) =~ s{<record>.*?</record>\s*(?=<record>)}{}s;
	my $ds   = open_xml('one.xml', $one);
	my $rows = $ds->fetch_all;
	is scalar @{$rows}, 1, 'one row';
	is $rows->[0]{row_source_ip}, '213.124.56.170', 'the record that is left';
	is $rows->[0]{report_metadata_org_name}, 'google.com', 'with the report beside it';
};

subtest 'elements called name, id and key are not folded away' => sub {
	my $ds = open_xml('named.xml', <<'XML');
<?xml version="1.0"?>
<doc>
  <title>Stock</title>
  <item><name>bolt</name><id>7</id><key>k1</key></item>
  <item><name>nut</name><id>8</id><key>k2</key></item>
</doc>
XML
	my $rows = $ds->fetch_all;
	is scalar @{$rows}, 2, 'two items';
	my ($bolt) = grep { $_->{name} eq 'bolt' } @{$rows};
	is $bolt->{id},    7,       'id kept as a value';
	is $bolt->{key},   'k1',    'key kept as a value';
	is $bolt->{title}, 'Stock', 'with the title beside it';
};

subtest 'a flat list of rows is left to Database::Abstraction' => sub {
	my $ds   = open_xml('flat.xml', <<'XML');
<?xml version="1.0"?>
<rows><row><sku>a</sku><qty>1</qty></row><row><sku>b</sku><qty>2</qty></row></rows>
XML
	is scalar @{ $ds->fetch_all }, 2, 'two rows';
	ok !$ds->{_json_tmpdir}, 'no flat copy was made';
};

subtest 'a file that is not XML is left to Database::Abstraction' => sub {
	my ($dir, $stem) = xml_file('broken.xml', "<feedback><record>");
	throws_ok { $DS->new(directory => $dir, table => $stem)->fetch_all } qr/\S/, 'the reader reports it, not a crash here';
};

subtest 'the report opens in the browser' => sub {
	my ($dir, $stem, $path) = xml_file('google.com!bandsman.co.uk!1!2.xml', $REPORT);
	$t->get_ok('/open?path=' . url_escape($path))->status_is(200)
	  ->content_like(qr{<td[^>]*>164\.92\.141\.245</td>}, 'a record is a table row')
	  ->content_like(qr{<td[^>]*>softfail</td>}, 'with its nested value')
	  ->content_unlike(qr/cannot handle HASH/, 'and no error');
};

# An entity can make the parser read a file or fetch an address of its own
# accord, past every path check (file_roots included).  Both reader routes
# are shut: the document one (_xml_table) and the flat one (D::A's).
subtest 'an XML entity is refused, whichever reader the file would reach' => sub {
	my $secret_dir = tempdir(CLEANUP => 1);
	my $secret     = File::Spec->catfile($secret_dir, 'secret.txt');
	Mojo::File->new($secret)->spew("TOP-SECRET-VALUE\n");
	my $doctype = qq{<!DOCTYPE r [<!ENTITY x SYSTEM "file://$secret">]>};
	my %files = (
		'flat'     => qq{<?xml version="1.0"?>\n$doctype\n<rows><row><sku>&x;</sku></row><row><sku>b</sku></row></rows>\n},
		'document' => qq{<?xml version="1.0"?>\n$doctype\n<report><meta>m</meta><row><sku>&x;</sku></row><row><sku>b</sku></row></report>\n},
		'internal' => qq{<?xml version="1.0"?>\n<!DOCTYPE r [<!ENTITY y "lol">]>\n<rows><row><sku>&y;</sku></row></rows>\n},
		'parameter' => qq{<?xml version="1.0"?>\n<!DOCTYPE r [<!ENTITY % p SYSTEM "file://$secret">]>\n<rows><row><sku>a</sku></row></rows>\n},
	);
	for my $kind (sort keys %files) {
		my ($dir, $stem, $path) = xml_file("$kind.xml", $files{$kind});
		throws_ok { $DS->new(directory => $dir, table => $stem)->fetch_all }
			qr/declares XML entities/, "$kind: refused, and says why";
		$t->get_ok('/open?path=' . url_escape($path))
		  ->content_unlike(qr/TOP-SECRET-VALUE/, "$kind: the file's contents are not on the page");
	}

	# UTF-16 spells <!ENTITY with NUL bytes, which a text match would miss.
	my $wide = "\xFF\xFE" . join '', map { "$_\0" } split //, qq{<?xml version="1.0"?>$doctype<rows><row><sku>&x;</sku></row></rows>};
	my ($dir, $stem) = xml_file('wide.xml', $wide);
	throws_ok { $DS->new(directory => $dir, table => $stem)->fetch_all }
		qr/declares XML entities/, 'UTF-16 is refused, not read';

	# A comment mentioning the word is only a comment, and a plain file is untouched.
	my ($d2, $s2) = xml_file('plain.xml', qq{<?xml version="1.0"?>\n<rows><row><sku>a</sku></row><row><sku>b</sku></row></rows>\n});
	is scalar @{ $DS->new(directory => $d2, table => $s2)->fetch_all }, 2, 'an ordinary file still opens';
};

done_testing();
