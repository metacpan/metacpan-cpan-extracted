##----------------------------------------------------------------------------
## Apache2 Server Side Include Parser - ~/lib/Apache2/SSI/File.pm
## Version v0.1.2
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/12/18
## Modified 2024/09/04
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
#----------------------------------------------------------------------------
# Apache2 Server Side Include Parser - ~/lib/Apache2/SSI/File.pm
# Version v0.1.1
# Copyright(c) 2021 DEGUEST Pte. Ltd.
# Author: Jacques Deguest <jack@deguest.jp>
# Created 2020/12/18
# Modified 2022/10/21
# All rights reserved
# 
# This program is free software; you can redistribute  it  and/or  modify  it
# under the same terms as Perl itself.
#----------------------------------------------------------------------------
package Apache2::SSI::File;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Apache2::SSI::Common );
    use vars qw( $DEBUG $VERSION $DIR_SEP );
    use Apache2::SSI::Finfo;
    use File::Spec ();
    use Scalar::Util ();
    use URI::file ();
    if( $ENV{MOD_PERL} )
    {
        require Apache2::RequestRec;
        require Apache2::RequestUtil;
        require Apache2::SubRequest;
        require Apache2::Access;
        require Apache2::Const;
        Apache2::Const->import( compile => qw( :common :http OK DECLINED ) );
        require APR::Const;
        APR::Const->import( -compile => qw( :filetype FINFO_NORM ) );
    }
    our( $DEBUG );
    use overload (
        q{""}    => sub    { $_[0]->filename },
        bool     => sub () { 1 },
        fallback => 1,
    );
    our $VERSION = 'v0.1.2';
    our $DIR_SEP = $Apache2::SSI::Common::DIR_SEP;
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    my $file = shift( @_ );
    return( $self->error( "No file was provided." ) ) if( !defined( $file ) || !length( $file ) );
    $self->{apache_request} = '';
    $self->{base_dir}       = '' unless( length( $self->{base_dir} ) );
    $self->{base_file}      = '';
    $self->{code}           = 200;
    $self->{finfo}          = '';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return;
    my $base_dir = '';
    if( length( $self->{base_file} ) )
    {
        if( -d( $self->{base_file} ) )
        {
            $base_dir = $self->{base_file};
        }
        else
        {
            my @segments = split( "\Q${DIR_SEP}\E", $self->{base_file}, -1 );
            pop( @segments );
            $base_dir = join( $DIR_SEP, @segments );
        }
        $self->{base_dir} = $base_dir;
    }
    elsif( !length( $self->{base_dir} ) )
    {
        $base_dir = URI->new( URI::file->cwd )->file( $^O );
        $self->{base_dir} = $base_dir;
    }
    $self->filename( $file ) || return;
    return( $self );
}

sub apache_request { return( shift->_set_get_object_without_init( 'apache_request', 'Apache2::RequestRec', @_ ) ); }

sub base_dir { return( shift->_make_abs( 'base_dir', @_ ) ); }

sub base_file { return( shift->_make_abs( 'base_file', @_ ) ); }

sub clone
{
    my $self = shift( @_ );
    my $new = {};
    my @fields = grep( !/^(apache_request|finfo)$/, keys( %$self ) );
    @$new{ @fields } = @$self{ @fields };
    $new->{apache_request} = $self->{apache_request};
    return( bless( $new => ( ref( $self ) || $self ) ) );
}

sub code
{
    my $self = shift( @_ );
    my $r = $self->apache_request;
    if( $r )
    {
        $r->status( @_ ) if( @_ );
        return( $r->status );
    }
    else
    {
        $self->{code} = shift( @_ ) if( @_ );
        return( $self->{code} );
    }
}

sub filename
{
    my $self = shift( @_ );
    my $newfile;
    if( @_ )
    {
        $newfile = shift( @_ );
        return( $self->error( "New file provided, but it was an empty string." ) ) if( !defined( $newfile ) || !length( $newfile ) );
    }
    
    my $r = $self->apache_request;
    if( $r )
    {
        if( defined( $newfile ) )
        {
            $r = $r->is_initial_req ? $r : $r->main;
            my $rr = $r->lookup_file( $newfile );
            # Amazingly, lookup_file will return ok  even if it does not find the file
            if( $rr->status == &Apache2::Const::HTTP_OK &&
                $rr->finfo && 
                $rr->finfo->filetype != &APR::Const::FILETYPE_NOFILE )
            {
                $self->apache_request( $rr );
                $newfile = $rr->filename;
                my $finfo = $rr->finfo;
                if( $finfo )
                {
                }
            }
            else
            {
                $self->code( 404 );
                $newfile = $self->collapse_dots( $newfile, { separator => $DIR_SEP });
                # We don't pass it the Apache2::RequestRec object, because it would trigger a fatal error since the file does not exist. Instead, we use the api without Apache2::RequestRec which is more tolerant
                # We do this so the user can call our object $file->finfo->filetype == Apache2::SSI::Finfo::FILETYPE_NOFILE
                $self->{finfo} = Apache2::SSI::Finfo->new( $newfile );
            }
            $self->{filename} = $newfile;
        }
        elsif( !length( $self->{filename} ) )
        {
            $self->{filename} = $r->filename;
        }
    }
    else
    {
        if( defined( $newfile ) )
        {
            my $base_dir = $self->base_dir;
            $base_dir .= $DIR_SEP unless( substr( $base_dir, -length( $DIR_SEP ), length( $DIR_SEP ) ) eq $DIR_SEP );
            # If we provide a string for the abs() method it works on Unix, but not on Windows
            # By providing an object, we make it work
            $newfile = URI::file->new( $newfile )->abs( URI::file->new( $base_dir ) )->file( $^O );
            $self->{filename} = $self->collapse_dots( $newfile, { separator => $DIR_SEP })->file( $^O );
            $self->finfo( $newfile );
            my $finfo = $self->finfo;
            if( !$finfo->exists )
            {
                $self->code( 404 );
            }
            # Force to create new Apache2::SSI::URI object
        }
    }
    return( $self->{filename} );
}

# Alias
sub filepath { return( shift->filename( @_ ) ); }

sub finfo
{
    my $self = shift( @_ );
    my $r = $self->apache_request;
    my $newfile;
    if( @_ )
    {
        $newfile = shift( @_ );
        return( $self->error( "New file path specified but is an empty string." ) ) if( !defined( $newfile ) || !length( $newfile ) );
    }
    elsif( !$self->{finfo} )
    {
        $newfile = $self->filename;
        return( $self->error( "No file path set. This should not happen." ) ) if( !$newfile );
    }
    
    if( defined( $newfile ) )
    {
        $self->{finfo} = Apache2::SSI::Finfo->new( $newfile, ( $r ? ( apache_request => $r ) : () ), debug => $self->debug );
        return( $self->pass_error( Apache2::SSI::Finfo->error ) ) if( !$self->{finfo} );
    }
    return( $self->{finfo} );
}

sub parent
{
    my $self = shift( @_ );
    my $r = $self->apache_request;
    # I deliberately did not do split( '/', $path, -1 ) so that if there is a trailing '/', it will not be counted
    # 2021-03-27: Was working well, but only on Unix systems...
    # my @segments = split( '/', $self->filename, -1 );
    my( $vol, $parent, $file ) = File::Spec->splitpath( $self->filename );
    $vol //= '';
    $file //= '';
    my @segments = File::Spec->splitpath( File::Spec->catfile( $parent, $file ) );
    pop( @segments );
    return( $self ) if( !scalar( @segments ) );
    # return( $self->new( join( '/', @segments ), ( $r ? ( apache_request => $r ) : () ) ) );
    return( $self->new( $vol . File::Spec->catdir( @segments ), ( $r ? ( apache_request => $r ) : () ) ) );
}

sub _make_abs
{
    my $self = shift( @_ );
    my $field = shift( @_ ) || return( $self->error( "No field provided." ) );
    if( @_ )
    {
        my $this = shift( @_ );
        if( Scalar::Util::blessed( $this ) && $this->isa( 'URI::file' ) )
        {
            $this = URI->new_abs( $this )->file( $^O );
        }
        # elsif( substr( $this, 0, 1 ) ne '/' )
        elsif( !File::Spec->file_name_is_absolute( $this ) )
        {
            $this = URI::file->new_abs( $this )->file( $^O );
        }
        $self->{ $field } = $this;
    }
    return( $self->{ $field } );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Apache2::SSI::File - Apache2 Server Side Include File Object Class

=head1 SYNOPSIS

    my $f = Apache2::SSI::File->new(
        '/some/file/path/file.html',
        apache_request => $r,
        base_dir => '/home/john/www',
    );
    $f->base_dir( '/home/joe/www' );
    my $f2 = $f->clone;
    unless( $f->code == Apache2::Const::HTTP_OK )
    {
        die( "File is not there!\n" );
    }
    # You can also use $f->filepath which is an alias to $f->filename
    print "Actual file is here: ", $f->filename, "\n";
    my $finfo = $f->finfo;
    if( $finfo->can_exec )
    {
        # do something
    }
    # prints Parent is: /some/file/path
    print "Parent is: ", $f->parent, "\n";

=head1 VERSION

    v0.1.2

=head1 DESCRIPTION

This packages serves to resolve files whether inside Apache scope with mod_perl or outside, providing a unified api.

=head1 METHODS

=head2 new

This instantiates an object that is used to access other key methods. It takes the following parameters:

=over 4

=item C<apache_request>

This is the L<Apache2::RequestRec> object that is provided if running under mod_perl.

it can be retrieved from L<Apache2::RequestUtil/request> or via L<Apache2::Filter/r>

You can get this L<Apache2::RequestRec> object by requiring L<Apache2::RequestUtil> and calling its class method L<Apache2::RequestUtil/request> such as C<Apache2::RequestUtil->request> and assuming you have set C<PerlOptions +GlobalRequest> in your Apache Virtual Host configuration.

Note that there is a main request object and subprocess request object, so to find out which one you are dealing with, use L<Apache2::RequestUtil/is_initial_req>, such as:

    use Apache2::RequestUtil (); # extends Apache2::RequestRec objects
    my $r = $r->is_initial_req ? $r : $r->main;

=back

=head2 apache_request

Sets or gets the L<Apache2::RequestRec> object. As explained in the L</new> method, you can get this Apache object by requiring the package L<Apache2::RequestUtil> and calling L<Apache2::RequestUtil/request> such as C<Apache2::RequestUtil->request> assuming you have set C<PerlOptions +GlobalRequest> in your Apache Virtual Host configuration.

When running under Apache mod_perl this is set automatically from the special L</handler> method, such as:

    my $r = $f->r; # $f is the Apache2::Filter object provided by Apache

=head2 base_dir

Sets or gets the base directory to be used as a reference to the files provided so they can be transformed into absolute file path.

    my $f = Apache2::SSI::File->new( './index.html',
        base_dir => '/home/joe/www',
    );
    # This would now be /home/joe/www/index.html
    $f->filename;

=head2 base_file

Returns the base file for this file object.

=head2 clone

Create a clone of the object and return it.

=head2 code

Sets or gets the http code for this file.

    $f->code( 404 );

=head2 collapse_dots

Provided with an uri or a file path, and this will resolve the path and removing the dots, such as C<.> and C<..> and return an L<URI> object.

This is done as per the L<RFC 3986 section 5.2.4 algorithm|https://tools.ietf.org/html/rfc3986#page-33>

    my $file = $f->collapse_dots( '/../a/b/../c/./d.html' );
    # would become /a/c/d.html

=head2 filename

Sets or gets the system file path to the file, as a string.

If a new file name is provided, under Apache/mod_perl2, this will perform a query with L<Apache2::SubRequest/lookup_file>

Any filename provided will be resolved with its dots flattened and transformed into an absolute system file path if it is not already.

=head2 filepath

Returns the file path for this file object.

=head2 finfo

Returns a L<Apache2::SSI::Finfo> object. This provides access to L<perlfunc/stat> information as methods, taking advantage of L<APR::Finfo> when running under Apache, and an identical interface otherwise. See L<Apache2::SSI::Finfo> for more information.

=head2 parent

Returns the parent of the file, or if there is no parent, it returns the current object itself.

    my $up = $f->parent;
    # would return /home/john/some/path assuming the file was /home/john/some/path/file.html

=head2 slurp

It returns the content of the L</filename>

it takes an hash reference of parameters:

=over 4

=item C<binmode>

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

L<Apache2::SSI::URI>, L<Apache2::SSI::Finfo>, L<Apache2::SSI>

mod_include, mod_perl(3), L<APR::URI>, L<URI>
L<https://httpd.apache.org/docs/current/en/mod/mod_include.html>,
L<https://httpd.apache.org/docs/current/en/howto/ssi.html>,
L<https://httpd.apache.org/docs/current/en/expr.html>
L<https://perl.apache.org/docs/2.0/user/handlers/filters.html#C_PerlOutputFilterHandler_>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
