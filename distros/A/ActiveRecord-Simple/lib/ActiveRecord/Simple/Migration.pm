package ActiveRecord::Simple::Migration;

use strict;
use warnings;
use 5.010;


sub new {
	my ($name, $num) = @_;

	$num ||= time();

	open my $fh_up, ">", "$num-UP.sql" or return;
	say {$fh_up} "--- Migration #$num, `$name`, UP";
	close $fh_up;

	open my $fh_dn, ">", "$num-DN.sql" or return;
	say {$fh_dn} "--- Migration #$num, `$name`. DOWN";
	close $fh_dn;

	return 1;
}

sub down {
	my ($dbh, $num) = @_;

	$dbh && $num or return;
	my $sql = _slurp_file("$num-DN.sql") or return;

	return $dbh->do($sql);
}

sub up {
	my ($dbh, $num) = @_;

	$dbh && $num or return;
	my $sql = _slurp_file("$num-UP.sql") or return;

	return $dbh->do($sql);
}

sub _slurp_file {
	my ($file_path) = @_;

	return if !-e $file_path;
	open my $fh, "$file_path";
	my $text = do { local $/; <$fh> };
	close $fh;

	return $text;
}


1;