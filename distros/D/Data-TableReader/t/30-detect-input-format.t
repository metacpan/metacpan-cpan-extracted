#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Encode qw( encode );

use_ok( 'Data::TableReader' ) or BAIL_OUT;

=head1 DESCRIPTION

This collection of tests verify that the detect_input_format method calculates the right decoder
arguments from a wide variety of input objects and with a variety of hints.

=cut


{ # Mock of HTTP::Headers
	package Local::HTTPHeaders;

	sub new {
		my ($class, %headers)= @_;
		bless \%headers, $class;
	}

	sub header {
		my ($self, $name)= @_;
		return $self->{$name};
	}
}

{ # Mock of various web framework ::Upload objects
	package Local::Upload;

	sub new {
		my ($class, %args)= @_;
		bless \%args, $class;
	}

	sub headers {
		$_[0]{headers};
	}
}

my %bom= (
	'UTF-8'    => "\xEF\xBB\xBF",
	'UTF-16LE' => "\xFF\xFE",
	'UTF-16BE' => "\xFE\xFF",
	'UTF-32LE' => "\xFF\xFE\x00\x00",
	'UTF-32BE' => "\x00\x00\xFE\xFF",
);
sub encode_with_bom {
	my ($encoding, $text)= @_;
	return $bom{$encoding} . encode($encoding, $text);
}
sub unused_input { my $x; \$x; }

my $csv= <<'CSV';
name,description
alpha,first
beta,second
CSV

my $tsv= <<'TSV';
name	description
alpha	first
beta	second
TSV

my @tests= (
	{
		name     => 'CSV from content type',
		hints    => {
			content_type => 'text/csv',
			content_head => $csv,
		},
		expected => [ 'CSV' ],
	},
	{
		name     => 'CSV content type with explicit charset',
		hints    => {
			content_type => 'text/csv',
			charset     => 'UTF-8',
			content_head => $csv,
		},
		expected => [ 'CSV', encoding => 'utf-8-strict' ],
	},
	{
		name     => 'CSV content type contains charset',
		hints    => {
			content_type => 'text/csv; charset=UTF-8',
			content_head => $csv,
		},
		expected => [ 'CSV', encoding => 'utf-8-strict' ],
	},
	{
		name     => 'quoted charset in content type',
		hints    => {
			content_type => 'text/csv; charset="ISO-8859-1"',
			content_head => $csv,
		},
		expected => [ 'CSV', encoding => 'iso-8859-1' ],
	},
	{
		name  => 'explicit charset overrides HTTP charset',
		hints => {
			content_type => 'text/csv',
			charset     => 'UTF-8',
			http_headers => {
				'Content-Type' => 'text/csv; charset=ISO-8859-1',
			},
			content_head => $csv,
		},
		expected => [ 'CSV', encoding => 'utf-8-strict' ],
	},
	{
		name  => 'content type from hash headers',
		hints => {
			http_headers => {
				'Content-Type' => 'text/csv; charset=UTF-8',
			},
			content_head => $csv,
		},
		expected => [ 'CSV', encoding => 'utf-8-strict' ],
	},
	{
		name  => 'case-insensitive hash header name',
		hints => {
			http_headers => {
				'content_type' => 'text/tab-separated-values; charset=UTF-8',
			},
			content_head => $tsv,
		},
		expected => [ 'TSV', encoding => 'utf-8-strict' ],
	},
	{
		name  => 'content type from HTTP::Headers-like object',
		hints => {
			http_headers => Local::HTTPHeaders->new(
				'Content-Type' => 'text/csv; charset=UTF-8',
			),
			content_head => $csv,
		},
		expected => [ 'CSV', encoding => 'utf-8-strict' ],
	},
	{
		name  => 'headers obtained from upload object',
		input => Local::Upload->new(
			headers => Local::HTTPHeaders->new(
				'Content-Type' => 'text/tab-separated-values; charset=UTF-8',
			),
		),
		hints => {
			content_head => $tsv,
		},
		expected => [ 'TSV', encoding => 'utf-8-strict' ],
	},
	{
		name  => 'explicit content type does not inherit charset from mismatched header',
		hints => {
			content_type => 'text/csv',
			http_headers => {
				'Content-Type' => 'text/plain; charset=UTF-16LE',
			},
			content_head => $csv,
		},
		expected => [ 'CSV' ],
	},
	{
		name  => 'TSV from content type',
		hints => {
			content_type => 'text/tab-separated-values',
			content_head => $tsv,
		},
		expected => [ 'TSV' ],
	},
	{
		name  => 'XLS from content type',
		hints => {
			content_type => 'application/vnd.ms-excel',
			content_head => '',
		},
		expected => [ 'XLS' ],
	},
	{
		name  => 'XLSX from content type',
		hints => {
			content_type =>
				'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
			content_head => '',
		},
		expected => [ 'XLSX' ],
	},
	{
		name  => 'CSV from filename',
		hints => {
			filename     => 'sample.csv',
			charset      => 'UTF-8',
			content_head => $csv,
		},
		expected => [ 'CSV', encoding => 'utf-8-strict' ],
	},
	{
		name  => 'TSV from filename',
		hints => {
			filename     => 'sample.tsv',
			charset      => 'UTF-16LE',
			content_head => encode('UTF-16LE', $tsv),
		},
		expected => [ 'TSV', encoding => 'UTF-16LE' ],
	},
	{
		name  => 'HTM suffix normalizes to HTML',
		hints => {
			filename     => 'sample.htm',
			content_head => '<html>',
		},
		expected => [ 'HTML' ],
	},
	{
		name  => 'XLS magic takes priority over CSV filename',
		hints => {
			filename     => 'wrong.csv',
			content_head => "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1",
		},
		expected => [ 'XLS' ],
	},
	{
		name  => 'XLSX magic takes priority over CSV filename',
		hints => {
			filename     => 'wrong.csv',
			content_head => "PK\x03\x04more bytes",
		},
		expected => [ 'XLSX' ],
	},
	{
		name  => 'HTML UTF-8 without BOM',
		hints => {
			content_head => '<!DOCTYPE html><html>',
		},
		expected => [ 'HTML' ],
	},
	{
		name  => 'HTML UTF-8 with BOM',
		hints => {
			content_head => encode_with_bom(
				'UTF-8',
				'<!DOCTYPE html><html>'
			),
		},
		expected => [ 'HTML', encoding => 'utf-8-strict' ],
	},
	{
		name  => 'HTML UTF-16LE with BOM',
		hints => {
			content_head => encode_with_bom(
				'UTF-16LE',
				'<!DOCTYPE html><html>',
			),
		},
		expected => [ 'HTML', encoding => 'UTF-16LE' ],
	},
	{
		name  => 'HTML UTF-16BE with BOM',
		hints => {
			content_head => encode_with_bom(
				'UTF-16BE',
				'<html>',
			),
		},
		expected => [ 'HTML', encoding => 'UTF-16BE' ],
	},
	{
		name  => 'HTML UTF-32LE with BOM',
		hints => {
			content_head => encode_with_bom(
				'UTF-32LE',
				'<html>',
			),
		},
		expected => [ 'HTML', encoding => 'UTF-32LE' ],
	},
	{
		name  => 'HTML UTF-32BE with BOM',
		hints => {
			content_head => encode_with_bom(
				'UTF-32BE',
				'<html>',
			),
		},
		expected => [ 'HTML', encoding => 'UTF-32BE' ],
	},
	{
		name  => 'CSV probe in UTF-8',
		hints => {
			content_head => $csv,
		},
		expected => [ 'CSV' ],
	},
	{
		name  => 'TSV probe in UTF-8',
		hints => {
			content_head => $tsv,
		},
		expected => [ 'TSV' ],
	},
	{
		name  => 'CSV probe using supplied UTF-16LE',
		hints => {
			charset      => 'UTF-16LE',
			content_head => encode('UTF-16LE', $csv),
		},
		expected => [ 'CSV', encoding => 'UTF-16LE' ],
	},
	{
		name  => 'TSV probe using supplied UTF-32BE',
		hints => {
			charset      => 'UTF-32BE',
			content_head => encode('UTF-32BE', $tsv),
		},
		expected => [ 'TSV', encoding => 'UTF-32BE' ],
	},
	{
		name  => 'CSV probe detects UTF-16LE BOM',
		hints => {
			content_head => encode_with_bom('UTF-16LE', $csv),
		},
		expected => [ 'CSV', encoding => 'UTF-16LE' ],
	},
	{
		name  => 'TSV probe detects UTF-16BE BOM',
		hints => {
			content_head => encode_with_bom('UTF-16BE', $tsv),
		},
		expected => [ 'TSV', encoding => 'UTF-16BE' ],
	},
	{
		name  => 'CSV probe detects UTF-32LE without BOM',
		hints => {
			content_head => encode('UTF-32LE', $csv),
		},
		expected => [ 'CSV', encoding => 'UTF-32LE' ],
	},
	{
		name  => 'TSV probe detects UTF-32BE without BOM',
		hints => {
			content_head => encode('UTF-32BE', $tsv),
		},
		expected => [ 'TSV', encoding => 'UTF-32BE' ],
	},
	{
		name  => 'unknown content type falls through to probe',
		hints => {
			content_type => 'application/octet-stream',
			content_head => $csv,
		},
		expected => [ 'CSV' ],
	},
	{
		name  => 'unknown charset is ignored',
		hints => {
			content_type => 'text/csv',
			charset     => 'surely-not-an-encoding',
			content_head => $csv,
		},
		expected => [ 'CSV' ],
	},
	{
		name  => 'nonsense is not detected',
		hints => {
			content_head => 'this is not tabular data',
		},
		expected => [],
	},
	{
		name  => 'ambiguous equal comma and tab evidence is not detected',
		hints => {
			content_head => "one,two\tthree\n",
		},
		expected => [],
	},
	{
		name  => 'empty content without filename is not detected',
		hints => {
			content_head => '',
		},
		expected => [],
	},
);

for my $t (@tests) {
	subtest $t->{name} => sub {
		my $tr= new_ok(
			'Data::TableReader',
			[
				input  => $t->{input} || unused_input(),
				fields => [],
				log    => sub { note "$_[0] $_[1]" },
			],
			'reader',
		);

		my (@got, $error);
		{
			local $@;
			eval {
				@got= $tr->detect_input_format($t->{hints});
				1;
			} or $error= $@;
		}

		if (exists $t->{error}) {
			like(
				$error || '',
				$t->{error},
				'throws expected exception',
			);
		}
		else {
			is(
				$error,
				undef,
				'does not throw',
			);

			is_deeply(
				\@got,
				$t->{expected},
				'detected decoder and arguments',
			);
		}
	};
}

done_testing;
