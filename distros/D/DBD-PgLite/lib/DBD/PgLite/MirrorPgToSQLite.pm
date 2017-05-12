package DBD::PgLite::MirrorPgToSQLite;
use strict;
use DBI;
use Storable;
use File::Copy;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(pg_to_sqlite);
our $VERSION = '0.05';

#### MAIN SUBROUTINE ####

sub pg_to_sqlite {
	my %opt = @_;
	my %defaults = defaults();
	for (keys %defaults) {
		next if exists $opt{$_};
		$opt{$_} = $defaults{$_};
	}
	$opt{tables} = _commasplit($opt{tables});
	$opt{views}  = _commasplit($opt{views});
	if ($opt{where}
		&& $opt{where} !~ /^\s*where\s/i 
		&& $opt{where} !~ /^\s*(?:natural\s+)?join\s/i) {
		$opt{where} = 'where '.$opt{where};
	}
	die "Incompatible options: 'append' and 'snapshot'" if $opt{append} && $opt{snapshot};
	die "Need either database handle (pg_dbh) or DSN (pg_dsn)" unless $opt{pg_dbh} || $opt{pg_dsn};
	my $disconnect = 0;
	unless ($opt{pg_dbh}) {
		$disconnect++;
		$opt{pg_dbh} = DBI->connect(@opt{ qw(pg_dsn pg_user pg_pass) },{RaiseError=>1})
		  or die "Could not connect to PostgreSQL: $DBI::errstr";
	}
	my $fn = $opt{sqlite_file};
	die "Need both list of source tables and a SQLite file" unless @{$opt{tables}} && $fn;
	$|++ if $opt{verbose};
	my $lockfile = "$fn.lock";
	lockfile('create',$lockfile);
	if (-f "$fn.tmp") {
		warn "WARNING: Removing temp file $fn.tmp - apparently left over from a previous run\n";
		unlink "$fn.tmp" or die "ERROR: Could not remove file.tmp: $!\n";
	}
	if ($opt{append}) {
		unless (copy $fn, "$fn.tmp") {
			warn "WARNING: Could not copy $fn to $fn.tmp for appending: $! - turning --append off\n";
			$opt{append} = 0;
		}
	}
	$opt{sl_dbh} = DBI->connect("dbi:SQLite:dbname=$fn.tmp",undef,undef,{RaiseError=>1});

	my @tables = tablelist($opt{pg_dbh}, $opt{schema}, @{ $opt{tables} }); # handle regexp
	print "MIRRORING ".scalar(@tables)." table(s):\n" if $opt{verbose};
	my @views = viewlist($opt{pg_dbh}, $opt{schema}, @{ $opt{views} }) 
	  if grep { /^\/.+\/$/ } @{ $opt{views} };

	eval {
		if ($opt{snapshot}) {
			$opt{pg_dbh}->do("set session characteristics as transaction isolation level serializable");
			$opt{pg_dbh}->begin_work;
			mirror_table($_,%opt) for @tables;
			mirror_functions(%opt) if $opt{functions};
			$opt{pg_dbh}->commit;
		} else {
			mirror_table($_,%opt) for @tables;
			mirror_functions(%opt) if $opt{functions};
		}
		if (@views) {
			print "CREATING ".scalar(@views)." view(s):\n" if $opt{verbose};
			create_view($_,%opt) for @views;
		}
		print "done!\n" if $opt{verbose};
	};

	if ($@) {
		lockfile('clear',$lockfile);
		die $@;
	}

	$opt{pg_dbh}->disconnect if $disconnect;
	$opt{sl_dbh}->disconnect;

	if (-f $fn) {
		copy $fn, "$fn.bak" or warn "WARNING: Could not make backup copy of $fn: $!\n";
	}
	move "$fn.tmp", $fn or die "ERROR: Could not move temporary SQLite file $fn.tmp to $fn";
	lockfile('clear',$lockfile);
}



########## OTHER SUBROUTINES ###########

sub _commasplit {
	my $list = shift;
	return [] unless $list;
	$list = [$list] unless ref $list;
	my @new = split(/\s*,\s*/,join(',',@$list));
	return \@new;
}

sub defaults {
	my %defaults = (
					verbose     => 0,
					pg_dsn      => ($ENV{PGDATABASE} ? "dbi:Pg:dbname=$ENV{PGDATABASE}" : undef),
					pg_user     => ($ENV{PGUSER} || $ENV{USER}),
					pg_pass     => $ENV{PGPASSWORD},
					schema      => 'public',
					tables      => [],
					sqlite_file => '',
					where       => '',
					cachedir    => '/tmp/sqlite_mirror_cache',
					append      => 0,
					snapshot    => 0,
					indexes     => 0,
					views       => [],
					functions   => 0,
					page_limit  => 5000, # each page is 8K
					pg_dbh      => undef,
				   );
	$defaults{pg_dsn} ||= "dbi:Pg:dbname=$defaults{pg_user}" if $defaults{pg_user};
	return %defaults;
}

sub mirror_table {
	my ($tn,%opt) = @_;
	my $sn = $opt{schema};
	print "  - $sn.$tn\n" if $opt{verbose};
	my ($create,$colcnt) = get_schema($sn,$tn,%opt);
	my $drop = '';
	if ($opt{append}) {
		$drop = $opt{sl_dbh}->selectrow_array("select name from sqlite_master where type = 'table' and name = ?",{},$tn);
		$opt{sl_dbh}->do("drop table $tn") if $drop;
	}
	$opt{sl_dbh}->do($create);
	my $pages = $opt{pg_dbh}->selectrow_array("select relpages from pg_class where relnamespace = (select oid from pg_namespace where nspname = ?) and relname = ?",{},$sn,$tn);
	my $ins = $opt{sl_dbh}->prepare("insert into $tn values (". join(',', ("?") x $colcnt) . ")");
	if ($pages > $opt{page_limit}) {
		warn "      pagelimit ($opt{page_limit}) kicks in for $sn.$tn ($pages)\n" if $opt{verbose};
		my @pkey = $opt{pg_dbh}->primary_key(undef,$sn,$tn);
		warn "         (pkey is )".join(":",@pkey)."\n" if $opt{verbose};
		if (@pkey) {
			my $pkey_vals = $opt{pg_dbh}->selectall_arrayref("select ".join(', ', @pkey)." from $sn.$tn");
			my $sql = "select * from $sn.$tn where ".join(" and ", map {"$_ = ?"} @pkey);
			my $selh = $opt{pg_dbh}->prepare($sql);
			$opt{sl_dbh}->begin_work;
			foreach (@$pkey_vals) {
				$selh->execute(@$_);
				my $row = $selh->fetchrow_arrayref;
				$ins->execute(@$row);
			}
			$opt{sl_dbh}->commit;
			$selh->finish;
		}
		else {
			warn "*** CANNOT READ $sn.$tn ROW-BY-ROW - NO PRIMARY KEY\n*** SKIPPING TABLE!\n";
			$ins->finish;
			return;
		}
	}
	else {
		my $res = $opt{pg_dbh}->selectall_arrayref("select * from $sn.$tn $opt{where}");
		if (@$res && scalar(@{$res->[0]}) != $colcnt) {
			$ins->finish;
			die "ERROR: Bad schema for table $tn: number of columns does not match\n";
		}
		$opt{sl_dbh}->begin_work;
		$ins->execute(@$_) for @$res;
		$opt{sl_dbh}->commit;
	}
	$ins->finish;
	create_indexes($tn,%opt) if $opt{indexes};
	$opt{sl_dbh}->do("vacuum") if $drop;
}

sub mirror_functions {
	my %opt = @_;
	unless ($opt{sl_dbh}->selectrow_array("select name from sqlite_master where name = 'pglite_functions' and type = 'table'")) {
		$opt{sl_dbh}->do("CREATE TABLE pglite_functions (name text, argnum int, type text, sql text, primary key (name,argnum))");
	}
	my $langnum = $opt{pg_dbh}->selectrow_array("select oid from pg_language where lanname = 'sql'");
	my $snum = $opt{pg_dbh}->selectrow_array("select oid from pg_namespace where nspname = ?",{},$opt{schema});
	my $fun = $opt{pg_dbh}->selectall_arrayref("select proname, pronargs, prosrc from pg_proc where prolang = ? and pronamespace = ?",{},$langnum,$snum);
	print "FUNCTIONS:\n" if $opt{verbose};
	return unless ref $fun eq 'ARRAY' && @$fun;
	for (@$fun) {
		my ($name,$argnum,$sql) = @$_;
		unless ($opt{sl_dbh}->selectrow_array("select name from pglite_functions where name = ? and argnum = ?",{},$name,$argnum)) {
			print "    - $name ($argnum)\n" if $opt{verbose};
			$opt{sl_dbh}->do("insert into pglite_functions (name,argnum,type,sql) values (?,?,'sql',?)",{},$name,$argnum,$sql);
		}
	}
}

sub create_indexes {
	my ($tn,%opt) = @_;
	my $sn = $opt{schema};
	my $ixn = $opt{pg_dbh}->selectcol_arrayref("select indexdef from pg_indexes where schemaname = ? and tablename = ? ", {}, $sn,$tn);
	for (@$ixn) {
		next if /\(oid\)/;
		next if /_pkey\b/; # No need to recreate primary keys
		s/USING btree //;
		s/ ON \w+\.\"?([^\"]+)\"?/ ON $1/;
		print "      + $_\n" if $opt{verbose};
		eval {  $opt{sl_dbh}->do($_); };
		# Pg supports multiple null values in  unique columns - SQLite doesn't
		if ($@ =~ /unique/i && s/ UNIQUE / /) {
			print "      + retry: $_\n" if $opt{verbose};
			eval { $opt{sl_dbh}->do($_); };
		}
	}
}

sub create_view {
	my ($vn,%opt) = @_;
	my $sn = $opt{schema};
	my $def = $opt{pg_dbh}->selectrow_array("select definition from pg_views where schemaname = ? and viewname = ?",{},$sn,$vn);
	print "  - $sn.$vn\n" if $opt{verbose};
	$def =~ s/::\w+//g; # casting is not supported in SQLite
	if ($opt{sl_dbh}->selectrow_array("select name from sqlite_master where name = ? and type = 'view'",{},$vn)) {
		eval { $opt{sl_dbh}->do("drop view $vn") };
	}
	eval { $opt{sl_dbh}->do("create view $vn as $def"); };
	warn "    *** COULD NOT CREATE VIEW $sn.$vn *** \n" if $@;
}

sub tablelist {
	my ($pg,$sn,@pats) = @_;
	my %tables; # prevent duplicate table names
	for my $pat (@pats) {
		if ($pat =~ s/^\/(.+)\/$/$1/) {
			my $res = $pg->selectcol_arrayref("select tablename from pg_tables where lower(schemaname) = lower('$sn') and tablename ~* '$pat'");
			$tables{$_}++ for @$res;
		} else {
			$tables{$pat}++;
		}
	}
	return keys %tables;
}

sub viewlist {
	my ($pg,$sn,@pats) = @_;
	my %views; # prevent duplicate table names
	for my $pat (@pats) {
		if ($pat =~ s/^\/(.+)\/$/$1/) {
			my $res = $pg->selectcol_arrayref("select viewname from pg_views where lower(schemaname) = lower('$sn') and viewname ~* '$pat'");
			$views{$_}++ for @$res;
		} else {
			$views{$pat}++;
		}
	}
	return keys %views;
}


sub get_schema {
	my ($sn,$tn,%opt) = @_;
	# Constructing a schema definition can be rather slow,
	# so we cache the result for up to a week
	my @cached = cached_schema($sn,$tn,undef,undef,%opt);
	return @cached if @cached;
	my @cdef = col_def($sn,$tn,%opt);
	my $colcnt = scalar @cdef;
	my @pknames = $opt{pg_dbh}->primary_key(undef,$sn,$tn);
	push @cdef, "primary key (" . join(',',@pknames) . ")" if @pknames && $pknames[0] ne '';
	my $create = "create table $tn (\n  ".join(",\n  ",@cdef)."\n)\n";
	cached_schema($sn,$tn,$create,$colcnt,%opt);
	return ($create, $colcnt);
}

sub cached_schema {
	my ($sn,$tn,$creat,$cnt,%opt) = @_;
	my $database = $opt{pg_dbh}->{mbl_dbh} 
	  ? $opt{pg_dbh}->{mbl_dbh}->[0]->{Name}
	  : $opt{pg_dbh}->{Name};
	unless (-d $opt{cachedir}) {
		mkdir $opt{cachedir};
		chmod 0777, $opt{cachedir};
	}
	my $uid = (getpwuid($>))[0] || $>;
	mkdir "$opt{cachedir}/$uid" unless -d "$opt{cachedir}/$uid";
	my $fn = "$opt{cachedir}/$uid/$database.$sn.$tn";
	if ($cnt) {
		Storable::store [$creat,$cnt], $fn;
	} elsif (-f $fn && time-(stat $fn)[9]<7*24*60*60) {
		my $ret = Storable::retrieve $fn || [];
		return @$ret;
	} else {
		return ();
	}
}

sub col_def {
	my ($sn,$tn,%opt) = @_;
	my $sth = $opt{pg_dbh}->column_info(undef,$sn,$tn,undef);
	$sth->execute;
	my $res = $sth->fetchall_arrayref;
	my @ret;
	foreach my $ci (@$res) {
		my ($colnam,$typnam,$nullable) = @{$ci}[qw(3 5 10)]; #)];
		my $notnull = $nullable ? "" : " not null";
		push @ret, "$colnam $typnam$notnull";
	}
	$sth->finish;
	return @ret;
}

sub lockfile {
	my ($action,$lockfile) = @_;
	if ($action eq 'create') {
		die "ERROR: Lockfile $lockfile exists - cannot continue" if -f $lockfile;
		open LOCK, ">", "$lockfile" or die "ERROR: Could not open lockfile $lockfile: $!";
		print LOCK $$;
		close LOCK;
	} elsif ($action eq 'clear') {
		if (-f $lockfile) {
			unlink $lockfile or die "ERROR: Could not remove lockfile $lockfile: $!";
		} else {
			warn "WARNING: Lockfile $lockfile does not exist - cannot clear" unless -f $lockfile;
		}
	}
}

1;

__END__

=pod

=head1 NAME

DBD::PgLite::MirrorPgToSQLite - Mirror tables from PostgreSQL to SQLite

=head1 SUMMARY

 use DBD::PgLite::MirrorPgToSQLite qw(pg_to_sqlite);
 pg_to_sqlite(
     sqlite_file => '/var/pg_mirror/news.sqlite',
     pg_dbh      => $dbh,
     schema      => 'news',
     tables      => [ qw(news cat img /^x_news/)],
     views       => [ 'v_newslist' ],
     indexes     => 1,
     verbose     => 1,
     snapshot    => 1,
 );

=head1 USAGE

The purpose of this module is to facilitate mirroring of tables from a
PostgreSQL dataabse to a SQLite file. The module has only be tested
with PostgreSQL 7.3 and SQLite 3.0-3.2. SQLite 2.x will probably not
work; as for PostgreSQL, any version after 7.2 is supposed to work. If
it doesn't, please let me know.

As seen above, options to the pg_to_sqlite() function (which is
exported on request) are passed in as a hash.  These options are
described below. The default values can be changed by overriding the
DBD::PgLite::MirrorPgToSQLite::defaults() subroutine.

=head2 Required options

Obviously, the mirroring function needs either a PosgtgreSQL database
connection or enough information to be able to connect to the database
by itself. It also needs the name of a target SQLite file, and a list
of tables to copy between the two databases.

=over 4

=item pg_dbh, pg_user, pg_pass, pg_dsn

If a database handle is specified in I<pg_dbh>, it takes
precedence. Otherwise we try to connect using I<pg_dsn>, I<pg_user>,
and I<pg_pass> (which are assigned defaults based on the environment
variables PGDATABASE, PGUSER and PGPASSWORD, if any of these is
present).

=item tables

The value of the required I<tables> option should be an arrayref of
strings or a string containing a comma-separated list of tablenames
and tablename patterns. A tablename pattern is a string or distinct
string portion delimited by forward slashes. To clarify: Suppose that
a database contains the tables news, img, img_group, cat, users,
comments, news_read_log, x_news_cat, x_news_img, and x_img_group; and
that we want to mirror news, img, cat, x_news_img and x_news_cat,
leaving the other tables alone. To achieve this, you would set the
I<tables> option to any of the following (there are of course also
other possibilities):

 (1) [qw(news img cat x_news_img x_news_cat)]
 (2) 'news, img, cat, x_news_img, x_news_cat'
 (3) [qw(news /img$/ /cat$/)]
 (4) 'news,/img$/,/cat/'

The purpose of this seemingly unneccesary flexibility in how the table
list is specified is to make the functionality of the module more
easily accessible from the command line.

Please note that the patterns between the slash delimiters are not
Perl regular expressions but rather POSIX regular expressions, used to
query the PostgreSQL system tables directly.

=item sqlite_file

This should specify the full path to a SQLite file. While the
mirroring takes place, the incoming data is not written directly to
this file, but to a file with the same name except for a '.tmp'
extension. When the operation has finished, the previous file with the
name specified (if any) is renamed with a '.bak' extension, and the
.tmp file is renamed to the requested filename. Unless you use the
I<append> option, the information previously in the file will be
totally replaced.

=back

=head2 Other options

=over 4

=item schema

This signifies the schema from which the tables on the PostgreSQL side
are to be fetched. Default: 'public'. Only one schema can be specified
at a time.

=item where

A WHERE-condition appended to the SELECT-statement used to get data
from the PostgreSQL tables.

=item views

A list of views, specified in the same manner as the list of tables
for the I<tables> option. An attempt is made to define corresponding
views on the SQLite side (though this functionality is far from
reliable).

=item indexes

A boolean option indicating whether to create indexes for the same
columns in SQLite as in PostgreSQL. Default: false. (Normally only the
primary key is created).

=item functions

A boolean indicating whether to attempt to create functions on the
SQLite side corresponding to any SQL language (NOT PL/pgSQL or other
procedural language) functions in the PostgreSQL database. This is
for use with DBD::PgLite only, since these functions are put into the
pglite_functions table. Default: false.

=item page_limit

Normally the information from the PostgreSQL tables is read into
memory in one go and transferred directly to the SQLite file. This is,
however, obviously not desireable for very large tables. If the
PostgreSQL system tables report that the page count for the table is
above the limit specified by I<page_limit>, the table is instead
transferred row-by-row. Default value: 5000; since each page normally
is 8K, this represents about 40 MB on disk and perhaps 70-100 MB of
memory usage by the Perl process. For page_limit to work, the table
must have a primary key.

NB! Do not set this limit lower than necessary: it is orders of
magnitude slower than the default "slurp into memory" mode.

=item append

If this boolean option is true, then instead of creating a new SQLite
file, the current contents of the I<sqlite_file> are added to. If a
table which is being mirrored existed previously in the file, it is
dropped and recreated, but any tables not being copied from PostgreSQL
in the current run are left alone. (This is primarily useful for
mirroring some tables in toto, and others only in part, into the same
file). Default: false. Incompatible with the I<snapshot> option.

=item snapshot

If this is true, then the copying from PostgreSQL takes place in
serialized mode (transaction isolation level serializable), which
should ensure consistency of relations between tables linked by
foreign key constraints. Currently, foreign keys are not created on
the SQLite side, however. Default: false. Incompatible with the
I<append> option.

=item cachedir

The current method for getting information about table structure in
PostgreSQL is somewhat slow, especially for databases with very many
tables. To offset this, table definitions are cached in a temporary
directory so that subsequent mirrorings of the same table will go
faster. The downside is, of course, that if the table structure
changes, the cache needs to be cleared manually. The cache directory
can be specified using this option; the default is
/tmp/sqlite_mirror_cache (with separate subdirectories for each user).

=item verbose

If this is true, a few messages will be output to stderr during the
mirroring process.

=back

=head1 TODO

=over 4

=item *

Support for foreign keys is missing.

=item *

The method used to read tables bigger than I<page_limit> needs to be
improved.

=item *

It would be nice to have a quick way of telling whether the cached
table definition of a specific table is still valid.

=item *

Tests.

=back

=head1 AUTHOR

Baldur Kristinsson (bk@mbl.is), 2004-2006.

 Copyright (c) 2006 Baldur Kristinsson. All rights reserved.
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

=cut

