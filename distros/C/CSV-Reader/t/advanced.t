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
	'delimiter' => ';',
	'enclosure' => '',
	'field_normalizer' => sub {
		my $nameref = shift;
		$$nameref = lc($$nameref);	# lowercase
		$$nameref =~ s/\s/_/g;	# spaces to underscore
	},
	'field_aliases'	=> {
		'postal_code' => 'postcode', # applied after normalization
	},
	'mutators' => {
		'postcode' => sub {	# if postalcode is Dutch, then make sure it has no spaces and is in uppercase.
			my $val_ref = shift;
			my $row_ref = shift;
			if (defined($$val_ref)) {
				$$val_ref =~ s/^(\d{4})([A-Z]{2})$/$1 $2/;	# add space between digits and letters
			}
		},
		'street_entrance' => sub {	# set a default for an empty (undef) value
			my $val_ref = shift;
			$$val_ref //= 'ground';
		},
	},
);

#my $csvfile = ($0 =~ s|[^/]+$||r) . 'utf8_with_bom.csv';
my $csvfile = $0; $csvfile =~ s|[^/]+$||; $csvfile .= 'utf8_with_bom.csv';

if ('test field_normalizer, field_aliases, and mutators') {
	my $o = $class->new($csvfile, %default_options);
	my @expect = (
		'id',
		'postcode',
		'street_no',
		'street_entrance',
		'floor',
		'address_code_1',
		'address_code_2',
		'subscription_list',
	);
	if (1) {
		my @actual = $o->fieldNames();
		is_deeply(\@actual, \@expect, 'Result of fieldNames() is as expected');
	}
	while (my $row = $o->nextRow()) {
		my @actual = keys(%$row);
		is_deeply(\@actual, \@expect, 'line ' . $o->linenum() . ' keys of nextRow() are as expected');
		ok($row->{'postcode'} =~ /^\d{4} [A-Z]{2}$/	, 'line ' . $o->linenum() . ' postcode mutator worked');
		ok($row->{'street_entrance'} eq 'ground'	, 'line ' . $o->linenum() . ' street_entrance mutator worked');
	}
}


unless($ENV{'HARNESS_ACTIVE'}) {
	my $o = $class->new(
		$csvfile,
		%default_options,
		#'debug' => 1
	);
	#require Encode;
	while (my $row = $o->nextRow()) {
		diag(Dumper($row));
		if (defined($row->{'address_code_2'})) {
			diag('address_code_2: ' . $row->{'address_code_2'});
			diag('is_utf8: ' . int(Encode::is_utf8($row->{'address_code_2'})));
		}
		#last;
	}
}
