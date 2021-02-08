#!perl

use strict;
use warnings;

use boolean;

use DBIx::Admin::BackupRestore;

use Error qw/:try/;

use File::Spec;
use File::Temp;

use Test::More;

# ---------------------------------------------

sub create
{
	my($opts, $table_name)	= @_;
	my($dbh)				= generate_dbh($opts);
	my($sql)				= "create table $table_name (id int not null primary key, value varchar(255) )";
	my($sth)				= $dbh -> prepare($sql);

	$sth -> execute || die "Unable to execute($sql)";

} # End of create.

# ---------------------------------------------

sub generate_dbh
{
	my($opts) = @_;

	return DBI -> connect
	(
		@$opts,
		{
			AutoCommit			=> 1,
			HandleError			=> sub {Error::Simple -> record($_[0]); 0},
			PrintError			=> 0,
			RaiseError			=> 1,
			ShowErrorStatement	=> 1,
		}
	);

} # End of generate_dbh.

# ---------------------------------------------

sub populate
{
	my($opts, $table_name, $empty) = @_;

	create($opts, $table_name);

	if (! $empty)
	{
		my($dbh)	= generate_dbh($opts);
		my($sql)	= "insert into $table_name (id, value) values (?, ?)";
		my($sth)	= $dbh -> prepare($sql);

		$sth -> execute(1, "Record $table_name.1") || die "Unable to execute($sql, 1)";
		$sth -> execute(2, "Record $table_name.2") || die "Unable to execute($sql, 2)";
	}

} # End of populate.

# ---------------------------------------------

eval "use DBI";
plan skip_all => "DBI required for testing DB plugin" if $@;

# The EXLOCK option is for BSD-based systems.

my($out_dir)	= File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
my($db_file)	= File::Spec -> catfile($out_dir, 'create.sqlite');
my($xml_file)	= File::Spec -> catfile($out_dir, 'test.xml');

plan skip_all => "Temp dir is un-writable" if (! -w $out_dir);

unlink $db_file;
unlink $xml_file;

if (! $ENV{DBI_DSN})
{
	eval "use DBD::SQLite";
	plan skip_all => "DBD::SQLite required for testing DB plugin" if $@;

	$ENV{DBI_DSN}	= "dbi:SQLite:dbname=$db_file";
	$ENV{DBI_USER}	= '';
	$ENV{DBI_PASS}	= '';
}

plan tests => 7;

my(@opts) = ($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS});

try
{
	populate(\@opts, 't0', false);
	populate(\@opts, 't1', true);
	populate(\@opts, 't2', false);
	# Backup phase.

	open(OUT, "> $xml_file") || die("Can't open(> $xml_file): $!");
	print OUT DBIx::Admin::BackupRestore -> new(dbh => generate_dbh(\@opts) ) -> backup($db_file);
	close OUT;

	ok(-r $db_file, "$db_file is readable");
	ok(-r $xml_file, "$xml_file is readable");

	# Restore phase.

	$db_file = File::Spec -> catfile($out_dir, 'restore.sqlite');

	unlink $db_file;

	$opts[0] = "dbi:SQLite:dbname=$db_file";

	create(\@opts, 't0');
	create(\@opts, 't1');
	create(\@opts, 't2');

	my($table_names) = DBIx::Admin::BackupRestore -> new(dbh => generate_dbh(\@opts) ) -> restore($xml_file);

	ok(-r $db_file, "$db_file is readable");
	ok($#$table_names == 2, 'Retrieved 3 table names');

	for my $i (0 .. $#$table_names)
	{
		my($table_name) = "t$i";

		ok($$table_names[$i] eq $table_name, "Restored table $table_name");
	}
}
catch Error::Simple with
{
	my($error) = $_[0] -> text();
	chomp $error;
	print $error;
};
