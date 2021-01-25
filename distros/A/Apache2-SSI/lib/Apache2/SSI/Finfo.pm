## <https://perl.apache.org/docs/2.0/api/APR/Finfo.html>
##----------------------------------------------------------------------------
## Apache2 Server Side Include Parser - ~/lib/Apache2/SSI/Finfo.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/12/18
## Modified 2021/01/13
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## File::Stat via Path::Tiny
package Apache2::SSI::Finfo;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use Exporter qw( import );
    use DateTime;
    use DateTime::Format::Strptime;
    use File::Basename ();
    use Nice::Try;
    our( $AUTOLOAD );
    use overload (
        q{""}    => sub    { $_[0]->{filepath} },
        bool     => sub () { 1 },
        fallback => 1,
    );
    if( exists( $ENV{MOD_PERL} ) )
    {
        require APR::Pool;
        require APR::Finfo;
        require APR::Const;
        APR::Const->import( -compile => qw( :filetype FINFO_NORM ) );
    }
    use constant FINFO_DEV => 0;
    use constant FINFO_INODE => 1;
    use constant FINFO_MODE => 2;
    use constant FINFO_NLINK => 3;
    use constant FINFO_UID => 4;
    use constant FINFO_GID => 5;
    use constant FINFO_RDEV => 6;
    use constant FINFO_SIZE => 7;
    use constant FINFO_ATIME => 8;
    use constant FINFO_MTIME => 9;
    use constant FINFO_CTIME => 10;
    use constant FINFO_BLOCK_SIZE => 11;
    use constant FINFO_BLOCKS => 12;
    ## Sames constant value as in APR::Const
    ##  the file type is undetermined.
    use constant FILETYPE_NOFILE => 0;
    ## a file is a regular file.
    use constant FILETYPE_REG => 1;
    ## a file is a directory
    use constant FILETYPE_DIR => 2;
    ## a file is a character device
    use constant FILETYPE_CHR => 3;
    ## a file is a block device
    use constant FILETYPE_BLK => 4;
    ## a file is a FIFO or a pipe.
    use constant FILETYPE_PIPE => 5;
    ## a file is a symbolic link
    use constant FILETYPE_LNK => 6;
    ## a file is a [unix domain] socket.
    use constant FILETYPE_SOCK => 7;
    ## a file is of some other unknown type or the type cannot be determined.
    use constant FILETYPE_UNKFILE => 127;
    our %EXPORT_TAGS = ( all => [qw( FILETYPE_NOFILE FILETYPE_REG FILETYPE_DIR FILETYPE_CHR FILETYPE_BLK FILETYPE_PIPE FILETYPE_LNK FILETYPE_SOCK FILETYPE_UNKFILE )] );
    our @EXPORT_OK = qw( FILETYPE_NOFILE FILETYPE_REG FILETYPE_DIR FILETYPE_CHR FILETYPE_BLK FILETYPE_PIPE FILETYPE_LNK FILETYPE_SOCK FILETYPE_UNKFILE );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || return( $self->error( "No file provided to instantiate a ", ref( $self ), " object." ) );
    ## return( $self->error( "File or directory \"$file\" does not exist." ) ) if( !-e( $file ) );
    $self->{apache_request} = '';
    $self->{apr_finfo} = '';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->{filepath} = $file;
    $self->{_data} = [];
    my $r = $self->{apache_request};
    if( $r )
    {
        ## <https://perl.apache.org/docs/2.0/api/Apache2/RequestRec.html#toc_C_filename_>
        try
        {
            my $finfo;
            if( $r->filename eq $file )
            {
                $finfo = $r->finfo;
            }
            else
            {
                $finfo = APR::Finfo::stat( $file, APR::Const::FINFO_NORM, $r->pool );
                $r->finfo( $finfo );
            }
            $self->{apr_finfo} = $finfo;
        }
        catch( $e )
        {
            ## This makes it possible to query this api even if provided with a non-existing file
            if( $e =~ /No[[:blank:]\h]+such[[:blank:]\h]+file[[:blank:]\h]+or[[:blank:]\h]+directory/i )
            {
                $self->{_data} = [];
            }
            else
            {
                return( $self->error( "Unable to set the APR::Finfo object: $e" ) );
            }
        }
    }
    else
    {
        $self->{_data} = [CORE::stat( $file )];
    }
    return( $self );
}

sub apache_request { return( shift->_set_get_object_without_init( 'apache_request', 'Apache2::RequestRec', @_ ) ); }

sub apr_finfo { return( shift->_set_get_object( 'apr_finfo', 'APR::Finfo', @_ ) ); }

sub atime
{
    my $self = shift( @_ );
    my $f = $self->apr_finfo;
    my $t;
    if( $f )
    {
        $t = $f->atime;
    }
    else
    {
        my $data = $self->{_data};
        return( '' ) if( !scalar( @$data ) );
        $t = $data->[ FINFO_ATIME ];
    }
    return( $self->_datetime( $t ) );
}

sub blksize { return( shift->block_size( @_ ) ); }

sub block_size
{
    my $self = shift( @_ );
    my $f = $self->apr_finfo;
    if( $f )
    {
        return( ( CORE::stat( $self->{filepath} ) )[ FINFO_BLOCK_SIZE ] );
    }
    else
    {
        my $data = $self->{_data};
        return( '' ) if( !scalar( @$data ) );
        return( $data->[ FINFO_BLOCK_SIZE ] );
    }
}

sub blocks
{
    my $self = shift( @_ );
    my $f = $self->apr_finfo;
    if( $f )
    {
        return( ( CORE::stat( $self->{filepath} ) )[ FINFO_BLOCKS ] );
    }
    else
    {
        my $data = $self->{_data};
        return( '' ) if( !scalar( @$data ) );
        return( $data->[ FINFO_BLOCKS ] );
    }
}

sub can_read { return( -r( shift->filepath ) ); }

sub can_write { return( -w( shift->filepath ) ); }

sub can_exec { return( -x( shift->filepath ) ); }

sub can_execute { return( -x( shift->filepath ) ); }

sub csize { return( shift->size ); }

sub ctime
{
    my $self = shift( @_ );
    my $f = $self->apr_finfo;
    my $t;
    if( $f )
    {
        $t = $f->ctime;
    }
    else
    {
        my $data = $self->{_data};
        return( '' ) if( !scalar( @$data ) );
        $t = $data->[ FINFO_CTIME ];
    }
    return( $self->_datetime( $t ) );
}

sub dev { return( shift->device( @_ ) ); }

sub device
{
    my $self = shift( @_ );
    my $f = $self->apr_finfo;
    if( $f )
    {
        return( $f->device );
    }
    else
    {
        my $data = $self->{_data};
        return( '' ) if( !scalar( @$data ) );
        return( $data->[ FINFO_DEV ] );
    }
}

sub exists { return( shift->filetype == FILETYPE_NOFILE ? 0 : 1 ); }

## Read-only
sub filepath { return( shift->_set_get_scalar( 'filepath' ) ); }

sub filetype
{
    my $self = shift( @_ );
    my $f = $self->apr_finfo;
    if( $f )
    {
        return( $f->filetype );
    }
    else
    {
        my $file = $self->{filepath};
        CORE::stat( $file );
        if( !-e( _ ) )
        {
            return( FILETYPE_NOFILE );
        }
        elsif( -f( _ ) )
        {
            return( FILETYPE_REG );
        }
        elsif( -d( _ ) )
        {
            return( FILETYPE_DIR );
        }
        elsif( -l( _ ) )
        {
            return( FILETYPE_LNK );
        }
        elsif( -p( _ ) )
        {
            return( FILETYPE_PIPE );
        }
        elsif( -S( _ ) )
        {
            return( FILETYPE_SOCK );
        }
        elsif( -b( _ ) )
        {
            return( FILETYPE_BLK );
        }
        elsif( -c( _ ) )
        {
            return( FILETYPE_CHR );
        }
        else
        {
            return( FILETYPE_UNKFILE );
        }
    }
}

sub fname
{
    my $self = shift( @_ );
    my $r = $self->apache_request;
    if( $r )
    {
        return( $r->fname );
    }
    else
    {
        return( $self->{filepath} );
    }
}

sub gid { return( shift->group ); }

sub group
{
    my $self = shift( @_ );
    my $f = $self->apr_finfo;
    if( $f )
    {
        return( $f->fname );
    }
    else
    {
        my $data = $self->{_data};
        return( '' ) if( !scalar( @$data ) );
        return( $data->[ FINFO_GID ] );
    }
}

sub ino { return( shift->inode( @_ ) ); }

sub inode
{
    my $self = shift( @_ );
    my $f = $self->apr_finfo;
    if( $f )
    {
        return( $f->inode );
    }
    else
    {
        my $data = $self->{_data};
        return( '' ) if( !scalar( @$data ) );
        return( $data->[ FINFO_INODE ] );
    }
}

sub is_block { return( shift->filetype == FILETYPE_BLK ); }

sub is_char { return( shift->filetype == FILETYPE_CHR ); }

sub is_dir { return( shift->filetype == FILETYPE_DIR ); }

sub is_file { return( shift->filetype == FILETYPE_REG ); }

sub is_link { return( shift->filetype == FILETYPE_LNK ); }

sub is_pipe { return( shift->filetype == FILETYPE_PIPE ); }

sub is_socket { return( shift->filetype == FILETYPE_SOCK ); }

sub mode
{
    my $self = shift( @_ );
    my $f = $self->apr_finfo;
    if( $f )
    {
        # Something like 1860
        my $hex = $f->protection;
        return( oct( sprintf( '%x', $hex ) ) );
    }
    else
    {
        my $data = $self->{_data};
        return( '' ) if( !scalar( @$data ) );
        return( $data->[ FINFO_MODE ] & 07777 );
    }
}

sub mtime
{
    my $self = shift( @_ );
    my $f = $self->apr_finfo;
    my $t;
    if( $f )
    {
        $t = $f->mtime;
    }
    else
    {
        my $data = $self->{_data};
        return( '' ) if( !scalar( @$data ) );
        $t = $data->[ FINFO_MTIME ];
    }
    return( $self->_datetime( $t ) );
}

sub name
{
    my $self = shift( @_ );
    my $f = $self->apr_finfo;
    if( $f )
    {
        return( $f->name || File::Basename::basename( $f->fname ) );
    }
    else
    {
        return( File::Basename::basename( $self->fname ) );
    }
}

sub nlink
{
    my $self = shift( @_ );
    my $f = $self->apr_finfo;
    if( $f )
    {
        return( $f->nlink );
    }
    else
    {
        my $data = $self->{_data};
        return( '' ) if( !scalar( @$data ) );
        return( $data->[ FINFO_NLINK ] );
    }
}

sub protection
{
    my $self = shift( @_ );
    my $f = $self->apr_finfo;
    if( $f )
    {
        ## Will return something like 1860 (i.e. 744 = hex(1860))
        return( $f->protection );
    }
    else
    {
        my @stat = CORE::stat( $self->filepath );
        return( '' ) if( !scalar( @stat ) );
        return( hex( sprintf( '%04o', $stat[2] & 07777 ) ) );
    }
}

sub rdev
{
    my $self = shift( @_ );
    my $f = $self->apr_finfo;
    if( $f )
    {
        return( ( CORE::stat( $self->{filepath} ) )[ FINFO_RDEV ] );
    }
    else
    {
        my $data = $self->{_data};
        return( '' ) if( !scalar( @$data ) );
        return( $data->[ FINFO_RDEV ] );
    }
}

sub size
{
    my $self = shift( @_ );
    my $f = $self->apr_finfo;
    if( $f )
    {
        return( $f->size );
    }
    else
    {
        my $data = $self->{_data};
        return( '' ) if( !scalar( @$data ) );
        return( $data->[ FINFO_SIZE ] );
    }
}

sub stat
{
    my $self = shift( @_ );
    my $r = $self->apache_request;
    my $file = shift( @_ );
    my $p = scalar( @_ ) ? { @_ } : {};
    $p->{apache_request} = $r if( $r && !$p->{apache_request} );
    return( $self->new( $file, $p ) );
}

sub uid { return( shift->user ); }

sub user
{
    my $self = shift( @_ );
    my $f = $self->apr_finfo;
    if( $f )
    {
        return( $f->user );
    }
    else
    {
        my $data = $self->{_data};
        return( '' ) if( !scalar( @$data ) );
        return( $data->[ FINFO_UID ] );
    }
}

sub _datetime
{
    my $self = shift( @_ );
    my $t = shift( @_ );
    return( $self->error( "No epoch time was provided." ) ) if( !length( $t ) );
    return( $self->error( "Invalid epoch time provided \"$t\"." ) ) if( $t !~ /^\d+$/ );
    try
    {
        my $dt = DateTime->from_epoch( epoch => $t, time_zone => 'local' );
        my $fmt = DateTime::Format::Strptime->new(
            pattern => '%s',
            time_zone => 'local',
        );
        $dt->set_formatter( $fmt );
        return( Apache2::SSI::Datetime->new( $dt ) );
    }
    catch( $e )
    {
        return( $self->error( "Unable to get the datetime object for \"$t\": $e" ) );
    }
}

package Apache2::SSI::Datetime;
BEGIN
{
    use strict;
    use warnings;
    use overload (
        q{""}    => sub    { $_[0]->{dt}->stringify },
        bool     => sub () { 1 },
        fallback => 1,
    );
    our( $ERROR );
};

sub new
{
    my $this = shift( @_ );
    my $dt   = shift( @_ ) || return;
    my $self = { dt => $dt };
    return( bless( { dt => $dt } => ( ref( $this ) || $this ) ) );
}

sub error
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{error} = $ERROR = join( '', @_ );
        return;
    }
    return( $self->{error} || $ERROR );
}

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    no overloading;
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    die( "DateTime object is gone !\n" ) if( !ref( $self->{dt} ) );
    my $dt = $self->{dt};
    if( $dt->can( $method ) )
    {
        return( $dt->$method( @_ ) );
    }
    else
    {
        return( $self->error( "No method \"$method\" available in DateTime" ) );
    }
};

1;

__END__

=encoding utf-8

=head1 NAME

Apache2::SSI::Finfo - Apache2 Server Side Include File Info Object Class

=head1 SYNOPSIS

    my $finfo = Apache2::SSI::Finfo->new( '/some/file/path.html' );
    # or with Apache
    use Apache2::RequestRec ();
    use apache2::RequestUtil ();
    my $r = Apache2::RequestUtil->request;
    my $finfo = Apache2::SSI::Finfo->new( '/some/file/path.html', apache_request => $r );
    # Direct access to APR::Finfo
    my $apr = $finfo->apr_finfo;
    # Get access time as a DateTime object
    $finfo->atime;
    # Block site
    $finfo->blksize;
    # Number of blocks
    $finfo->blocks;
    if( $finfo->can_read )
    {
        # Do something
    }
    # Can also use
    $finfo->can_write;
    $finfo->can_exec;
    $finfo->csize;
    # Inode change time as a DateTime object
    $finfo->ctime;
    $finfo->dev;
    if( $finfo->exists )
    {
        # Do something
    }
    print "File path is: ", $finfo->filepath;
    if( $finfo->filetype == Apache2::SSI::Finfo::FILETYPE_NOFILE )
    {
        # File does not exist
    }
    # Same as $finfo->filepath
    print "File path is: ", $finfo->fname;
    print "File group id is: ", $finfo->gid;
    # Can also use $finfo->group which will yield the same result
    $finfo->ino;
    # or $finfo->inode;
    if( $finfo->is_block )
    {
        # Do something
    }
    elsif( $finfo->is_char )
    {
        # Do something else
    }
    elsif( $finfo->is_dir )
    {
        # It's a directory
    }
    elsif( $finfo->is_file )
    {
        # It's a regular file
    }
    elsif( $finfo->is_link )
    {
        # A file alias
    }
    elsif( $info->is_pipe )
    {
        # A Unix pipe !
    }
    elsif( $finfo->is_socket )
    {
        # It's a socket
    }
    elsif( ( $info->mode & 0100 ) )
    {
        # Can execute
    }
    $finfo->mtime->strftime( '%A %d %B %Y %H:%m:%S' );
    print "File base name is: ", $finfo->name;
    printf "File has %d links\n", $finfo->nlink;
    print "File permission in hexadecimal: ", $finfo->protection;
    $finfo->rdev;
    $finfo->size;
    my $new_object = $finfo->stat( '/some/other/file.txt' );
    # Get the user id
    $finfo->uid;
    # Or
    $finfo->user;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class provides a file info object oriented consistant whether it is accessed from Apache/mod_perl2 environment or from outside of it.

The other advantage is that even if a non-existing file is provided, an object is returned. Obviously many of this module's methods will return an empty value since the file does not actually exist. This is an advantage, because one cannot create an L<APR::Finfo> object over a non-existing file.

=head1 METHODS

=head2 new

This instantiate an object that is used to access other key methods. It takes a file path followed by the following parameters:

=over 4

=item I<apache_request>

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

=head2 apr_finfo

Sets or gets the L<APR::Finfo> object when running under Apache/mod_perl. Note that this value might be empty if the file does not exist. This is mentioned here for completeness only.

=head2 atime

Returns the file last access time as a L<Apache2::SSI::Datetime> object, which stringifies to its value in second since epoch. L<Apache2::SSI::Datetime> is just a wrapper around L<DateTime> to allow a L<DateTime> to be used in comparison with another non L<DateTime> value.

For example:

    if( $finfo->atime > time() + 86400 )
    {
        print( "You are traveling in the future\n" );
    }

=head2 blksize

Returns the preferred I/O size in bytes for interacting with the file.
You can also use C<block_size>.

=head2 blocks

Returns the actual number of system-specific blocks allocated on disk (often, but not always, 512 bytes each).

=head2 can_read

Returns true if the the effective user can read the file.

=head2 can_write

Returns true if the the effective user can write to the file.

=head2 can_exec

Returns true if the the effective user can execute the file. Same as L</execute>

=head2 can_execute

Returns true if the the effective user can execute the file. Same as L</exec>

=head2 csize

Returns the total size of file, in bytes. Same as L</size>

=head2 ctime

Returns the file inode change time as a L<Apache2::SSI::Datetime> object, which stringifies to its value in second since epoch. L<Apache2::SSI::Datetime> is just a wrapper around L<DateTime> to allow a L<DateTime> to be used in comparison with another non L<DateTime> value.

=head2 dev

Returns the device number of filesystem. Same as L</dev>

=head2 device

Returns the device number of filesystem. Same as L</device>

=head2 exists

Returns true if the filetype is not L</FILETYPE_NOFILE>

=head2 filepath

Returns the file path as a string. Same as L</fname>

=head2 filetype

Returns the file type which is one of the L</CONSTANTS> below.

=head2 fname

Returns the file path as a string. Same as L</filepath>

=head2 gid

Returns the numeric group ID of file's owner. Same as L</group>

=head2 group

Returns the numeric group ID of file's owner. Same as L</gid>

=head2 inode

Returns the inode number.

=head2 is_block

Returns true if this is a block file, false otherwise.

=head2 is_char

Returns true if this is a character file, false otherwise.

=head2 is_dir

Returns true if this is a directory, false otherwise.

=head2 is_file

Returns true if this is a regular file, false otherwise.

=head2 is_link

Returns true if this is a symbolic link, false otherwise.

=head2 is_pipe

Returns true if this is a pipe, false otherwise.

=head2 is_socket

Returns true if this is a socket, false otherwise.

=head2 mode

Returns the file mode. This is equivalent to the mode & 07777, ie without the file type bit.

So you could do something like:

    if( $finfo->mode & 0100 )
    {
        print( "Owner can execute\n" );
    }
    if( $finfo->mode & 0001 )
    {
        print( "Everyone can execute too!\n" );
    }

=head2 mtime

Returns the file last modify time as a L<Apache2::SSI::Datetime> object, which stringifies to its value in second since epoch. L<Apache2::SSI::Datetime> is just a wrapper around L<DateTime> to allow a L<DateTime> to be used in comparison with another non L<DateTime> value.

=head2 name

Returns the file base name. So if the file is C</home/john/www/some/file.html> this would return C<file.html>

Interesting to note that L<APR::Finfo/name> which is advertised as returning the file base name, actually returns just an empty string. With this module, this uses a workaround to provide the proper value. It use L<File::Basename/basename> on the value returned by L</fname>

=head2 nlink

Returns the number of (hard) links to the file.

=head2 protection

=head2 rdev

Returns the device identifier (special files only).

=head2 size

Returns the total size of file, in bytes. Same as L</csize>

=head2 stat

Provided with a file path and this returns a new L<Apache2::SSI::Finfo> object.

=head2 uid

=head2 user

Returns the numeric user ID of file's owner. Same as L</uid>

=head2 uid

Returns the numeric user ID of file's owner. Same as L</user>

=head1 CONSTANTS

=head2 FILETYPE_NOFILE

File type constant to indicate the file does not exist.

=head2 FILETYPE_REG

Regular file

=head2 FILETYPE_DIR

The element is a directory

=head2 FILETYPE_CHR

The element is a character block

=head2 FILETYPE_BLK

A block device

=head2 FILETYPE_PIPE

The file is a FIFO or a pipe

=head2 FILETYPE_LNK

The file is a symbolic link

=head2 FILETYPE_SOCK

The file is a (unix domain) socket

=head2 FILETYPE_UNKFILE

The file is of some other unknown type or the type cannot be determined

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

CPAN ID: jdeguest

L<https://git.deguest.jp/jack/Apache2-SSI>

=head1 SEE ALSO

L<Apache2::SSI::File>, L<Apache2::SSI::URI>, L<Apache2::SSI>

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

