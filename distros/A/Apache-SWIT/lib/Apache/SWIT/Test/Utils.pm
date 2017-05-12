use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Test::Utils;
use base 'Exporter';
use File::Slurp;

our @EXPORT = qw(ASTU_Wait ASTU_Read_Error_Log ASTU_Read_Access_Log
		ASTU_Apache_Pids ASTU_Mem_Stats ASTU_Mem_Report ASTU_Mem_Show
		ASTU_Reset_Table ASTU_Module_Dir ASTU_Clear_Error_Log);

sub ASTU_Wait {
	my $dir = shift || "";
	print STDERR "# ASTU_WAIT: $dir\n" . Carp::longmess();
	if (!defined($ENV{ASTU_WAIT})) {
		print STDERR "# No \$ENV{ASTU_WAIT} is given. Exiting ...\n";
		goto OUT;
	} elsif (!$ENV{ASTU_WAIT}) {
		print STDERR "# \$ENV{ASTU_WAIT} == 0. Continuing ...\n";
		return;
	}
	print STDERR "# Press ENTER to continue ...\n";
	readline(\*STDIN);
OUT:
	exit 1;
}

sub ASTU_Module_Dir { return "$INC[0]/../.."; }

sub ASTU_Read_Error_Log {
	return read_file(ASTU_Module_Dir() . "/t/logs/error_log");
}

sub ASTU_Read_Access_Log {
	return read_file(ASTU_Module_Dir() . "/t/logs/access_log");
}

sub ASTU_Reset_Table {
	my $t = shift;
	my $dbh = Apache::SWIT::DB::Connection->instance->db_handle;
	$dbh->do("delete from $t");
	$dbh->do("alter sequence $t\_id_seq restart with 1");
}

sub ASTU_Clear_Error_Log {
	my $ef = ASTU_Module_Dir() . "/t/logs/error_log";
	write_file($ef, "Cleared" . Carp::longmess());
}

sub ASTU_Apache_Pids {
	my $pid_file = shift || ($INC[0] . '/../../t/logs/httpd.pid');
	my $pid = read_file($pid_file);
	my @lines = `pstree -p $pid`;
	my @res = (shift(@lines) =~ /\((\d+).*\((\d+)/);
	push @res, (/\((\d+)/) for @lines;
	return @res;
}

sub ASTU_Mem_Stats {
	eval "use Linux::Smaps";

	my @res;
	for my $pid (@_) {
		my $map = Linux::Smaps->new($pid);
		push @res, [ $pid, $map->shared_clean + $map->shared_dirty
				, $map->private_clean + $map->private_dirty ];
	}
	return @res;
}

sub ASTU_Mem_Report {
	my @mem = ASTU_Mem_Stats(ASTU_Apache_Pids(@_));
	my $m = shift @mem;
	my $res = "$m->[0]: shared $m->[1], private $m->[2]kb\n";
	my $tot = $m->[2];
	for (@mem) {
		$res .= "\t$_->[0]: shared $_->[1]kb, private $_->[2]kb\n";
		$tot += $_->[2];
	}
	return $res . "Private: $tot\n";
}

sub ASTU_Mem_Show {
	return unless $ENV{ASTU_MEM};
	print STDERR shift() . ":\n" . ASTU_Mem_Report(@_);
}

1;
