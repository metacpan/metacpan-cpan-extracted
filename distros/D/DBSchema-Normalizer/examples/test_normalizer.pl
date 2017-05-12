#!/usr/bin/perl -w
# #########################
# 
# test_normalizer.pl
# (C) Giuseppe Maxia 2001
# released under GPL
# 
# ############################################
# 
# example of usage for module Normalizer.pm
# for more information, read 
# perldoc DBSchema::Normalizer
# under "Algorithm"
# 
# (don't try to see this example with perldoc. 
# An editor with syntax highlighting will do)
#
# ############################################

use strict;

use DBSchema::Normalizer 0.08;

=pod instantiating a DBSchema::Normalizer object

 This DSN works only if you have a configuration file in your home directory.
 Please refer to MySQL manual (http://www.mysql.com/documentation) for more info.

 In case you don't have such file, replace the first item with the following:

 DSN      => "DBI:mysql:music;host=localhost",
 username => "yourusername",
 password => "yourpasswd"

=cut

=pod

# calling the constructor with DSN parameters
# 
my $norm = DBSchema::Normalizer->new ( 
	{
		DSN           => "DBI:mysql:music;host=localhost"  # change database and host if different
						 . ";mysql_read_default_file=$ENV{HOME}/.my.cnf", # see comments above
	  	src_table     => "MP3",
	  	index_field   => "album_id",
	  	lookup_fields => "artist,album,genre",
	  	lookup_table  => "tmp_albums", 
		dest_table    => "songs",
		verbose       =>  2, # A LOT of information. Change to "1" to reduce it
		copy_indexes  =>  1, # if "1", indexes are recreated into dest_table before data insertion
		simulate      =>  1  # Does not perform anything on the database, but only print the SQL statements
	 });

=cut


# New constructor available in 0.08, passing a database handler
#
my $dbh = DBI->connect("DBI:mysql:music;host=localhost"
    . ";mysql_read_default_file=$ENV{HOME}/.my.cnf", undef, undef, {RaiseError=>1});

my $norm = DBSchema::Normalizer->new ( 
	{
		dbh           => $dbh,
	  	src_table     => "MP3",
	  	index_field   => "album_id",
	  	lookup_fields => "artist,album,genre",
	  	lookup_table  => "tmp_albums", 
		dest_table    => "songs",
		verbose       =>  2, # A LOT of information. Change to "1" to reduce it
		copy_indexes  =>  1, # if "1", indexes are recreated into dest_table before data insertion
		simulate      =>  0  # Does not perform anything on the database, but only print the SQL statements
	 });



=pod carrying out the actions

 This instruction will perform what we have told the constructor:
 1. create a lookup table "tmp_album" with primary key 'album_id'
    and fields 'artist', 'album' and 'genre'
 2. create a destination table "songs", containing all fields
    from "MP3", except 'artist', 'album' and 'genre', plus a
    field 'album_id', which is foreign key for the lookup table
 3. fill in the table "songs" JOINing information from the
    source table and the lookup table.

=cut
 
$norm->do();	

=pod the alternative approach

 This is the alternative approach. Instead of creating a new DBSchema::Normalizer object,
 we use the existing one, but changing the parameters.
 Notice that the values for 'verbose', 'copy_indexes' and 'simulate' are taken
 from the constructor, but you may change them.
 'DSN', 'username' and 'password' will be recognized as valid keywords, but 
 not used. If you need to change them set up another constructor.

=cut

$norm->create_lookup_table ( 
	{ 
	  src_table     => "tmp_albums",
	  index_field   => "artist_id",
	  lookup_fields => "artist",
	  lookup_table  => "artists"
  	});

$norm->create_normalized_table (
	{
	  src_table     => "tmp_albums",
	  lookup_table  => "artists",
	  index_field   => "artist_id",
	  lookup_fields => "artist",
	  dest_table    => "albums"
	});

