use strict;
use warnings FATAL => 'all';

package T::TransFailure::Root;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV, 'fail_on_commit');
__PACKAGE__->ht_add_widget(::HTV, 'rollback');

package T::TransFailure;
use base 'Apache::SWIT::HTPage';
use Apache::SWIT::DB::Connection;

sub ht_swit_update {
	my ($class, $r, $root) = @_;
	my $dbh = Apache::SWIT::DB::Connection->instance->db_handle;
	if ($root->fail_on_commit) {
		$dbh->do("insert into t2 values (30)");
	} elsif ($root->rollback) {
		$dbh->do("insert into trans values(50)");
	} else {
		$dbh->do("insert into trans values(20)");
		$dbh->do("insert into trans values(1)");
	}
	return "r";
}

1;
