package Archive::Zip::SimpleUnzip;

require 5.006;

use strict ;
use warnings;
use bytes;

use IO::File;
use Carp;
use Scalar::Util ();

use IO::Compress::Base::Common  2.081 qw(:Status);
use IO::Compress::Zip::Constants 2.081 ;
use IO::Uncompress::Unzip 2.081 ;


require Exporter ;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS, $SimpleUnzipError);

$VERSION = '0.025';
$SimpleUnzipError = '';

@ISA    = qw(IO::Uncompress::Unzip Exporter);
@EXPORT_OK = qw( $SimpleUnzipError unzip );
%EXPORT_TAGS = %IO::Uncompress::RawInflate::EXPORT_TAGS ;
push @{ $EXPORT_TAGS{all} }, @EXPORT_OK ;
Exporter::export_ok_tags('all');

our %PARAMS = (
                'filesonly' => [IO::Compress::Base::Common::Parse_boolean, 0],
              );

sub _ckParams
{
    my $got = IO::Compress::Base::Parameters::new();

    $got->parse(\%PARAMS, @_)
        or _myDie("Parameter Error: " . $got->getError())  ;

    return $got;
}

sub _setError
{
    $SimpleUnzipError = $_[2] ;
    $_[0]->{Error} = $_[2]
        if defined  $_[0] ;

    return $_[1];
}

sub _myDie
{
    $SimpleUnzipError = $_[0];
    Carp::croak $_[0];
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

    my $got = _ckParams(@_);
    my $filesOnly = $got->getValue('filesonly');

    my $inner = IO::Compress::Base::Common::createSelfTiedObject($class, \$SimpleUnzipError);

    *$inner->{Pause} = 1;
    $inner->_create(undef, 0, $fh)
        or return undef;

    my ($CD, $Members, $comment) = $inner->scanCentralDirectory($filesOnly);
    $obj{CD} = $CD;
    $obj{Members} = $Members ;
    $obj{Comment} = $comment;
    $obj{Cursor} = 0;
    $obj{Inner} = $inner;
    $obj{Open} = 1 ;

    bless \%obj, $class;
}

sub close
{
    my $self = shift;
    # TODO - fix me
#    $self->{Inner}->close();
    return 1;
}

sub DESTROY
{
    my $self = shift;
}

sub _readLocalHeader
{
    my $self = shift;
    my $member = shift;

    my $inner = $self->{Inner};
    my $status = $inner->smartSeek($member->{LocalHeaderOffset}, 0, SEEK_SET);

    #*$inner->{InputLength} = undef;
    #*$inner->{InputLengthRemaining} = undef;
    #*$inner->{BufferOffset}      = 0 ;
    #*$inner->{Prime}      = '' ;

    $inner->_readFullZipHeader() ;

    *$inner->{NewStream} = 0 ;
    *$inner->{EndStream} = 0 ;
#    *$inner->{CompressedInputLengthDone} = undef ;
#    *$inner->{CompressedInputLength} = undef ;
    *$inner->{TotalInflatedBytesRead} = 0;
#    $inner->reset();
#    *$inner->{UnCompSize}->reset();
#    *$inner->{CompSize}->reset();
    *$inner->{Info}{TrailerLength} = 0;

    # disable streaming if present & set sizes from central dir
    # TODO - this will only allow a single file to be read at a time.
    #        police it or fix it.
    *$inner->{ZipData}{Streaming} = 0;
    *$inner->{ZipData}{Crc32} = $member->{CRC32};
    *$inner->{ZipData}{CompressedLen} = $member->{CompressedLength};
    *$inner->{ZipData}{UnCompressedLen} = $member->{UncompressedLength};
    *$inner->{CompressedInputLengthRemaining} =
            *$inner->{CompressedInputLength} = $member->{CompressedLength};
}

sub comment
{
    my $self = shift;

    return $self->{Comment} ;
}

sub _mkMember
{
    my $self = shift;
    my $member = shift;

    $self->_readLocalHeader($member);

    my %member ;
    $member{Inner}  = $self->{Inner};
    $member{Info} = $member;
    #Scalar::Util::weaken $member{Inner}; # for 5.8


    return bless \%member, 'Archive::Zip::SimpleUnzip::Member';
}

sub member
{
    my $self = shift;
    my $name = shift;

    return _setError(undef, undef, "Member '$name' not in zip")
        if ! defined $name ;

    my $member = $self->{Members}{$name};

    return _setError(undef, undef, "Member '$name' not in zip")
        if ! defined $member ;

    return $self->_mkMember($member) ;
}

sub open
{
    my $self = shift;
    my $name = shift;

    my $member = $self->{Members}{$name};

    # TODO - get to return unef
    die "Member '$name' not in zip file\n"
        if ! defined $member ;

     $self->_readLocalHeader($member);

#    return $self->{Inner};
    my $z = IO::Compress::Base::Common::createSelfTiedObject("Archive::Zip::SimpleUnzip::Handle", \$SimpleUnzipError) ;

    *$z->{Open} = 1 ;
    *$z->{SZ} = $self->{Inner};
    Scalar::Util::weaken *$z->{SZ}; # for 5.8

    $z;
}

sub extract # to file - return actual path or pass/fail?
{
    my $self = shift;
    my $name = shift;
    my $out  = shift;

    my $member = $self->member($name)
        or return undef ;

    return $member->extract(defined $out ? $out : $name);
}

sub getCanonicalPath
{
    my $self = shift;
    my $name = shift;

    return _canonicalPath($name);
}



sub _isDirectory
{
    my $self = shift;
    my $name = shift ;

    return substr($name, -1, 1) eq '/' &&
        $self->{Info}{UncompressedLength} == 0  ;
}

sub content
{
    my $self = shift;
    my $name = shift;

    return undef
        if ! exists $self->{Members}{$name};

    $self->{Inner}->read(my $data, $self->{Info}{UncompressedLength});

    return $data;
}

sub exists
{
    my $self = shift;
    my $name = shift;

   return exists $self->{Members}{$name};
}

sub names
{
    my $self = shift ;
    return wantarray ? map { $_->{Name} } @{ $self->{CD} } : scalar @{ $self->{CD} } ;
}

sub next
{
    my $self = shift;
    return undef if $self->{Cursor} >= @{ $self->{CD} } ;
    return $self->_mkMember($self->{CD}[ $self->{Cursor} ++]) ;
}

# sub rewind
# {
#     my $self = shift;

#     $self->{Cursor} = 0;
# }

# sub unzip
# {
#     my $obj = IO::Compress::Base::Common::createSelfTiedObject(undef, \$SimpleUnzipError);
#     return $obj->_inf(@_) ;
# }

sub getExtraParams
{
    return ();
}

sub ckParams
{
    my $self = shift ;
    my $got = shift ;

    # unzip always needs crc32
    $got->setValue('crc32' => 1);

    return 1;
}

sub mkUncomp
{
    my $self = shift ;
    my $got = shift ;

    my $magic = $self->ckMagic()
        or return 0;

    return 1;
}

sub chkTrailer
{
    my $self = shift;
    my $trailer = shift;
    return STATUS_OK ;
}


sub seekOrDie
{
    # temp method to die if bad seek
    # TODO - revisist
    my $self   = shift ;
    my $offset = shift ;
    my $truncate = shift;
    my $position = shift || SEEK_SET;
    my $message = shift || "Error Seeking in CentralDirectory" ;

    my $got =  $self->smartSeek($offset, $truncate, $position);

    return $got ;
}

sub readOrDie
{
    # temp method to die if bad read
    # TODO - revisist
    my $self = shift;

    $self->smartReadExact(@_)
        or die "Error reading";
}

sub scanCentralDirectory
{
#    print "scanCentralDirectory\n";

    my $self = shift;
    my $filesOnly = shift ; # *$self->{FilesOnly};
    my $here = $self->smartTell();

    # Use cases
    # 1 32-bit CD
    # 2 64-bit CD

    my @CD = ();
    my %Members = ();
    my ($entries, $offset, $zipcomment) = $self->findCentralDirectoryOffset();

    return ()
        if ! defined $offset;

    return ([], {}, $zipcomment)
        if $entries == 0;

    $self->seekOrDie($offset, 0, SEEK_SET) ;

    # Now walk the Central Directory Records
    my $index = 0;
    my $buffer ;
    while ($self->smartReadExact(\$buffer, 46) &&
           unpack("V", $buffer) == ZIP_CENTRAL_HDR_SIG) {

        my $crc32              = unpack("V", substr($buffer, 16, 4));
        my $compressedLength   = unpack("V", substr($buffer, 20, 4));
        my $uncompressedLength = unpack("V", substr($buffer, 24, 4));
        my $filename_length    = unpack("v", substr($buffer, 28, 2));
        my $extra_length       = unpack("v", substr($buffer, 30, 2));
        my $comment_length     = unpack("v", substr($buffer, 32, 2));
        my $locHeaderOffset    = unpack("V", substr($buffer, 42, 4));

        my $filename;
        my $extraField;
        my $comment = '';
        if ($filename_length)
        {
            $self->smartReadExact(\$filename, $filename_length)
                or return $self->TruncatedTrailer("filename");
#            print "Filename [$filename]\n";
        }

        if ($extra_length)
        {
            $self->smartReadExact(\$extraField, $extra_length)
                or return $self->TruncatedTrailer("extra");

            # Check for Zip64
            my $zip64Extended = IO::Compress::Zlib::Extra::findID("\x01\x00", $extraField);
            if ($zip64Extended)
            {
                if ($uncompressedLength == 0xFFFFFFFF)
                {
                    $uncompressedLength = U64::Value_VV64  substr($zip64Extended, 0, 8, "");
                    # $uncompressedLength = unpack "Q<", substr($zip64Extended, 0, 8, "");
                }
                if ($compressedLength == 0xFFFFFFFF)
                {
                    $compressedLength = U64::Value_VV64  substr($zip64Extended, 0, 8, "");
                    # $compressedLength = unpack "Q<", substr($zip64Extended, 0, 8, "");
                }
                if ($locHeaderOffset == 0xFFFFFFFF)
                {
                    $locHeaderOffset = U64::Value_VV64  substr($zip64Extended, 0, 8, "");
                    # $locHeaderOffset = unpack "Q<", substr($zip64Extended, 0, 8, "");
                }
            }
        }

        next
            if $filesOnly && substr($filename, -1, 1) eq '/' && $uncompressedLength == 0;

        if ($comment_length)
        {
            $self->smartReadExact(\$comment, $comment_length)
                or return $self->TruncatedTrailer("comment");
        }

        my %data = (
                    'Name'               => $filename,
                    'Comment'            => $comment,
                    'LocalHeaderOffset'  => $locHeaderOffset,
                    'CompressedLength'   => $compressedLength ,
                    'UncompressedLength' => $uncompressedLength ,
                    'CRC32'              => $crc32 ,
                    #'Time'               => _dosToUnixTime($lastModTime),
                    #'Stream'             => $streamingMode,
                    #'Zip64'              => $zip64,
                    #
                    #'MethodID'           => $compressedMethod,
                    );
        push @CD, \%data;
        $Members{$filename} = \%data ;

        ++ $index;
    }

    $self->seekOrDie($here, 0, SEEK_SET) ;

    return (\@CD, \%Members, $zipcomment) ;
}

sub offsetFromZip64
{
#    print "offsetFromZip64\n";

    my $self = shift ;
    my $here = shift;

    $self->seekOrDie($here - 20, 0, SEEK_SET) ;

    my $buffer;
    my $got = 0;
    $self->readOrDie(\$buffer, 20) ;
        # or die "xxx $here $got $!" ;

    if ( unpack("V", $buffer) == ZIP64_END_CENTRAL_LOC_HDR_SIG ) {
        my $cd64 = U64::Value_VV64 substr($buffer,  8, 8);
        # my $cd64 = unpack "Q<", substr($buffer,  8, 8);

        $self->seekOrDie($cd64, 0, SEEK_SET) ;

        $self->readOrDie(\$buffer, 4) ;

        if ( unpack("V", $buffer) == ZIP64_END_CENTRAL_REC_HDR_SIG ) {

            $self->readOrDie(\$buffer, 8);
                # or die "xxx" ;
            my $size  = U64::Value_VV64($buffer);
            # my $size  = unpack "Q<", $buffer;

            $self->readOrDie(\$buffer, $size);
                # or die "xxx" ;

            my $cd64 =  U64::Value_VV64 substr($buffer,  36, 8);
            # my $cd64 = unpack "Q<", substr($buffer,  36, 8);

            return $cd64 ;
        }

        die "zzz1";
    }

    die "zzz2";
}

use constant Pack_ZIP_END_CENTRAL_HDR_SIG => pack("V", ZIP_END_CENTRAL_HDR_SIG);

sub findCentralDirectoryOffset
{
    my $self = shift ;

    # Most common use-case is where there is no comment, so
    # know exactly where the end of central directory record
    # should be.

    $self->seekOrDie(-22, 0, SEEK_END) ;
    my $here = $self->smartTell();

    my $buffer;
    $self->readOrDie(\$buffer, 22) ;

    my $zip64 = 0;
    my $centralDirOffset ;
    my $comment = '';
    my $entries = 0;
    if ( unpack("V", $buffer) == ZIP_END_CENTRAL_HDR_SIG ) {
        $entries          = unpack("v", substr($buffer, 8,  2));
        $centralDirOffset = unpack("V", substr($buffer, 16,  4));
    }
    else {
        $self->seekOrDie(0, 0, SEEK_END) ;

        my $fileLen = $self->smartTell();
        my $want = 0 ;

        while(1) {
            $want += 1024;
            my $seekTo = $fileLen - $want;
            if ($seekTo < 0 ) {
                $seekTo = 0;
                $want = $fileLen ;
            }

            $self->seekOrDie($seekTo, 0, SEEK_SET) ;
            my $got;
            $self->readOrDie(\$buffer, $want) ;
            my $pos = rindex( $buffer, Pack_ZIP_END_CENTRAL_HDR_SIG);

            if ($pos >= 0) {

                #$here = $self->smartTell();
                $here = $seekTo + $pos ;
                $entries            = unpack("v", substr($buffer, $pos + 8,  2));
                $centralDirOffset   = unpack("V", substr($buffer, $pos + 16, 4));
                my $comment_length  = unpack("v", substr($buffer, $pos + 20, 2));
                $comment = substr($buffer, $pos + 22, $comment_length)
                    if $comment_length ;

                last ;
            }

            return undef
                if $want == $fileLen;
        }
    }

    $centralDirOffset = $self->offsetFromZip64($here)
        if $entries and U64::full32 $centralDirOffset ;

#    print "findCentralDirectoryOffset $centralDirOffset [$comment]\n";
    return ($entries, $centralDirOffset, $comment) ;
}


sub STORABLE_freeze
{
    my $type = ref shift;
    croak "Cannot freeze $type object\n";
}

sub STORABLE_thaw
{
    my $type = ref shift;
    croak "Cannot thaw $type object\n";
}

{
    package Archive::Zip::SimpleUnzip::Member;

    use IO::File ;

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

        return substr($self->{Info}{Name}, -1, 1) eq '/' &&
                $self->{Info}{UncompressedLength} == 0  ;
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

    sub compressedSize
    {
        my $self = shift;
#        $self->_stdPreq() or return 0 ;

        return $self->{Info}{CompressedLength};
    }

    sub uncompressedSize
    {
        my $self = shift;
#        $self->_stdPreq() or return 0 ;

        return $self->{Info}{UncompressedLength};
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
#        tie *$handle, "Archive::Zip::SimpleUnzip::Handle", $self->{SZ}{UnZip};
#        return $handle;

        my $z = IO::Compress::Base::Common::createSelfTiedObject("Archive::Zip::SimpleUnzip::Handle", \$SimpleUnzipError) ;

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

    sub comment
    {
        my $self = shift;

        return $self->{Info}{Comment};
    }

    sub _canonicalPath
    {
        my $name = shift ;

        # Not an absolute path
        $name =~ s#^/+## ;

        # Remove trailing slash
        $name =~ s#/+$## ;

        $name =~ s#/+#/#g ;

        # Drop any ".." and "." paths
        # Us of ".." is unsafe
        my @paths = split '/', $name ;
        my @have =  grep { ! m#^\.(\.)?$# } @paths ;

        return @have ;

        $name = join '/', grep { ! m#^\.(\.)?$# } @paths ;

        # use Perl::OSType;
        # my $type = Perl::OSType::os_type();
        # if ( $type eq 'Unix' )
        # {
        # }
        # # TODO Win32
    }

    sub canonicalName
    {
        my $self = shift;

        return join '/', _canonicalPath($self->{Info}{Name});
    }

    sub extract # to file 
    {
        my $self = shift;
        my $out  = shift;

        my @path = _canonicalPath(defined $out ? $out : $self->{Info}{Name}) ;
        my $filename = join '/', @path ;
        pop @path
            if ! $self->isDirectory();
        
        my @dir  ;

        while (@path)
        {
            push @dir, shift @path;
            my $dir = join '/', @dir;
            mkdir $dir
                or return _setError("Cannot create path '$dir': $!");
        }

        # TODO - symlink

        if ($self->isFile())
        {
            my $handle = $self->open();
            my $fh = new IO::File ">$filename"
                or return _setError("Cannot open file '$filename': $!");
            #$fh->binmode(); # not available in 5.8.0

            my $data;
            print $fh $data 
                while $handle->read($data);
            $handle->close();
            $fh->close();
        }

        # TODO - set timestamps etc...

        return 1 ;
    } 

    sub _setError
    {
        $Archive::Zip::SimpleUnzip::SimpleUnzipError = $_[0] ;
        return 0;
    }       
}


{
    package Archive::Zip::SimpleUnzip::Handle ;

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
        $Archive::Zip::SimpleUnzip::SimpleUnzipError = $_[0] ;
        return 0;
    }

    sub binmode { 1 }

#    sub clearerr { $Archive::Zip::SimpleUnzip::SimpleUnzipError = '' }

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

Archive::Zip::SimpleUnzip - Read Zip Archives

=head1 SYNOPSIS

    use Archive::Zip::SimpleUnzip qw($SimpleUnzipError) ;

    my $z = new Archive::Zip::SimpleUnzip "my.zip"
        or die "Cannot open zip file: $SimpleUnzipError\n" ;

    # How many members in the archive?
    my $members = scalar $z->names();

    # Get the names of all the members in a zip archive
    my @names = $z->names();

    # Test member existence
    if ($z->exists("abc.txt"))
    {
     ...
    }

    # Extract member to filesystem
    $z->extract("member") ;
    $z->extract("member", "outfile") ;


    # Read the zip comment
    my $comment = $zip->comment();

    # Select a member by name
    my $member = $z->member("abc.txt");
    my $name = $member->name();
    my $content = $member->content();
    my $comment = $member->comment();

    # Iterate through a zip archive
    while (my $member = $z->next)
    {
        print $member->name() . "\n" ;

        $member->extract();
        $member->extract("outfile");
    }

    # Archive::Zip::SimpleUnzip::Member

    # Open a filehandle to read from a zip member
    $fh = $member->open("mydata1.txt");

    # Read blocks of data
    read($fh, $buffer, 1234) ;

    # or a line at a time
    $line = <$fh> ;

    close $fh;

    $z->close();

=head1 DESCRIPTION

Archive::Zip::SimpleUnzip is a module that allows reading of Zip archives.

For writing Zip archives, there is a companion module,
called L<Archive::Zip::SimpleZip>, that can create Zip archives.

B<NOTE> This is late alpha quality code, so the interface may change.

=head2 Features

=over 5

=item * Read zip archive from a file, a filehandle or from an in-memory buffer.

Note that the code assume that the zip archive is being read from a seekable file/filhandle/buffer.

=item * Perl Filehandle interface for reading a zip member.

=item * Supports deflate, store, bzip2 and lzma compression.

=item * Supports Zip64, so can read archves larger than 4Gig and/or have greater than 64K members.

=back

=head2 Constructor

     $z = new Archive::Zip::SimpleUnzip "myzipfile.zip" [, OPTIONS] ;
     $z = new Archive::Zip::SimpleUnzip \$buffer [, OPTIONS] ;
     $z = new Archive::Zip::SimpleUnzip $filehandle [, OPTIONS] ;

The constructor takes one mandatory parameter along with zero or more
optional parameters.

The mandatory parameter controls where the zip archive is read from.
This can be any one of the following:

=over 5

=item * Input from a Filename

When SimpleUnzip is passed a string, it will read the zip archive from the
filename stored in the string.

=item * Input from a String

When SimpleUnzip is passed a string reference, like C<\$buffer>, it will
read the in-memory zip archive from that string.

=item * Input from a Filehandle

When SimpleUnzip is passed a filehandle, it will read the zip archive from
that filehandle. Note the filehandle must be seekable.


=back

See L</Options> for a list of the optional parameters that can be specified
when calling the constructor.

=head2 Options

=over 5

=item -FilesOnly => 1|0

When true, ignore members in the zip archive that are directories.

Enabling this option will change the behaviour of the C<names>, C<next> and C<exists> methods.

Default is false.

=back

=head2 Methods

=over 5

=item $buffer = $z->content($member)

Returns the uncompressed data stored in $member.
Returns C<undef> if the member does not exist.

=item $buffer = $z->extract($member [, $outfile])

Uncompresses the data stored in $member and writes it to the filesystem.
By default the filename used is the member name. 
If the optional parameter $outfile is specified, the payload is written to that file instead.


=item $string = $z->comment()

Returns the comment, if any, associated with the zip archive.

=item $z->exists("name")

Tests for the existence of member "name" in the zip archive.

=item $count = $z->names()

=item @names = $z->names()

In scalar context returns the number of members in the Zip archive.

In array context returns a list of the names of the members in the Zip archive.

=item $z->next()

Returns the next member from the zip archive as a
Archive::Zip::SimpleUnzip::Member object.
See L</Archive::Zip::SimpleUnzip::Member>

Standard usage is

    use Archive::Zip::SimpleUnzip qw($SimpleUnzipError) ;

    my $match = "hello";
    my $zipfile = "my.zip";

    my $z = new Archive::Zip::SimpleUnzip $zipfile
        or die "Cannot open zip file: $SimpleUnzipError\n" ;

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

Closes the zip archive.

=back

=head1 Archive::Zip::SimpleUnzip::Member

The C<next> method from C<Archive::Zip::SimpleUnzip> returns a member object of
type C<Archive::Zip::SimpleUnzip::Member>
that has the following methods.

=over 5

=item $string = $m->name()

Returns the name of the member.

=item $string = $m->comment()

Returns the member comment.

=item $data = $m->content()

Returns the uncompressed content.

=item $buffer = $z->extract()
=item $buffer = $z->extract($outfile])

Uncompresses the data stored in the current member and writes to the filesystem.
By default the filename used is the member name. 
If the optional parameter $outfile is specified, the payload is written to that file instead.

=item $fh = $m->open()

Returns a filehandle that can be used to read the uncompressed content.

=item $bool = $m->isDirectory()

Returns true is the member is a directory.
Otherwise returns false.

=item $bool = $m->isFile()

Returns true is the member is standard file.
Otherwise returns false.

=back

=head1 Examples

=head2 Print the contents of a Zip member

The code below shows how this module is used to
read the contents of the member
"abc.txt" from the zip archive  "my1.zip".

    use Archive::Zip::SimpleUnzip qw($SimpleUnzipError) ;

    my $z = new Archive::Zip::SimpleUnzip "my1.zip"
        or die "Cannot open zip file: $SimpleUnzipError\n" ;

    my $name = "abc.txt";
    if ($z->exists($name))
    {
        print $z->content($name);
    }
    else
    {
        warn "$name not present in my1.zip\n"
    }

=head2 Iterate through a Zip file

    use Archive::Zip::SimpleUnzip qw($SimpleUnzipError) ;

    my $zipfile = "my.zip";
    my $z = new Archive::Zip::SimpleUnzip $zipfile
        or die "Cannot open zip file: $SimpleUnzipError\n" ;

    my $members = $z->names();
    print "Zip file '$zipfile' has $members entries\n";

    while (my $member = $z->next())
    {
        print "$member->name()\n";
    }

=head2 Filehandle interface

Here is a simple grep, that walks through a zip file and
prints matching strings present in the compressed payload.
The C<FilesOnly> option has been included in the call to the
constructor to automaticaly skip members that just contain directories.

    use Archive::Zip::SimpleUnzip qw($SimpleUnzipError) ;

    my $match = "hello";
    my $zipfile = "my.zip";

    my $z = new Archive::Zip::SimpleUnzip $zipfile, FilesOnly => 1
        or die "Cannot open zip file: $SimpleUnzipError\n" ;

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

=head2 rezip

Another example that uses the filehandle interface. This time the code uses C<Archive::Zip::SimpleUnzip>
to get a filehandle for each member of a zip archive which it passes to  C<Archive::Zip::SimpleZip> to recompress.


    use Archive::Zip::SimpleUnzip qw($SimpleUnzipError) ;
    use Archive::Zip::SimpleZip qw($SimpleZipError Z_BEST_COMPRESSION) ;

    my $input  = shift ;
    my $output = shift ;

    my $unzip = new Archive::Zip::SimpleUnzip $input
                    or die "Cannot open '$input': $SimpleUnzipError";

    my $zip = new Archive::Zip::SimpleZip $output, Level => Z_BEST_COMPRESSION
            or die "Cannot create zip file '$output': $SimpleZipError";

    while (my $member = $unzip->next())
    {
        my $name = $member->name();
        warn "Processing member $name\n"  ;

        my $fh = $member->open();

        $zip->addFileHandle($fh, Name => $name)
                or die "Cannot addFileHandle file '$file': $SimpleZipError\n" ;
    }


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

=head1 SEE ALSO


L<Archive::Zip::SimpleZip>, L<Archive::Zip>, L<IO::Compress::Zip>,  L<IO::Uncompress::UnZip>


=head1 AUTHOR

This module was written by Paul Marquess, F<pmqs@cpan.org>.

=head1 MODIFICATION HISTORY

See the Changes file.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2019 Paul Marquess. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.