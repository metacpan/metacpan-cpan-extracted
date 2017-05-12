package DBIx::Recordset::Playground;

use strict;
use warnings;

use DBI;
use DBIx::Recordset;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DBIx::Recordset::Playground ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(	
);

our $VERSION = sprintf '%s', q$Revision: 1.9 $ =~ /Revision:\s+(\S+)\s+/ ;

# Preloaded methods go here.


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

  DBIx::Recordset::Playground - working sample usages of DBIx::Recordset

=head1 INTRODUCTION

This document serves several purposes. One, it makes it easy to get started
with DBIx::Recordset. Two, it serves as a place for those experienced with
recordset to examine the code to discover how to make usage of recordset
even simpler. Finally, it serves as a place for me to clarify all the
areas in the original docs that were a bit confusing to me.

After creating a database using L<DBSchema::Sample|DBSchema::Sample>,
you will be
able to manipulate it using  from DBIx::Recordset using the examples here.
Let the games begin!

=head1 Preliminaries:

=head2 Our Generic Connection/Library Script

This script contains our connection information and a variety of
convenience subroutines. The existence of these points to how we might
want to abstract Recordset usage further, once we are comfortable with the
basics.

 #
 #   scripts/dbconn.pl
 #
 
 use Data::Dumper;
 use DBIx::Recordset;
 
 # change to match your local connection parameters
 
 my ($dsn, $user, $pass);
 
 # mysql
 {
   last;
   $dsn = 'DBI:mysql:database=princepawn;host=localhost';
   $user='princepawn';
   $pass='money1';
 }
 
 # psql
   $dsn = 'DBI:Pg:dbname=test;host=localhost';
 
 
 my  $attr= { RaiseError => 1 };
 
 
 sub dbh {
     *DBIx::Recordset::LOG   = \*STDOUT;
     $DBIx::Recordset::Debug = 2;
 
     my $dbh = DBI->connect($dsn, $user, $pass, $attr) or die $DBI::errstr;
 
 }
 
 sub conn_dbh {
     ( '!DataSource' => dbh() );
 }
 
 sub author_table {
     ( '!Table'      => 'authors' );
 }
 
 sub royalty_table {
     ( '!Table'      => 'roysched' );
 }
 
 sub tblnm {
 
     (
      '!Table' =>
      shift()
     )
 
 }
 
 
 sub print_recordset {
 
     my $glob = shift;
     my $set = $glob;
 
     while ( my $rec = $set->Next )
       {
 	  print Dumper(\%set);
       }
 
 }
 
 
 1;



=head2 Create and Populate the Database

The schema description is given in:

L<DBSchema::Sample|DBSchema::Sample>

which is built via:

  perl -MDBSchema::Sample -e load


=head1 LIVING CODE SAMPLES

=head2 Building Where Clauses

=head3 field op A OR field op B or file op C ...

 #
 #   scripts/build-where/or-conjunct.pl
 #
 
 require '../dbconn.pl';
 use DBIx::Recordset;
 use strict;
 
 use vars qw(*set);
 
 # Find all authors whose phone number is in area code 801 or 415
 
 my @area_code = qw(801 415);
 
 *set =
   DBIx::Recordset -> Search
   ({
     conn_dbh(),
     '!Table'   => 'authors',
     '*phone'   => 'LIKE',
       phone    => ( join "\t", map { "$_%" } @area_code ),
    });
 
 while ($set->Next) {
     print Dumper(\%set)
 }


=head2 Selecting data with where criteria in a hash

 #
 #   scripts/select-using-href.pl
 #
 
 require 'dbconn.pl';
 use DBIx::Recordset;
 use strict;
 
 use vars qw(*set);
 
 *set =
   DBIx::Recordset -> Search
   ({
     au_lname => 'Ringer',
     state    => 'UT',
     conn_dbh(), author_table()
 
    });
 
 warn 1.0;
 #print Dumper(\@set); # results not fetched because FetchsizeWarn not disabled
 
 warn 1.01;
 $DBIx::Recordset::FetchsizeWarn = 0;
 print Dumper(\@set); # results are now fetched
 
 warn 1.1;
 print Dumper(\%set); # only print current record
 
 warn 1.2; # Here we print all
 $set->Reset;
 while ($set->Next) {
     print Dumper(\%set)
 }
 
 
 warn 1.3; # Here we print all in another way
 $set->Reset;
 while (my $rec = $set->Next) {
     print Dumper($rec);
 }
 
 warn 1.4; # This doesnt work either <... why?>
 $set->Reset;
 while ($set->MoreRecords) {
     print Dumper($set->Next);
 }


This is useful when your have formdata in a hash for instance.

=head2 Selecting data where values are in an arrayref:

 #
 #   scripts/select-using-aref.pl
 #
 
 require 'dbconn.pl';
 #use Data::Dumper;
 use DBIx::Recordset;
 use strict;
 
 use vars qw(*rs);
 
 *rs =
   DBIx::Recordset -> Search ({
 
       '$where'   => 'au_lname = ? and state = ?',
       '$values'  => ['Ringer',  "UT"],
       conn_dbh(), author_table()
 
       });
 
 # print Dumper($rs[0]) only works if FetchsizeWarn siabled
 
 warn $rs{au_fname};


=head2 Update

 #
 #   scripts/synopsis-update.pl
 #
 
 require 'dbconn.pl';
 #use Data::Dumper;
 use DBIx::Recordset;
 use strict;
 
 use vars qw(*rs);
 
 *rs =
   DBIx::Recordset -> Setup ({
 
       conn_dbh(), author_table()
 
       });
 
 $rs->Update
   (
    {
     state => 'Utah'   # SET
    },
    {
     state => 'UT'     # WHERE
    }
   );
 
 # It worked. The field is truncated to 2 chars


=head2 Reusing a Set Object to do Another Search:

 #
 #   scripts/do-another-search.pl
 #
 
 require 'dbconn.pl';
 use DBIx::Recordset;
 
 use vars qw(*set);
 
 *set =
   DBIx::Recordset -> Search
   ({
 
     au_fname => 'Akiko',
     conn_dbh(), author_table()
 
    });
 
 
 print $set{address}, $/;
 
 # Now do another search
 
 $set->Search({
 
 	      au_fname => 'Sylvia'
     });
 
 print $set{address}, $/;


=head2 Using C<Next()> 

=head3 Using C<Next()> to Iterate over a Result Set:

 #
 #   scripts/all-users-with.pl
 #
 
 require 'dbconn.pl';
 use DBIx::Recordset;
 use strict;
 use vars qw(*set);
 
 my %where = (title_id => 'MC3026');
 
 *set =
   DBIx::Recordset -> Search ({
 
       %where,
       conn_dbh(), royalty_table()
 
       });
 
 
 while (my $rec = $set->Next) {
     print $rec->{royalty}, $/;
 }


=head3 Using C<Next()> but Using the Implicitly Bound Hash:

 #
 #   scripts/using-implicit-hash.pl
 #
 
 require 'dbconn.pl';
 use DBIx::Recordset;
 use strict;
 use vars qw(*set);
 
 my %where = (title_id => 'MC3026');
 
 *set =
   DBIx::Recordset -> Search ({
 
       %where,
       conn_dbh(), royalty_table()
 
       });
 
 
 while ($set->Next) {
     print $set{royalty}, $/;
 }


=head2 Filtering Data on Input/Output to/from Database

 #
 #   scripts/filter-authors.pl
 #
 
 require 'dbconn.pl';
 use DBIx::Recordset;
 use strict;
 
 use vars qw(*set);
 
 *set =
   DBIx::Recordset -> Search
   ({
     conn_dbh(), author_table(),
     '$max' => 10,
     '!Filter' => {
 		  DBI::SQL_VARCHAR => [
 				       undef, # no input filtering
 				       sub { uc (shift()) }
 				      ]
 		  }
    });
 
 
 while ($set->Next) {
     print Dumper(\%set)
 }
 



=head2 Tying a Table to a Hash for Easy Lookup by Primary Key

 #
 #   scripts/hash-as-row-key.pl
 #
 
 require 'dbconn.pl';
 use DBIx::Recordset;
 use strict;
 use vars qw(*set);
 
 *set = DBIx::Recordset -> Setup
   ({
     conn_dbh(),
     '!Table'	    => 'authors',
     '!HashAsRowKey' => 1,
     '!PrimKey'      => 'au_id'
    });
 
 
 my @au_id = qw( 409-56-7008  213-46-8915 998-72-3567 );
 
 
 warn Dumper($set{$_}) for @au_id;


=head2 Tying Hashes with Expirable Caches to Databases 

L<DBIx::Recordset|DBIx::Recordset> 
allows you to tie a hash to a database table, and retrieve the
records of the table via the hash's key. You can tie the entire table
or create an expirable "view" of a subset of the table 
via Recordset's C<!PreFetch>
option. Your view can be expired based on a fixed amount of seconds or
via a boolean subroutine which accepts the (tied hash via a scalar?) 
as an argument.


 #
 #   scripts/prefetch-expire.pl
 #
 
 #!/usr/bin/perl
 
 require 'dbconn.pl';
 use DBIx::Recordset;
 use strict;
 
 # This program repeatedly presents sales data on STDOUT, refreshing 
 # the view every $view_refresh seconds. It refreshes its 
 # model (from the database) every $model_refresh seconds.
 
 # The default values for $model_refresh and $view_refresh imply that 
 # the model will refreshed after 2.6 view refreshes or practically speaking
 # on every 3rd view refresh.
 
 # You can verify that it makes new hits on the database by noting the
 # DBIx::Recordset log messages. You will see this after every 3 view
 # displays:
 # DB:  'SELECT * FROM sales     ORDER BY sonum DESC  LIMIT 6' bind_values=<> bind_types=<>
 
 # To spice things up, you can open a different terminal window and run
 # prefetch-insert.pl, which will insert a new record into the sales table
 # every $x seconds.
 
 # This program requires a version of DBIx::Recordset > 0.24, which is the 
 # current CPAN release. Or you can apply the patch recently posted to
 # the embperl@perl.apache.org mailing list.
 
 my $model_refresh = 13;
 my $view_refresh  = 5;
 
 use vars qw(%sales);
 
 tie %sales, 'DBIx::Recordset::Hash',
   {
    conn_dbh(),
    '!Table' => 'sales',
    '!PreFetch' => {
 		   '$max'    => 5,
 		   '$order'  => 'sonum DESC'
 		  },
    '!PrimKey'  => 'sonum',
    '!Expires'  => $model_refresh
   };
 
 sub bynumber { $a <=> $b }
 
 while (1) {
 
   my (@key) = keys %sales;
   print $sales{$_}{sonum}, $/ for sort bynumber @key;
   sleep $view_refresh;
   print $/;
 
 }
 


 #
 #   scripts/prefetch-insert.pl
 #
 
 require 'dbconn.pl';
 use DBIx::Recordset;
 use strict;
 
 
 # This program takes one argument, an integer indicating how often it should
 # insert a random record into the sales table.
 
 my $insert_frequency = shift or die 'must specify insert frequency';
 
 use vars qw(*set);
 
 sub rand_ponum {
   sprintf "%s%d%s", chr(65 + rand 25), rand 400 + rand 1000, 
     lc chr(65 + rand 25);
 }
 
 
 *set = DBIx::Recordset->Search
   ({
     conn_dbh(),
     '!Table'  => 'sales',
     '!Fields' => 'max(sonum) as max_id',
     });
 
 my $max_id = $set{max_id};
 
 
 while (1) {
 
   DBIx::Recordset->Insert
       (
        {
 	conn_dbh(),
 	'!Table'  => 'sales',
 	sonum     => ++$max_id,
 	stor_id   => (sprintf "%d", 7000 + rand 1000),
 	ponum     => rand_ponum,
 	sdate     => '2003-10-22'
        }
        );
 
   sleep $insert_frequency;
 
 }


=head1

Most functions which set up an object return a B<typeglob>. A typeglob
in Perl is an  
object which holds pointers to all datatypes with the same
name. Therefore a typeglob 
must always have a name and B<can't> be declared with B<my>. You can only
use it as B<global> (package) variable or declare it with
B<local>. The trick for using 
a typglob is that setup functions can return a B<reference to an object>, an
B<array> and a B<hash> at the same time.

B<... concerns about package variables and mod_perl ...>

However, most if not all Recordset functionality is useable from the object
alone, thus it suffices to setup the object by returning a reference into
a lexical or package-scoped scalar.


=head1 ARGUMENTS

NOTE 1: Fieldnames specified with !Order can't be overridden. If you plan
to use other fields with this object later, use $order instead.

B<... of course the question being how to do ascending and descending>

=head1 WORKING WITH MULTIPLE TABLES

=item B<!TabRelation>

Condition which describes the relation between the given tables
(e.g. tab1.id = tab2.id) (See also L<!TabJoin>.)

Let's look at a query and it's results:

 mysql> select title_id,ponum from sales, salesdetails where sales.sonum=salesdetails.sonum and qty_ordered=15;
 +----------+----------+
 | title_id | ponum    |
 +----------+----------+
 | MC3021   | 423LL922 |
 | BU7832   | QQ2299   |
 | PS3333   | P3087a   |
 +----------+----------+

Or in English:

  What was the title and purchase order number for all sales whose order quantity was 15.

Now let's see it rendered in Recordset:

 #
 #   scripts/join-tabrelation.pl
 #
 
 require 'dbconn.pl';
 use DBIx::Recordset;
 
 use vars qw(*set);
 
 *set =
   DBIx::Recordset -> Search
   ({
     '!TabRelation' => 'sales.sonum = salesdetails.sonum',
     'qty_ordered'  => 15,
     '$fields'      => 'title_id,ponum',
     conn_dbh(),
     tblnm('sales,salesdetails')
    });
 
 
 while ( $set->Next) {
     print join "\t", $set{title_id}, $set{ponum}, $/;
 }


=item B<!TabJoin>

!TabJoin allows you to specify an B<INNER/RIGHT/LEFT JOIN> which is
used in a B<SELECT> statement. (See also L<!TabRelation>.)

 #
 #   scripts/join-tabrelation.pl
 #
 
 require 'dbconn.pl';
 use DBIx::Recordset;
 
 use vars qw(*set);
 
 *set =
   DBIx::Recordset -> Search
   ({
     '!TabRelation' => 'sales.sonum = salesdetails.sonum',
     'qty_ordered'  => 15,
     '$fields'      => 'title_id,ponum',
     conn_dbh(),
     tblnm('sales,salesdetails')
    });
 
 
 while ( $set->Next) {
     print join "\t", $set{title_id}, $set{ponum}, $/;
 }


  SELECT au_fname, au_lname, pub_name 
    FROM authors left outer join publishers 
      ON authors.city = publishers.city;

=item B<!PrimKey>

Name of the primary key. When this key appears in a WHERE parameter list
(see below), DBIx::Recordset will ignore all other keys in the list,
speeding up WHERE expression preparation and execution.

B<... oh I think I see. He means that the primary key alone should be
enough to find your records, so why bother with anything else. So, if
you set this up beforehand, then when formdata came piling in, you
could search on primary key only if it happened to be in the formdata.>

Note that this
key does NOT have to correspond to a field tagged as PRIMARY KEY in a
CREATE TABLE statement.

=item B<!Serial>

Name of the primary key. In contrast to C<!PrimKey> this field is treated
as an autoincrement field. If the database does not support
autoincrement fields, 
but sequences the field is set to the next value of a sequence (see
C<!Sequence> and C<!SeqClass>) 
upon each insert. If a C<!SeqClass> is given the values are always
retrived from the sequence class 
regardless if the DBMS supports autoincrement or not.
The value from this field from the last insert could be retrieved
by the function C<LastSerial>.

B<... aha! an how-to! ...>

=item C<!Sequence>

Name of the sequence to use for this table when inserting a new record and
C<!Serial> is defind. Defaults to <tablename>_seq.

B<... a feature related to DBMS which use sequences>

=item C<!SeqClass>

Name and Parameter for a class that can generate unique sequence
values. This is 
a string that holds comma separated values. The first value is the
class name and 
the following parameters are given to the new constructor. See also
I<DBIx::Recordset::FileSeq> 
and I<DBIx::Recordset::DBSeq>.  

Example:  

   '!SeqClass' => 'DBIx::Recordset::FileSeq, /tmp/seq'

B<... another sequence-related feature>

=item B<!WriteMode>

!WriteMode specifies which write operations to the database are
allowed and which are 
disabled. You may want to set C<!WriteMode> to zero if you only need
to query data, to 
avoid accidentally changing the content of the database.

B<NOTE:> The !WriteMode only works for the DBIx::Recordset methods. If you
disable !WriteMode, it is still possible to use B<do> to send normal
SQL statements to the database engine to write/delete any data.

!WriteMode consists of some flags, which may be added together:

=over 4

=item DBIx::Recordset::wmNONE (0)

Allow B<no> write access to the table(s)

=item DBIx::Recordset::wmINSERT (1)

Allow INSERT

=item DBIx::Recordset::wmUPDATE (2)

Allow UPDATE

=item DBIx::Recordset::wmDELETE (4)

Allow DELETE

=item DBIx::Recordset::wmCLEAR (8)

To allow DELETE for the whole table, wmDELETE must be also specified. This is 
necessary for assigning a hash to a hash which is tied to a table. (Perl will 
first erase the whole table, then insert the new data.)

=item DBIx::Recordset::wmALL (15)

Allow every access to the table(s)


=back

Default is wmINSERT + wmUPDATE + wmDELETE

=item B<!StoreAll>

If present, this will cause DBIx::Recordset to store all rows which will be fetched between
consecutive accesses, so it's possible to access data in a random order. (e.g.
row 5, 2, 7, 1 etc.) If not specified, rows will only be fetched into memory
if requested, which means that you will have to access rows in ascending order.
(e.g. 1,2,3 if you try 3,2,4 you will get an undef for row 2 while 3 and 4 is ok)
see also B<DATA ACCESS> below.

=item B<!HashAsRowKey>

By default, the hash returned by the setup function is tied to the
current record. 

<... this is already confusing. by "Setup Function" I presume he
means the function SetupObject and only this function? Or does he mean
any function which calls SetupObject. Such as Search(), Insert(),
Update(), Delete(). 

Also, the hash is not "returned" because the last sentence below says
that
this whole discussion relates to functions which return a
typeglob... therefore I think he means functions which bind a hash
with data of the current record.>

You can use it to access the fields of the current
record. If you set this parameter to true, the hash will by tied to
the whole 
database. This means that the key of the hash will be used as the
primary key in 
the table to select one row. 

B<... cool can we get an example of this?>

(This parameter only has an effect on
functions 
which return a typglob.)

B<... "typglob" should be spelled "typeglob">

=item B<!IgnoreEmpty>

This parameter defines how B<empty> and B<undefined> values are handled. 
The values 1 and 2 may be helpful when using DBIx::Recordset inside a CGI
script, because browsers send empty formfields as empty strings.

=over 4

=item B<0 (default)>

An undefined value is treated as SQL B<NULL>: an empty string remains an empty 
string.

=item B<1>

All fields with an undefined value are ignored when building the WHERE expression.

=item B<2>

All fields with an undefined value or an empty string are ignored when building the 
WHERE expression.

=back

B<NOTE:> The default for versions before 0.18 was 2.

=item B<!Filter>

Filters can be used to pre/post-process the data which is read from/written to the database.
The !Filter parameter takes a hash reference which contains the filter functions. If the key
is numeric, it is treated as a type value and the filter is applied to all fields of that 
type. If the key if alphanumeric, the filter is applied to the named field.  Every filter 
description consists of an array with at least two elements.  The first element must contain the input
function, and the second element must contain the output function. Either may be undef, if only
one of them are necessary. The data is passed to the input function before it is written to the
database. The input function must return the value in the correct format for the database. The output
function is applied to data read from the database before it is returned
to the user.
 
 
 Example:

     '!Filter'   => 
	{
	DBI::SQL_DATE     => 
	    [ 
		sub { shift =~ /(\d\d)\.(\d\d)\.(\d\d)/ ; "19$3$2$1"},
		sub { shift =~ /\d\d(\d\d)(\d\d)(\d\d)/ ; "$3.$2.$1"}
	    ],

	'datefield' =>
	    [ 
		sub { shift =~ /(\d\d)\.(\d\d)\.(\d\d)/ ; "19$3$2$1"},
		sub { shift =~ /\d\d(\d\d)(\d\d)(\d\d)/ ; "$3.$2.$1"}
	    ],

	}

Both filters convert a date in the format dd.mm.yy to the database format 19yymmdd and
vice versa. The first one does this for all fields of the type
SQL_DATE, the second one 
does this for the fields with the name datefield.

The B<!Filter> parameter can also be passed to the function
B<TableAttr> of the B<DBIx::Database> 
object. In this case it applies to all DBIx::Recordset objects which
use 
these tables.

B<... aha! so this is the second place so far that we have a means of
globally affecting all recordset object using tables. This means less
needs be done in pure OOP and more can be done by Recordset, for
better or worse>

A third parameter can be optionally specified. It could be set to
C<DBIx::Recordset::rqINSERT>, 
C<DBIx::Recordset::rqUPDATE>, or the sum of both. If set, the
InputFunction (which is called during 
UPDATE or INSERT) is always called for this field in updates and/or
inserts depending on the value. 

B<... what InputFunction is he talking about?>

If there is no data specified for this field
as an argument to a function which causes an UPDATE/INSERT, the
InputFunction 
is called with an argument of B<undef>.

During UPDATE and INSERT the input function gets either the string 'insert' or 'update' passed as
second parameter.

=item B<!LinkName>

This allows you to get a clear text description of a linked table,
instead of (or in addition to) the !LinkField. For example, if you
have a record with all your bills, and each record contains a customer
number, setting !LinkName DBIx::Recordset can automatically retrieve
the name of the customer instead of (or in addition to) the bill
record itself.

=over 4

=item 1 select additional fields

This will additionally select all fields given in B<!NameField> of the Link or the table
attributes (see TableAttr).

=item 2 build name in uppercase of !MainField

This takes the values of B<!NameField> of the Link or the table attributes (see 
TableAttr)
and joins the content of these fields together into a new field, which has the same name
as the !MainField, but in uppercase.


=item 2 replace !MainField with the contents of !NameField

Same as 2, but the !MainField is replaced with "name" of the linked record.

=back

See also B<!Links> and B<WORKING WITH MULTIPLE TABLES> below

Here is how you "join" 3 tables if you are not comfortable with the link syntax:

 #
 #   scripts/3-table-join-manual.pl
 #
 
 require 'dbconn.pl';
 use DBIx::Recordset;
 use strict;
 use vars qw(*set *set2 *set3);
 
 {
 
     my %DEBUG = ('!Debug' => 0);
 
     *set = DBIx::Recordset -> Search 
       ({
 	conn_dbh(),
 	%DEBUG,
 	'!Table'	   => 'authors'
        }) ;
 
     while ( my $rec = $set->Next) {
 	print join "\t", $set{au_fname}, $set{au_lname}, $set{au_id}, $/;
 	*set2 = DBIx::Recordset -> Search
 	  ({
 	    conn_dbh(),
 	    %DEBUG,
 	    '!Table'	   => 'titleauthors',
 	    au_id              => $set{au_id}
 	   }) ;
     
 	while ( my $rec2 = $set2->Next) {
 	    #	warn 1.3;
 	    print "\t", $set2{title_id}, $/;
 
 	    #	warn 1.4;
 	    *set3 = DBIx::Recordset -> Search
 	      ({
 		conn_dbh(),
 		%DEBUG,
 		'!Table'	   => 'titles',
 		title_id       => $set2{title_id}
 	       });
 
 	    while ( my $rec3 = $set3->Next) {
 		print "\t\t", $set3{title}, $/;
 
 	    }
 	}
     }
 
 
 }



=item B<!Links>

This parameter can be used to link multiple tables together. It takes a
reference to a hash, which has - as keys, names for a special B<"linkfield">
and - as value, a parameter hash. The parameter hash can contain all the
B<Setup parameters>. The setup parameters are taken to construct a new
recordset object to access the linked table. If !DataSource is omitted (as it
normally should be), the same DataSource (and database handle), as the
main object is taken. There are special parameters which can only 
occur in a link definition (see next paragraph). For a detailed description of
how links are handled, see B<WORKING WITH MULTIPLE TABLES> below.

=head2 Link Parameters

=item B<!MainField>

The B<!MailField> parameter holds a fieldname which is used to retrieve
a key value for the search in the linked table from the main table.
If omitted, it is set to the same value as B<!LinkedField>.

=item B<!LinkedField>

The fieldname which holds the key value in the linked table.
If omitted, it is set to the same value as B<!MainField>.

=item B<!NameField>

This specifies the field or fields which will be used as a "name" for the destination table. 
It may be a string or a reference to an array of strings.
For example, if you link to an address table, you may specify the field "nickname" as the 
name field
for that table, or you may use ['name', 'street', 'city'].

Look at B<!LinkName> for more information.


B<... this is very confusing... there is some stuff in test.pl in the
Recorset distribution which does this... but boy is it confusing!>

=item B<!DoOnConnect>

You can give an SQL Statement (or an array reference of SQL
statements), that will be executed every time, just after an connect
to the db. As third possibilty you can give an hash reference. After
every successful connect, DBIx::Recordset excutes the statements, in
the element which corresponds to the name of the driver. '*' is
executed for all drivers.

=item B<!Default>

Specifies default values for new rows that are inserted via hash or array access. The Insert
method ignores this parameter.

=item B<!TieRow>

Setting this parameter to zero will cause DBIx::Recordset to B<not> tie the returned rows to
an DBIx::Recordset::Row object and instead returns an simple hash. The benefit of this is
that it will speed up things, but you aren't able to write to such an row, nor can you use
the link feature with such a row.

=item B<!Debug>

Set the debug level. See DEBUGGING.


=item B<!PreFetch>

Only for tieing a hash! Gives an where expression (either as string or as hashref) 
that is used to prefetch records from that
database. All following accesses to the tied hash only access this prefetched data and
don't execute any database queries. See C<!Expires> how to force a refetch.
Giving a '*' as value to C<!PreFetch> fetches the whole table into memory.

 The following example prefetches all record with id < 7:

 tie %dbhash, 'DBIx::Recordset::Hash', {'!DataSource'   =>  $DSN,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  'foo',
                                        '!PreFetch'     =>  {
                                                             '*id' => '<',
                                                             'id' => 7
                                                            },
                                        '!PrimKey'      =>  'id'} ;

 The following example prefetches all records:

 tie %dbhash, 'DBIx::Recordset::Hash', {'!DataSource'   =>  $DSN,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  'bar',
                                        '!PreFetch'     =>  '*',
                                        '!PrimKey'      =>  'id'} ;

=item B<!Expires>

Only for tieing a hash! If the values is numeric, the prefetched data will be refetched 
is it is older then the given number of seconds. If the values is a CODEREF the function
is called and the data is refetched is the function returns true.

=item B<!MergeFunc>

Only for tieing a hash! Gives an reference to an function that is called when more then one
record for a given hash key is found to merge the records into one. The function receives
a refence to both records a arguments. If more the two records are found, the function is
called again for each following record, which is already merged data as first parameter.

 The following example sets up a hash, that, when more then one record with the same id is
 found, the field C<sum> is added and the first record is returned, where the C<sum> field
 contains the sum of B<all> found records:

 tie %dbhash, 'DBIx::Recordset::Hash', {'!DataSource'   =>  $DSN,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  'bar',
                                        '!MergeFunc'    =>  sub { my ($a, $b) = @_ ; $a->{sum} += $b->{sum} ; },
                                        '!PrimKey'      =>  'id'} ;



=head1 AUTHOR

T. M. Brannon, <tbone@cpan.org>

=cut
