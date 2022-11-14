# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Postgres/Lo.pm
## Version v0.300.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2022/11/04
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## Package for PostgreSQL large objects
package DB::Object::Postgres::Lo;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    our $VERSION = 'v0.300.1';
    use Devel::Confess;
};

use strict;
use warnings;

sub new
{
    my $this  = shift( @_ );
    my $dbh   = shift( @_ ) || return( $this->error( "No database handler was provided." ) );
    return( $this->error( "Value provided is not a database handler object." ) ) if( !ref( $dbh ) || ( ref( $dbh ) && !$dbh->isa( 'DB::Object' ) ) );
    my $class = ref( $this ) ? ref( $this ) : $this;
    my $self  = {};
    $self->{dbh} = $dbh;
    bless( $self, $class );
    return( $self );
}

sub close
{
    my $self = shift( @_ );
    return( $self->error( "Deactivate AutoCommit before using this function." ) ) if( $self->{dbh}->{AutoCommit} );
    my $fh = $self->{fh} || return( $self->error( "No file handle currently set. You must open the large object before using this method." ) );
    my $rv = $self->{dbh}->pg_lo_close( $fh );
    return( $self->error( "Unable to close the large object file descriptor." ) ) if( !defined( $rv ) );
    return( $self );
}

sub create
{
    my $self = shift( @_ );
    my $mode  = shift( @_ ) || 077;
    my $id = $self->{dbh}->pg_lo_creat( $mode );
    $self->{id} = $id;
    return( $id );
}

sub export_file
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || return( $self->error( "No file provided to export the large object to." ) );
    my $rv = $self->{dbh}->pg_lo_export( $file );
    return( $self->error( "Unable to export the large object to file $file." ) ) if( !defined( $rv ) );
    return( $self );
}

sub id
{
    my $self = shift( @_ );
    $self->{id} = shift( @_ ) if( @_ );
    return( $self->{id} );
}

sub import_file
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || return( $self->error( "No file provided to import the large object from it." ) );
    my $fh = $self->{fh} || return( $self->error( "No file handle currently set. You must open the large object before using this method." ) );
    my $id = $self->{dbh}->pg_lo_import( $file );
    return( $self->error( "Unable to import the large object." ) ) if( !defined( $id ) );
    my $new = $self->new( $self->{dbh} );
    $new->id( $id );
    return( $new );
}

sub import_with_oid
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || return( $self->error( "No file provided to import the large object from it." ) );
    my $oid  = shift( @_ );
    return( $self->error( "No oid was provided to import the large object." ) ) if( !defined( $oid ) || !length( $oid ) );
    my $fh = $self->{fh} || return( $self->error( "No file handle currently set. You must open the large object before using this method." ) );
    my $id = $self->{dbh}->pg_lo_import_with_oid( $file, $oid );
    return( $self->error( "Unable to import the large object with the oid $oid." ) ) if( !defined( $id ) );
    my $new = $self->new( $self->{dbh} );
    $new->id( $id );
    return( $new );
}

sub open
{
    my $self = shift( @_ );
    my $id   = shift( @_ );
    return( $self->error( "No id was provided." ) ) if( !defined( $id ) || !length( $id ) );
    ## $dbh->{pg_INV_READ}, $dbh->{pg_INV_WRITE},  $dbh->{pg_INV_READ} | $dbh->{pg_INV_WRITE}
    my $mode = shift( @_ );
    my $fh = $self->{dbh}->pg_lo_open( $id, $mode );
    return( $self->error( "Cannot open large object. An error has occured." ) ) if( !defined( $fh ) );
    $self->{fh} = $fh;
    return( $self );
}

sub read
{
    my $self = shift( @_ );
    my( $buffer, $len ) = @_;
    return( $self->error( "No length was provided." ) ) if( !defined( $len ) || !length( $len ) );
    return( $self->error( "Deactivate AutoCommit before using this function." ) ) if( $self->{dbh}->{AutoCommit} );
    my $fh = $self->{fh} || return( $self->error( "No file handle currently set. You must open the large object before using this method." ) );
    my $bytes = $self->{dbh}->pg_lo_read( $fh, $buffer, $len );
    return( $self->error( "Unable to read from the large object file descriptor." ) ) if( !defined( $bytes ) );
    return( $bytes );
}

sub seek
{
    my $self = shift( @_ );
    my( $offset, $whence ) = @_;
    return( $self->error( "Deactivate AutoCommit before using this function." ) ) if( $self->{dbh}->{AutoCommit} );
    my $fh = $self->{fh} || return( $self->error( "No file handle currently set. You must open the large object before using this method." ) );
    my $loc = $self->{dbh}->pg_lo_lseek( $fh, $offset, $whence );
    return( $self->error( "Unable to seek a position from the large object file descriptor." ) ) if( !defined( $loc ) );
    return( $loc );
}

sub tell
{
    my $self = shift( @_ );
    return( $self->error( "Deactivate AutoCommit before using this function." ) ) if( $self->{dbh}->{AutoCommit} );
    my $fh = $self->{fh} || return( $self->error( "No file handle currently set. You must open the large object before using this method." ) );
    my $loc = $self->{dbh}->pg_lo_tell( $fh );
    return( $self->error( "Unable to get the current position from the large object file descriptor." ) ) if( !defined( $loc ) );
    return( $loc );
}

sub truncate
{
    my $self = shift( @_ );
    my $len  = shift( @_ );
    return( $self->error( "No length was provided." ) ) if( !defined( $len ) || !length( $len ) );
    return( $self->error( "Deactivate AutoCommit before using this function." ) ) if( $self->{dbh}->{AutoCommit} );
    my $fh = $self->{fh} || return( $self->error( "No file handle currently set. You must open the large object before using this method." ) );
    my $rv = $self->{dbh}->pg_lo_truncate( $fh );
    return( $self->error( "Unable to truncate the large object file descriptor." ) ) if( !defined( $rv ) );
    return( $self );
}

sub unlink
{
    my $self = shift( @_ );
    return( $self->error( "Deactivate AutoCommit before using this function." ) ) if( $self->{dbh}->{AutoCommit} );
    my $fh = $self->{fh} || return( $self->error( "No file handle currently set. You must open the large object before using this method." ) );
    my $rv = $self->{dbh}->pg_lo_unlink( $fh );
    return( $self->error( "Unable to delete the large object file descriptor." ) ) if( !defined( $rv ) );
    return( $self );
}

sub write
{
    my $self = shift( @_ );
    my( $buffer, $len ) = @_;
    return( $self->error( "No length was provided." ) ) if( !defined( $len ) || !length( $len ) );
    return( $self->error( "Deactivate AutoCommit before using this function." ) ) if( $self->{dbh}->{AutoCommit} );
    my $fh = $self->{fh} || return( $self->error( "No file handle currently set. You must open the large object before using this method." ) );
    my $bytes = $self->{dbh}->pg_lo_write( $fh, $buffer, $len );
    return( $self->error( "Unable to write to the large object file descriptor." ) ) if( !defined( $bytes ) );
    return( $bytes );
}

1;

# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DB::Object::Postgres::Lo - Large Object

=head1 SYNOPSIS

    use DB::Object::Postgres::Lo( $dbh );
    my $lo = DB::Object::Postgres::Lo->new || die( DB::Object::Postgres::Lo->error, "\n" );

=head1 DESCRIPTION

This is the PostgreSQL large object class

=head1 METHODS

=head2 new

Instantiate a new PostgreSQL large object.

This takes only parameter: a database handler (L<DB::Object> or one of its inheriting package).

=head2 close

Close the large object by calling L<DBD::Pg/pg_lo_close>

=head2 create

Provided with an octal mode such as 077 and this creates a new large object by calling L<DBD::Pg/pg_lo_creat> passing it the octal mode.

Save the id returned in the object property C<id>

It returns the id.

=head2 export_file

Provided with a file and this will export the large object to file by calling L<DBD::Pg/pg_lo_export> and passing it the file.

Upon error, this returns an error, otherwise this returns the current object.

=head2 id

Sets or gets the id.

=head2 import_file

Provided with a file and this will import it as a large object by calling L<DBD::Pg/pg_lo_import> and passing it the file.

This creates a new L<DB::Object::Postgres::Lo> object, sets the id retrieved from PostgreSQL.

Upon error, this returns an error, otherwise this returns the newly created object.

=head2 import_with_oid

Provided with a file and an oid and this will import the file by calling L<DBD::Pg/pg_lo_import_with_oid> passing it the file and the oid arguments.

Upon error, this returns an error, otherwise this returns a newly created L<DB::Object::Postgres::Lo> object with the id set to the value returned by L<DBD::Pg/pg_lo_import_with_oid>.

=head2 open

Provided with large object id and an octal mode, and this will open it by calling L<DBD::Pg/pg_lo_open> passing it the id and the octal mode.

It will save the file handle returned in the object property C<fh>

Upon error, this returns an error, otherwise this returns the current object.

=head2 read

This method requires the large object to have been opened before so that a file handle is readily available.

Provided with a buffer and a length and this will attempt to read the length provided into the buffer by calling L<DBD::Pg/pg_lo_read> passing it the file handle, buffer and length.

Upon error, this returns an error, otherwise this returns the number of bytes actually read.

=head2 seek

This method requires the large object to have been opened before so that a file handle is readily available.

Provided with an offset and a whence and this will attempt to do a seek by calling L<DBD::Pg/pg_lo_lseek> passing it the file handle, the offset and the whence.

Upon error, this returns an error, otherwise this returns the new offset position received from L<DBD::Pg/pg_lo_lseek>

=head2 tell

This method requires the large object to have been opened before so that a file handle is readily available.

This will attempt to do a tell by calling L<DBD::Pg/pg_lo_tell> passing it only the file handle.

Upon error, this returns an error, otherwise this returns the current offset position received from L<DBD::Pg/pg_lo_tell>

=head2 truncate

This method requires the large object to have been opened before so that a file handle is readily available.

This will attempt to do a tell by calling L<DBD::Pg/pg_lo_truncate> passing it only the file handle.

Upon error, this returns an error, otherwise this returns the returned value received from L<DBD::Pg/pg_lo_truncate>

=head2 unlink

This method requires the large object to have been opened before so that a file handle is readily available.

This will attempt to remove the file by calling L<DBD::Pg/pg_lo_unlink> passing it only the file handle.

Upon error, this returns an error, otherwise this returns the returned value received from L<DBD::Pg/pg_lo_unlink>

=head2 write

This method requires the large object to have been opened before so that a file handle is readily available.

Provided with a buffer and a length and this will attempt to write to the large object by calling L<DBD::Pg/pg_lo_write> passing it the file handle, the buffer and the length.

Upon error, this returns an error, otherwise this returns the actual number writen from L<DBD::Pg/pg_lo_write>

=head1 SEE ALSO

L<DBD::Pg>, L<DBI>, L<Apache::DBI>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
