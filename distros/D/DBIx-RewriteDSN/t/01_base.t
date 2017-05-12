use strict;
use Test::More;

use File::Temp;
eval 'use DBD::SQLite';
plan skip_all => "DBD::SQLite is not installed." if $@;

my $fh;
my ($db1, $db1name);
my ($db2, $db2name);
BEGIN {
	$db1 = File::Temp->new;
	$db1->close;
	$db1name = $db1->filename;

	$db2 = File::Temp->new;
	$db2->close;
	$db2name = $db2->filename;

	$fh = File::Temp->new;
	$fh->print(<<"	EOS");
		dbi:rewrite:foo dbi:rewrote:foo
		(dbi:rewrite:through) \$1
		dbi:rewrite:backslash dbi:rewrite:\\BACKSLASH

		# dbi:rewrite:comment unko

		dbi:SQLite:dbname=.+ dbi:SQLite:dbname=$db2name

		# fallback
		.* dbi:fallback
	EOS
	$fh->close;
}

use DBIx::RewriteDSN -file => $fh->filename;

is DBIx::RewriteDSN::rewrite("dbi:rewrite:foo"), "dbi:rewrote:foo";
is DBIx::RewriteDSN::rewrite("dbi:rewrite:through"), "dbi:rewrite:through";
is DBIx::RewriteDSN::rewrite("dbi:rewrite:comment"), "dbi:fallback";
is DBIx::RewriteDSN::rewrite("dbi:rewrite:backslash"), "dbi:rewrite:\\BACKSLASH";

my $dbh;

$dbh = DBI->connect("dbi:SQLite:dbname=$db1name", "", "");
is $dbh->{Name}, "dbname=$db1name", "disabled by default";

DBIx::RewriteDSN->enable;

$dbh = DBI->connect("dbi:SQLite:dbname=$db1name", "", "");
is $dbh->{Name}, "dbname=$db2name", "enable";

DBIx::RewriteDSN->disable;

$dbh = DBI->connect("dbi:SQLite:dbname=$db1name", "", "");
is $dbh->{Name}, "dbname=$db1name", "rewrite is disabled";

DBIx::RewriteDSN->enable;

$dbh = DBI->connect("dbi:SQLite:dbname=$db1name", "", "");
is $dbh->{Name}, "dbname=$db2name", "re-enable";

is DBIx::RewriteDSN::rewrite("dbi:rewrite:foo"), "dbi:rewrote:foo";

DBIx::RewriteDSN->prepend_rules('dbi:rewrite:foo dbi:rewrote:prepended');

is DBIx::RewriteDSN::rewrite("dbi:rewrite:foo"), "dbi:rewrote:prepended";

done_testing;

