##----------------------------------------------------------------------------
## Apache2 Server Side Include Parser - ~/lib/Apache2/SSI/Common.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/01/13
## Modified 2021/01/13
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Apache2::SSI::Common;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use File::Spec ();
    use IO::File;
    use Nice::Try;
    use Scalar::Util ();
    use URI;
    our $VERSION = 'v0.1.0';
    ## https://en.wikipedia.org/wiki/Path_(computing)
    ## perlport
    our $OS2SEP  =
    {
    amigaos     => '/',
    android     => '/',
    aix         => '/',
    bsdos       => '/',
    beos        => '/',
    bitrig      => '/',
    cygwin      => '/',
    darwin      => '/',
    dec_osf     => '/',
    dgux        => '/',
    dos         => "\\",
    dragonfly   => '/',
    dynixptx    => '/',
    freebsd     => '/',
    gnu         => '/',
    gnukfreebsd => '/',
    haiku       => '/',
    hpux        => '/',
    interix     => '/',
    iphoneos    => '/',
    irix        => '/',
    linux       => '/',
    machten     => '/',
    macos       => ':',
    midnightbsd => '/',
    minix       => '/',
    mirbsd      => '/',
    mswin32     => "\\",
    msys        => '/',
    netbsd      => '/',
    netware     => "\\",
    next        => '/',
    nto         => '/',
    openbsd     => '/',
    os2         => '/',
    ## Extended Binary Coded Decimal Interchange Code
    os390       => '/',
    os400       => '/',
    qnx         => '/',
    riscos      => '.',
    sco         => '/',
    sco_sv      => '/',
    solaris     => '/',
    sunos       => '/',
    svr4        => '/',
    svr5        => '/',
    symbian     => "\\",
    unicos      => '/',
    unicosmk    => '/',
    vms         => '/',
    vos         => '>',
    win32       => "\\",
    };
    our $DIR_SEP = $OS2SEP->{ lc( $^O ) };
};

## RFC 3986 section 5.2.4
## This is aimed for web URI initially, but is also used for filesystems in a simple way
sub collapse_dots
{
    my $self = shift( @_ );
    my $path = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    ## To avoid warnings
    $opts->{separator} //= '';
    ## A path separator is provided when dealing with filesystem and not web URI
    ## We use this to know what to return and how to behave
    my $sep  = length( $opts->{separator} ) ? $opts->{separator} : '/';
    return( '' ) if( !length( $path ) );
    my $u = $opts->{separator} ? URI::file->new( $path ) : URI->new( $path );
    my( @callinfo ) = caller;
    $self->message( 4, "URI based on '$path' is '$u' (", overload::StrVal( $u ), ") and separator to be used is '$sep' and uri path is '", $u->path, "' called from $callinfo[0] in file $callinfo[1] at line $callinfo[2]." );
    $path = $opts->{separator} ? $u->file( $^O ) : $u->path;
    my @new = ();
    my $len = length( $path );
    
    ## "If the input buffer begins with a prefix of "../" or "./", then remove that prefix from the input buffer"
    if( substr( $path, 0, 2 ) eq ".${sep}" )
    {
        substr( $path, 0, 2 ) = '';
        ## $self->message( 3, "Removed './'. Path is now '", substr( $path, 0 ), "'." );
    }
    elsif( substr( $path, 0, 3 ) eq "..${sep}" )
    {
        substr( $path, 0, 3 ) = '';
    }
    ## "if the input buffer begins with a prefix of "/./" or "/.", where "." is a complete path segment, then replace that prefix with "/" in the input buffer"
    elsif( substr( $path, 0, 3 ) eq "${sep}.${sep}" )
    {
        substr( $path, 0, 3 ) = $sep;
    }
    elsif( substr( $path, 0, 2 ) eq "${sep}." && 2 == $len )
    {
        substr( $path, 0, 2 ) = $sep;
    }
    elsif( $path eq '..' || $path eq '.' )
    {
        $path = '';
    }
    elsif( $path eq $sep )
    {
        return( $u );
    }
    
    ## -1 is used to ensure trailing blank entries do not get removed
    my @segments = split( "\Q$sep\E", $path, -1 );
    $self->message( 3, "Found ", scalar( @segments ), " segments: ", sub{ $self->dump( \@segments ) } );
    for( my $i = 0; $i < scalar( @segments ); $i++ )
    {
        my $segment = $segments[$i];
        ## "if the input buffer begins with a prefix of "/../" or "/..", where ".." is a complete path segment, then replace that prefix with "/" in the input buffer and remove the last segment and its preceding "/" (if any) from the output buffer"
        if( $segment eq '..' )
        {
            pop( @new );
        }
        elsif( $segment eq '.' )
        {
            next;
        }
        else
        {
            push( @new, ( defined( $segment ) ? $segment : '' ) );
        }
    }
    ## Finally, the output buffer is returned as the result of remove_dot_segments.
    my $new_path = join( $sep, @new );
    # substr( $new_path, 0, 0 ) = $sep unless( substr( $new_path, 0, 1 ) eq '/' );
    substr( $new_path, 0, 0 ) = $sep unless( File::Spec->file_name_is_absolute( $new_path ) );
    $self->message( 4, "Adding back new path '$new_path' to uri '$u'." );
    if( $opts->{separator} )
    {
        $u = URI::file->new( $new_path );
    }
    else
    {
        $u->path( $new_path );
    }
    $self->message( 4, "Returning uri '$u' (", ( $opts->{separator} ? $u->file( $^O ) : 'same' ), ")." );
    return( $u );
}

## Credits: Path::Tiny
sub slurp
{
    my $self = shift( @_ );
    my $args = {};
    no warnings 'uninitialized';
    $args = Scalar::Util::reftype( $_[0] ) eq 'HASH'
        ? shift( @_ )
        : !( scalar( @_ ) % 2 )
            ? { @_ }
            : {};
    my $file = $args->{filename} || $args->{file} || $self->filename;
    return( $self->error( "No filename found." ) ) if( !length( $file ) );
    my $binmode = $args->{binmode} // '';
    try
    {
        my $fh = IO::File->new( "<$file" ) ||
        return( $self->error( "Unable to open file \"$file\" in read mode: $!" ) );
        $fh->binmode( $binmode ) if( length( $binmode ) );
        my $size;
        if( $binmode eq ':unix' && ( $size = -s( $fh ) ) )
        {
            my $buf;
            $fh->read( $buf, $size );
            return( $buf );
        }
        else
        {
            local $/;
            return( scalar( <$fh> ) );
        }
    }
    catch( $e )
    {
        return( $self->error( "An error occured while trying to open and read file \"$file\": $e" ) );
    }
}

sub slurp_utf8
{
    my $self = shift( @_ );
    my $args = {};
    no warnings 'uninitialized';
    $args = Scalar::Util::reftype( $_[0] ) eq 'HASH'
        ? shift( @_ )
        : !( scalar( @_ ) % 2 )
            ? { @_ }
            : {};
    $args->{binmode} = ':utf8';
    my $file = $args->{filename} || $args->{file} || $self->filename;
    return( $self->error( "No filename found." ) ) if( !length( $file ) );
    $args->{filename} = $file;
    return( $self->slurp( $args ) );
}


1;

__END__

=encoding utf-8

=head1 NAME

Apache2::SSI::Common - Apache2 Server Side Include Common Resources

=head1 VERSION

    v0.1.0

=head1 SYNOPSIS

    use parent qw( Apache2::SSI::Common );

=head1 DESCRIPTION

There is no specific api for this. This module contains only common resources used by other modules in this distribution.

=head1 METHODS

=head2 collapse_dots

Provided with an uri, and this will resolve the path and removing the dots, such as C<.> and C<..> and return an L<URI> object.

This is done as per the L<RFC 3986 section 5.2.4 algorithm|https://tools.ietf.org/html/rfc3986#page-33>

    my $uri = $ssi->collapse_dots( '/../a/b/../c/./d.html' );
    # would become /a/c/d.html
    my $uri = $ssi->collapse_dots( '/../a/b/../c/./d.html?foo=../bar' );
    # would become /a/c/d.html?foo=../bar
    $uri->query # foo=../bar

=head2 slurp

It returns the content of the L</filename>

it takes an hash reference of parameters:

=over 4

=item I<binmode>

    my $content = $uri->slurp({ binmode => ':utf-8' });

=back

It will return undef and sets an L<Module::Generic/error> if there is no L</filename> value set or if the file cannot be opened.

=head2 slurp_utf8

It returns the content of the file L</filename> utf-8 decoded.

This is equivalent to:

    my $content = $uri->slurp({ binmode => ':utf8' });

C<:utf8> is slightly a bit more lax than C<:utf-8>, so it you want strict utf8, you can do:

    my $content = $uri->slurp({ binmode => ':utf-8' });

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

CPAN ID: jdeguest

L<https://gitlab.com/jackdeguest/Apache2-SSI>

=head1 SEE ALSO

L<Apache2::SSI::File>, L<Apache2::SSI::URI>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

