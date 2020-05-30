# Save this file in UTF-8 encoding!
use strict;
use warnings;
use utf8;
use Data::Dumper qw(Dumper); local $Data::Dumper::Terse = 1;
#use open ':std', ':encoding(utf8)';
use open OUT => ':locale';	# before Test::More because it duplicates STDOUT and STDERR
use Test::More qw(no_plan);
use Cwd ();
use File::Basename;
use lib (
	File::Basename::dirname(Cwd::abs_path(__FILE__)) . '/../lib',	# in build dir
	File::Basename::dirname(Cwd::abs_path(__FILE__)) . '/../..'		# in project dir with t subdir in same dir as .pm file
);

my $verbose = !$ENV{'HARNESS_ACTIVE'} && 0;

my $class = 'CSV::Reader';
require_ok($class) || BAIL_OUT("$class has errors");
my %default_options = (
	#'delimiter' => ',',
	#'enclosure' => '"',
	'field_aliases'	=> {
		'Postal Code' => 'postcode',
	},
);

#my $csvfile = ($0 =~ s|[^/]+$||r) . 'broken_line.csv';
my $csvfile = $0; $csvfile =~ s|[^/]+$||; $csvfile .= 'broken_line.csv';

if ('test broken line') {
	my $o = $class->new($csvfile, %default_options);
	my @rows;
	while (my $row = $o->nextRow()) {
		push(@rows, $row);
	}
	my $expected = 3;
	is(scalar(@rows), 3, 'File has expected data row count');
	if (@rows) {
		my $field = 'Address Code 2';
		my $addr = $rows[0]->{$field};
		ok(utf8::is_utf8($addr), "'$field' value is flagged as UTF-8");
		is($addr, "Déjà vu\n straat", "UTF-8 encoding is OK after parsing and line feed is present");
	}
}


unless($ENV{'HARNESS_ACTIVE'}) {
	my $o = $class->new(
		$csvfile,
		%default_options,
		#'debug' => 1
	);
	require Encode;
	while (my $row = $o->nextRow()) {
		diag(Dumper($row));
		#diag($row->{'Address Code 2'});
		#warn '# ' . $row->{'Address Code 2'} . "\n";
		#print '# ' . $row->{'Address Code 2'} . "\n";
		#diag('is_utf8: ' . int(Encode::is_utf8($row->{'Address Code 2'})));
		#last;
	}
}
