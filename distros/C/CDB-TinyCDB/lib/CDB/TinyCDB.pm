package CDB::TinyCDB;

use 5.007003;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = ();

our @EXPORT = qw();

our $VERSION = '0.05';

require XSLoader;
XSLoader::load('CDB::TinyCDB', $VERSION);

1;
__END__

=encoding utf8

=head1 NAME

CDB::TinyCDB - Perl extension for TinyCDB library to cdb databases

=head1 SYNOPSIS

  use CDB::TinyCDB;

  # open ( direct file access )
  my $cdb = CDB::TinyCDB->open( 'my.cdb' );

  # load ( loads file into memory )
  my $cdb = CDB::TinyCDB->load( 'my.cdb' );

  # returns first occurence of key in file
  print $cdb->get("key");

  # returns all records for key
  print "$_\n" for $cdb->getall("key");

  # returns last record for key
  print $cdb->getlast("key");

  # checks if key exists
  print $cdb->exists("key");

  # iterates over all entries
  while ( my ($key, $value) = $cdb->each ) {
    # same as cdb -d my.cdb, but skips null keys
    printf("+%d,%d:%s->%s\n", length($key), length($value), $key, $value);
  }

  # returns all keys (skips null keys)
  print "$_\n" for $cdb->keys;

or

  use CDB::TinyCDB;

  # open/load for updating - loads all existing records into temp file
  my $cdb = CDB::TinyCDB->open( 'my.cdb', for_update => "my.cdb.$$" );
  my $cdb = CDB::TinyCDB->load( 'my.cdb', for_update => "my.cdb.$$" );

  # add new records (allows duplicates)
  print "records added: ", $cdb->put_add( k1, 'value1'); # 1
  print "records added: ", $cdb->put_add( k1 => 'value1', k2 => 'value2' ); # 2

  # replace and remove old records
  print "records replaced: ", $cdb->put_replace( k3, 'value3'); # 0
  print "records replaced: ", $cdb->put_replace( key, 'value'); # 1

  # replace and fill with null old records
  print "records replaced: ", $cdb->put_replace0( k2, 'value3'); # 1

  # add and warn if record previously existed
  print "records added: ", $cdb->put_warn( k1, 'value4'); # 1
  # warns: Key k1 already exists - added anyway

  # checks if key exists
  print $cdb->exists("k1");

  # dies if record already existed
  eval {
      $cdb->put_insert( k1, 'value1');
  };
  if ( $@ ) {
    print "k1 wasn't added: $@\n"; # Unable to insert new record - key exists
  }
  
  # commit changes and reopen/reload db - temp file replaces my.cdb
  $cdb->finish( save_changes => 1, reopen => 1);
  # same as
  $cdb->finish();

  print $cdb->getlast("k1"); # value4 

  # finish without saving changes
  $cdb->finish( save_changes => 0 );

  # finish without reopening file
  $cdb->finish( reopen => 0 );

or

  use CDB::TinyCDB;

  # create new cdb file
  my $cdb = CDB::TinyCDB->create( 'my-new.cdb', "my-new.cdb.$$" );

  # add new records (allows duplicates)
  print "records added: ", $cdb->put_add( k1, 'value1'); # 1
  print "records added: ", $cdb->put_add( k1 => 'value1', k2 => 'value2' ); # 2

  # replace and remove old records
  print "records replaced: ", $cdb->put_replace( k3, 'value3'); # 0
  print "records replaced: ", $cdb->put_replace( key, 'value'); # 1

  # replace and fill with null old records
  print "records replaced: ", $cdb->put_replace0( k2, 'value3'); # 1

  # add and warn if record previously existed
  print "records added: ", $cdb->put_warn( k1, 'value4'); # 1
  # warns: Key k1 already exists - added anyway

  # checks if key exists
  print $cdb->exists("k1");

  # dies if record already existed
  eval {
      $cdb->put_insert( k1, 'value1');
  };
  if ( $@ ) {
    print "k1 wasn't added: $@\n"; # Unable to insert new record - key exists
  }
  
  # commit changes and reopen/reload db - temp file replaces my-new.cdb
  $cdb->finish( save_changes => 1 );
  # same as
  $cdb->finish();

  # reading is not allowed in create mode
  print $cdb->getlast("k1"); # dies


=head1 DESCRIPTION

CDB::TinyCDB is a perl extension for TinyCDB library to query and create CDB
files;

=head1 Query interface

TinyCDB supports two variants of query interface - first that maps the cdb file
into memory (using L<mmap(2)> on *nixes and I<MapViewOfFile> on Windows) and
the second one which reads file directly from disk. 

=head2 load (Query interface 1)

Loads the CDB into memory - designed to be efficient for multiple queries.

  my $cdb = CDB::TinyCDB->load( 'my.cdb' );

=head2 open (Query interface 2)

Opens file and acceses it using L<read(2)> and L<seek(2)> - designed to be
efficient for single queries or if cdb file is huge.

  my $cdb = CDB::TinyCDB->open( 'my.cdb' );

=head2 Query methods

Both L<load|"load (Query interface 1)"> and L<open|"open (Query interface 2)">
support same query methods (even though TinyCDB doesn't support some of them
in L<open mode|"open (Query interface 2)">).

=over 4

=item get

  print $cdb->get("key");

Returns first occurence of key in file.

=item getall

  print "$_\n" for $cdb->getall("key");

Returns all records for given key.

=item getlast

  print $cdb->getlast("key");

Returns last record for key. Useful if there are duplicated records added by
L<"put_add">.

=item exists

  print $cdb->exists("key");

Returns if key exists in file.

=item each

  while ( my ($key, $value) = $cdb->each ) {
    printf("+%d,%d:%s->%s\n", length($key), length($value), $key, $value);
  }

Iterates over all entries in file. Maintains the current position in file, so
while iterating please don't call other methods.

Note: CDB allows to have duplicated keys, so don't use it directly to create
hashes.

Note: it doesn't return records with zero length keys (most likely replaced by
L<"put_replace0">).

=item keys

  print "$_\n" for $cdb->keys;

Returns all keys.

Note: CDB allows to have duplicated keys, so don't use it directly to create
hashes.

Note: it doesn't return records with zero length keys (most likely replaced by
L<"put_replace0">).

=back

=head1 Create interface

CDB database file is created in two steps: first, temporary file created and
written to disk, and second, that temporary file is renamed to permanent
place.  Unix  L<rename(2)>  call is atomic operation, it removes destination
file if any AND renames another file in one step. This way it is guaranteed
that readers will not see incomplete database.  To prevent multiple
simultaneous updates, locking may also be used.

Note: L<rename(2)> requires that both files are on the same filesystem.

=head2 Create methods

In create mode no query methods can be used. The only exception is
L<"exists">, but it may significantly slow down the whole process, as it
currently flushes internal buffer to disk on every call with key those hash
value already exists in db.

=over 4

=item create

  my $cdb = CDB::TinyCDB->create( 'my-new.cdb', "my-new.cdb.$$" );

Creates new cdb file (my-new.cdb) and uses temporary file until changes are
committed (my-new.cdb.$$).

=item put_add

  print "records added: ", $cdb->put_add( k1, 'value1'); # 1
  print "records added: ", $cdb->put_add( k1 => 'value1', k2 => 'value2' ); # 2
  print "records added: ", $cdb->put_add( %hash ); # scalar keys %hash 

Adds new records and returns number of records added. No duplicate checking
will be performed - allowing duplicate keys to exists.

=item put_replace

  print "records replaced: ", $cdb->put_replace( k3, 'value3'); # 0
  print "records replaced: ", $cdb->put_replace( key, 'value'); # 1

If the key already exists, it will be removed from the database before adding
new key,value pair.  This requires moving data in the file, and can be  quite
slow if the file is large.  All matching old records will be removed this way.

Returns number of records replaced.

=item put_replace0

  print "records replaced: ", $cdb->put_replace0( k2, 'value3'); # 1

If the key already exists and it isn't the last record in the file, old
record will be zeroed out before adding new key,value pair.  This is alot
faster than L<"put_replace">, but some extra data will still be present in the
file. The data -- old record -- will not be accessible by normal searches, but
will appear in direct file dumps (cdb -d).

=item put_insert

  # dies if record already existed
  eval {
      $cdb->put_insert( k1, 'value1');
  };
  if ( $@ ) {
    print "k1 wasn't added: $@\n"; # Unable to insert new record - key exists
  }
  
Add key,value pair only if such key does not exists in a database.  Note
that since query (see L<"get"> above) will find first added record, this
mode is somewhat useless (but allows to reduce database size in case of
repeated keys). This is the same as calling L<"exists"> followed by
L<"put_add"> if the key was not found.

=item put_warn

  print "records added: ", $cdb->put_warn( k1, 'value4'); # 1
  # warns: Key k1 already exists - added anyway

Add key,value pair unconditionally, but also check if this key already exists.
This is equivalent of calling L<"exists">, printing a warning if key exists,
and unconditionally followed by L<"put_add">.

=item finish

  $cdb->finish();

Commits changes and renames temp file into chosen CDB file. Allows to abort
changes when called like this:

  $cdb->finish( save_changes => 0 );

=back

=head1 Update interface

Although TinyCDB doesn't support updating already existent files L<CDB::TinyCDB>
provides inteface to do so.

  my $cdb = CDB::TinyCDB->open( 'my.cdb', for_update => "my.cdb.$$" );
  my $cdb = CDB::TinyCDB->load( 'my.cdb', for_update => "my.cdb.$$" );

Depending on the L<query method|"Query interface"> used CDB will be reopened
or reloaded after changes are committed.

On startup it loads all existing records into temp file, where new records will be
added. Until changes are committed the query methods will be used against the
old file.

=head2 Update query methods

=over 4

=item get

=item getall

=item getlast

=item exists

=item each

=item keys

Allows querying the old file - for all above please see L<"Query methods">.

Note: L<"exists"> however will check against temp file.

=back

=head2 Update create methods

=over 4

=item put_add

=item put_replace

=item put_replace0

=item put_insert

=item put_warn

Add new records - for all above please see L<"Create methods">.

=item finish

  $cdb->finish();

Commits changes and renames temp file into chosen CDB file, which will be then
reopened/reloaded.

Allows to abort changes with:

  $cdb->finish( save_changes => 0 );

Allows to abort file reloading with:

  $cdb->finish( reopen => 0 );

Note: both params can be used together in single call.

=back

=head1 EXPORT

None by default.

=head1 TinyCDB INSTALLATION

Please see README file if you need to install it from sources.

=head1 SEE ALSO

=over 4

=item L<CDB_File> 

Use tied hashes for accessing cdb files - doesn't require external libraries.

=item L<http://www.corpit.ru/mjt/tinycdb.html>

TinyCDB home page. Some methods description were copied from there.

=back

=head1 AUTHOR

Alex J. G. Burzyński, E<lt>ajgb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Alex J. G. Burzyński

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
