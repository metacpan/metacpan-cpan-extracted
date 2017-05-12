#!/usr/local/bin/perl -w

# POD docs at end

use strict;

use Carp;
use Data::Stag;
use DBIx::DBStag;
use Getopt::Long;

my $debug;
my $help;
my $db;
my $user;
my $pass;
my @units;
my $parser;
my @mappings;
my $mapconf;
my @noupdate = ();
my $force;
my $tracenode;
my $transform;
my $trust_ids;
my $autocommit;
my %cache_h = ();
my $safe;
GetOptions(
           "help|h"=>\$help,
	   "db|d=s"=>\$db,
	   "user=s"=>\$user,
	   "password|pass=s"=>\$pass,
	   "unit|u=s@"=>\@units,
           "parser|p=s"=>\$parser,
	   "mapping|m=s@"=>\@mappings,
	   "conf|c=s"=>\$mapconf,
           "noupdate=s@"=>\@noupdate,
           "tracenode=s"=>\$tracenode,
           "transform|t=s"=>\$transform,
           "trust_ids=s"=>\$trust_ids,
           "cache=s%"=>\%cache_h,
           "force"=>\$force,
           "safe"=>\$safe,
           "autocommit"=>\$autocommit,
          );
if ($help) {
    system("perldoc $0");
    exit 0;
}

#print STDERR "Connecting to $db\n";
my $dbh = DBIx::DBStag->connect($db, $user, $pass);
eval {
    $dbh->dbh->{AutoCommit} = $autocommit || 0;
};
if ($@) {
    print STDERR $@;
}

if ($trust_ids) {
    $dbh->trust_primary_key_values(1);
}
if ($mapconf) {
    $dbh->mapconf($mapconf);
}
if (@mappings) {
    $dbh->mapping(\@mappings);
}
@noupdate = map {split(/\,/,$_)} @noupdate;
$dbh->noupdate_h({map {$_=>1} @noupdate});
$dbh->tracenode($tracenode) if $tracenode;
$dbh->force(1) if $force;
$dbh->force_safe_node_names(1) if $safe;

foreach (keys %cache_h) {
    $dbh->is_caching_on($_, $cache_h{$_});
}

sub store {
    my $self = shift;
    my $stag = shift;
    #$dbh->begin_work;
    eval {
        $dbh->storenode($stag);
        $dbh->commit
          unless $autocommit;
    };
    if ($@) {
        print STDERR $@;
        if ($force) {
            print STDERR "-force set, ignoring error";
        }
        else {
            exit 1;
        }
    }
    return;
}

my $thandler;
if ($transform) {
    $thandler = Data::Stag->makehandler($transform);
}

foreach my $fn (@ARGV) {
    if ($fn eq '-' && !$parser) {
	$parser = 'xml';
    }
    my $H;
    if (@units) {
        my $storehandler = Data::Stag->makehandler(
                                                   map {
                                                       $_ =>sub{store(@_)};
                                                   } @units
                                               );
        if ($thandler) {
            $H = Data::Stag->chainhandlers([@units],
                                           $thandler,
                                           $storehandler);
        }
        else {
            $H = $storehandler;
        }
    }
    else {
        # if no load units are specified, store everything
        # nested one-level below top
        $H = Data::Stag->makehandler;
        $H->catch_end_sub(sub {
                              my ($handler,$stag) = @_;
                              if ($handler->depth == 1 &&
                                  $stag->element ne '@') {
                                  store($handler,$stag);
                                  return;
                              }
                              return $stag;
                          });
    }
    Data::Stag->parse(-format=>$parser,-file=>$fn, -handler=>$H);
}
$dbh->disconnect;
exit 0;

__END__

=head1 NAME 

stag-storenode.pl

=head1 SYNOPSIS

  stag-storenode.pl -d "dbi:Pg:dbname=mydb;host=localhost" myfile.xml

=head1 DESCRIPTION

This script is for storing data (specified in a nested file format
such as XML or S-Expressions) in a database. It assumes a database
schema corresponding to the tags in the input data already exists.

=head2 ARGUMENTS

=head3 -d B<DBNAME>

This is either a DBI locator or the logical name of a database in the
DBSTAG_DBIMAP_FILE config file

=head3 -user B<USER>

db user name

=head3 -password B<PASSWORD>

db user password

=head3 -u B<UNIT>

This is the node/element name on which to load; a database loading
event will be fired every time one of these elements is parsed; this
also constitutes a whole transaction

=head3 -c B<STAGMAPFILE>

This is a stag mapping file, indicating which elements are aliases

=head3 -p B<PARSER>

Default is xml; can be any stag compatible parser, OR a perl module
which will parse the input file and fire stag events (see
L<Data::Stag::BaseGenerator>)

=head3 -t B<TRANSFORMER>

This is the name of a perl module that will perform a transformation
on the stag events/XML. See also L<stag-handle.pl>

=head3 -noupdate B<NODELIST>

A comma-seperated (no spaces) list of nodes/elements on which no
update should be performed if a unique key is found to be present in
the DB

=head3 -trust_ids

If this flag is present, the values for primary key values are
trusted; otherwise they are assumed to be surrogate internal IDs that
should not be used. In this case they will be remapped.

=head3 -tracenode B<TABLE/COLUMN>

E.g.

  -tracenode person/name

Writes out a line on STDERR for every new person inserted/updated

=head3 -cache B<TABLE>=B<MODE>

Can be specified multiple times

Example:

  -cache 

                   0: off (default)
                   1: memory-caching ON
                   2: memory-caching OFF, bulkload ON
                   3: memory-caching ON, bulkload ON

IN-MEMORY CACHING

By default no in-memory caching is used. If this is set to 1,
then an in-memory cache is used for any particular element. No cache
management is used, so you should be sure not to cache elements that
will cause memory overloads.

Setting this will not affect the final result, it is purely an
efficiency measure for use with storenode().

The cache is indexed by all unique keys for that particular
element/table, wherever those unique keys are set

BULKLOAD

If bulkload is used without memory-caching (set to 2), then only
INSERTs will be performed for this element. Note that this could
potentially cause a unique key violation, if the same element is
present twice

If bulkload is used with memory-caching (set to 3) then only INSERTs
will be performed; the unique serial/autoincrement identifiers for
those inserts will be cached and used. This means you can have the
same element twice. However, the load must take place in one session,
otherwise the contents of memory will be lost


=head1 XML TO DB MAPPING

See L<DBIx::DBStag> for details of the actual mapping. Two styles of
mapping are allowed: stag-dbxml and XORT-style XML. You do not have to
specify which, they are sufficiently similar that the loader can
accept either.

=head1 MAKING DATABASE FROM XML FILES

It is possible to automatically generate a database schema and
populate it directly from XML files (or from Stag objects or other
Stag compatible files). Of course, this is no substitute for proper
relational design, but often it can be necessary to quickly generate
databases from heterogeneous XML data sources, for the purposes of
data mining.

There are 3 steps involved:

1. Prepare the input XML (for instance, modifying db reserved words).
2. Autogenerate the CREATE TABLE statements, and make a db from these.
3. Store the XML data in the database.

=head2 Step 1: Prepare input file

You may need to make modifications to your XML before it can be used
to make a schema. If your XML elements contain any words that are
reserved by your DB you should change these.

Any XML processing tool (eg XSLT) can be used. Alternatively you can
use the script 'stag-mogrify'

e.g. to get rid of '-' characters (this is how Stag treates
attributes) and to change the element with postgresql reserved word
'date', do this:

  stag-mogrify.pl -xml -r 's/^date$/moddate/' -r 's/\-//g' data.xml > data.mog.xml

You may also need to explicitly make elements where you will need
linking tables. For instance, if the relationship between 'movie' and
'star' is many-to-many, and your input data looks like this:

  (movie
   (name "star wars")
   (star
    (name "mark hamill")))

You will need to *interpose* an element between these two, like this:

  (movie
   (name "star wars")
   (movie2star
    (star
     (name "mark hamill"))))

you can do this with the -i switch:

  stag-mogrify.pl -xml -i movie,star,movie2star data.xml > data.mog.xml

or if you simply do:

  stag-mogrify.pl -xml -i star data.xml > data.mog.xml

the mogrifier will simply interpose an element above every time it
sees 'star'; the naming rule is to use the two elements with an
underscore between (in this case, 'movie_star').

=head2 Step 2: Generating CREATE TABLE statements

Use the stag-autoddl.pl script;

  stag-autoddl.pl data.mog.xml > table.sql

The default rule is to create foreign keys from the nested element to
the outer element; you will want linking tables tobe treated
differently (a linking table will point to parent and child elements).

  stag-autoddl.pl -l movie2star -l star2character data.mog.xml > table.sql

Once you have done this, load the statements into your db; eg for postgresql
(for other databases, use L<SQL::Translator>)

  psql -a mydb < table.sql

If something goes wrong, go back to step 1 and sort it out!

Note that certain rules are followed: ever table generated gets a
surrogate primary key of type 'serial'; this is used to generate
foreign key relationships. The rule used is primary and foreign key
names are the name of the table with the '_id' suffix.

Feel free to modify the autogenerated schema at this stage (eg add
uniqueness constraints)

=head2 Step 3: Store the data in the db

  stag-storenode.pl -u movie -d 'dbi:Pg:mydb' data.mog.xml

You generally dont need extra metadata here; everything can be
infered by introspecting the database.

The -u|unit switch controls when transactions are committed

You can omit the -u switch, and every node directly under the top node
will be stored. This will also be the transaction unit.

If this works, you should now be able to retreive XML from the database, eg

  selectall_xml.pl -d 'dbi:Pg:mydb' 'SELECT * FROM x NATURAL JOIN y'

=cut


