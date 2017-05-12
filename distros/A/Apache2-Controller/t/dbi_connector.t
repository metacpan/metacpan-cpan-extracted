
# skip if SQLite is not installed
#
# create an SQLite database from dump file
#
# controller should set some things, select them etc.
#
# and test transactions and rollback

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw( GET_BODY GET_STR );
use FindBin;

use lib "$FindBin::Bin/lib";
use Apache2::Controller::Test::Funk;
use YAML::Syck;
use URI::Escape;

Apache::TestRequest::user_agent(cookie_jar => {});

my @tests = (
    working                 => 'TestApp::DBI::Controller is working.',
    handle_available        => 'DBI::db is dbh class',
    select_1                => 'Query (select 1) works.',
    exception_works         => 'Bogus query threw correct exception.',
    create_table            => 'Created test table.',
    insert_ok               => q{Inserted biz = 'baz'.},
    txn_goodquery           => q{Inserted boz = 'noz'.},
    txn_dont_commit         => q{Updated biz without commit.},
    txn_dont_commit_didnt_insert => q{Verify no commit: biz = 'baz'.},
);

plan tests => scalar(@tests / 2), need_module qw( LWP DBD::SQLite );

my $i = -2;
my $j = -1;

while (exists $tests[$i += 2] && exists $tests[$j += 2]) {
    ( my $content = GET_BODY("/dbi_connector/$tests[$i]") ) =~ s{ \s+ \z }{}mxs;
  # od($content);
    ok t_cmp($content => $tests[$j], $tests[$j]);
} # how do you like them apples, oh evil thread-unsafe natatime() ?

