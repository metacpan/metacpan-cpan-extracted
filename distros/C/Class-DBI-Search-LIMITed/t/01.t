use strict;

use Test::More;

BEGIN {
	eval "use DBD::Mock";
	plan $@ ? (skip_all => 'needs DBD::Mock for testing') : (tests => 1);
}

package My::Mock;

use base 'Class::DBI';

__PACKAGE__->connection('DBI:Mock:', '', '');
__PACKAGE__->table('faked');
__PACKAGE__->columns(All => qw/title year rating/);
__PACKAGE__->add_searcher(search => "Class::DBI::Search::LIMITed");

package main;

my @ltd = eval {  My::Mock->search(title => "Common Title", {
  order_by => 'filmid',
  limit    => "20,10"
})};

my $history = My::Mock->db_Main->{mock_all_history};
my $sth = $history->[0];
my $match = qr/SELECT.*FROM.*WHERE.*ORDER.*LIMIT 20,10$/ism;
like $sth->statement, $match, "We have our LIMIT";

