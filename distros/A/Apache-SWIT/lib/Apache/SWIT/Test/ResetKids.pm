use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Test::ResetKids;
use File::Slurp;
use Apache::SWIT::Test::Utils;

sub access_handler($$) {
	my ($class, $r) = @_;
	my $kfile = ASTU_Module_Dir() . "/t/logs/kids_are_clean.$$";
	goto OUT if -f $kfile;
	Apache::SWIT::DB::Connection->instance->db_handle->{CachedKids} = {};
	write_file($kfile, "");
OUT:
	return Apache2::Const::OK();
}

1;
