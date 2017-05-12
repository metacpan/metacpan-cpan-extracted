#!/usr/local/bin/perl -w

# POD docs at bottom of file

use strict;
use Data::Stag qw(:all);
use DBIx::DBStag;
use Getopt::Long;

my $record_type;
my $unique_key;
my $dir;
my $fmt = '';
my $out;
my $help;
my $top;
my $dbname;
my $qf;
my @query = ();
my $keys;
my $reset;
my $verbose;
my $create;
my $clear;
my $newonly;
my $insertonly;
my $transaction_size;
my $all;
my $ID_DOMAIN = 'VARCHAR(255)';
GetOptions("record_type|r=s"=>\$record_type,
	   "unique_key|unique|u|k=s"=>\$unique_key,
	   "parser|format|p=s"=>\$fmt,
	   "out|o=s"=>\$out,
	   "dbname|d=s"=>\$dbname,
	   "top|t=s"=>\$top,
	   "query|q=s@"=>\@query,
	   "qf=s"=>\$qf,
	   "all|a"=>\$all,
	   "create"=>\$create,
	   "clear"=>\$clear,
	   "newonly"=>\$newonly,
	   "insertonly"=>\$insertonly,
	   "transaction_size=s"=>\$transaction_size,
	   "help|h"=>\$help,
	   "keys"=>\$keys,
	   "reset"=>\$reset,
	   "idtype=s"=>\$ID_DOMAIN,
	   "verbose|v"=>\$verbose,
	  );
if ($help) {
    system("perldoc $0");
    exit 0;
}

my $dbh = DBIx::DBStag->connect($dbname);

if ($create) {
    $dbh->do("CREATE TABLE $record_type (id $ID_DOMAIN NOT NULL PRIMARY KEY, xml TEXT NOT NULL)");
    # No index required, because it is a primary key
}
if ($clear) {
    $dbh->do("DELETE FROM $record_type");
}

my $is_store_mode = scalar(@ARGV);

$dbh->dbh->{AutoCommit} = 0 if $transaction_size;

if ($is_store_mode) {
    my $sth = 
      $dbh->prepare("INSERT INTO $record_type (id,xml) VALUES (?, ?)");
    my $sthcheck = 
      $dbh->prepare("SELECT id FROM $record_type WHERE id = ?");
    my $n=0;

    my $store_handler;
    if ($insertonly) {
	my $sth = 
	  $dbh->prepare("INSERT INTO $record_type (id,xml) VALUES (?, ?)");
	$store_handler =
	  Data::Stag->makehandler($record_type=>sub {
				      my ($self, $stag) = @_;
				      my $id = $stag->get($unique_key);
				      $sth->execute($id, $stag->xml);
				      $n++;
				      $dbh->commit if $transaction_size && $n % $transaction_size == 0;
				      return;
				  });
    }
    elsif ($newonly) {
	# don't touch existing
	$store_handler =
	  Data::Stag->makehandler($record_type=>sub {
				      my ($self, $stag) = @_;
				      my $id = $stag->get($unique_key);
				      my $ids =
					$dbh->selectcol_arrayref($sthcheck,undef,$id);
				      if (!@$ids) {
					  $sth->execute($id, $stag->xml);
					  $n++;
				      }
				      $dbh->commit if $transaction_size && $n % $transaction_size == 0;
				      return;
				  });
    }
    else {
	# default clobber mode
	my $sthupdate = 
	  $dbh->prepare("UPDATE $record_type SET xml = ? WHERE id = ?");
	$store_handler =
	  Data::Stag->makehandler($record_type=>sub {
				      my ($self, $stag) = @_;
				      my $id = $stag->get($unique_key);
				      my $ids =
					$dbh->selectcol_arrayref($sthcheck,undef,$id);
				      if (@$ids) {
					  $sthupdate->execute($stag->xml, $id);
				      }
				      else {
					  $sth->execute($id, $stag->xml);
				      }
				      $n++;
				      $dbh->commit if $transaction_size && $n % $transaction_size == 0;
				      return;
				  });
    }
    foreach my $file (@ARGV) {
	my $p;
	if ($file eq '-') {
	    $fmt ||= 'xml';
	    $p = Data::Stag->parser(-format=>$fmt, -fh=>\*STDIN);
	    $p->handler($store_handler);
	    $p->parse(-fh=>\*STDIN);
	}
	else {
	    if (!-f $file) {
		print "the file \"$file\" does not exist\n";
	    }
	    $p = Data::Stag->parser($file, $fmt);
	    $p->handler($store_handler);
	    $p->parse($file);
	}
    }
    
    $dbh->commit if $transaction_size;
}
else {  # query mode

    if ($keys) {
	my $cols =
	  $dbh->selectcol_arrayref("SELECT id FROM $record_type");
	printf "$_\n", $_ foreach (@$cols);
	exit 0;
    }

    if ($qf) {
	open(F, $qf) || die "cannot open queryfile: $qf";
	@query = map {chomp;$_} <F>;
	close(F);
    }

    my $fh;
    if ($out) {
	$fh = FileHandle->new(">$out") || die("cannot write to $out");
    }
    else {
	$fh = \*STDOUT;
    }
    if ($top) {
	print $fh "<top>\n";
    }

    if ($all) {
	my $sth =
	  $dbh->prepare("SELECT xml FROM $record_type") || die;
	$sth->execute;
	while (my $row = $sth->fetchrow_arrayref) {
	    print $fh "@$row";
	}
    }

    if (@query) {
    
	my $n_found = 0;

	my $sth = 
	  $dbh->prepare("SELECT xml FROM $record_type WHERE id = ?");
	    
	foreach my $q (@query) {
	
	    my $xmls = $dbh->selectcol_arrayref($sth, undef, $q);
	    if (!@$xmls) {
		print STDERR "Could not find a record indexed by key: \"$q\"\n";
		next;
	    }
	    if (@$xmls > 1) {
		die "assertion error $q";
	    }
	    my $xml = shift @$xmls;
	    print $fh $xml;
	    $n_found++;
	}
	if (!$n_found && !$top) {
	    print STDERR "NONE FOUND!\n";
	}
    }
    if ($top) {
	print "</$top>\n";
    }
    $fh->close if $out;
}
$dbh->disconnect;
exit 0;

__END__

=head1 NAME 

stag-ir.pl - information retrieval using a simple relational index

=head1 SYNOPSIS

  stag-ir.pl -r person -k social_security_no -d Pg:mydb myrecords.xml
  stag-ir.pl -d Pg:mydb -q 999-9999-9999 -q 888-8888-8888

=head1 DESCRIPTION

Indexes stag nodes (XML Elements) in a simple relational db structure
- keyed by ID with an XML Blob as a value

Imagine you have a very large file of data, in a stag compatible
format such as XML. You want to index all the elements of type
B<person>; each person can be uniquely identified by
B<social_security_no>, which is a direct subnode of B<person>

The first thing to do is to build the index file, which will be stored
in the database mydb

  stag-ir.pl -r person -k social_security_no -d Pg:mydb myrecords.xml

You can then use the index "person-idx" to retrieve B<person> nodes by
their social security number

  stag-ir.pl -d Pg:mydb -q 999-9999-9999 > some-person.xml

You can export using different stag formats

  stag-ir.pl -d Pg:mydb -q 999-9999-9999 -w sxpr > some-person.xml

You can retrieve multiple nodes (although these need to be rooted to
make a valid file)

  stag-ir.pl -d Pg:mydb -q 999-9999-9999 -q 888-8888-8888 -top personset

Or you can use a list of IDs from a file (newline delimited)

  stag-ir.pl -d Pg:mydb -qf my_ss_nmbrs.txt -top personset

=head2 ARGUMENTS

=head3 -d DB_NAME

This database will be used for storing the stag nodes

The name can be a logical name or DBI locator or DBStag shorthand -
see L<DBIx::DBStag>

The database must already exist

=head3 -clear

Deletes all data from the relation type (specified with B<-r>) before loading

=head3 -insertonly

Does not check if the ID in the file exists in the db - will always
attempt an INSERT (and will fail if ID already exists)

This is the fastest way to load data (only one SQL operation per node
rather than two) but is only safe if there is no existing data

(Default is clobber mode - existing data with same ID will be replaced)

=head3 -newonly

If there is already data in the specified relation in the db, and the
XML being loaded specifies an ID that is already in the db, then this
node will be ignored

(Default is clobber mode - existing data with same ID will be replaced)

=head3 -transaction_size

A commit will be performed every n UPDATEs/COMMITs (and at the end)

Default is autocommit

note that if you are using -insertonly, and you are using
transactions, and the input file contains an ID already in the
database, then the transaction will fail because this script will try
and insert a duplicate ID

=head3 -r RELATION-NAME

This is the name of the stag node (XML element) that will be stored in
the index; for example, with the XML below you may want to use the
node name B<person> and the unique key B<id>

  <person_set>
    <person>
      <id>...</id>
    </person>
    <person>
      <id>...</id>
    </person>
    ...
  </person_set>

This flag should only be used when you want to store data

=head3 -k UNIQUE-KEY

This node will be used as the unique/primary key for the data

This node should be nested directly below the node that is being
stored in the index - if it is more that one below, specify a path

This flag should only be used when you want to store data

=head3 -u UNIQUE-KEY

Synonym for B<-k>

=head3 -create

If specified, this will create a table for the relation name specified
below; you should use this the first time you index a relation

=head3 -idtype TYPE

(optional)

This is the SQL datatype for the unique key; it defaults to VARCHAR(255)

If you know that your id is an integer, you can specify INTEGER here

If your id is always a 8-character field you can do this

  -idtype 'CHAR(8)'

This option only makes sense when combined with the B<-c> option

=head3 -p PARSER

This can be the name of a stag supported format (xml, sxpr, itext) -
XML is assumed by default

It can also be a module name - this module is used to parse the input
file into a stag stream; see L<Data::Stag::BaseGenerator> for details
on writing your own parsers/event generators

This flag should only be used when you want to store data

=head3 -q QUERY-ID

Fetches the relation/node with unique key value equal to query-id

Multiple arguments can be passed by specifying -q multple times

This flag should only be used when you want to query data

=head3 -top NODE-NAME

If this is specified in conjunction with B<-q> or B<-qf> then all the
query result nodes will be nested inside a node with this name (ie
this provides a root for the resulting document tree)

=head3 -qf QUERY-FILE

This is a file of newline-seperated IDs; this is useful for querying
the index in batch

=head3 -keys

This will write a list of all primary keys in the index

=head1 SEE ALSO

L<Data::Stag>

For more complex stag to database mapping, see L<DBIx::DBStag> and the
scripts

L<stag-db.pl> use file DBM indexes

L<stag-storenode.pl> is for storing fully normalised stag trees

L<selectall_xml>

=cut

