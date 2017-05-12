#!/usr/bin/env perl

# Developed by Sheeju Alex
# Licensed under terms of GNU General Public License.
# All rights reserved.
#
# Changelog:
# 2014-08-18 - created

use FindBin;
use Getopt::Std;
use Data::Dumper;
use Test::More;

use lib qw( lib t/lib );

#database - pg_log_test
my $database = $ENV{PG_NAME} || '';
#user - sheeju
my $user     = $ENV{PG_USER} || '';
#password - sheeju
my $password = $ENV{PG_PASS} || '';

if( !$database || !$user ) {
	plan skip_all => 'You need to set the PG_NAME, PG_USER and PG_PASS environment variables';
} else {
	our ($opt_F, $opt_d);
	getopts('Fd');
	use DBIx::Class::Schema::Loader 'make_schema_at';
	make_schema_at('PgLogTest::Schema',
		{
			debug => !!($opt_d), 
			really_erase_my_files => !!($opt_F),
			dump_directory=>"$FindBin::Bin/lib",
			overwrite_modifications=>1,
			preserve_case=>1,
		},
		['dbi:Pg:dbname='.$database, $user, $password, {'quote_char' => '"', 'quote_field_names' => '0', 'name_sep' => '.' }],
	);
	done_testing();
}
1;
