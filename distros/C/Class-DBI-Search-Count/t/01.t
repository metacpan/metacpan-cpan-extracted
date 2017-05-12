use strict;

use Test::More;

BEGIN {
	eval "use DBD::Mock";
	plan $@ ? (skip_all => 'needs DBD::Mock for testing') : (tests => 2);
}

package My::Mock;

use base 'Class::DBI';

__PACKAGE__->connection('DBI:Mock:', '', '');
__PACKAGE__->table('faked');
__PACKAGE__->columns(All => qw/title year rating/);
__PACKAGE__->add_searcher(search_count => 'Class::DBI::Search::Count');


package main;

my $count = My::Mock->search_count(title => "Title", year => 1990);

my $history = My::Mock->db_Main->{mock_all_history};
my $sth = $history->[0];
my $match = quotemeta 'SELECT COUNT(*) FROM faked WHERE title = ? AND year = ?';
like $sth->statement, qr/$match/, "SQL correct";

my $bind = $sth->bound_params;
is_deeply $sth->bound_params, ["Title", 1990], "Bind vals";

