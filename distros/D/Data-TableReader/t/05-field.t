#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok( 'Data::TableReader::Field' ) or BAIL_OUT;

subtest header_regex => sub {
	my @tests= ({
		name => 'name', header => undef,
		match   => [ 'name', ' nAMe', '^%name&*^%^' ],
		nomatch => [ 'na me', 'names', 'surname', 'first name' ],
	},{
		name => 'first_name', header => undef,
		match   => [ 'first name', 'FirstName', ' First_Name', 'First.Name' ],
		nomatch => [ 'first_nam',  'first.*', 'name', 'first name 0' ],
	},{
		name => 'first_name', header => 'first_name',
		match   => [ 'first_name', '  first_name', 'first_name#"$:^' ],
		nomatch => [ 'first name', 'first.name', 'first _name', 'FirstName' ],
	},{
		name => 'zip5',
		match => [ 'zip5', 'zip 5', 'zip_5', 'ZIP-5' ],
		nomatch => [ 'zip' ],
	},{
		name => 'ZipCode',
		match => [ 'ZipCode', 'zip code', 'zip.code', 'ZIP CODE', '--ZIP CODE--' ],
		nomatch => [ 'ZipCode(5)' ],
	},{
		name => 'ZipCode', header => "Zip\nCode",
		match => ["Zip\nCode", "zip \n code"],
		nomatch => [ 'zipcode' ],
	});
	plan tests => scalar @tests;
	for my $t (@tests) {
		subtest "name=$t->{name} header=".($t->{header}||'') => sub {
			plan tests => 1 + @{$t->{match}} + @{$t->{nomatch}};
			my $field= new_ok( 'Data::TableReader::Field',
				[ name => $t->{name}, header => $t->{header} ], 'field' );
			like( $_, $field->header_regex, "match $_" ) for @{ $t->{match} };
			unlike( $_, $field->header_regex, "nomatch $_" ) for @{ $t->{nomatch} };
		};
	}
};

done_testing;
