############################################################
#
# DBSchema::Normalizer - a MySQL database table normalizer
#
# Copyright (c) 2001 by Giuseppe Maxia
# Produced under the GPL (Golden Perl Laziness) 
# Distributed under the GPL (GNU Geneal Public License) 
#
############################################################

require 5.004;

=head1 NAME

 DBSchema::Normalizer - database normalization. - Convert a table from 1st to 2nd normal form

=head1 SYNOPSIS

  # the easy way is to give all parameters to the constructor
  # and then call do()
  #
  use DBSchema::Normalizer;
  my $norm = DBSchema::Normalizer->new ( 
	{ 
	    DSN           => $DSN,
	    username      => $username,
	    password      => $password,
	    src_table     => $sourcetable,
	    index_field   => $indexfield,
	    lookup_fields => $lookupfields, # comma separated list
	    lookup_table  => $lookuptable,
	    dest_table    => $dest_table,
	    copy_indexes  => "yes", 
	});
  $norm->do();  # Just Do It!

  # Alternatively, you can have some more control, by
  # creating the lookup table and normalized table separately,
  # especially useful if one of them is an intermediate step.
  #
  use DBSchema::Normalizer qw(create_lookup_table create_normalized_table);
  my $norm = DBSchema::Normalizer->new( 
	{ 
	    DSN      => $DSN,
	    username => $username,
	    password => $password
	});
  $norm->create_lookup_table (
	  {
	     src_table     => $tablename,
	     index_field   => $indexfield,
	     lookup_fields => $lookupfields,
	     lookup_table  => $lookuptable
      });
  $norm->create_normalized_table (
	  {
	     src_table     => $tablename,
	     index_field   => $indexfield,
	     lookup_fields => $lookupfields,
	     lookup_table  => $lookuptable,
	     dest_table    => $dest_table,
	     copy_indexes  => "yes",
      });

=head1 DESCRIPTION

B<DBSchema::Normalizer> is a module to help transforming MySQL database tables from 1st to 2nd normal form.
Simply put, it will create a lookup table out of a set of repeating fields from a source table, and replace such fields by a foreign key that points to the corresponding fields in the newly created table.
All information is taken from the database itself. There is no need to specify existing details. 
The module is capable of re-creating existing indexes, and should deal with complex cases where the replaced fields are part of a primary key.

=head2 Algorithm

The concept behind B<DBSchema::Normalizer> is based upon some DBMS properties. To replace repeating fields with a foreign key pointing to a lookup table, you must be sure that for each distinct set of values you have a distinct foreign key. You might be tempted to solve the problem with something like this:

	 I. Read all records into memory
	II. for each record, identify the unique value for the fields to be
	    moved into a lookup table and store it in a hash
	II. again, for each record, find the corresponding value in the 
	    previously saved hash and save the non-lookup fields plus the 
		unique key into a new table
	IV. for each key in the hash, write the values to a lookup table

I can find four objections against such attempt:

1. Memory problems. The source table can be very large (and some of the table I had to normalize were indeed huge. This kind of solution would have crashed any program trying to load them into memory.) Instead of reading the source table into memory, we could just read the records twice from the database and deal with them one at the time. However, even the size of the hash could prove to be too much for our computer memory. A hash of 2_000_000 items is unlikely to handle memory efficiently in most nowadays desktops.

2. Data specific solution. To implement this algorithm, we need to include details specific to our particular records in our code. It is not a good first step toward re-utilization.

3. Data conversion. We need to fetch data from the database, eventually transform it into suitable formats for our calculation and then send it back, re-packed in database format. Not always an issue, but think about the handling of floating point fields and timestamp fields with reduced view.  Everything can be solved, but it could be a heavy overhead for your sub.

4. Finally, I would say that this kind of task is not your job. Nor is Perl's. It belongs in the database engine, which can easily, within its boundaries, identify unique values and make a lookup table out of them. And it can also easily make a join between source and lookup table.

That said, the solution springs to mind. Let the database engine do its job, and have Perl drive it towards the solution we need to achieve.  The algorithm is based upon the fact that a table created from a SELECT DISTINCT statement is guaranteed to have a direct relationship with each record of the source table, when compared using the same elements we considered in the SELECT DISTINCT.

The algorithm takes four steps:

I. create the lookup table

	CREATE TABLE lookup ({lookupID} INT NOT NULL auto_increment 
	          primary key, {LOOKUP FIELDS});

	#(and add a key for each {LOOKUP FIELDS})

II. fill in the lookup table
	
	INSERT INTO lookup 
	SELECT DISTINCT NULL {LOOKUP FIELDS} FROM source_table;
	#(the {lookupID} is automatically created, being auto_increment)

III. create the normalized table

	CREATE TABLE norm_table ({source_table FIELDS} - 
	         {LOOKUP FIELDS} + {lookupID}) 

IV. fill in the normalized table

	INSERT INTO normalized table 
	SELECT {source_table FIELDS} - {LOOKUP FIELDS} + {lookupID}
	FROM source_table 
	INNER JOIN lookup 
	    on (source_table.{LOOKUP FIELDS}= lookup.{LOOKUP FIELDS}) 

As you can see, the entire operation is run in the server workspace, thus avoiding problems of (a) fetching records (less network traffic), (b) handling data conversion, (c) memory occupation and (d) efficiency.

Let's see an example.

Having a table MP3 with these fields

 mysql> describe MP3;
 +----------+-------------+------+-----+----------+----------------+
 | Field    | Type        | Null | Key | Default  | Extra          |
 +----------+-------------+------+-----+----------+----------------+
 | ID       | int(11)     |      | PRI | NULL     | auto_increment |
 | title    | varchar(40) |      | MUL |          |                |
 | artist   | varchar(20) |      | MUL |          |                |
 | album    | varchar(30) |      | MUL |          |                |
 | duration | time        |      |     | 00:00:00 |                |
 | size     | int(11)     |      |     | 0        |                |
 | genre    | varchar(10) |      | MUL |          |                |
 +----------+-------------+------+-----+----------+----------------+
 7 rows in set (0.00 sec)

We want to produce two tables, the first one having only [ID, title, duration, size], while the second one should get [artist, album, genre]. (The second one will also needed to be further split into [artist] and [album, genre] but we can deal with that later).

Here are the instructions to normalize this table:

	DROP TABLE IF EXISTS tmp_albums;
	CREATE TABLE tmp_albums (album_id INT NOT NULL AUTO_INCREMENT 
	       PRIMARY KEY, 
	artist varchar(20) not null,
	album varchar(30) not null,
	genre varchar(10) not null, 
	KEY artist (artist), KEY album (album), KEY genre (genre));

	INSERT INTO tmp_albums 
	SELECT DISTINCT NULL, artist,album,genre FROM MP3;

	DROP TABLE IF EXISTS songs;
	CREATE TABLE songs (ID int(11) not null auto_increment,
	title varchar(40) not null,
	duration time not null default '00:00:00',
	size int(11) not null, 
	album_id INT(11) NOT NULL, 
	PRIMARY KEY (ID), KEY title (title), KEY album_id (album_id));
 
	INSERT INTO songs SELECT src.ID, src.title, src.duration, 
	     src.size, album_id 
	FROM MP3 src INNER JOIN tmp_albums lkp 
		ON (src.artist =lkp.artist and src.album =lkp.album 
			and src.genre =lkp.genre);

Eventually, we can use the same technique to normalize the albums into a proper table.

	DROP TABLE IF EXISTS artists;
	CREATE TABLE artists (artist_id INT NOT NULL AUTO_INCREMENT 
	     PRIMARY KEY, 
	artist varchar(20) not null, 
	KEY artist (artist)) ;
	
	INSERT INTO artists 
	SELECT DISTINCT NULL, artist FROM tmp_albums;

	DROP TABLE IF EXISTS albums;
	
	CREATE TABLE albums (album_id int(11) not null auto_increment,
	album varchar(30) not null,
	genre varchar(10) not null, 
	artist_id INT(11) NOT NULL, 
	PRIMARY KEY (album_id), 
	KEY genre (genre), KEY album (album), KEY artist_id (artist_id));
	
	INSERT INTO albums 
	SELECT src.album_id, src.album, src.genre, artist_id 
	FROM tmp_albums src 
	INNER JOIN artists lkp ON (src.artist =lkp.artist);

 mysql> describe artists;
 +-----------+-------------+------+-----+---------+----------------+
 | Field     | Type        | Null | Key | Default | Extra          |
 +-----------+-------------+------+-----+---------+----------------+
 | artist_id | int(11)     |      | PRI | NULL    | auto_increment |
 | artist    | varchar(20) |      | MUL |         |                |
 +-----------+-------------+------+-----+---------+----------------+
 2 rows in set (0.00 sec)
 
 mysql> describe albums;
 +-----------+-------------+------+-----+---------+----------------+
 | Field     | Type        | Null | Key | Default | Extra          |
 +-----------+-------------+------+-----+---------+----------------+
 | album_id  | int(11)     |      | PRI | NULL    | auto_increment |
 | album     | varchar(30) |      | MUL |         |                |
 | genre     | varchar(10) |      | MUL |         |                |
 | artist_id | int(11)     |      | MUL | 0       |                |
 +-----------+-------------+------+-----+---------+----------------+
 4 rows in set (0.00 sec)
 
 mysql> describe songs;
 +----------+-------------+------+-----+----------+----------------+
 | Field    | Type        | Null | Key | Default  | Extra          |
 +----------+-------------+------+-----+----------+----------------+
 | ID       | int(11)     |      | PRI | NULL     | auto_increment |
 | title    | varchar(40) |      | MUL |          |                |
 | duration | time        |      |     | 00:00:00 |                |
 | size     | int(11)     |      |     | 0        |                |
 | album_id | int(11)     |      | MUL | 0        |                |
 +----------+-------------+------+-----+----------+----------------+
 5 rows in set (0.00 sec)
 
It should be clear now WHAT we have to do. Less clear is HOW. The above instructions seem to imply that we manually copy the field structure from the source table to the lookup and normalized tables.

Actually, that SQL code (except the DESCRIBEs) was produced by this very module and printed to the STDOUT, so that all I had to do was some cut-and-paste.
And then we are back to the question of the algorithm. If this is all SQL, where is Perl involved?
The answer is that Perl will reduce the amount of information we need to give to the database engine.
The information about the field structure and indexes is already in the database. Our Perl module (with a [not so] little help from the DBI) can extract the structure from the database and create the appropriate SQL statements.
On the practical side, this means that, before producing SQL code, this module will gather information about the source table. It will issue a "SHOW FIELDS FROM tablename" and a "SHOW INDEX FROM tablename" statements, and parse their results to prepare the operational code.

That's it. It seems a rather small contribution to your average workload, but if you ever have to deal with a project involving several large tables, with many fields, to be transformed into many normalized tables, I am sure you will appreciate the GPL (Golden Perl Laziness) behind this module.

BTW, this is the code used to produce the above SQL statements:

	#!/usr/bin/perl -w
	use strict;

	use DBSchema::Normalizer;

	my $norm = DBSchema::Normalizer->new ({
		DSN  => "DBI:mysql:music;host=localhost;"
			 . "mysql_read_default_file=$ENV{HOME}/.my.cnf", 
	  	src_table     => "MP3",
	  	index_field   => "album_id",
	  	lookup_fields => "artist,album,genre",
	  	lookup_table  => "tmp_albums", 
		dest_table    => "songs",
		copy_indexes  =>  1,
		simulate      =>  1
	 });

	$norm->do();

	$norm->create_lookup_table ({ 
	  src_table     => "tmp_albums",
	  index_field   => "artist_id",
	  lookup_fields => "artist",
	  lookup_table  => "artists"
  	});

	$norm->create_normalized_table ({
	  src_table     => "tmp_albums",
	  lookup_table  => "artists",
	  index_field   => "artist_id",
	  lookup_fields => "artist",
	  dest_table    => "albums"
	});

Twenty-five lines of code. Not bad for such a complicated task. But even that could have been replaced by these two one-liners:

 perl -e 'use DBSchema::Normalizer; DBSchema::Normalizer->snew(qw(localhost music MP3 \ 
       album_id album,artist,genre tmp_albums songs 1 1 1))->do()'
	
 perl -e 'use DBSchema::Normalizer; DBSchema::Normalizer->snew(qw(localhost music \ 
    tmp_albums artist_id artist artists albums 1 1 1))->do()'

(See below item "snew" for more details.)
	
One thing that this module won't do for you, though, is to decide which columns should stay with the source table and which ones should go to the lookup table. This is something for which you need to apply some database theory, and I don't expect you to know it unless you have studied it (unless you happen to be J.F. Codd) either at school or independently.
I am planning (in a very idle and distant way) another module that will analyze a database table and decide if it is a good design or not. The examples from commercial software I have seen so far did not impress me a lot. I am still convinced that humans are better than machines at this task.  But, hey! Ten years ago I was convinced that humans were much better than machines at chess, and instead, not long ago, I had to see an IBM box doing very nasty things to Gary Kasparov. So maybe I'll change my mind. In the meantime, I am enjoying my present intellectual superiority and I keep analyzing databases with the same pleasure that I once felt when solving a chess problem.

=head2 Simulation mode

This module can do the data transfer for you, or you may want to run it in "simulation mode", by adding simulate => "1" to the constructor parameters. When in simulation mode, the DBSchema::Normalizer will just print the necessary SQL statements to STDOUT, without passing them to the database engine. You can thus check the queries and eventually change them and use them within some other application. 

=head2 EXPORT

new, snew, create_lookup_table, create_normalized_table

=head2 DEPENDENCIES

DBI, DBD::mysql

=head2 Architecture

The Normalizer doesn't enforce private data protection. You are only supposed to call the methods which are documented here as public. In the spirit of Perl OO philosophy, nobody will prevent you from calling private methods (the ones beginning with "_") or fiddling with internal hash fields. However, be aware that such behaviour is highly reprehensible, could lead to unpredictable side effects, of which B<You> are entirely, utterly an irrimediably responsible (not to mention that your reputation will be perpetually tarnished, your nephews will call you "Cheating Joe" and you won't be ever - EVER - invited as dinner speaker to any Perl OO conference and even if you manage to sneak in you will find a hair in your soup.)

=head2 PORTABILITY

The algorithm used here is general. It was initially developed in C for an embedded RDBMS and there is no reason to assume that it won't work in any other database engine. However, the information about field types and indexes is, in this module, MySQL dependent. At the moment, I haven't found a clean method to get such information in a database-independent way.
To adapt this module for a different database, corresponding SQL statements for the MYSQL specific SHOW INDEX and SHOW FIELDS should be provided. Also the syntax for INNER JOIN might not be portable across databases.

=head2 CAVEAT

As always, when dealing with databases, some caution is needed. 
The create_lookup_table() method will B<drop the lookup table>, if exists. Be careful about the name you supply for this purpose. If you want to use an existing lookup table (whose data integrity and relational correspondence you can swear upon), then skip the create_lookup_table() and ask only for create_normalized_table(). Also for this one, a B<DROP TABLE> statement is issued before the creation.
Exercise double care on the names you pass to the module. 

Be also aware that the tables created by this module are of default type. You may either choose to convert them after the data transfer or run the Normalizer in "simulation mode" and then manually modify the SQL statements.

The Normalizer will usually warn you (and exit with flags and bells) if one or more designated lookup fields in the source table are not indexed. This fact could result in VERY SLOW PERFORMANCE, even for a reasonably low number of records involved. 
You can choose to ignore this warning, by setting the appropriate parameter, but it is not advisable.

If the source table does not have a primary key (don't laugh, I have seen some of them) then a fatal error is issued, without any possible remedy. The reason is simple. If there is no primary key, the engine doesn't have a way of identifying which rows should go in a JOIN and then your result may have duplicates (and in addition you will be waiting a lot to get it.)

=head2 TO DO

1. Parametrizing the statements for fields and indexes information should improve the chances for
portability. 

	# e.g.: MySQL index information comes in this flavor
	$mysql_index_info = {
	  function_name => "SHOW INDEX FROM $table", 
	  info_names => "Table,Non_unique,Key_name,Index_seq,Col_name" #etc
	};
	# but it is hard to generalize, especially if another database 
	# engine defines
	# as positive (Unique) what here is negative (Non_unique)

Maybe a more effective way would be to have a polymorphic version of DBSchema::Normalizer, with the base class calling abstract subs, which the descendant classes are supposed to implement.
Sounds interesting, even though I feel that I might have some clashes with the DBI.

2. Adding support for intermediate steps in converting should also speed up some ugly cases with nested normalization problems, when the lookup table needs to be further normalized.

3. Adding support for conversion from Zero normal form to First is not straightforward. Some cases are easy to identify and to deal with (e.g. columns Student1, Student2, Student3, StudentN can be converted to column Student_id pointing at a Students table), but others are more subtle and difficult to generalize (e.g. having two column for Male and Female, with yes/no content).

=head2 DISCLAIMER

This software can alter data in your database. If used improperly, it can also damage existing data.
(And so can any most powerful software on your machine, such as Perl itself. Sorry to scare you, but I have to warn users about potential misuse.)
There is B<NO WARRANTY> of any sort on this software. This software is provided "AS IS". 
Please refer to the GPL, GNU General Public License, Version 2, paragraphs 11 and 12, for more details.

=head1 SEE ALSO

DBI, DBD::mysql

=cut

package DBSchema::Normalizer;
use strict;
use warnings;

use DBI;
use DBD::mysql; # This version is MySQL dependent. It could be changed later
use Carp;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(new snew do );
our @EXPORT_OK = qw(create_lookup_table create_normalized_table);

our $VERSION = '0.08'; # 09-Nov-2002

my @_accepted_parameters = qw(dbh DSN username password src_table index_field 
    lookup_fields lookup_table dest_table copy_indexes verbose 
	simulate ignore_warning);

my %_accepted_params = map {$_, 1} @_accepted_parameters;

=head1 Class methods

=over

=item new

 DBSchema::Normalizer->new ({ 
	DSN => $DSN, 
	username => $username, 
	password => $password 
      });

new() - object constructor. Requires a hash reference with at least the following keys

	DSN
	username
	password

Alternatively, you may pass one already initialized database handler

    dbh => $dbh

Optional fields (in the sense that if you omit them here, you must declare them when calling I<create_lookup_table> or I<create_normalized_table>)

	src_table       The table in 1st normal form
	index_field     the index field that we need to create
	                will become foreign key in the source table
	                and primary key in the lookup table
	lookup_fields   the fields depending on the index, 
	                in a comma-separated list
	lookup_table    the lookup table
	dest_table      the Normalized (2nd form) table

Really optional fields. You may not mention them at all. Their default is 0.

	copy_indexes    three values:
	                "no" or "0"    : no indexes are copied
	                "yes" or "1"   : indexes from the source table will
	                                 be immediately replicated to the 
	                                 destination table
	                "later" or "2" : indexes will be created after the 
					                 data transfer,
	                                 as an ALTER TABLE statement. 
	                                 It may speed up the insertion
	                                 for large tables.
	verbose         if "1", messages indicating what is going on
	                will be sent to STDOUT. 
	                Using "2", even more verbose information is 
	                given (all queries printed before execution);
	                Level "3" will also show details about src_table 
	                fields and indexes;
	ignore_warning  if "1", warning on missing indexes on lookup fields 
	                are ignored, and the requested operation carried 
					out even at a price of long waiting. Default "0"
	simulate        if "1", no operation is carried out
	                but the queries are printed to STDOUT (as in 
					verbose => 2)

B<note>: src_table, dest_table and lookup_table B<cannot> be called I<src> or I<lkp>, which are used internally by the Normalizer. If such names are given, a fatal error is issued.

If the keys for src_table, index_field, lookup table and fields are missing, they can (actually they MUST) be later provided by calls to create_lookup_table() and create_normalized_table().

=cut

sub new {
	my $class = shift;
	my $params = shift;
	my $_dbh = undef;
    if (exists $params->{dbh} && defined $params->{dbh}) {
        $_dbh = $params->{dbh}
    }
    else {
        return undef unless defined $params->{DSN};
        $_dbh= DBI->connect($params->{DSN}, $params->{username}, 
		$params->{password}, { RaiseError => 1});
    }
	my $self = bless {
		verbose         => 0,
		copy_indexes    => 0,
		simulate        => 0,
		ignore_warning  => 0,
		_dbh            => $_dbh # Being an object, $_dbh is already 
		                         # a reference. Doesn't need the "\" 
								 # before it.
	}, $class;
	foreach my $key (keys (%$params)) {
		croak "invalid parameter $key \n" unless exists $_accepted_params{$key}; 
		$self->{$key} = $params->{$key};
	}
	if ($self->{simulate} eq "1") {
		$self->{verbose} = "2";
	}
	elsif ($self->{simulate} ne "0") {
		croak "invalid value for <simulate>\n";
	}
	return ($self);
}

=item snew

snew is a shortcut for new(). It is called with parameters passed by position instead of using a hash reference.
It is a "quick-and-dirty" ("dirty" being the operational word) method intended for the impatient who does not want to write a script.
B<Assumes that you have a configuration file for MySQL with username and password>.
Parameters are passed in this order:

	host
	database
	source table
	index field
	lookup fields
	lookup table
	destination table
	copy indexes
	verbose
	simulate
	
Here is an example of one-liner normalization call:
 
 perl -e 'use DBSchema::Normalizer; DBSchema::Normalizer->snew(qw(localhost music MP3 \
    album_id album,artist,genre tmp_albums songs 1 1 1))->do()'

Note: ALL 11 parameters must be passed, or an "use of uninitialized value" error is issued.

This one-liner is equivalent to the following script:
 
	#!/usr/bin/perl 
	no warnings; # Yeah. No warnings. I said it is equivalent, 
				 # not recommended.
	no strict;   # Yup. No strict either. 
	use DBSchema::Normalizer;
	$norm = DBSchema::Normalizer->new ( 
	{
		DSN => "DBI:mysql:music;host=localhost;"
			. "mysql_read_default_file=$ENV{HOME}/.my.cnf", 
	  	src_table     => "MP3",
	  	index_field   => "album_id",
	  	lookup_fields => "artist,album,genre",
	  	lookup_table  => "tmp_albums", 
		dest_table    => "songs",
		copy_indexes  =>  1,
		verbose       =>  1,
		simulate      =>  1,
	 });
	$norm->do();

It is definitely not as safe as the normal call. However, TMTOWTDI, and it's your call. I am using it, but I don't recommend it. Read my lips: I DON'T RECOMMEND IT.

=cut

sub snew { # shortcut new (parameters called by position)
	my ($class, $host, $db, $src_table, $index_field, 
		$lookup_fields,	$lookup_table, $dest_table, 
		$copy_indexes, $verbose, $simulate) = @_;
	my $DSN= "DBI:mysql:$db;host=$host;"
		. "mysql_read_default_file=$ENV{HOME}/.my.cnf";
	return new ($class, {
		DSN           => $DSN,
	  	src_table     => $src_table,
	  	index_field   => $index_field,
	  	lookup_fields => $lookup_fields,
	  	lookup_table  => $lookup_table, 
		dest_table    => $dest_table,
		copy_indexes  => $copy_indexes,
		verbose       => $verbose,
		simulate      => $simulate,
	 });
}

=for internal use
(The Destroyer will clean-up DBI objects.)

=cut

# use Data::Dumper;
sub DESTROY {
	my $self = shift;
	# print STDERR Data::Dumper->Dump([$self],["InDestroyer"]);
	$self->{_dbh}->disconnect();
	undef $self->{_dbh};
}

=item do

do();

do() performs the Normalization according to the parameters already received. Internally calls I<create_lookup_table()> and I<create_normalized_table()>

Will fail if not enough parameters have been supplied to new()

=cut

sub do {
	my $self = shift;
	return 0 unless $self->_init();
	$self->create_lookup_table();
	$self->create_normalized_table();
	return 1;
}

=for internal use
(Checks that given keys in internal blessed hash are defined)

=cut

sub _init_field {
	my $self = shift;
	my @fields = @_;
	my $def = 1;
	foreach (@fields) {
		if (!defined $self->{$_}) {
			$self->_verbose("0", "missing $_\n");
			return 0;
		}
	}
	return 1;
}

=for internal use
(_verbose() will print a message, depending on the currently set verbose level)

=cut

sub _verbose {
	my $self = shift;
	my $level = shift;
	my $msg = shift;
	if ($self->{verbose} >= $level) {
		$msg =~ s/\s+/ /g;
		print STDOUT "$msg\n";
	}
}

=for internal use
(_get_indexes() will find the indexes from src_table and set the internal values _primary_key_fields and _normal_fields_indexes with DML instructions to re-create the indexes within a SQL statement - It will identify multiple and unique keys)

=cut

sub _get_indexes {
	my $self = shift;
	# gets indexes description from the DB engine
	my $DML = "SHOW INDEX FROM $self->{src_table}";
	$self->_verbose("2","#$DML;");
	my $sth = $self->{_dbh}->prepare($DML); 
	$sth->execute();
	my %indexes = (); # list of indexes with associated columns
	my @unique = ();  # list of unique indexes
	my $new_index_added =0;
	my @lu_fields = split /,/, $self->{lookup_fields};
	my %lu_indexes = map { $_ , 0 } @lu_fields;
	while (my $hash_ref = $sth->fetchrow_hashref()) {
		$self->_verbose("3", 
		     "# $hash_ref->{Key_name}\t$hash_ref->{Column_name} ");
		# check that lookup fields have an associated index
		if (exists $lu_indexes{$hash_ref->{Column_name}}) {
			 $lu_indexes{$hash_ref->{Column_name}} = 1;
		 }
		# first, we collect primary key columns
		if ($hash_ref->{Key_name} eq "PRIMARY") {
			# check if primary key column is among the lookup fields
			# and if so, replace any lookup field reference with 
			# the new index (foreign key)
			if (grep {$hash_ref->{Column_name} eq $_} @lu_fields) {
				if (!$new_index_added) {
					$self->{_primary_key_fields} .= "," 
						if $self->{_primary_key_fields} ; 
					$self->{_primary_key_fields} .=$self->{index_field};
					$new_index_added =1;
				}
			}
			else {
				$self->{_primary_key_fields} .= "," 
					if $self->{_primary_key_fields} ; 
				$self->{_primary_key_fields} .=$hash_ref->{Column_name};
			}
		}
		else {
			# collects normal columns indexes, skipping lookup fields
			next if (grep {$hash_ref->{Column_name} eq $_} @lu_fields);
			$indexes{$hash_ref->{Key_name}} .= "," 
				if $indexes{$hash_ref->{Key_name}}; 
			$indexes{$hash_ref->{Key_name}} .=$hash_ref->{Column_name}; 
			push @unique, $hash_ref->{Key_name} 
				if $hash_ref->{Non_unique} eq "0";
		}		
	}
	$self->{_primary_key_fields} = 
	", PRIMARY KEY (" . $self->{_primary_key_fields} . ")" 
		if $self->{_primary_key_fields};
	foreach my $key (keys %indexes) {
		# create the indexes description for SQL
		$self->{_normal_fields_indexes} .= ", ";
		$self->{_normal_fields_indexes} .= " UNIQUE " 
			if grep { $key eq $_ } @unique;
		$self->{_normal_fields_indexes} .= 
			" KEY " . $key ." ($indexes{$key})";
	}
	# check for primary key and keys associated with lookup fields.
	croak "missing primary key in $self->{src_table}\n"
		. " A primary key is needed for this operation\n" 
			unless ($self->{_primary_key_fields});	
	if (grep {$_ == 0} values %lu_indexes) {
		print STDERR "*" x 70, "\n";
		print STDERR 
		"WARNING. the following columns, identified as lookup fields,\n"
		. "ARE NOT INDEXED. This fact will have a huge inpact on "
		. "performance.\n"
		. "Therefore it is advisable to set these indexes before "
		. "continuing\n";
		print STDERR "missing indexes: ",  
			map {"<$_> "} grep {$lu_indexes{$_} == 0} keys %lu_indexes;
		print STDERR "\n";
		print STDERR "*" x 70, "\n";
		if ($self->{ignore_warning}) {
			print STDERR 
			"you chose to ignore this warning and the operation is "
				. "carried out anyway, as you wish\n";
		}
		else {
			croak 
			"missing indexes in lookup fields - operation aborted\n";
		}			     
	}
}

=for internal use
(_get_field_descriptions() will extract data definition from src_table and prepare apt statements to re-create the needed fields in dest_table and lookup_table)

=cut

sub _get_field_descriptions {
	my $self = shift;
	# gets table description from DB engine
	my $DML = "SHOW FIELDS FROM $self->{src_table}"; # DESCRIBE $self->{src_table} would have the same effect
	$self->_verbose("2","#$DML;");
	my $sth = $self->{_dbh}->prepare($DML);
	$sth->execute();
	my @lu_fields = split /,/, $self->{lookup_fields};
	# divide description between normal fields (which will go to the 
	# destination table) and lookup fields (for the lookup table)
	while (my $hash_ref = $sth->fetchrow_hashref()) {
		$self->_verbose("3", "#$hash_ref->{Field}\t$hash_ref->{Type}");
		if (grep {$hash_ref->{Field} eq $_} @lu_fields) {
			$self->{_lookup_fields_description} .= "," 
			    if $self->{_lookup_fields_description} ;
			$self->{_lookup_fields_description} .= $hash_ref->{Field} 
				. " " . $hash_ref->{Type};
			$self->{_lookup_fields_description} .= " not null " 
				unless $hash_ref->{Null};
			$self->{_lookup_fields_description} .= 
				" default " . $self->{_dbh}->quote($hash_ref->{Default})
					if $hash_ref->{Default};
		}
		else {
			$self->{_normal_fields_description} .= "," 
				if $self->{_normal_fields_description} ;
			$self->{_normal_fields_description} .= 
				$hash_ref->{Field} . " " . $hash_ref->{Type};
			$self->{_normal_fields_description} .= " not null " 
				unless $hash_ref->{Null};
			$self->{_normal_fields_description} .= " default " 
				. $self->{_dbh}->quote($hash_ref->{Default}) 
					if $hash_ref->{Default};
			if (lc $hash_ref->{Extra} eq "auto_increment" 
					and $self->{copy_indexes}) 
			{
				$self->{_normal_fields_description} .= 
					" auto_increment ";
			}
			$self->{_non_lookup_fields} .= "," 
				if $self->{_non_lookup_fields} ;
			$self->{_non_lookup_fields} .= $hash_ref->{Field};
		} 
	}
}

=for internal use
(_init() will clean the description fields ane fill them with appropriate calls to _get_field_descriptions() and _get_indexes())
Uncommenting the lines mentioning Data::Dumper will produce useful debug information.

=cut

#use Data::Dumper;	
sub _init {
	my $self = shift;
	return 0 unless $self->_init_field(qw(src_table lookup_table 
		dest_table index_field lookup_fields));
	$self->{lookup_fields} =~ tr/ //d;
	my @lookup_fields = split /,/, $self->{lookup_fields};
	croak "invalid index field" 
		if grep {$self->{index_field} eq $_} @lookup_fields;
	# <src> and <lkp> are the aliases for source and lookup tables used
	# in the final query.
	# Therefore they can't be accepted as normal table names
	croak "<src> and <lkp> are reserved words for this module. "
	. "Please choose a different name\n"
		if grep { /^(:?src|lkp)$/ } ($self->{src_table}, 
			$self->{dest_table}, $self->{lookup_table}); 
	#print STDERR Data::Dumper->Dump([$self], [ ref $self ]),"\n";	<>;
	$self->{$_} =""	foreach (qw(_normal_fields_indexes 
		_lookup_fields_description _non_lookup_fields 
		_normal_fields_description _primary_key_fields));
	$self->_get_field_descriptions();
	$self->_get_indexes 
		if lc $self->{copy_indexes} =~ /^(:?1|2|yes|later)$/;
	#print STDERR Data::Dumper->Dump([$self],["AfterInit"]),"\n"; <>;
	return 1;
}

=for internal use
(gets additional parameters into internal hash)

=cut

sub _get_params {
	my $self = shift;
	# if parameters are provided, they are merged with the internal hash
	# and _init() is called
	if (scalar @_) {
		my $params = shift;
		foreach my $key (keys %$params) {
			croak "invalid parameter $key \n" 
				unless exists $_accepted_params{$key};
			$self->{$key} = $params->{$key};
		}
		if ($self->{simulate} eq "1") {
			$self->{verbose} = "2";
		}
		elsif ($self->{simulate} ne "0") {
			croak "invalid value for <simulate>\n";
		}
		$self->_init();
	}
}

=item create_normalized_table()

create_normalized_table() will create a 2nd normal form table, getting data from a source table and a lookup table.
Lookup fields in the source table will be replaced by the corresponding index field in the lookup table.

If called without parameters, assumes the parameters passed to the object constructor.

Parameters are passed as a hash reference, and are the same given to new() except I<DSN>, I<username> and I<password>. None are compulsory here. The missing ones are taken from the constructor. However, a check is done to ensure that all parameters are passed from either sub.

=cut

sub create_normalized_table {
	my $self = shift;
	$self->_get_params(@_);
	my $join_clause = "";
	my $good_fields = ""; # fields that will be moved to the 
						  # destination table
	# ensure that the fields are called with an appropriate table alias
	foreach (split /,/, $self->{_non_lookup_fields}) {
		$good_fields .= ", " if $good_fields;
		$good_fields .= "src." . $_;
	}
	# create the JOIN clause, using the lookup fields as foreign keys
	foreach (split /,/, $self->{lookup_fields}) {
		$join_clause .= " and " if $join_clause;
		$join_clause .= "src.$_ =lkp.$_";
	}
	# removes any existing table with the same name as dest_table.
	my $DML = "DROP TABLE IF EXISTS $self->{dest_table}";
	$self->_verbose("2", "$DML;");
	$self->{_dbh}->do ("DROP TABLE IF EXISTS $self->{dest_table}");
	# creates the destination table.
	$DML =qq[CREATE TABLE $self->{dest_table} 
		($self->{_normal_fields_description}, 
		$self->{index_field} INT(11) NOT NULL];
	if (defined $self->{copy_indexes} 
			and (lc $self->{copy_indexes} =~ /^(:?1|yes)$/)) 
	{
	 	$DML .= $self->{_primary_key_fields} ;
		$DML .= $self->{_normal_fields_indexes};
	}
	$DML .= qq[, KEY $self->{index_field} ($self->{index_field}))];
	if (defined $self->{copy_indexes} 
			and (lc $self->{copy_indexes} =~ /^(:?2|later)$/)) 
	{
		$DML =~ s/ auto_increment / /;
		print "# auto_increment for $self->{dest_table} needs to "
		. "be set manually\n";
	}
	$self->_verbose("2", "$DML;");
	$self->{_dbh}->do($DML) unless ($self->{simulate});
	# inserts values into the destination table, from the source table 
	# JOINed with the lookup table
	$DML = qq[INSERT INTO $self->{dest_table} 
		SELECT $good_fields, $self->{index_field} 
		FROM $self->{src_table} src
		INNER JOIN $self->{lookup_table} lkp ON ($join_clause)];
	$self->_verbose("2", "$DML;");
	$self->{_dbh}->do($DML) unless ($self->{simulate});
	# if copy indexes was <later>, then an ALTER TABLE statement 
	# is issued.
	if (defined $self->{copy_indexes} 
			and (lc $self->{copy_indexes} =~ /^(:?2|later)$/)) 
	{ 
		$DML = qq[ALTER TABLE $self->{dest_table} ];
		if ($self->{_primary_key_fields}) {
			$self->{_primary_key_fields} =~ s/^\s?,/ADD/;
			$DML .=  $self->{_primary_key_fields};
		}
		if ($self->{_normal_fields_indexes}) {
			$self->{_normal_fields_indexes} =~ s/^\s?,// 
				unless $self->{_primary_key_fields};
			$self->{_normal_fields_indexes} =~ s/,/, ADD /g;
			$DML .= $self->{_normal_fields_indexes};
		}		
		$self->_verbose("2", "$DML;");
	    $self->{_dbh}->do($DML) unless ($self->{simulate});
	}
	$self->_verbose("1", "# $self->{dest_table} created and filled");
}

=item create_lookup_table

create_lookup_table() will create a lookup table, extracting repeating fields from a 1st normal form table. A numeric primary key is created.

When called without parameters, assumes the values passed to the object constructor (I<new>).

Parameters are passed as a hash reference, and should include the following

	src_table      table where to take the values from
	lookup_fields  which fields to take
	lookup_table   table to create
	index_field	   primary key (will be foreign key in src_table) 
                   to be created

=cut

sub create_lookup_table {
	my $self = shift;
	$self->_get_params(@_);
	my $table_keys ="";
	foreach (split /,/, $self->{lookup_fields}) {
		$table_keys .= ", KEY $_ ($_)";
	}
	# removes any existing table with the same name as Lookup_table
	my $DML = qq[DROP TABLE IF EXISTS $self->{lookup_table}];
	$self->_verbose("2", "$DML;");
	$self->{_dbh}->do($DML) unless ($self->{simulate});
	# create the new table
	$DML = qq[CREATE TABLE $self->{lookup_table}
		($self->{index_field} INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
		 $self->{_lookup_fields_description} $table_keys) ];
	$self->_verbose("2", "$DML;");
    $self->{_dbh}->do($DML) unless ($self->{simulate});
	# gets fields from the source table
	$DML = qq[INSERT INTO $self->{lookup_table} 
		SELECT DISTINCT NULL, $self->{lookup_fields} 
		FROM $self->{src_table}];
	$self->_verbose("2", "$DML;");
	$self->{_dbh}->do($DML) unless ($self->{simulate});
	$self->_verbose("1", "# $self->{lookup_table} created and filled");
}

=back

=head1 AUTHOR

Giuseppe Maxia, giuseppe@gmaxia.it

=head1 COPYRIGHT

The DBSchema::Normalizer module is Copyright (c) 2001 Giuseppe Maxia,
Sardinia, Italy. All rights reserved.
 
You may distribute this software under the terms of either the GNU
General Public License version 2 or the Artistic License, as
specified in the Perl README file.
   
The embedded and encosed documentation is released under 
the GNU FDL Free Documentation License 1.1

=cut

1;
