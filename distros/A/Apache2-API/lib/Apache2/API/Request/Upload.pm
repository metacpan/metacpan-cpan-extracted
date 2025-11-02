##----------------------------------------------------------------------------
## Apache2 API Framework - ~/lib/Apache2/API/Request/Upload.pm
## Version v0.1.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/05/30
## Modified 2023/05/31
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Apache2::API::Request::Upload;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Apache2::API' );
    use parent qw( APR::Request::Param );
    use version;
    use APR::Request::Param;
    our $VERSION = 'v0.1.0';
};

sub bucket { return( shift->upload( @_ ) ); }

# This one is not very useful, since the charaset value here is an integer: 0, 1, 2, 8
# sub charset

sub fh { return( shift->upload_fh( @_ ) ); }

sub filename { return( shift->upload_filename( @_ ) ); }

# The header for this field
# sub info

sub io { return( shift->upload_io( @_ ) ); }

# sub is_tainted

sub length { return( shift->upload_size( @_ ) ); }

sub link { return( shift->upload_link( @_ ) ); }

# sub make

# sub name

sub size { return( shift->upload_size( @_ ) ); }

sub slurp { return( shift->upload_slurp( @_ ) ); }

sub tempname { return( shift->upload_tempname( @_ ) ); }

sub type { return( shift->upload_type( @_ ) ); }

# Returns an APR::Brigade, if any
# upload

# sub value

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Apache2::API::Request::Upload - Apache2 Request Upload Object

=head1 SYNOPSIS

    use Apache2::API::Request::Params;
    ## $r is the Apache2::RequestRec object
    my $req = Apache2::API::Request::Params->new(
        request         => $r,
        # pool of 2Mb
        brigade_limit   => 2097152,
        disable_uploads => 0,
        # For example: 3Mb
        read_limit      => 3145728,
        temp_dir        => '/home/me/my/tmp'
        upload_hook     => sub
        {
            my( $upload, $new_data ) = @_; 
            # do something
        },
    );
    
    my $file = $req->upload( 'file_upload' );

    # or more simply
    use parent qw( Apache2::API )
    
    # in your sub
    my $self = shift( @_ );
    my $file = $self->request->upload( 'file_upload' );
    # or
    my $file = $self->request->param( 'file_upload' );

    print( "No check done on data? ", $file->is_tainted ? 'no' : 'yes', "\n" );
    print( "Is it encoded in utf8? ", $file->charset == 8 ? 'yes' : 'no', "\n" );
    
    my $field_header = $file->info;
    
    # Returns the APR::Brigade object content for file_upload
    my $brigade = $field->bucket
    
    printf( "File name provided by client is: %s\n", $file->filename );
    
    # link to the temporary file or make a copy if on different file system
    $file->link( '/to/my/temp/file.png' );
    
    my $buff;
    # Read in our buffer if this is less than 500Kb
    $file->slurp( $buff ) if( $file->length < 512000 );
    
    print( "Uploaded data is %d bytes big\n, $file->length );
    
    print( "MIME type of uploaded data is: %s\n", $file->type );
    
    print( "Temporary file name is: %s\n", $file->tempname );
    
    my $io = $file->io;
    print while( $io->read( $_ ) );
    
    # overloaded object reverting to $file->value
    print( "Data is: $file\n" );
    
    print( "Data is: ", $file->value, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a module that inherits from L<APR::Request::Param> to deal with data upload leveraging directly Apache mod_perl's methods making it fast and powerful.

=head1 METHODS

=head2 bucket

Get or set the L<APR::Brigade> file-upload content for this param.

May also be called as B<upload>

=head2 charset

    $param->charset();
    $param->charset( $set );

Get or sets the param's internal charset. The charset is a number between 0 and 255; the current recognized values are

=over 4

=item 0 APREQ_CHARSET_ASCII

7-bit us-ascii

=item 1 APREQ_CHARSET_LATIN1

8-bit iso-8859-1

=item 2 APREQ_CHARSET_CP1252

8-bit Windows-1252

=item 8 APREQ_CHARSET_UTF8

utf8 encoded Unicode

=back

    my $charset = $up->charset;
    $up->charset( 8 );
    print( "Data in utf8 ? ", $up->charset == 8 ? 'yes' : 'no', "\n" );

=head2 filename

Returns the client-side filename associated with this param.

Depending on the user agent, this may be the file full path name or just the file base name.

=head2 fh

Returns a seekable filehandle representing the file-upload content.

=head2 info

Get or set the L<APR::Table> headers for this param.

    my $info = $up->info;
    while( my( $hdr_name, $hdr_value ) = each( %$info ) )
    {
        # etc
    }
    printf( "Content type is: %s\n", $up->info->{'Content-type'} );
    
    # could yield for example: application/json; charset=utf-8

See also L</type>, but be careful C<< $up->info->{'Content-type'} >> is not necessarily the same.

=head2 io

Returns an L<APR::Request::Brigade::IO> object, which can be treated as a non-seekable IO stream.

This is more efficient than L</fh>

This object has the B<read> and B<readline> methods corresponding to the methods B<READ> and B<READLINE> from L<APR::Request::Brigade>

    $io->read( $buffer );

    # or
    $io->read( $buffer, $length );

    # or
    $io->read( $buffer, $length, $offset );

Reads data from the brigade C<$io> into C<$buffer>. When omitted C<$length> defaults to C<-1>, which reads the first bucket into C<$buffer>. A positive C<$length> will read in C<$length> bytes, or the remainder of the brigade, whichever is greater. C<$offset> represents the index in C<$buffer> to read the new data.

    $io->readline;

Returns the first line of data from the bride. Lines are terminated by linefeeds (the '\012' character), but this may be changed to C<$/> instead.

=head2 is_tainted

    $param->is_tainted();
    $param->is_tainted(0); # untaint it

Get or set the param's internal tainted flag.

=head2 length

Returns the size of the param's file-upload content.

May also be called as B<size>

=head2 link

Provided with a file path and this will link the file-upload content with the local file named $path. Creates a hard-link if the spoolfile's (see upload_tempname) temporary directory is on the same device as $path; otherwise this writes a copy.

This is useful to avoid recreating the data. This works on *nix-like systems

    my $up = $req->param( 'file_upload' );
    $up->link( '/to/my/location.png' ) ||
        die( sprintf( "Cannot symlink from %s: $!\n", $up->tempname ) );

=head2 make

Fast XS param constructor.

    my $param = Apache2::API::Request::Param::Upload->make( $pool, $name, $value );

=head2 name

    $param->name();

Returns the param's name, i.e. the html form field name. This attribute cannot be modified.

=head2 size

    $param->size();

Returns the size of the param's file-upload content.

=head2 slurp

Provided with a variable, such as C<$data> and this reads the entire file-upload content into C<$data> and returns an integer representing the size of C<$data>.

    my $up = $req->param( 'file_upload' );
    my $size = $up->slurp( $data );

=head2 tempname

Provided with a string and this returns the name of the local spoolfile for this param.

=head2 type

Provided with a string and this returns the MIME-type of the param's file-upload content.

=head2 upload

    my $brigade = $param->upload();
    $param->upload( $brigade );

Get or set the L<APR::Brigade> file-upload content for this param.

=head2 upload_fh

    my $fh = $param->upload_fh();

Returns a seekable filehandle representing the file-upload content.

=head2 upload_filename

    my $filename = $param->upload_filename();

Returns the client-side filename associated with this param.

=head2 upload_io

    my $fh = $param->upload_io();

Returns an L<APR::Request::Brigade::IO> object, which can be treated as a non-seekable IO stream.

See also L</upload_fh>

=head2 upload_link

    $param->upload_link( $path );

Links the file-upload content with the local file named $path. Creates a hard-link if the spoolfile's (see upload_tempname) temporary directory is on the same device as $path; otherwise this writes a copy.

=head2 upload_size

    my $nbytes = $param->upload_size();

Returns the size of the param's file-upload content.

=head2 upload_slurp

    $param->upload_slurp( $data );

Reads the entire file-upload content into $data.

=head2 upload_tempname

    my $filename = $param->upload_tempname();

Returns the name of the local spoolfile for this param.

=head2 upload_type

    my $type = $param->upload_type();

Returns the MIME-type of the param's file-upload content.

=head2 value

    $param->value();

Returns the param's value. This attribute cannot be modified.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Apache2::Request>, L<APR::Request>, L<APR::Request::Param>, L<APR::Request::Apache2>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
