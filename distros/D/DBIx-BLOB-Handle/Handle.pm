package DBIx::BLOB::Handle; 

use base qw( IO::Handle IO::Seekable );
use strict;
use vars qw( $VERSION );
use warnings;
use Symbol;
use DBI;

$VERSION = '0.2';

sub import {
    my $class = shift;
    if( grep { $_ eq ':INTO_STATEMENT' } @_ ){
        # Danger! Pretend the DBI statement class can provide blobs as handles
        no warnings;
        *DBI::st::blob_as_handle = sub {
            return "$class"->new(@_);
        };
    }
}

# required is the DBI statement
# optional is the 0 based column index that contains the blob (default = 0)
# optional is the blocksize to be read from the database (default = 4096)
sub new {
	my($self, $sth, $field, $blocksize) = @_;
    $self = ref $self || $self;
    my $s = Symbol::gensym;
    tie $$s,$self,$sth,$field,$blocksize;
    return bless $s, $self;
}

sub TIEHANDLE {
    my $class = shift;
    return bless {sth       => shift
                 ,field     => shift || 0
                 ,blocksize => shift || 4096
                 ,pos       => 0
                 ,eof       => 0
                 ,line      => undef
                 ,lines_ref => []
                 },$class;
}

sub READLINE {
    my $self = shift;
    my $buf;
    ( my $sep = $/ ) ||= '';
    unless( $sep ){ # more efficient if we want to slurp the whole lot
        my @frags;
        while( ! $self->{eof} ){
            READ($self, $buf);
            last if $self->{eof};
            push @frags, $buf;
        }
        $. = ++$self->{line};
        wantarray ? return ( join('',@frags) ) : return join('',@frags);
    }
    elsif(wantarray){
        while( ! $self->{eof} ){
            READ($self,$buf);
            my $lines = pop( @{$self->{lines_ref}} ) . $buf;
            push @{$self->{lines_ref}}, $lines =~ /(.*?$sep|.+)/gs;           
        }
        $. = $self->{line} = scalar @{$self->{lines_ref}};
        return @{ delete $self->{lines_ref} };
    }else{
        while(1){
            if( ( @{$self->{lines_ref}} > 1 ) || $self->{eof} ){
                $. = ++$self->{line} if @{$self->{lines_ref}};
                return shift @{$self->{lines_ref}};
            }
            READ($self,$buf);
            my $lines = pop( @{$self->{lines_ref}} ) . $buf;
            push @{$self->{lines_ref}}, $lines =~ /(.*?$sep|.+)/gs;
        }
    }
}

sub TELL {
    return $_[0]->{pos};
}

sub EOF {
    return $_[0]->{eof};
}

sub GETC {
    my $self = shift;
    my($len,$buf) = (0,'');
    $self->{sth}->blob_read($self->{field}, $self->{pos}, 1,\$buf);
    $len = length $buf;
    if( $len ){
        $self->{pos} += $len;
        return $buf;
    }else{
        $self->{eof} = 1;
        return undef;
    }
}

sub READ {
    my($self,undef,$length,$offset) = @_;
    $length ||= $self->{blocksize} unless defined $length;
    die "Negative length" unless $length >= 0; # like the built in read does
    $offset ||= 0;
    if( defined($_[1]) && ( ( $offset > length($_[1]) ) || ( $offset < 0 ) ) ){
        die "Offset outside string"; # like the built in read does
    }
    my($len,$buf) = (0,'');
    $self->{sth}->blob_read($self->{field}, $self->{pos}, $length,\$buf);
# The 5 argument form of blob_read appears to be broken
# (dies when called as such) otherwise we could do
# $h->blob_read($field, $offset, $len [, \$buf [, $bufoffset]])
# and then we wouldn't have to do the substring manipulation of $_[1]
    $len = length $buf;
    if($len){
        $self->{pos} += $len;
    }else{
        $self->{eof} = 1;
    }
    $_[1] ||= ''; # avoids substr error
    substr($_[1],$offset) = $buf;
    return $len;    
}

sub SEEK {
    my($self,$offset,$whence) = @_;
    if( $whence == IO::Seekable::SEEK_SET() ){
        if( $offset > 0 ){
            if( $offset > $self->{pos} ){
                $offset -= $self->{pos};
                while( ! $self->{eof} && ( $self->{pos} < $offset ) ){
                    READ($self, undef, undef);
                }
                if( $offset < $self->{pos} ){
                    $self->{pos} = $offset;
                    $self->{eof} = 0;
                }
            }else{
                $self->{pos} = $offset;
                $self->{eof} = 0;
            }
        }else{
            $self->{pos} = 0;
            $self->{eof} = 0;
        }
    }
    elsif( $whence == IO::Seekable::SEEK_CUR() ){
        if( $offset < 0 ){
            $self->{pos} += $offset;
            $self->{pos} = 0 if $self->{pos} < 0;
            $self->{eof} = 0;
        }else{
            my $seekto = $self->{pos} + $offset;
            while( ! $self->{eof} && ( $self->{pos} < $seekto ) ){
                READ($self, undef, undef);
            }
            if( $seekto < $self->{pos} ){
                $self->{pos} = $seekto;
                $self->{eof} = 0;
            }
        }
    }
    elsif( $whence == IO::Seekable::SEEK_END() ){
        while( ! $self->{eof} ){
            READ($self, undef, undef);
        }
        if( $offset < 0 ){
            $self->{eof} = 0; # reset eof
            $self->{pos} += $offset;
            $self->{pos} = 0 if $self->{pos} < 0;
        }
    }
    return $self->{pos}; # tell
}

1;

__END__

=head1 NAME

DBIx::BLOB::Handle - Read Database Large Object Binaries from file handles

=head1 SYNOPSIS

use DBI;

use DBIx::BLOB::Handle;

# use DBIx::BLOB::Handle qw( :INTO_STATEMENT );

$dbh = DBI->connect('DBI:Oracle:ORCL','scott','tiger',
                    {RaiseError => 1, PrintError => 0 }
				   )
                   
or die 'Could not connect to database:' , DBI->errstr;

$dbh->{LongTruncOk} = 1; # very important!

$sql = 'select mylob from mytable where id = 1';

$sth = $dbh->prepare($sql);

$sth->execute;

$sth->fetch;

$fh = DBIx::BLOB::Handle->new($sth,0,4096);

...

print while <$fh>;

# print $fh->getlines;

print STDERR 'Size of LOB was ' . $fh->tell . " bytes\n";

...

# read default buffer size

# fastest way to process a LOB

print $chunk while read($fh,$chunk,undef);

...

# fastest way to read a LOB into a scalar

local $/;

$blob = <$handle>;

...

# or if we used the dangerous :INTO_STATEMENT pragma,

# we could say:

# $fh = $sth->blob_as_handle(0,4096);

...

$sth->finish;

$dbh->disconnect;

=head1 DESCRIPTION AND RATIONALE

DBI has a blob_copy_to_file method which takes a file handle argument and copies
a database large object binary (LOB) to this file handle. However, the method is
undocumented and faulty. Constructing a similar method yourself is pretty simple
but what if you wished to read the data and perform operations on it? You could 
use the DBI's blob_read method yourself to process chunks of data from the LOB 
or even dump its contents into a scalar, but maybe it would be nice to read the 
data line by line or piece by piece from a familiar old filehandle?!

DBIx::BLOB::Handle constructs a tied filehandle that also extends from 
IO::Handle and IO::Selectable. It wraps DBI's blob_read method. By making LOB's
available as a file handle to read from we can process the data in a familiar 
(perly) way.

Additionally, by making the module respect $/ and $. then we can 
read lines of text data from a textual LOB (CLOB) and treat it just
as we would any other file handle!

=head1 CONSTRUCTOR

=item new 

=over

=over

$fh = DBIx::BLOB::Handle->new($sth,$column,$blocksize);

$fh = $statement->blob_as_handle($column,$blocksize);

=back

=back

Constructs a new file handle from the given DBI statement, given the column
number (zero based) of the LOB within the statement. The column number defaults
to '0'. The blocksize argument specifies how many bytes at a time should be read
from the LOB and defaults to '4096'

...

By 'use'ing the :INTO_STATEMENT pragma as follows;

use DBIx::BLOB::Handle qw( :INTO_STATEMENT );

DBIx::BLOB::Handle will install itself as a method of the DBI::st (statement) 
class. Thus you can create a file handle by calling

    $fh = $statement->blob_as_handle($column,$blocksize);

which in turn calls new.

=head1 METHODS

=over

=item readline

=over

$line = $handle->getline;

$line = scalar <$handle>;

@lines = $handle->getlines; 

@lines = <$handle>;

Read from the LOB. $handle->getline, or <$handle> in scalar context will return
a line, according to the current definition of a line (everything up to the next
value of $/); $handle->getlines or <$handle> in list context will return an 
array of lines.

Note: the actual implementation is to do a B<read> (see below) at the default
blocksize. The data read back is then split to find the actual rows. Thus there
is a trade off between number of network reads performed and the amount of
storage on the client.

Bug: Mixing reads and readlines on the same handle will screw everything up! 
This is because the stored position within the blob is the position from the 
last read, not the number of bytes from the currently returned lines.

=back

=item getc

=over

$char = $handle->getc;

$char = getc $handle;

Returns the next byte from $handle. Returns undef if there are no more bytes to
read. This is SLOW as it fetches one byte from the database each time. A future
implementation might fetch the default (blocksize) number of bytes from the 
database and then return these as single characters. Thoughts anyone?

=back

=item read

=over

$handle->read($chunk,[$length], [$offset]);

read $handle, $chunk, $length, [$offset];

Read $length bytes from $handle into $chunk, starting at position $offset in
$chunk (thus you can build up a scalar data structure). If $length is omitted
then the default blocksize will be used. If $length is omitted then the bytes
read will fill $chunk. Returns the number of bytes read.

=back

=item seek

=over

$handle->seek($offset, $whence);

seek $handle $offset, $whence;

Positions the file pointer for $handle. The first position is 0, not 1. Units
are bytes, not line numbers; $whence specifies what file position $offset uses;
0, the beginning of the file; 1, the current position; or 2, the end of the 
file.

Note: The behaviour currently differs from that of a standard file handle. 
Seeking before the beginning or after then end of the handle will reset the 
handle position to the beginning or end respectively.

Note: Seeking backwards for $handle is efficient because we don't have to do any
further network traffic. Seeking forward means we have to do more reads from the
blob as i am unaware of any (database independant) method to get the size of a
LOB. Currently reads are NOT cached since we don't know the final size of the 
blob. Thus seeking to the end of the blob, and then reading it backward or 
reading the entire blob, seeking to position 0 and re-reading (as examples) 
would result in double the amount of network traffic.

=back

=item tell

=over

$handle->tell; 

tell $handle;

=back

Gives the current position (in bytes, zero based) within the LOB

=back

=item eof

=over

$handle->eof;

eof $handle;

=back

Returns true if we have finished reading from the LOB.

=head1 SEE ALSO

Perls Filehandle functions,
The Tied Handle interface,
L<IO::Handle>,
L<IO::Seekable>

=head1 BUGS

Don't use the read method and the readline methods on the same handle.

The handle position ( tell method ) and thus eof follow the chunks read via the 
READ method NOT lines accessed via the READLINE ( <$handle> ) methods.

Otherwise please report them!

=head1 AUTHOR

Mark Southern (mark_southern@merck.com)

=head1 COPYRIGHT

Copyright (c) 2002, Merck & Co. Inc. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

=cut
