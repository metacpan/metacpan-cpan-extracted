package Archive::Zip::SimpleZip;

use strict;
use warnings;

require 5.006;

use IO::Compress::Zip 2.081 qw(:all);
use IO::Compress::Base::Common  2.081 ();
use IO::Compress::Adapter::Deflate 2.081 ;

use Fcntl ();
use File::Spec ();
use IO::File ();
use Scalar::Util ();
use Carp;
require Exporter ;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS, $SimpleZipError);

$SimpleZipError= '';
$VERSION = "0.024";

@ISA = qw(Exporter);
@EXPORT_OK = qw( $SimpleZipError ) ;

%EXPORT_TAGS = %IO::Compress::Zip::EXPORT_TAGS ;

Exporter::export_ok_tags('all');

our %PARAMS = (
        'name'          => [IO::Compress::Base::Common::Parse_any,       ''],
        'comment'       => [IO::Compress::Base::Common::Parse_any,       ''],
        'zipcomment'    => [IO::Compress::Base::Common::Parse_any,       ''],
        'stream'        => [IO::Compress::Base::Common::Parse_boolean,   0],
        'method'        => [IO::Compress::Base::Common::Parse_unsigned,  ZIP_CM_DEFLATE],
        'minimal'       => [IO::Compress::Base::Common::Parse_boolean,   0],
        'zip64'         => [IO::Compress::Base::Common::Parse_boolean,   0],
        'filtername'    => [IO::Compress::Base::Common::Parse_code,      undef],
        'canonicalname' => [IO::Compress::Base::Common::Parse_boolean,   1],
        'textflag'      => [IO::Compress::Base::Common::Parse_boolean,   0],
        'storelinks'    => [IO::Compress::Base::Common::Parse_boolean,   0],
        'autoflush'     => [IO::Compress::Base::Common::Parse_boolean,   0],        
        #'storedirs'    => [IO::Compress::Base::Common::Parse_boolean,   0],
        'encode'       => [IO::Compress::Base::Common::Parse_any,        undef],
        #'extrafieldlocal'  => [IO::Compress::Base::Common::Parse_any,    undef],
        #'extrafieldcentral'=> [IO::Compress::Base::Common::Parse_any,    undef],
        'filtercontainer' => [IO::Compress::Base::Common::Parse_code,  undef],
#        'time'          => [IO::Compress::Base::Common::Parse_any,       undef],
#        'extime'        => [IO::Compress::Base::Common::Parse_any,       undef],        
        
        # Zlib
        'level'         => [IO::Compress::Base::Common::Parse_signed,    Z_DEFAULT_COMPRESSION],
        'strategy'      => [IO::Compress::Base::Common::Parse_signed,    Z_DEFAULT_STRATEGY],

        # Lzma
        'preset'        => [IO::Compress::Base::Common::Parse_unsigned, 6],
        'extreme'       => [IO::Compress::Base::Common::Parse_boolean,  0],
        
        # Bzip2
        'blocksize100k' => [IO::Compress::Base::Common::Parse_unsigned,  1],
        'workfactor'    => [IO::Compress::Base::Common::Parse_unsigned,  0],
        'verbosity'     => [IO::Compress::Base::Common::Parse_boolean,   0],
    );


sub _ckParams
{
    my $got = shift || IO::Compress::Base::Parameters::new();
    my $top = shift;
       
    $got->parse(\%PARAMS, @_) 
        or _myDie("Parameter Error: " . $got->getError())  ;
    
    if ($top)
    {
        for my $opt ( qw(name comment) )
        {
            _myDie("$opt option not valid in constructor")  
                if $got->parsed($opt);
        }
                        
        $got->setValue('crc32'   => 1);
        $got->setValue('adler32' => 0);
        $got->setValue('os_code' => $Compress::Raw::Zlib::gzip_os_code);
    }
    else
    {
        for my $opt ( qw( zipcomment) )
        {
            _myDie("$opt option only valid in constructor")  
                if $got->parsed($opt);
        }
    }
    
    my $e = $got->getValue("encode");
    if (defined $e)
    {
        _myDie("Encode::find_encoding not found") if ! defined &Encode::find_encoding;
        _myDie("Unknown Encoding '$e'")           if ! defined Encode::find_encoding($e) ;
    }

    return $got;
}

sub _illegalFilename
{
    return _setError(undef, undef, "Illegal Filename") ;
}


#sub simplezip
#{
#    my $from = shift;
#    my $filename = shift ;
#    #my %opts
#
#    my $z = new Archive::Zip::SimpleZip $filename, @_;
#
#    if (ref $from eq 'ARRAY')
#    {
#        $z->add($_) for @$from;
#    }
#    elsif (ref $from)
#    {
#        die "bad";
#    }
#    else
#    {
#        $z->add($filename);
#    }
#
#    $z->close();
#}


sub new
{
    my $class = shift;
    
    $SimpleZipError = '';
    
    return _setError(undef, undef, "Missing Filename") 
        unless @_ ;
       
    my $outValue = shift ;  
    my $fh;
    
    if (!defined $outValue)
    {
        return _illegalFilename
    }

    my $isSTDOUT = ($outValue eq '-') ;
    my $outType = IO::Compress::Base::Common::whatIsOutput($outValue);
    
    if ($outType eq 'filename')
    {
        if (-e $outValue && ( ! -f _ || ! -w _))
        {
            return _illegalFilename
        }
        
        $fh = new IO::File ">$outValue"    
            or return _illegalFilename;         
    }
    elsif( $outType eq 'buffer' || $outType eq 'handle')
    {
        $fh = $outValue;
    }
    else
    {
        return _illegalFilename        
    }
    
    my $got = _ckParams(undef, 1, @_);
    $got->setValue('autoclose' => 1) unless $outType eq 'handle' ;
    $got->setValue('stream' => 1) if $isSTDOUT ;   

    my $obj = {
                ZipFile      => $outValue,
                FH           => $fh,
                Open         => 1,
                FilesWritten => 0,
                Opts         => $got,
                Error        => undef,
                Raw          => undef,                
              };

    bless $obj, $class;
}

sub DESTROY
{
    my $self = shift;       
    $self->close();
}

sub close
{
    my $self = shift;
   
    return 0
        if ! $self->{Open} ; 

    $self->{Open} = 0;
    if ($self->{FilesWritten} || defined $self->{Raw})
    {
         if(defined $self->{Zip})
         {                   
             if (defined $self->{Raw})   
             {
                 $self->{Raw} = undef ;
             }
             
            $self->{Zip}->_flushCompressed() || return 0;
            $self->{Zip}->close() || return 0;
            delete $self->{Zip} ;
         }
    }
      
    1;
}

sub _newStream
{
    my $self = shift;
    my $filename = shift ;
    my $options =  shift;

    if (defined $filename)
    {
        IO::Compress::Zip::getFileInfo(undef, $options, $filename) ;
    
        # Force STORE for directories, symbolic links & empty files
        $options->setValue(method => ZIP_CM_STORE)  
            if -d $filename || -z _ || -l $filename ;
    }

    # Archive::Zip::SimpleZip handles canonical    
    $options->setValue(canonicalname => 0);

    $! = 0;    
    if (! defined $self->{Zip}) {
        $self->{Zip} = IO::Compress::Base::Common::createSelfTiedObject('IO::Compress::Zip', \$SimpleZipError);    
        $self->{Zip}->_create($options, $self->{FH})        
            or die "_create $SimpleZipError";
        $self->{Zip}->_autoflush()
            if  $options->getValue('autoflush');       
            
    }
    else {
        $self->{Zip}->_newStream($options)
            or die "_newStream - $SimpleZipError";
    }
    
    ++ $self->{FilesWritten} ;
    
    return 1;
}


sub _setError
{  
    $SimpleZipError = $_[2] ;
    $_[0]->{Error} = $_[2]
        if defined  $_[0] ;
    
    return $_[1];
}


sub error
{
    my $self = shift;
    return $self->{Error};
}

sub _myDie
{
    $SimpleZipError = $_[0];
    Carp::croak $_[0];

}

sub _stdPreq
{
    my $self = shift;
    
    return 0 
        if $self->{Error} ; 
            
    return $self->_setError(0, "Zip file closed") 
        if ! $self->{Open} ;
            
    return $self->_setError(0, "openMember filehandle already open") 
        if  defined $self->{Raw};
           
     return 1;    
}

sub add
{
    my $self = shift;
    my $filename = shift;

    $self->_stdPreq or return 0 ;
        
    return $self->_setError(0, "File '$filename' does not exist") 
        if ! -e $filename  ;
        
    return $self->_setError(0, "File '$filename' cannot be read") 
        if ! -r $filename ;        
    
    my $options =  $self->{Opts}->clone();
        
    my $got = _ckParams($options, 0, @_);
    
    # Force Encode off.
    $got->setValue('encode', undef);

    my $isLink = $got->getValue('storelinks') && -l $filename ;
    my $isDir = -d $filename;
    
    return 0
        if $filename eq '.' || $filename eq '..';
    
    if ($options->getValue("canonicalname"))
    {    
        if (! $got->parsed("name"))
        {
            $got->setValue(name => IO::Compress::Zip::canonicalName($filename, $isDir && ! $isLink));
        }
        else
        {
            $got->setValue(name => IO::Compress::Zip::canonicalName($got->getValue("name"), $isDir && ! $isLink));     
        }
    }
    
    my ($mode, $uid, $gid, $size, $atime, $mtime, $ctime) ;

    if ( $got->parsed('storelinks') )
    {
        ($mode, $uid, $gid, $size, $atime, $mtime, $ctime) 
                = (lstat($filename))[2, 4, 5, 7, 8, 9, 10] ;
    }
    else
    {
        ($mode, $uid, $gid, $size, $atime, $mtime, $ctime) 
                = (stat($filename))[2, 4, 5,7, 8, 9, 10] ;
    }

    $got->setValue(time => $mtime);

    if (! $got->getValue('minimal')) {

        $got->setValue(extime => [$atime, $mtime, $ctime]) ;

        use Perl::OSType;
        my $type = Perl::OSType::os_type();
        if ( $type eq 'Unix' ) 
        {
            $got->setValue(exunixn => [$uid, $gid]) ;
        }
        # TODO add Windows 
    }

    $self->_newStream($filename, $got);
    
    if($isLink)
    {
        my $target = readlink($filename);
        $self->{Zip}->write($target);
    }
    elsif (-d $filename)
    {
        # Do nothing, a directory has no payload
    }
    elsif (-f $filename)
    {
        my $fh = new IO::File "<$filename"
            or die "Cannot open file $filename: $!";

        binmode $fh;

        my $data; 
        my $last ;
        while ($fh->read($data, 1024 * 16))
        {
            $self->{Zip}->write($data);
        }
    }
    else
    {
        return 0;
    }

    return 1;
}


sub addString
{
    my $self    = shift;
    my $string  = shift;   

    $self->_stdPreq or return 0 ;

    my $options =  $self->{Opts}->clone();
        
    my $got = _ckParams($options, 0, @_);
    
    _myDie("Missing 'Name' parameter in addString")
        if ! $got->parsed("name");

    $got->setValue(name => IO::Compress::Zip::canonicalName($got->getValue("name")))
        if $options->getValue("canonicalname") ;        

    $self->_newStream(undef, $got);
    $self->{Zip}->write($string);    
    
    return 1;            
}

sub addFileHandle
{
    my $self = shift;
    my $fh   = shift;   

    $self->_stdPreq or return 0 ;

    my $options =  $self->{Opts}->clone() ;
        
    my $got = _ckParams($options, 0, @_);
    
    _myDie("Missing 'Name' parameter in addFileHandle")
        if ! $got->parsed("name");

    $got->setValue(name => IO::Compress::Zip::canonicalName($got->getValue("name")))
        if $options->getValue("canonicalname") ;        

    $self->_newStream(undef, $got);
    
    my $data; 

    while ($fh->read($data, 1024 * 16))
    {
        $self->{Zip}->write($data);
    }     
    
    return 1;   
}

# sub createDirectory
# {
#     my $self = shift ;
#     my $directory = shift;

#     # TODO - file attributes

#     $self->_stdPreq or return 0 ;

#     my $got = _ckParams($options, 0, @_);
#     $got->setValue(name => IO::Compress::Zip::canonicalName($filename, 1));

#     $self->_newStream(undef, $got);
        
#     return 1;   
# }

sub openMember
{
    my $self    = shift;     

    $self->_stdPreq or return undef ;

    my $options =  $self->{Opts}->clone();
        
    my $got = _ckParams($options, 0, @_);
    
    _myDie("Missing 'Name' parameter in openMember")
        if ! $got->parsed("name");
        
    $got->setValue(name => IO::Compress::Zip::canonicalName($got->getValue("name")))
        if $options->getValue("canonicalname") ;           

    $self->_newStream(undef, $got);
  
#  if (1)
#  {
    my $z = IO::Compress::Base::Common::createSelfTiedObject("Archive::Zip::SimpleZip::Handle", \$SimpleZipError) ;

    $self->{Raw} = 1;
    
    *$z->{Open} = 1 ;
    *$z->{SZ} = $self;
    Scalar::Util::weaken *$z->{SZ}; # for 5.8
    
    return $z;
#  }
#  else
#  { 
#    my $handle = Symbol::gensym();
#    tie *$handle, "Archive::Zip::SimpleZip::Handle", $self, $self->{Zip};  
#    
#    $self->{Raw} = 1;      
#    
#    return $handle;
#  }      
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
    package Archive::Zip::SimpleZip::Handle ;
              
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
            *$self->{SZ}{Raw} = undef ;
            *$self->{SZ} = undef ;
        }

        1;
    }
    
    sub print
    {
        my $self = shift;
        $self->_stdPreq() or return 0 ;    
        
        *$self->{SZ}{Zip}->print(@_);
    }
    
    sub printf
    {
        my $self = shift;
        $self->_stdPreq() or return 0 ;
        
        *$self->{SZ}{Zip}->printf(@_);
    }
    
    sub syswrite
    {
        my $self = shift;
        $self->_stdPreq() or return 0 ;
        
        *$self->{SZ}{Zip}->syswrite(@_);
    }
    
    sub tell
    {
        my $self = shift;
        $self->_stdPreq() or return 0 ;
        
        *$self->{SZ}{Zip}->tell(@_);
    }
    
    sub eof
    {
        my $self = shift;
        $self->_stdPreq() or return 0 ;
        
        *$self->{SZ}{Zip}->eof;
    }

    sub _stdPreq
    {
        my $self = shift;
                                           
        return _setError("Zip file closed") 
            if ! defined defined *$self->{SZ} || ! *$self->{SZ}{Open} ; 
            
                            
        return _setError("openMember filehandle closed") 
            if  ! *$self->{Open} || ! defined *$self->{SZ}{Raw};
            
        return 0 
            if *$self->{SZ}{Error} ; 
                          
         return 1;    
    }
    
    sub _setError
    {  
        $Archive::Zip::SimpleZip::SimpleZipError = $_[0] ;
        return 0;
    }        
       
    sub binmode { 1 }
#    sub clearerr { $Archive::Zip::SimpleZip::SimpleZipError = '' }

    *FILENO   = \&fileno;
    *PRINT    = \&print;
    *PRINTF   = \&printf;
    *WRITE    = \&syswrite;
    *write    = \&syswrite;
    *TELL     = \&tell;
    *EOF      = \&eof;
    *CLOSE    = \&close;
    *BINMODE  = \&binmode;
}

#{
#    package Archive::Zip::SimpleZip::HandleNEW ;
#
## TODO - fix this
##    require Tie::Handle;
##
##    @ISA = qw(Tie::Handle);
##@ISA = qw(IO::Handle) ;
#              
#    sub TIEHANDLE
#    {
#        my $class = shift;
#        my $parent = shift;
#        my $zip = shift;
#        my $errorRef = shift;
#        
#        my %obj = (
#            Zip  => $zip ,
#            SZ   => $parent,
#            Open => 1,
#        ) ;
#
#        Scalar::Util::weaken $obj{SZ}; # for 5.8  
#        return bless \%obj, $class;  
#    }
#      
#    sub UNTIE
#    {
#        my $self = shift ;
#    }
#    
#    sub DESTROY
#    {
#        my $self = shift ;
#        local ($., $@, $!, $^E, $?);
#        $self->close() ;
#    
#        # TODO - memory leak with 5.8.0 - this isn't called until 
#        #        global destruction
#        #
#        %{ $self } = () ;
#        undef $self ;
#    }
#             
#    sub close
#    {
#        my $self = shift ;
#        return 1 if ! $self->{Open};
#        
#        $self->{Open} = 0 ;
#        
##        untie *$self 
##            if $] >= 5.008 ;
#
#        if (defined $self->{SZ})
#        {
#            $self->{SZ}{Raw} = undef ;
#            $self->{SZ} = undef ;
#        }
#
#        1;
#    }
#    
#    sub print
#    {
#        my $self = shift;
#        $self->_stdPreq() or return 0 ;    
#        
#        $self->{Zip}->print(@_);
#    }
#    
#    sub printf
#    {
#        my $self = shift;
#        $self->_stdPreq() or return 0 ;
#        
#        $self->{Zip}->printf(@_);
#    }
#    
#    sub syswrite
#    {
#        my $self = shift;
#        $self->_stdPreq() or return 0 ;
#        
#        $self->{Zip}->syswrite(@_);
#    }
#    
#    sub tell
#    {
#        my $self = shift;
#        $self->_stdPreq() or return 0 ;
#        
#        $self->{Zip}->tell(@_);
#    }
#    
#    sub eof
#    {
#        my $self = shift;
#        $self->_stdPreq() or return 0 ;
#        
#        $self->{Zip}->eof;
#    }
#
#    sub _stdPreq
#    {
#        my $self = shift;
#                                           
#        return _setError("Zip file closed") 
#            if ! defined defined $self->{SZ} || ! $self->{SZ}{Open} ; 
#            
#                            
#        return _setError("openMember filehandle closed") 
#            if  ! $self->{Open} || ! defined $self->{SZ}{Raw};
#            
#        return 0 
#            if $self->{SZ}{Error} ; 
#                          
#         return 1;    
#    }
#    
#    sub _setError
#    {  
#        $Archive::Zip::SimpleZip::SimpleZipError = $_[0] ;
#        return 0;
#    }        
#       
#    sub binmode { 1 }
##    sub clearerr { $Archive::Zip::SimpleZip::SimpleZipError = '' }
#
#    *FILENO   = \&fileno;
#    *PRINT    = \&print;
#    *PRINTF   = \&printf;
#    *WRITE    = \&syswrite;
#    *write    = \&syswrite;
#    *TELL     = \&tell;
##    sub IO::Handle::tell { bless $_[0], "Archive::Zip::SimpleZip::Handle" ; Archive::Zip::SimpleZip::Handle::tell @_ };
#    *EOF      = \&eof;
#    *CLOSE    = \&close;
#    *BINMODE  = \&binmode;
#}

1;

__END__

=head1 NAME

Archive::Zip::SimpleZip - Create Zip Archives

=head1 SYNOPSIS

    use Archive::Zip::SimpleZip qw($SimpleZipError) ;

    my $z = new Archive::Zip::SimpleZip "my.zip"
        or die "Cannot create zip file: $SimpleZipError\n" ;

    $z->add("/some/file1.txt");
    $z->addString("some text", Name => "myfile");
    $z->addFileHandle($FH, Name => "myfile2") ;

    $fh = $z->openMember(Name => "mydata1.txt");
    print $fh "some data" ;
    $fh->print("some more data") ;
    close $fh;

    $z->close();

=head1 DESCRIPTION

Archive::Zip::SimpleZip is a module that allows the creation of Zip
archives. For reading Zip archives, there is a companion module, called L<Archive::Zip::SimpleUnzip>, 
that can read Zip archives.

The module allows Zip archives to be written to a named file, a filehandle
or stored in-memory.

There are a small number methods available in Archive::Zip::SimpleZip, and
quite a few options, but for the most part all you need to know is how to
create a Zip archive and how to add a file to it. 

Below is an example of how this module is used to add the two files
"file1.txt" and "file2.txt" to the zip file called "my1.zip".

    use Archive::Zip::SimpleZip qw($SimpleZipError) ;

    my $z = new Archive::Zip::SimpleZip "my1.zip"
        or die "Cannot create zip file: $SimpleZipError\n" ;

    $z->add("/some/file1.txt");
    $z->add("/some/file2.txt");

    $z->close();

The data written to a zip archive doesn't need to come from the filesystem.
You can also write string data directly to the zip archive using the
C<addString> method, like this

    use Archive::Zip::SimpleZip qw($SimpleZipError) ;

    my $z = new Archive::Zip::SimpleZip "my2.zip"
        or die "Cannot create zip file: $SimpleZipError\n" ;

    $z->addString($myData, Name => "file2.txt");

    $z->close();

Alternatively you can use the C<openMember> option to get a filehandle that
allows you to write directly to the zip archive member using standard Perl
file output functions, like C<print>. 

    use Archive::Zip::SimpleZip qw($SimpleZipError) ;

    my $z = new Archive::Zip::SimpleZip "my3.zip"
        or die "Cannot create zip file: $SimpleZipError\n" ;

    my $fh = $z->openMember(Name => "file3.txt");

    $fh->print("some data");
    # can also use print $fh "some data"

    print $fh "more data" ;

    $fh->close() ; 
    # can also use close $fh;

    $z->close();

You can also "drop" a filehandle into a zip archive. 

    use Archive::Zip::SimpleZip qw($SimpleZipError) ;

    my $z = new Archive::Zip::SimpleZip "my4.zip"
        or die "Cannot create zip file: $SimpleZipError\n" ;

    my $fh = $z->addFileHandle(FH, Name => "file3.txt");

    $z->close();

=head2 Constructor

     $z = new Archive::Zip::SimpleZip "myzipfile.zip" [, OPTIONS] ;
     $z = new Archive::Zip::SimpleZip \$buffer [, OPTIONS] ;
     $z = new Archive::Zip::SimpleZip $filehandle [, OPTIONS] ;

The constructor takes one mandatory parameter along with zero or more
optional parameters.

The mandatory parameter controls where the zip archive is written.  This
can be any of the following

=over 5

=item * Output to a File

When SimpleZip is passed a string, it will write the zip archive to the
filename stored in the string.

=item * Output to a String

When SimpleZip is passed a string reference, like C<\$buffer>, it will
write the zip archive into that string.

=item * Output to a Filehandle

When SimpleZip is passed a filehandle, it will write the zip archive to
that filehandle. 

Use the string '-' to write the zip archive to standard output (Note - this
will also enable the C<Stream> option). 


=back

See L</Options> for a list of the optional parameters that can be specified
when calling the constructor.

=head2 Methods

=over 5

=item $z->add($filename [, OPTIONS])

The C<add> method writes the contents of the filename stored in
C<$filename> to the zip archive.
 
The following file types are supported.

=over 5

=item * Standard files

The contents of the file is written to the zip archive. 

=item * Directories

The directory name is stored in the zip archive.

=item * Symbolic Links

By default this module will store the contents of the file that the
symbolic link refers to.  To store the symbolic link itself set the
C<StoreLink> option to 1.


=back

By default the name of the member created in the zip archive will be
derived from the value of the C<$filename> parameter.  See L</File Naming
Options> for more details.  

See L</Options> for a full list of the options available for this method.

Returns 1 if the file was added, or 0. Check the $SimpleZipError for a
message.

=item $z->addString($string, Name => "whatever" [, OPTIONS]) 

The C<addString> method writes <$string> to the zip archive. The C<Name>
option I<must> be supplied.

See L</Options> for the options available for this method.

Returns 1 if the file was added, or 0. Check the $SimpleZipError for a
message.

=item $z->addFileHandle($fh, Name => "whatever" [, OPTIONS]) 

The C<addFileHandle> method assumes that C<$fh> is a valid filehandle that
is opened for reading. 

It writes what is read from C<$fh> to the zip archive 
until it reaches the eof. The filehandle, C<$fh>, will not be closed by C<addFileHandle>.

The C<Name> option I<must> be supplied.

See L</Options> for the options available for this method.

Returns 1 if the file was added, or 0. Check the C<$SimpleZipError> for a
message.

=item my $fh = $z->openMember(Name => "abc" [, OPTIONS]);

This option returns a filehandle (C<$fh>)that allows you to write directly
to a zip member. The C<Name> option I<must> be supplied.  See L</Options>
for the options available for this method.

The filehandle returned works just like a standard Perl filehandle, so all
the standard file output operators, like C<print>, are available to write
to the zip archive.

When you have finished writing data to the member, close the filehandle by
letting it go out of scope or by explicitly using either of the two forms 
shown below

    $fh->close()
    close $fh;

Once the filehandle is closed you can then open another member with 
C<openMember> or use the C<add> or
<addString> or C<>addFilehandle> methods.

Note that while a zip member has been opened with C<openMember>, you cannot
use the C<add> or <addString> methods, or open another member with
C<openMember>.

Also, if the enclosing zip object is closed whilst a filehandle is
still open for a zip member, it will be closed automatically.

Returns a filehandle on success or C<undef> on failure.

=item $z->close() 

Returns 1 if the zip archive was closed successfully, or 0. Check the
$SimpleZipError for a message.

=back 

=head1 Options

The majority of options are valid in both the constructor and in the
methods that accept options. Any exceptions are noted in the text below.

Options specified in the constructor will be used as the defaults for all
subsequent method calls.

For example, in the constructor below, the C<Method> is set to
C<ZIP_CM_STORE>. 

    use Archive::Zip::SimpleZip qw($SimpleZipError) ;

    my $z = new Archive::Zip::SimpleZip "my.zip",
                             Method => ZIP_CM_STORE 
        or die "Cannot create zip file: $SimpleZipError\n" ;

    $z->add("file1");
    $z->add("file2", Method => ZIP_CM_DEFLATE);
    $z->add("file3");

    $z->close();
   

The first call to C<add> doesn't specify the C<Method> option, so it uses
the value from the constructor (C<ZIP_CM_STORE>). The second call overrides
the default set in the constructor to use C<ZIP_CM_DEFLATE>. The third will
revert to using the default, C<ZIP_CM_STORE>. 
    

=head2 File Naming Options

The options listed below control how the names of the files are store in
the zip archive.

=over 5

=item C<< Name => $string >>

Stores the contents of C<$string> in the zip filename header field. 

When used with the C<add> method, this option will override any filename
that was passed as a parameter.

The C<Name> option is mandatory for the C<addString> method.

This option is not valid in the constructor.

=item C<< CanonicalName => 0|1 >>

This option controls whether the filename field in the zip header is
I<normalized> into Unix format before being written to the zip archive.

It is recommended that you keep this option enabled unless you really need
to create a non-standard Zip archive.

This is what APPNOTE.TXT has to say on what should be stored in the zip
filename header field.

    The name of the file, with optional relative path.          
    The path stored should not contain a drive or
    device letter, or a leading slash.  All slashes
    should be forward slashes '/' as opposed to
    backwards slashes '\' for compatibility with Amiga
    and UNIX file systems etc.

This option defaults to B<true>.

=item C<< FilterName => sub { ... }  >>

This option allow the filename field in the zip archive to be modified
before it is written to the zip archive.

This option takes a parameter that must be a reference to a sub.  On entry
to the sub the C<$_> variable will contain the name to be filtered. If no
filename is available C<$_> will contain an empty string.

The value of C<$_> when the sub returns will be  stored in the filename
header field.

Note that if C<CanonicalName> is enabled, a normalized filename will be
passed to the sub.

If you use C<FilterName> to modify the filename, it is your responsibility
to keep the filename in Unix format.

See L</Rename whilst adding> for an example of how the C<FilterName> option
can be used.

=back

Taking all the options described above, filename entry stored in a Zip
archive is constructed as follows.

The initial source for the filename entry that gets stored in the zip
archive is the filename parameter supplied to the C<add> method, or the
value supplied with the C<Name> option to the C<addString> and
C<openMember> methods. 

Next, for the C<add> option, if the C<Name> option is supplied that will
overide the filename parameter.

If the C<CanonicalName> option is enabled, and it is by default, the
filename gets normalized into Unix format.  If the filename was absolute,
it will be changed into a relative filename.

Finally, is the C<FilterName> option is enabled, the filename will get
passed to the sub supplied via the C<$_> variable.  The value of C<$_> on
exit from the sub will get stored in the zip archive.

Here are some examples

    use Archive::Zip::SimpleZip qw($SimpleZipError) ;

    my $z = new Archive::Zip::SimpleZip "my.zip"
        or die "$SimpleZipError\n" ;

    # store "my/abc.txt" in the zip archive
    $z->add("/my/abc.txt") ;

    # store "/my/abc.txt" in the zip archive
    $z->add("/my/abc.txt", CanonoicalName => 0) ;
    
    # store "xyz" in the zip archive
    $z->add("/some/file", Name => "xyz") ;
 
    # store "file3.txt" in the zip archive
    $z->add("/my/file3.txt", FilterName => sub { s#.*/## } ) ;
        
    # no Name option, so store "" in the zip archive
    $z->addString("payload data") ;
            
    # store "xyz" in the zip archive
    $z->addString("payload data", Name => "xyz") ;
                        
    # store "/abc/def" in the zip archive
    $z->addString("payload data", Name => "/abc/def", CanonoicalName => 0) ;
                    
    $z->close(); 
  

=head2 Overall Zip Archive Structure

=over 5

=item C<< Minimal => 1|0 >>

If specified, this option will disable the automatic creation of all
I<extra> fields in the zip local and central headers (with the exception of
those needed for Zip64). 

In particular the following fields will not be created

    "UT" Extended Timestamp
    "ux" ExtraExtra Type 3 (if running Unix)


This option is useful in a number of scenarios. 

Firstly, it may be needed if you require the zip files created by
C<Archive::Zip::SimpleZip> to be read using a legacy version of unzip or by
an application that only supports a sub-set of the zip features.

The other main use-case when C<Minimal> is handy is when the data that
C<Minimal> suppresses is not needed, and so just adds unnecessary bloat to
the zip file.  The extra fields that C<Archive::Zip::SimpleZip> adds by
default all store information that assume the entry in the zip file
corresponds to a file that will be stored in a filesystem.  This
information is very useful when archiving files from a filesystem - it
means the unzipped files will more closely match their originals.  If the
zip file isn't going to be unzipped to a filesystem you can save a few
bytes by enabling <Minimal>.

This parameter defaults to 0.

=item C<< Stream => 0|1 >>

This option controls whether the zip archive is created in I<streaming
mode>.

Note that when outputting to a file or filehandle with streaming mode
disabled (C<Stream> is 0), the output file/handle I<must> be seekable.

When outputting to '-' (STDOUT) the C<Stream> option is automatically
enabled.

The default is 0.

=item C<< Zip64 => 0|1 >>

ZIP64 is an extension to the Zip archive structure that allows 

=over 5

=item * Zip archives larger than 4Gig.

=item * Zip archives with more that 64K members.

=back

The module will automatically enable ZIP64 mode as needed when creating zip
archive.  

You can force creation of a Zip64 zip archive by enabling this option.

If you intend to manipulate the Zip64 zip archives created with this module
using an external zip/unzip program/library, make sure that it supports
Zip64.   

The default is 0.

=back

=head2 Other Options

=over 5

=item C<< AutoFlush => 0|1 >>

When true this option enabled flushing of the underlying filehandle after
each write/print operation.

If SimpleZip is writing to a buffer, this option is ignored.



=item C<< Comment => $comment >>

This option allows the creation of a comment that is associated with the
member added to the zip archive with the C<add> and C<addString> methods. 

This option is not valid in the constructor.

By default, no comment field is written to the zip archive.

=item C<< Encode => "encoding" >>

The C<Encode> option allows you to set the character encoding of the data
before it is compressed and written to the zip file. The option is only
valid with the C<add> or C<addString> methods. It will be ignored if you
use it with the C<add> option.

Under the hood this option relies on the C<Encode> module to carry do the
hard work. In particular it uses the C<Encode::find_encoding> to check that
the encoding you have request exists.
   
    use Archive::Zip::SimpleZip qw($SimpleZipError) ;

    my $z = new Archive::Zip::SimpleZip "my.zip"
        or die "$SimpleZipError\n" ;
       
    $z->addString("payload data", Encode => "utf8") ;


=item C<< Method => $method >>

Controls which compression method is used. At present four compression
methods are supported, namely, Store (no compression at all), Deflate,
Bzip2 and Lzma.

The symbols, ZIP_CM_STORE, ZIP_CM_DEFLATE, ZIP_CM_BZIP2 and ZIP_CM_LZMA are
used to select the compression method.

These constants are not imported by default by this module.

    use Archive::Zip::SimpleZip qw(:zip_method);
    use Archive::Zip::SimpleZip qw(:constants);
    use Archive::Zip::SimpleZip qw(:all);

Note that to create Bzip2 content, the module C<IO::Compress::Bzip2> must
be installed. A fatal error will be thrown if you attempt to create Bzip2
content when C<IO::Compress::Bzip2> is not available.

Note that to create Lzma content, the module C<IO::Compress::Lzma> must be
installed. A fatal error will be thrown if you attempt to create Lzma
content when C<IO::Compress::Lzma> is not available.

The default method is ZIP_CM_DEFLATE for files and ZIP_CM_STORE for
directories and symbolic links.



=item C<< StoreLink => 1|0  >>

Controls what C<Archive::Zip::SimpleZip> does with a symbolic link
(assuming your operating system supports .

When true, it stores the link itself.  When false, it stores the contents
of the file the link refers to.

If your platform does not support symbolic links this option is ignored.

Default is 0.



=item C<< TextFlag => 0|1 >>

This parameter controls the setting of a flag in the zip central header. It
is used to signal that the data stored in the zip archive is probably text.

The default is 0. 
        

=item C<< ZipComment => $comment >>

This option allows the creation of a comment field for the entire zip
archive.

This option is only valid in the constructor.

By default, no comment field is written to the zip archive.


=back
 

=head2 Deflate Compression Options

These option are only valid if the C<Method> is ZIP_CM_DEFLATE. They are
ignored otherwise.

=over 5

=item C<< Level => value >> 

Defines the compression level used by zlib. The value should either be a
number between 0 and 9 (0 means no compression and 9 is maximum
compression), or one of the symbolic constants defined below.

   Z_NO_COMPRESSION
   Z_BEST_SPEED
   Z_BEST_COMPRESSION
   Z_DEFAULT_COMPRESSION

The default is Z_DEFAULT_COMPRESSION.

=item C<< Strategy => value >> 

Defines the strategy used to tune the compression. Use one of the symbolic
constants defined below.

   Z_FILTERED
   Z_HUFFMAN_ONLY
   Z_RLE
   Z_FIXED
   Z_DEFAULT_STRATEGY

The default is Z_DEFAULT_STRATEGY.

=back  
        

=head2 Bzip2 Compression Options

These option are only valid if the C<Method> is ZIP_CM_BZIP2. They are
ignored otherwise.

=over 5

=item C<< BlockSize100K => number >>

Specify the number of 100K blocks bzip2 uses during compression. 

Valid values are from 1 to 9, where 9 is best compression.

The default is 1.

=item C<< WorkFactor => number >>

Specifies how much effort bzip2 should take before resorting to a slower
fallback compression algorithm.

Valid values range from 0 to 250, where 0 means use the default value 30.


The default is 0.

=back

=head2 Lzma Compression Options

These option are only valid if the C<Method> is ZIP_CM_LZMA. They are
ignored otherwise.

=over 5

=item C<< Preset => number >>

Used to choose the LZMA compression preset.

Valid values are 0-9 and C<LZMA_PRESET_DEFAULT>.

0 is the fastest compression with the lowest memory usage and the lowest
compression.

9 is the slowest compession with the highest memory usage but with the best
compression.

Defaults to C<LZMA_PRESET_DEFAULT> (6).

=item C<< Extreme => 0|1 >>

Makes LZMA compression a lot slower, but a small compression gain.

Defaults to 0.


=back

=head1 Summary of Default Behaviour

By default C<Archive::Zip::SimpleZip> will  do the following

=over 5

=item * Use Deflate Compression for all standard files. 

=item * Create a non-streamed Zip archive.

=item * Follow Symbolic Links

=item * Canonicalise the filename before adding it to the zip archive

=item * Only use create a ZIP64 Zip archive if any of the input files is greater than 4 Gig or there are more than 64K members in the zip archive.

=item * Fill out the following zip extended attributes

    "UT" Extended Timestamp
    "ux" ExtraExtra Type 3 (if running Unix)
    

=back
  

You can change the behaviour of most of the features mentioned above.

=head1 Examples

=head2 A Simple example

Add all the "C" files in the current directory to the zip archive "my.zip".

    use Archive::Zip::SimpleZip qw($SimpleZipError) ;

    my $z = new Archive::Zip::SimpleZip "my.zip"
        or die "$SimpleZipError\n" ;

    for ( <*.c> )
    {
        $z->add($_) 
            or die "Cannot add '$_' to zip file: $SimpleZipError\n" ;
    }

    $z->close();
    
=head2 Creating an in-memory Zip archive

All you need to do if you want the zip archive to be created in-memory is
to pass a string reference to the constructor.  The example below will
store the zip archive in the variable C<$zipData>. 

    use Archive::Zip::SimpleZip qw($SimpleZipError) ;

    my $zipData ;
    my $z = new Archive::Zip::SimpleZip \$zipData
        or die "$SimpleZipError\n" ;

    $z->add("part1.txt");
    $z->close(); 

    
Below is a slight refinement of the in-memory story. As well as writing the
zip archive into memory, this example uses c<addString> to create the
member "part2.txt" without having to read anything from the filesystem.

    use Archive::Zip::SimpleZip qw($SimpleZipError) ;

    my $zipData ;
    my $z = new Archive::Zip::SimpleZip \$zipData
        or die "$SimpleZipError\n" ;

    $z->addString("some text", Name => "part2.txt");
    $z->close(); 

       
=head2 Rename whilst adding

The example below shows how the C<FilterName> option can be use to remove
the path from the filename before it gets written to the zip archive,
"my.zip".

    use Archive::Zip::SimpleZip qw($SimpleZipError) ;

    my $z = new Archive::Zip::SimpleZip "my.zip"
        or die "$SimpleZipError\n" ;

    for ( </some/path/*.c> )
    {
        $z->add($_, FilterName => sub { s[^.*/][] }  ) 
            or die "Cannot add '$_' to zip file: $SimpleZipError\n" ;
    }

    $z->close();

=head2 Adding a directory tree to a Zip archive 

If you need to add all (or part) of a directory tree into a Zip archive,
you can use the standard Perl module C<File::Find> in conjunction with this
module.

The code snippet below assumes you want the non-directories files in the
directory tree C<myDir> added to the zip archive C<found.zip>.  It also
assume you don't want the files added to include any part of the C<myDir>
relative path. 

    use strict;
    use warnings;

    use Archive::Zip::SimpleZip;
    use File::Find;

    my $filename = "found.zip";
    my $dir = "myDir";
    my $z = new Archive::Zip::SimpleZip $filename 
        or die "Cannot open file $filename\n";

    find( sub { $z->add($_) if ! -d $_ }, $dir);

    $z->close();

If you I<do> want to include relative paths, pass the C<$File::Find::name>
variable with the C<Name> option, as shown below.

    find( sub 
          { 
              $z->add($_, Name => $File::Find::name)                        
                   if ! -d $_ 
          },
          $dir);

=head2 Using addFileHandle

Say you have a number of old-style ".Z" compressed files that you want
to uncompress and put into a zip file. The script below, Z2zip.pl, will
do just that 

    use strict;
    use warnings;
    
    use Archive::Zip::SimpleZip qw($SimpleZipError);
    
    die "Usage: Z2zip.pl zipfilename file1.Z file2.Z...\n"
        unless @ARGV >= 2 ;
    
    my $zipFile = shift ;
    my $zip = new Archive::Zip::SimpleZip $zipFile
                or die "Cannot create zip file '$zipFile': $SimpleZipError";
    
    for my $Zfile (@ARGV)
    {
        my $cleanName = $Zfile ;
        $cleanName =~ s/\.Z$//;
    
        print "Adding $cleanName\n" ;
    
        open my $z, "uncompress -c $Zfile |" ;
    
        $zip->addFileHandle($z, Name => $cleanName) 
            or die "Cannot addFileHandle '$cleanName': $SimpleZipError\n" ;
    }

=head2 Another filehandle example - Working with Net::FTP

Say you want to read all the json files from ftp://ftp.perl.org/pub/CPAN/ 
using Net::FTP and write them directly
to a zip archive without having to store them in the filesystem first.

Here are a couple of ways to do that. The first uses the C<openMember> method
in conjunction with the C<Net::FTP::get> method as shown below. 

    use strict;
    use warnings;

    use Net::FTP;
    use Archive::Zip::SimpleZip qw($SimpleZipError);

    my $zipFile = "json.zip";
    my $host = 'ftp.perl.org';
    my $path = "/pub/CPAN";    
    
    my $zip = new Archive::Zip::SimpleZip $zipFile
            or die "Cannot create zip file '$zipFile': $SimpleZipError";

    my $ftp = new Net::FTP($host)
        or die "Cannot connect to $host: $@";

    $ftp->login("anonymous",'-anonymous@')
        or die "Cannot login ", $ftp->message;

    $ftp->cwd($path)
        or die "Cannot change working directory ", $ftp->message;
    
    my @files = $ftp->ls()
        or die "Cannot ls", $ftp->message;

    for my $file ( grep { /json$/ } @files)
    {
        print " Adding $file\n" ;

        my $zipMember = $zip->openMember(Name => $file)
            or die "Cannot openMember file '$file': $SimpleZipError\n" ;

        $ftp->get($file, $zipMember)
            or die "Cannot get", $ftp->message;
    }


Alternatively, Net::FTP allows a read filehandle to be opened for a file to 
transferred using the C<retr> method. 
This filehandle can be I<dropped> into a zip archive using C<addFileHandle>.
The code below is a rewrite of the for loop in the previous version that 
shows how this is done.
    
    for my $file ( grep { /json$/ } @files)
    {
        print " Adding $file\n" ;

        my $fh = $ftp->retr($file) 
            or die "Cannot get", $ftp->message;
            
        $zip->addFileHandle($fh, Name => $file)
            or die "Cannot addFileHandle file '$file': $SimpleZipError\n" ;
            
        $fh->close()
            or die "Cannot close", $ftp->message;
    }

One point to be aware of with the C<Net::FTP::retr>. Not all FTP servers 
support it. See L<Net::FTP> for details of how to find out what features
an FTP server implements.


=head1 Importing 

A number of symbolic constants are required by some methods in
C<Archive::Zip::SimpleZip>. None are imported by default.

=over 5

=item :all

Imports C<zip>, C<$SimpleZipError> and all symbolic constants that can be
used by C<IArchive::Zip::SimpleZip>. Same as doing this

    use Archive::Zip::SimpleZip qw(zip $SimpleZipError :constants) ;

=item :constants

Import all symbolic constants. Same as doing this

    use Archive::Zip::SimpleZip qw(:flush :level :strategy :zip_method) ;

=item :flush

These symbolic constants are used by the C<flush> method.

    Z_NO_FLUSH
    Z_PARTIAL_FLUSH
    Z_SYNC_FLUSH
    Z_FULL_FLUSH
    Z_FINISH
    Z_BLOCK

=item :level

These symbolic constants are used by the C<Level> option in the
constructor.

    Z_NO_COMPRESSION
    Z_BEST_SPEED
    Z_BEST_COMPRESSION
    Z_DEFAULT_COMPRESSION

=item :strategy

These symbolic constants are used by the C<Strategy> option in the
constructor.

    Z_FILTERED
    Z_HUFFMAN_ONLY
    Z_RLE
    Z_FIXED
    Z_DEFAULT_STRATEGY

=item :zip_method

These symbolic constants are used by the C<Method> option in the
constructor.

    ZIP_CM_STORE
    ZIP_CM_DEFLATE
    ZIP_CM_BZIP2

=back

=head1 FAQ


=head2 Can SimpleZip update an existing Zip file?

No. You can only create a zip file from scratch.

=head2 Can I write a Zip Archive to STDOUT?

Yes. Writing zip files to filehandles that are not seekable (so that
includes both STDOUT and sockets) is supported by this module. You just
have to set the C<Stream> option when you call the constructor.

    use Archive::Zip::SimpleZip qw($SimpleZipError) ;

    my $zipData ;
    my $z = new Archive::Zip::SimpleZip '-',
                        Stream => 1
        or die "$SimpleZipError\n" ;

    $z->add("file1.txt");
    $z->close(); 

See L</What is a Streamed Zip file?> for a discussion on the C<Stream>
option.

=head2 Can I write a Zip Archive directly to a socket?

See previous question.

=head2 What is a Streamed Zip file?

Streaming mode allows you to write a zip file in situation where you cannot
seek backwards/forwards. The classic examples are when you are working with
sockets or need to write the zip file to STDOUT. 

By default C<Archive::Zip::SimpleZip> does I<not> use streaming mode when
writing to a zip file (you need to set the C<Stream> option to 1 to enable
it). 

If you plan to create a streamed Zip file be aware that it will be slightly
larger than the non-streamed equivalent. If the files you archive are
32-bit the overhead will be an extra 16 bytes per file written to the zip
archive. For 64-bit it is 24 bytes per file.


=head1 SEE ALSO


L<Archive::Zip::SimpleUnzip>, L<IO::Compress::Zip>, L<Archive::Zip>, L<IO::Uncompress::UnZip>


=head1 AUTHOR

This module was written by Paul Marquess, F<pmqs@cpan.org>. 

=head1 MODIFICATION HISTORY

See the Changes file.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2019 Paul Marquess. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
