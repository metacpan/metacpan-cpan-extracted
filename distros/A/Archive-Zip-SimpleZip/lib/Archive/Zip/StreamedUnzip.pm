package Archive::Zip::StreamedUnzip;

require 5.006;

use strict ;
use warnings;
use bytes;

use IO::File;
use Carp;
use Scalar::Util ();

use IO::Compress::Base::Common  2.093 qw(:Status);
use IO::Compress::Zip::Constants 2.093 ;
use IO::Uncompress::Unzip 2.093 ;


require Exporter ;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS, $StreamedUnzipError);

$VERSION = '0.001';
$StreamedUnzipError = '';

@ISA    = qw(IO::Uncompress::Unzip Exporter);
@EXPORT_OK = qw( $StreamedUnzipError unzip );
%EXPORT_TAGS = %IO::Uncompress::RawInflate::EXPORT_TAGS ;
push @{ $EXPORT_TAGS{all} }, @EXPORT_OK ;
Exporter::export_ok_tags('all');


sub _setError
{
    $StreamedUnzipError = $_[2] ;
    $_[0]->{Error} = $_[2]
        if defined  $_[0] ;

    return $_[1];
}

sub _illegalFilename
{
    return _setError(undef, undef, "Illegal Filename") ;
}

sub is64BitPerl
{
    use Config;
    # possibly use presence of pack/unpack "Q" for int size test?
    $Config{lseeksize} >= 8 and $Config{uvsize} >= 8;
}

sub new
{
    my $class = shift ;

    return _setError(undef, undef, "Missing Filename")
        unless @_ ;

    my $inValue = shift ;
    my $fh;

    if (!defined $inValue)
    {
        return _illegalFilename
    }

    my $isSTDOUT = ($inValue eq '-') ;
    my $inType = IO::Compress::Base::Common::whatIsOutput($inValue);

    if ($inType eq 'filename')
    {
        if (-e $inValue && ( ! -f _ || ! -r _))
        {
            return _illegalFilename
        }

        $fh = new IO::File "<$inValue"
            or return _setError(undef, undef, "cannot open file '$inValue': $!");
    }
    elsif( $inType eq 'buffer' || $inType eq 'handle')
    {
        $fh = $inValue;
    }
    else
    {
        return _illegalFilename
    }

    my %obj ;
    # my $inner = IO::Compress::Base::Common::createSelfTiedObject($class, \$StreamedUnzipError);

    # # *$inner->{Pause} = 1;
    # $inner->_create(undef, 0, $fh, @_)
    #     or return undef;

    my $inner = IO::Uncompress::Unzip->new($fh) ;

    $obj{Inner} = $inner;
    $obj{Open} = 1 ;
    $obj{FirstOne} = 1 ;

    bless \%obj, $class;
}

sub close
{
    my $self = shift;
    # TODO - fix me
    $self->{Inner}->close();
    return 1;
}

sub DESTROY
{
    my $self = shift;
}

sub next
{
    my $self = shift;

    if ($self->{FirstOne})
    {
        $self->{FirstOne} = 0;
    }
    else
    {
        my $status = $self->{Inner}->nextStream();
        return undef
            if $status <= 0;
    }

    my %member ;
    $member{Inner}  = $self->{Inner};
    # $member{Member} = $member;
    $member{Info} = $self->{Inner}->getHeaderInfo() ;
    #Scalar::Util::weaken $member{Inner}; # for 5.8

    return bless \%member, 'Archive::Zip::StreamedUnzip::Member';
}

sub member
{
    my $self = shift;
    my $name = shift;

    return _setError(undef, undef, "Member '$name' not in zip")
        if ! defined $name ;

    while (my $member = $self->next())
    {
        return $member
            if $member->name() eq $name ;

    }

    return _setError(undef, undef, "Member '$name' not in zip") ;
}

sub getExtraParams
{

    return (
            # Zip header fields
            'name'    => [IO::Compress::Base::Common::Parse_any,       undef],

#            'stream'  => [IO::Compress::Base::Common::Parse_boolean,   1],
        );
}

sub ckParams
{
    my $self = shift ;
    my $got = shift ;

    # unzip always needs crc32
    $got->setValue('crc32' => 1);

    *$self->{UnzipData}{Name} = $got->getValue('name');

    return 1;
}




{
    package Archive::Zip::StreamedUnzip::Member;

    sub name
    {
        my $self = shift;
#        $self->_stdPreq() or return 0 ;

        return $self->{Info}{Name};
    }

    sub isDirectory
    {
        my $self = shift;
#        $self->_stdPreq() or return 0 ;

        return substr($self->{Info}{Name}, -1, 1) eq '/' ; 
    }

    sub isFile
    {
        my $self = shift;
#        $self->_stdPreq() or return 0 ;

        # TODO - test for symlink
        return ! $self->isDirectory() ;
    }

# TODO
#
#    isZip64
#    isDir
#    isSymLink
#    isText
#    isBinary
#    isEncrypted
#    isStreamed
#    getComment
#    getExtra
#    compressedSize - 64 bit alert
#    uncompressedSize
#    time
#    isStored
#    compressionName
#
#   extractToFile

    sub compressedSize
    {
        my $self = shift;
#        $self->_stdPreq() or return 0 ;

        my $CompressedLength = $self->{Info}{CompressedLength};
        if (ref $CompressedLength)
        {
            return U64::get64bit($CompressedLength)
        }
        return $CompressedLength;
    }

    sub uncompressedSize
    {
        my $self = shift;
#        $self->_stdPreq() or return 0 ;
        my $UncompressedLength = $self->{Info}{UncompressedLength};
        if (ref $UncompressedLength)
        {
            return U64::get64bit($UncompressedLength)
        }
        return $UncompressedLength;
    }

    sub content
    {
        my $self = shift;
        my $data ;

        # $self->{Inner}->read($data, $self->{UncompressedLength});
        $self->{Inner}->read($data, $self->{Info}{UncompressedLength});

        return $data;
    }

    sub open
    {
        my $self = shift;

#        return  return $self->{Inner} ;

#        my $handle = Symbol::gensym();
#        tie *$handle, "Archive::Zip::StreamedUnzip::Handle", $self->{SZ}{UnZip};
#        return $handle;

        my $z = IO::Compress::Base::Common::createSelfTiedObject("Archive::Zip::StreamedUnzip::Handle", \$StreamedUnzipError) ;

        *$z->{Open} = 1 ;
        *$z->{SZ} = $self->{Inner};
        Scalar::Util::weaken *$z->{SZ}; # for 5.8

        $z;
    }

    sub close
    {
        my $self = shift;
        return 1;
    }


}


{
    package Archive::Zip::StreamedUnzip::Handle ;

    sub TIEHANDLE
    {
        return $_[0] if ref($_[0]);
        die "OOPS\n" ;
    }

    sub UNTIE
    {
        my $self = shift ;
    }

    sub DESTROY
    {
#        print "DESTROY H";
        my $self = shift ;
        local ($., $@, $!, $^E, $?);
        $self->close() ;

        # TODO - memory leak with 5.8.0 - this isn't called until
        #        global destruction
        #
        %{ *$self } = () ;
        undef $self ;
    }


    sub close
    {
        my $self = shift ;
        return 1 if ! *$self->{Open};

        *$self->{Open} = 0 ;

#        untie *$self
#            if $] >= 5.008 ;

        if (defined *$self->{SZ})
        {
#            *$self->{SZ}{Raw} = undef ;
            *$self->{SZ} = undef ;
        }

        1;
    }

    sub read
    {
        # TODO - remember to fix the return value to match real read & not the broken one in IO::Uncompress
        my $self = shift;
        $self->_stdPreq() or return 0 ;

#        warn "READ [$self]\n";
#        warn "READ [*$self->{SZ}]\n";

#        $_[0] = *$self->{SZ}{Unzip};
#        my $status = goto &IO::Uncompress::Base::read;
#        $_[0] = \$_[0] unless ref $_[0];
        my $status = *$self->{SZ}->read(@_);
        $status = undef if $status < 0 ;
        return $status;
    }

    sub readline
    {
        my $self = shift;
        $self->_stdPreq() or return 0 ;
        *$self->{SZ}->getline(@_);
    }

    sub tell
    {
        my $self = shift;
        $self->_stdPreq() or return 0 ;

        *$self->{SZ}->tell(@_);
    }

    sub eof
    {
        my $self = shift;
        $self->_stdPreq() or return 0 ;

        *$self->{SZ}->eof;
    }

    sub _stdPreq
    {
        my $self = shift;

        # TODO - fix me
        return 1;

        return _setError("Zip file closed")
            if ! defined defined *$self->{SZ} || ! *$self->{Inner}{Open} ;


        return _setError("member filehandle closed")
            if  ! *$self->{Open} ; #|| ! defined *$self->{SZ}{Raw};

        return 0
            if *$self->{SZ}{Error} ;

         return 1;
    }

    sub _setError
    {
        $Archive::Zip::SimpleUnzip::StreamedUnzipError = $_[0] ;
        return 0;
    }

    sub binmode { 1 }

#    sub clearerr { $Archive::Zip::SimpleUnzip::StreamedUnzipError = '' }

    *BINMODE  = \&binmode;
#    *SEEK     = \&seek;
    *READ     = \&read;
    *sysread  = \&read;
    *TELL     = \&tell;
    *READLINE = \&readline;
    *EOF      = \&eof;
    *FILENO   = \&fileno;
    *CLOSE    = \&close;
}


1;

__END__

=head1 NAME

Archive::Zip::StreamedUnzip - Read Zip Archives in streaming mode

=head1 SYNOPSIS

    use Archive::Zip::StreamedUnzip qw($StreamedUnzipError) ;

    my $z = new Archive::Zip::StreamedUnzip "my.zip"
        or die "Cannot open zip file: $StreamedUnzipError\n" ;


    # Iterate through a zip archive
    while (my $member = $z->next)
    {
        print $member->name() . "\n" ;
    }

    # Archive::Zip::StreamedUnzip::Member

    my $name = $member->name();
    my $content = $member->content();
    my $comment = $member->comment();

    # open a filehandle to read from a zip member
    $fh = $member->open("mydata1.txt");

    # read blocks of data
    read($fh, $buffer, 1234) ;

    # or a line at a time
    $line = <$fh> ;

    close $fh;

    $z->close();

=head1 DESCRIPTION

Archive::Zip::StreamedUnzip is a module that allows reading of Zip archives in streaming mode.
This is useful if you are processing a zip coming directly off a socket without having to
read the complete file into memory and/or store it on disk. Similarly it can be handy when 
woking with a pipelined command.

Working with a streamed zip file does have limitations, so 
most of the time L<Archive::Zip::SimpleUnzip> and/or L<Archive::Zip> are a  better choice of
module for reading file files.

For writing Zip archives, there is a companion module,
called L<Archive::Zip::SimpleZip>, that can create Zip archives.

B<NOTE> This is alpha quality code, so the interface may change.

=head2 Features

=over 5

=item * Read zip archive from a file, a filehandle or from an in-memory buffer.

=item * Perl Filehandle interface for reading a zip member.

=item * Supports deflate, store, bzip2 and lzma compression.

=item * Supports Zip64, so can read archves larger than 4Gig and/or have greater than 64K members.

=back

=head2 Constructor

     $z = new Archive::Zip::StreamedUnzip "myzipfile.zip" [, OPTIONS] ;
     $z = new Archive::Zip::StreamedUnzip \$buffer [, OPTIONS] ;
     $z = new Archive::Zip::StreamedUnzip $filehandle [, OPTIONS] ;

The constructor takes one mandatory parameter along with zero or more
optional parameters.

The mandatory parameter controls where the zip archive is read from.
This can be any one of the following

=over 5

=item * Input from a Filename

When StreamedUnzip is passed a string, it will read the zip archive from the
filename stored in the string.

=item * Input from a String

When StreamedUnzip is passed a string reference, like C<\$buffer>, it will
read the in-memory zip archive from that string.

=item * Input from a Filehandle

When StreamedUnzip is passed a filehandle, it will read the zip archive from
that filehandle. Note the filehandle must be seekable.


=back

See L</Options> for a list of the optional parameters that can be specified
when calling the constructor.

=head2 Options

None yet.

=head2 Methods

=over 5

=item $z->next()

Returns the next member from the zip archive as a
Archive::Zip::StreamedUnzip::Member object.
See L</Archive::Zip::StreamedUnzip::Member>

Standard usage is

    use Archive::Zip::StreamedUnzip qw($StreamedUnzipError) ;

    my $match = "hello";
    my $zipfile = "my.zip";

    my $z = new Archive::Zip::StreamedUnzip $zipfile
        or die "Cannot open zip file: $StreamedUnzipError\n" ;

    while (my $member = $z->next())
    {
        my $name = $member->name();
        my $fh = $member->open();
        while (<$fh>)
        {
            my $offset =
            print "$name, line $.\n" if /$match/;
        }
    }

=item $z->close()

Closes the zip file.

=back

=head1 Archive::Zip::StreamedUnzip::Member

The C<next> method returns a member object of
type C<Archive::Zip::StreamedUnzip::Member>
that has the following methods.

=over 5

=item $string = $m->name()

Returns the name of the member.

=item $data = $m->content()

Returns the uncompressed content.

=item $fh = $m->open()

Returns a filehandle that can be used to read the uncompressed content.

=back

=head1 Examples

=head2 Iterate through a Zip file

    use Archive::Zip::StreamedUnzip qw($StreamedUnzipError) ;

    my $zipfile = "my.zip";
    my $z = new Archive::Zip::StreamedUnzip $zipfile
        or die "Cannot open zip file: $StreamedUnzipError\n" ;

    while (my $member = $z->next())
    {
        print "$member->name()\n";
    }

=head2 Filehandle interface

Here is a simple grep, that walks through a zip file and
prints matching strings.

    use Archive::Zip::StreamedUnzip qw($StreamedUnzipError) ;

    my $match = "hello";
    my $zipfile = "my.zip";

    my $z = new Archive::Zip::StreamedUnzip $zipfile
        or die "Cannot open zip file: $StreamedUnzipError\n" ;

    while (my $member = $z->next())
    {
        my $name = $member->name();
        my $fh = $member->open();
        while (<$fh>)
        {
            my $offset =
            print "$name, line $.\n" if /$match/;
        }
    }


=head2 Nested Zip

Here is a script that will list the contents of a zip file along with any zip files that are embedded in it.
In fact it will work with any level of nesting.

    sub walk
    {
        my $unzip  = shift ;
        my $depth = shift // 1;

        while (my $member = $unzip->next())
        {
            my $name = $unzip->name();
            print "  " x $depth . "$name\n" ;

            if ($name =~ /\.zip$/i)
            {
                my $fh = $member->open();
                my $newunzip = new Archive::Zip::StreamedUnzip $fh;
                walk($newunzip, $depth + 1);
            }
        }
    }

    my $unzip = new Archive::Zip::StreamedUnzip $zipfile
                or die "Cannot open '$zipfile': $StreamedUnzipError";

    print "$zipfile\n" ;
    walk($unzip) ;

=head1 Zip File Interoperability

The intention is to be interoperable with zip archives created by other
programs, like pkzip or WinZip, but the majority of testing carried out
used the L<Info-Zip zip/unzip|http://www.info-zip.org/> programs
running on Linux.

This doesn't necessarily mean that there is no interoperability with other
zip programs like pkzip and WinZip - it just means that I haven't tested
them. Please report any issues you find.

=head2 Compression Methods Supported

The following compression methods are supported

=over 5

=item deflate (8)

This is the most common compression used in zip archives.

=item store (0)

This is used when no compression has been carried out.

=item bzip2 (12)

Only if the C<IO-Compress-Bzip2> module is available.

=item lzma (14)

Only if the C<IO-Compress-Lzma> module is available.

=back

=head2 Zip64 Support

This modules supports Zip64, so it can read archves larger than 4Gig
and/or have greater than 64K members.


=head2 Limitations

The following features are not currently supported.

=over 4

=item * Compression methods not listed in L</Compression Methods Supported>

=item * Multi-Volume Archives

=item * Encrypted Archives

=back

=head1 SUPPORT

General feedback/questions/bug reports should be sent to 
L<https://github.com/pmqs/Archive-Zip-SimpleZip/issues> (preferred) or
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Archive-Zip-SimpleZip>.


=head1 SEE ALSO


L<Archive::Zip::SimpleUnzip>, L<Archive::Zip::SimpleZip>, L<Archive::Zip>, L<IO::Compress::Zip>,  L<IO::Uncompress::UnZip>


=head1 AUTHOR

This module was written by Paul Marquess, F<pmqs@cpan.org>.

=head1 MODIFICATION HISTORY

See the Changes file.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019 Paul Marquess. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.