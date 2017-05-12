package DBIx::FileStore;
use strict;

# this reads and writes files from the db.  
use DBI;
use Digest::MD5 qw( md5_base64 );
use File::Copy;

use DBIx::FileStore::ConfigFile;

use fields qw(  dbh dbuser dbpasswd 
                dbhost dbname filetable blockstable  blocksize 
                verbose 
                confhash
                uselocks
                );

our $VERSION = '0.29';  # version also mentioned in POD below.

sub new {
    my ($self, %opts) = @_;
    unless (ref $self) {
        $self = fields::new($self);
    }
    if ($opts{verbose}) { $self->{verbose}=1; }

    my $config_reader = new DBIx::FileStore::ConfigFile();
    my $conf = $self->{confhash} = $config_reader->read_config_file();

    # FOR TESTING WITH 1 BYTE BLOCKS
    #my $block_size = 1; # 1 byte blocks (!)
    my $block_size = 500 * 1024;        # 512K blocks
    $self->{blocksize}   = $block_size;

    #   with 900K (or even 600K) blocks, when inserting binary .rpm files, 
    #   we get
    #
    #   DBD::mysql::db do failed: Got a packet bigger than 'max_allowed_packet' bytes.
    #
    #   We think there's some encoding of the binary data going 
    #   that inflates binary data during transmission. 
    #
    

    ###############################################################################
    # By default, WE DON'T USE LOCKS ANY MORE. Like a real filesystem, you might
    # get interspersed or truncated information if the filesystem is
    # being changed while you're reading!
    ###############################################################################
    $self->{uselocks}    = 0;

    $self->{dbuser}      = $conf->{dbuser} || die "$0: no dbuser set\n";
    $self->{dbpasswd}    = $conf->{dbpasswd} || warn "$0: no dbpasswd set\n";    # this could be ok.
    $self->{dbname}      = $conf->{dbname} || die "$0: no dbname set\n";

    # dbhost defaults to 127.0.0.1
    $self->{dbhost}      = $conf->{dbhost} || "127.0.0.1";

    $self->{filetable}   = "files";
    $self->{blockstable} = "fileblocks";

    my $dsn = "DBI:mysql:database=$self->{dbname};host=$self->{dbhost}";

    my %attr  = ( RaiseError => 1, PrintError => 1, AutoCommit => 1 );  # for mysql

    $self->{dbh} = DBI->connect_cached( 
        $dsn, $self->{dbuser}, $self->{dbpasswd}, \%attr);  
    $self->{dbh}->{mysql_auto_reconnect} = 1;   # auto reconnect

    return $self;
}

sub get_all_filenames {
    my ($self) = @_;
    my $files = $self->{dbh}->selectall_arrayref( # lasttime + 0 gives us an int back
                "select name, c_len, c_md5, lasttime+0 from $self->{filetable} 
                where b_num=0 order by name");
    return $files;
}

sub get_filenames_matching_prefix {
    my ($self, $name) = @_;
    my $pattern = $name . "%"; 
    my $files = $self->{dbh}->selectall_arrayref( # lasttime + 0 gives us an int back
        "select name, c_len, c_md5, lasttime+0 from $self->{filetable} 
         where name like ? and b_num=0 order by name", {}, $pattern);
    return $files;
}

sub rename_file {
    my ($self, $from, $to) = @_;
    die "$0: name not ok: $from" unless name_ok($from);
    die "$0: name not ok: $to" unless name_ok($to);
    # renames the rows in the filetable and the blockstable
    my $dbh = $self->{dbh};
    $self->_lock_tables();

    for my $table ( ( $self->{filetable}, $self->{blockstable} ) ) {
        my $sql = "select name from $table where name like ?";
        $sql .= " order by b_num" if $table eq $self->{filetable};

        my $files = $dbh->selectall_arrayref( $sql, {}, $from . " %");
        for my $f (@$files) {
            (my $num = $f->[0]) =~ s/.* //;
            print "$0: Moving $table:$f->[0], (num $num) to '$to $num'...\n" if $self->{verbose};
            $dbh->do("update $table set name=? where name=?", {}, "$to $num", $f->[0]);
        }
    }

    $self->_unlock_tables();
    return 1;
}

sub delete_file {
    my ($self, $name) = @_;
    die "$0: name not ok: $name" unless name_ok($name);

    my $dbh         = $self->{dbh};
    my $filetable   = $self->{filetable};        # probably "files"
    my $blockstable = $self->{blockstable};    # probably "fileblocks"
    for my $table ( ( $filetable, $blockstable ) ) {
        my $rv = int($dbh->do( "delete from $table where name like ?", {}, "$name %" ));
        if($rv) {
            print "$0: $table: deleted $name ($rv blocks)\n" if $self->{verbose};
        } else {
            warn  "$0: no blocks to delete for $table:$name\n" if $self->{verbose};
        }
    }
    return 1;
}


sub copy_blocks_from_db_to_filehandle {
    my ($self, $fdbname, $filehandle) = @_;
    die "$0: name not ok: $fdbname" unless name_ok($fdbname);
    my $print_to_filehandle_callback = sub {    
        # this is a closure, so $fh comes from the surrounding context
        my $content = shift;
        print $filehandle $content;
    };
    # read all our blocks, calling our callback for each one
    my $ret = $self->_read_blocks_from_db( $print_to_filehandle_callback, $fdbname ); 
    return $ret;
}


# reads the content into $pathname, returns the length of the data read.
sub read_from_db {
    my ($self, $pathname, $fdbname) = @_;

    die "$0: name not ok: $fdbname" unless name_ok($fdbname);

    open( my $fh, ">", $pathname) || die "$0: can't open for output: $pathname\n";

    # this is a function used as a callback and called with each chunk of the data 
    # into a temporary file.  $fh stay in context for the function (closure) below.
    my $print_to_file_callback = sub {    
        # this is a closure, so $fh comes from the surrounding context
        my $content = shift;
        print $fh $content;
    };

    # read all our blocks, calling our callback for each one
    my $ret = $self->_read_blocks_from_db( $print_to_file_callback, $fdbname ); 

    # if we fetched *something* into our scoped $fh to the temp file,
    # then copy it to the destination they asked for, and delete
    # the temp file.
    if (!$fh) {  
        warn "$0: not found in FileDB: $fdbname\n";
    } 
    # clear our fh member
    close($fh) if defined($fh);  # this 'close' should cause the associated file to be deleted
    $fh = undef;

    # return number of bytes read.
    return $ret;    
}


# my $bytes_written = $self->write_to_db( $localpathname, $filestorename );
sub write_to_db {
    my ($self, $pathname, $fdbname) = @_;

    die "$0: name not ok: $fdbname" unless name_ok($fdbname);

    open(my $fh, "<" , $pathname) 
        || die "$0: Couldn't open: $pathname\n";
    

    my $total_length = -s $pathname;   # get the length 
    if ($total_length == 0) { warn "$0: warning: writing 0 bytes for $pathname\n"; }

    my $bytecount = $self->write_from_filehandle_to_db( $fh, $fdbname );

    die "$0: file length didn't match written data length for $pathname: $bytecount != $total_length\n"
        if ($bytecount != $total_length);

    close ($fh) || die "$0: couldn't close: $pathname\n";
    return $total_length;
}

sub write_from_filehandle_to_db {
    my ($self, $fh, $fdbname) = @_;

    my $ctx = Digest::MD5->new; 
    my $dbh = $self->{dbh};
    my $filetable = $self->{filetable};
    my $blockstable = $self->{blockstable};
    my $verbose = $self->{verbose};
    my $size = 0;

    $self->_lock_tables();
    for( my ($bytes,$part,$block) = (0,0,"");           # init
    $bytes = read($fh, $block, $self->{blocksize});    # test 
    $part++, $block="" ) {                              # increment
        $ctx->add( $block );
        $size += length( $block );
        my $b_md5 = md5_base64( $block );

        printf("saving from filehandle into '%s $part'\n", $fdbname )
            if($verbose && $part%25==0); 

        my $name = sprintf("%s %05d", $fdbname, $part);
        $dbh->do("replace into $filetable set name=?, c_md5=?, b_md5=?, c_len=?, b_num=?", {}, 
            $name, "?", $b_md5, 0, $part);
        $dbh->do("replace into $blockstable set name=?, block=?", {}, 
            $name, $block);
    }
    print "\n" if $verbose;
    $dbh->do( "update $filetable set c_md5=?, c_len=? where name like ?", {}, $ctx->b64digest, $size, "$fdbname %" );
    $self->_unlock_tables();

    return $size;
}


#  From here below is utility code and implementation details
# returns the length of the data read,
# calls &$callback( $block ) for each block read.
sub _read_blocks_from_db {
    my ($self, $callback, $fdbname) = @_;
        # callback is called on each block, like &$callback( $block )
    die "$0: name not ok: $fdbname" unless name_ok($fdbname);
    my $dbh = $self->{dbh};
    my $verbose = $self->{verbose};
    my $ctx = Digest::MD5->new();
    
    warn "$0: Fetching rows $fdbname" if $verbose;
    $self->_lock_tables();
    my $cmd = "select name, b_md5, c_md5, b_num, c_len from $self->{filetable} where name like ? order by b_num";
    my @params = ( $fdbname . ' %' );
    my $sth = $dbh->prepare($cmd);
    my $rv =  $sth->execute( @params );
    my $rownum = 0;
    my $c_len  = 0;
    my $orig_c_md5;
    while( my $row = $sth->fetchrow_arrayref() ) {
        $c_len  ||= $row->[5];
        unless ($row && defined($row->[0])) {
            warn "$0: Error: bad row returned?";
            next;
        }
        print "$row->[0]\n" if $verbose;
        unless ($row->[0] =~ /\s+(\d+)$/) {
            warn "$0: Skipping block that doesn't match ' [0-9]+\$': $row->[0]";
            next;
        }
        my $name_num = $1;
        $orig_c_md5 ||= $row->[2];

        # check the MD5...
        if ($row->[2] ne $orig_c_md5) { die "$0: Error: Is DB being updated? Bad content md5sum for $row->[0]\n"; }
        die "$0: Error: our count is row num $rownum, but file says $name_num" 
            unless $rownum == $name_num;
        
        my ($block) =  $dbh->selectrow_array("select block from fileblocks where name=?", {}, $row->[0]);
        die "$0: Bad MD5 checksum for $row->[0] ($row->[1] != " . md5_base64( $block ) 
            unless ($row->[1] eq md5_base64( $block ));
        $ctx->add($block);

        &$callback( $block );   # call the callback, and pass it the block!

        $rownum++;
    }
    $self->_unlock_tables();

    my $retrieved_md5 = $ctx->b64digest();
    die "$0: Bad MD5 checksum for $fdbname ($retrieved_md5 != $orig_c_md5)"
        unless ($retrieved_md5 eq $orig_c_md5);
        
    return $c_len;  # for your inspection
}


sub _lock_tables {
    my $self = shift;
    if ($self->{uselocks}) {
        $self->{dbh}->do("lock tables $self->{filetable} write, $self->{blockstable} write");
    }
}
sub _unlock_tables {
    my $self = shift;
    if ($self->{uselocks}) {
        $self->{dbh}->do("unlock tables");
    }
}


# warns and returns 0 if passed filename ending with like '/tmp/file 1'
# else returns 1, ie, that the name is OK
# Note that this is a FUNCTION, not a METHOD
sub name_ok {
    my $file = shift;
    if (!defined($file) || $file eq "" ) {
        warn "$0: Can't use empty filename\n";
        return 0;
    }
    if ($file && $file =~ /\s/) {
        warn "$0: Can't use filedbname containing whitespace\n";
        return 0;
    }
    if (length($file) > 75) {
        warn "$0: Can't use filedbname longer than 75 chars\n";
        return 0;
    }
    return 1;
}

1;

=pod

=head1 NAME

DBIx::FileStore - Module to store files in a DBI backend

=head1 VERSION

Version 0.29

=head1 SYNOPSIS

Ever wanted to store files in a database? 

This code helps you do that.

All the fdb tools in script/ use this library to 
get at file names and contents in the database.

To get started, see the README file (which includes a QUICKSTART
guide) from the DBIx-FileStore distribution.  

This document details the DBIx::FileStore module implementation.

=head1 FILENAME NOTES

The name of the file in the filestore cannot contain spaces.

The maximum length of the name of a file in the filestore
is 75 characters.

You can store files under any name you wish in the filestore. 
The name need not correspond to the original name on the filesystem.

All filenames in the filestore are in one flat address space.
You can use / in filenames, but it does not represent an actual
directory. (Although fdbls has some support for viewing files in the 
filestore as if they were in folders. See the docs on 'fdbls' 
for details.)


=head1 METHODS

=head2 new DBIx::FileStore()

my $filestore = new DBIx::FileStore();

returns a new DBIx::FileStore object

=head2 get_all_filenames()

my $fileinfo_ref = $filestore->get_all_filenames()

Returns a list of references to data about all the files in the
filestore. 

Each row consist of the following columns:
  name, c_len, c_md5, lasttime_as_int

=head2 get_filenames_matching_prefix( $prefix )

my $fileinfo_ref = get_filenames_matching_prefix( $prefix );

Returns a list of references to data about the files in the 
filestore whose name matches the prefix $prefix.

Returns a list of references in the same format as get_all_filenames().

=head2 read_from_db( $filesystem_name, $storage_name);

my $bytecount = $filestore->read_from_db( "filesystemname.txt", "filestorename.txt" );

Copies the file 'filestorename.txt' from the filestore to the file filesystemname.txt
on the local filesystem.

=head2 rename_file( $from, $to );

my $ok = $self->rename_file( $from, $to );

Renames the file in the database from $from to $to.
Returns 1;

=head2 delete_file( $fdbname );

my $ok = $self->delete_file( $fdbname );

Removes data named $filename from the filestore.

=head2 copy_blocks_from_db_to_filehandle()

my $bytecount = $filestore->copy_blocks_from_db_to_filehandle( $fdbname, $fh );

copies blocks from the filehandle $fh into the fdb at the name $fdbname

=head2 _read_blocks_from_db( $callback_function, $fdbname );

my $bytecount = $filestore->_read_blocks_from_db( $callback_function, $fdbname );

** Intended for internal use by this module. ** 

Fetches the blocks from the database for the file stored under $fdbname,
and calls the $callback_function on the data from each one after it is read.

It also confirms that the base64 md5 checksum for each block and the file contents
as a whole are correct. Die()'s with an error if a checksum doesn't match.

If uselocks is set, lock the relevant tables while data is extracted. 

=head2 write_to_db( $localpathname, $filestorename );

my $bytecount = $self->write_to_db( $localpathname, $filestorename );

Copies the file $localpathname from the filesystem to the name
$filestorename in the filestore.

Locks the relevant tables while data is extracted. Locking should probably 
be configurable by the caller.

Returns the number of bytes written. Dies with a message if the source
file could not be read. 

Note that it currently reads the file twice: once to compute the md5 checksum
before insterting it, and a second time to insert the blocks.

=head2 write_from_filehandle_to_db ($fh, $fdbname)

Reads blocks of the appropriate block size from $fb and writes them 
into the fdb under the name $fdbname.
Returns the number of bytes written into the filestore.

=head1 FUNCTIONS

=head2 name_ok( $fdbname )

my $filename_ok = DBIx::FileStore::name_ok( $fdbname )

Checks that the name $fdbname is acceptable for using as a name
in the filestore. Must not contain spaces or be over 75 chars.

=head1 IMPLEMENTATION

The data is stored in the database using two tables: 'files' and 
'fileblocks'.  All meta-data is stored in the 'files' table, 
and the file contents are stored in the 'fileblocks' table.

=head2 fileblocks table

The fileblocks table has only three fields:

=head3 name 

The name of the block, exactly as used in the fileblocks table. 
Always looks like "filename.txt <BLOCKNUMBER>",
for example "filestorename.txt 00000".

=head3 block

The contents of the named block. Each block is currently set
to be 512K.  Care must be taken to use blocks that are 
not larger than mysql buffers can handle (in particular, 
max_allowed_packet).

=head3 lasttime

The timestamp of when this block was inserted into the DB or updated.

=head2 files table

The files table has several fields. There is one row in the files table 
for each row in the fileblocks table-- not one per file (see IMPLEMENTATION 
CAVEATS, below). The fields in the files table are:

=head3 c_len 

Content length. The content length of the complete file (sum of length of all the file's blocks).

=head3 b_num

Block number. The number of the block this row represents. The b_num is repeated as a five
(or more) digit number at the end of the name field (see above). We denormalize
the data like this so we can quickly and easily find blocks by name or block number.

=head3 b_md5

Block md5. The md5 checksum for the block (b is for 'block') represented by this row.
We use base64 encoding (which uses 0-9, a-z, A-Z, and a few other characters)
to represent md5's because it's a little shorter than the hex 
representation. (22 vs. 32 characters)

=head3 c_md5

Content md5. The base64 md5 checksum for the whole file (c is for 'content') represented by this row.

=head3 lasttime

The timestamp of when this row was inserted into the DB or updated.

=head2 See the file 'table-definitions.sql' for more details about 
the db schema used.

=head1 IMPLEMENTATION CAVEATS

DBIx::FileStore is what I would consider production-grade code, 
but the overall wisdom of storing files in blobs in a mysql database
may be questionable (for good reason).  

That having been said, if you have a good reason to do so, as long 
as you understand the repercussions of storing files in 
your mysql database, then this toolkit offers a stable and 
flexible backend for binary data storage, and it works quite nicely. 

If we were to redesign the system, in particular we might reconsider 
having one row in the 'files' table for each block stored in the 
'fileblocks' table.  Perhaps instead, we'd have one entry in 
the 'files' table per file.

In concrete terms, though, the storage overhead of doing it this way
(which only affects files larger than the block size, which defaults
to 512K) is about 100 bytes per block.  Assuming files larger than
512K, and with a conservative average block size of 256K, the extra 
storage overhead of doing it this way is still only about 0.039% 

=head1 AUTHOR

Josh Rabinowitz, C<< <Josh Rabinowitz> >>

=head1 SUPPORT

You should probably read the documentation for the various filestore command-line
tools:

L<fdbcat>, L<fdbget>, L<fdbls>, L<fdbmv>, L<fdbput>, L<fdbrm>, L<fdbslurp>, L<fdbstat>, and L<fdbtidy>.

=over 4

=item * Search CPAN

You can also read the documentation at:

L<http://search.cpan.org/dist/DBIx-FileStore/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2015 Josh Rabinowitz.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of DBIx::FileStore

