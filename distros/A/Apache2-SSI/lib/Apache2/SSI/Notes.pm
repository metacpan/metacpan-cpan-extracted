##----------------------------------------------------------------------------
## Apache2 Server Side Include Parser - ~/lib/Apache2/SSI/Notes.pm
## Version v0.1.3
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/01/18
## Modified 2025/03/22
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Apache2::SSI::Notes;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    # 512Kb
    use constant MAX_SIZE => 524288;
    use Apache2::SSI::SharedMem ':all';
    our $VERSION = 'v0.1.3';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{key}  = 'ap2_ssi_notes';
    $self->{size} = MAX_SIZE;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    return( $self->error( "Notes under this system $^O are unsupported." ) ) if( !Apache2::SSI::SharedMem->supported );
    my $mem = Apache2::SSI::SharedMem->new(
        key => ( length( $self->{key} ) ? $self->{key} : 'ap2_ssi_notes' ),
        # 512 Kb max
        size => $self->{size},
        # Create if necessary
        create => 1,
        debug => $self->debug,
    ) || return( $self->pass_error( Apache2::SSI::SharedMem->error ) );
    my $shem = $mem->open || return( $self->pass_error( $mem->error ) );
    $self->shem( $shem );
    return( $self );
};

sub add { return( shift->set( @_ ) ); }

sub clear
{
    my $self = shift( @_ );
    my $data = {};
    $self->write_mem( $data ) || return;
    return( $self );
}

sub do
{
    my $self = shift( @_ );
    my $code = shift( @_ );
    my @keys = @_;
    return( $self->error( "Code provided ($code) is not actually a code reference." ) ) if( ref( $code ) ne 'CODE' );
    my $data = $self->read_mem || return;
    @keys = sort( keys( %$data ) ) unless( scalar( @keys ) );
    local $@;
    foreach my $k ( @keys )
    {
        my $k_orig = $k;
        my $v = $data->{ $k };
        # try-catch
        eval
        {
            # Code can modify values in-place like:
            # sub
            # {
            #     $_[1] = 'new value' if( $_[0] eq 'some_key_name' );
            # }
            $code->( $k, $v );
            # Store possibly updated value
            $data->{ $k_orig } = $v;
        };
        if( $@ )
        {
            return( $self->error( "Callback died with error: $@" ) );
        }
    }
    # No need to bother if there was no keys in the first place
    if( scalar( @keys ) )
    {
        $self->write_mem( $data ) || return;
    }
    return( $self );
}

sub get
{
    my $self = shift( @_ );
    my $key;
    if( @_ )
    {
        $key = shift( @_ );
        return( $self->error( "Key provided to retrieve is empty." ) ) if( !length( $key ) );
    }
    my $data = $self->read_mem || return;
    # As it is the case for the first time, before any write
    $data = {} if( !ref( $data ) );
    return( $data ) if( !defined( $key ) );
    return( $data->{ $key } );
}

sub key { return( shift->_set_get_scalar( 'key', @_ ) ); }

sub read_mem
{
    my $self = shift( @_ );
    my $shem = $self->shem ||
        return( $self->error( "Oh no, the shared memory object is gone! That should not happen." ) );
    my $data;
    my $len = $shem->read( $data );
    return( $self->pass_error( $shem->error ) ) if( !defined( $len ) );
    $data = {} unless( ref( $data ) eq 'HASH' );
    return( $data );
}

sub remove
{
    my $self = shift( @_ );
    my $shem = $self->shem ||
        return( $self->error( "Oh no, the shared memory object is gone! That should not happen." ) );
    my $rv;
    if( !defined( $rv = $shem->remove ) )
    {
        return( $self->pass_error( $shem->error ) );
    }
    return( $rv );
}

sub set
{
    my $self = shift( @_ );
    my $data = $self->read_mem || return;
    my @callinfo = caller;
    my( $key, $value ) = @_;
    return( $self->error( "Key provided to set value is empty." ) ) if( !length( $key ) );
    $data->{ $key } = $value;
    $self->write_mem( $data ) || return;
    return( $self );
}

sub shem { return( shift->_set_get_object_without_init( 'shem', 'Apache2::SSI::SharedMem', @_ ) ); }

sub size { return( shift->_set_get_scalar( 'size', @_ ) ); }

sub supported { return( Apache2::SSI::SharedMem->supported ); }

sub unset
{
    my $self = shift( @_ );
    my $key  = shift( @_ );
    return( $self->error( "Key provided to unset value is empty." ) ) if( !length( $key ) );
    my $data = $self->read_mem || return;
    delete( $data->{ $key } );
    $self->write_mem( $data ) || return;
    return( $self );
}

sub write_mem
{
    my $self = shift( @_ );
    my $shem = $self->shem ||
        return( $self->error( "Oh no, the shared memory object is gone! That should not happen." ) );
    my $data = shift( @_ );
    return( $self->error( "I was expecting an hash reference and got instead '$data'" ) ) if( ref( $data ) ne 'HASH' );
    if( !defined( $shem->lock( ( LOCK_EX | LOCK_NB ) ) ) )
    {
        return( $self->pass_error( $shem->error ) );
    }
    my $rc = $shem->write( $data );
    $shem->unlock;
    return( $self->pass_error( $shem->error ) ) if( !defined( $rc ) );
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Apache2::SSI::Notes - Apache2 Server Side Include Notes

=head1 SYNOPSIS

    my $notes = Apache2::SSI::Notes->new(
        # 100K
        size => 102400,
        debug => 3,
    ) || die( Apache2::SSI::Notes->error );
    
    $notes->add( key => $val );
    
    $notes->clear;
    
    $notes->do(sub
    {
        # $_[0] = key
        # $_[1] = value
        $_[1] = Encode::decode( 'utf8', $_[1] );
    });
    
    # Or specify the keys to check
    $notes->do(sub
    {
        # $_[0] = key
        # $_[1] = value
        $_[1] = Encode::decode( 'utf8', $_[1] );
    }, qw( first_name last_name location ) );

    my $val = $notes-get( 'name' );

    # Get all as an hash reference
    my $hashref = $notes->get;

    $notes->set( name => 'John Doe' );

    # remove entry. This is different from $notes->set( name => undef() );
    # equivalent to delete( $hash->{name} );
    $notes->unset( 'name' );

=head1 VERSION

    v0.1.3

=head1 DESCRIPTION

L<Apache2::SSI::Notes> provides a mean to share notes in and out of Apache/mod_perl2 environment.

The interface is loosely mimicking L<APR::Table> on some, but not all, methods.

So you could have in your script, outside of Apache:

    $notes->set( API_ID => 1234567 );

And then, under mod_perl, in your file:

    <!--#if expr="note('API_ID')" -->

Normally, the C<note> function would work only for values set and retrieved inside the Apache/mod_perl2 framework, but with L<Apache2::SSI::Notes>, you can set a note, say, in a command line script and share it with your Server-Side Includes files.

To achieve this sharing of notes, L<Apache2::SSI::Notes> uses shared memory (see L<perlipc>) with L<Apache2::SSI::SharedMem> that does the heavy work.

However, this only works when L<Apache2::SSI> is in charge of parsing SSI files. Apache mod_includes module will not recognise notes stored outside of Apache/mod_perl framework.

=head1 METHODS

=head2 new

This instantiates a notes object. It takes the following parameters:

=over 4

=item C<debug>

A debug value will enable debugging output (equal or above 3 actually)

=item C<size>

The fixed size of the memory allocation. It defaults to 524,288 bytes which is 512 Kb, which should be ample enough.

=back

An object will be returned if it successfully initiated, or undef() upon error, which can then be retrieved with C<Apache2::SSI::Notes->error>. You should always check the return value of the methods used here for their definedness.

    my $notes = Apache2::SSI::Notes->new ||
        die( Apache2::SSI::Notes->error );

=head2 add

This is an alias for set.

=head2 clear

Empty all the notes. Beware that this will empty the notes for all the processes, since the notes are stored in a shared memory.

=head2 do

Provided with a callback as a code reference, and optionally an array of keys, and this will loop through all keys or the given keys if any, and call the callback passing it the key and its value.

For example:

    $notes->do(sub
    {
        my( $n, $v ) = @_;
        if( $n =~ /name/ )
        {
            $_[1] = Encode::decode( 'utf8', $_[1] );
        }
    });

=head2 get

Provided with a key and this retrieve its corresponding value, whatever that may be.

    my $val = $notes->get( 'name' );

If no key is provided, it returns all the notes as an hash reference.

    my $all = $notes->get;
    print( "API id is $all->{api}\n" );

Or maybe

    print( "API id is ", $notes->get->{api}, "\n" );

=head2 key

Set or get the shared memory key value.

=head2 read_mem

Access the shared memory and return the hash reference stored.

If an error occurred, C<undef()> is returned and an L<Module::Generic/error> is set, which can be retrieved like:

    die( $notes->error );

Be careful however, that L</get> may return C<undef()> not because an error would have occurred, but because this is the value you would have previously set.

=head2 remove

Removes the shared memory for this note.

=head2 set

Provided with a key and value pair, and this will set its entry into the notes hash accordingly.

    $notes->set( name => 'John Doe' );

It returns the notes object to enable chaining.

=head2 shem

Returns the current value of the L<Apache2::SSI::SharedMem> object.

You can also set an alternative value, but this is not advised unless you know what you are doing.

=head2 size

Sets or gets the shared memory block size.

This should really not be changed. If you do want to change it, you first need to remove the shared memory.

    $notes->shem->remove;

And then create a new L<Apache2::SSI::Notes> object with a different size parameter value.

=head2 supported

Returns true if shared memory is supported, or false otherwise.

=head2 unset

Remove the notes entry for the given key.

    # No more name key:
    $notes->unset( 'name' );

It returns the notes object to enable chaining.

=head2 write_mem

Provided with data, and this will write the data to the shared memory.

=head1 CAVEAT

L<Apache2::SSI::Notes> do not work under threaded perl

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

CPAN ID: jdeguest

L<https://gitlab.com/jackdeguest/Apache2-SSI>

=head1 SEE ALSO

mod_include, mod_perl(3), L<APR::Finfo>, L<perlfunc/stat>
L<https://httpd.apache.org/docs/current/en/mod/mod_include.html>,
L<https://httpd.apache.org/docs/current/en/howto/ssi.html>,
L<https://httpd.apache.org/docs/current/en/expr.html>
L<https://perl.apache.org/docs/2.0/user/handlers/filters.html#C_PerlOutputFilterHandler_>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
