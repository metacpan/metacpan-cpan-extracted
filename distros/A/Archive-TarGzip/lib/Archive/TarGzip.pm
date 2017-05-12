#!perl
#
# Documentation, copyright and license is at the end of this file.
#

package  Archive::TarGzip;

use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.03';
$DATE = '2004/05/14';
$FILE = __FILE__;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA= qw(Exporter);
@EXPORT_OK = qw(tar untar parse_header encode_tar);

my $tar_header_length = 512;

use Tie::Gzip;
use Cwd;
use Data::Startup 0.02;

use vars qw($default_options);
$default_options =  Archive::TarGzip->defaults();

#######
# Close the TAR file
#
sub CLOSE
{
     my $event = '';
     my ($self) = @_;
     my $fh = $self->{FH};
     unless ($fh) {
        return undef unless $self->{event};
        return undef if $self->{event} =~ /No open file handle/;
        $event = "No open file handle\n";
        goto EVENT;
     }
     print $fh "\0" x 1024 if $self->{flag} eq '>'; 
     my $success = close $fh;
     $self->{FH} = undef;
     return 1 if $success;
     return 0 if $self->{event} =~ /Bad close/;
     $event .= "Bad close\n\t$!\n";
     $event .= "\n\t" . $self->{file} . "\n" if $self->{file};

EVENT:
     $self->{event} .= $event;
     $self->{event} .= "\tArchive::TarGzip::CLOSE() $VERSION\n";
     if($self->{options}->{warn}) {
         warn($self->{event});
     }
     undef;
}


######
# Program module wide configuration
#
sub config
{
     $default_options = Archive::TarGzip->defaults() unless $default_options;
     my $self = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift :  $default_options;
     $self = ref($self) ? $self : $default_options;
     $self->Data::Startup::config(@_);

}



#######
# Object used to set default, startup, options values.
#
sub defaults
{
   my $class = shift;
   $class = ref($class) if ref($class);
   my $self = $class->Data::Startup::new(   
       warn => 1,
       compress => 1,
       gz_suffix => '.gz',
       tar_suffix => '.tar',
   );
   $self->Data::Startup::override(@_);

}



#######
# add a file to the TAR file
#
#
sub encode_tar
{
     my ($self, $file_name, $file_contents) = @_;
     my $tar = $self->{tar};

     ########
     # Pack the header
     #
     my ($prefix,$pos);
     if (length($file_name)>99) {
    	 $pos = index $file_name, "/",(length($file_name) - 100);
	 next if $pos == -1;	# Filename longer than 100 chars!
	
	 $prefix = substr $file_name,0,$pos;
	 $file_name = substr $file_name,$pos+1;
	 substr($prefix,0,-155)="" if length($prefix)>154;
     }
     else {
	 $prefix="";
     }

     my $umask = $self->{TarGzip}->{umask};
     $umask = umask unless $umask;
     my $size = length($file_contents);
     my $tar_contents = pack("a100a8a8a8a12a12a8a1a100",
        $file_name,
        sprintf("%6o ",($file_contents ? 0666 : 0777) & (0777-umask)), # mode
        sprintf("%6o ",0),  # uid
        sprintf("%6o ",0),  # gid
        sprintf("%11o ",$size),
        sprintf("%11o ",time()), # mtime
        "        ",  # chksum
        0,           # typeflag
        '');        # linkname
     $tar_contents .= pack("a6", "ustar\0"); # magic
     $tar_contents .= '00'; # version
     $tar_contents .= pack("a32","unknown"); # uname
     $tar_contents .= pack("a32","unknown"); # gname
     $tar_contents .= pack("a8",sprintf("%6o ",0)); # minor device
     $tar_contents .= pack("a8",sprintf("%6o ",0)); # major device
     $tar_contents .= pack("a155",$prefix);
     substr($tar_contents,148,6) = sprintf("%6o", unpack("%16C*",$tar_contents));
     substr($tar_contents,154,1) = "\0";
     $tar_contents .= "\0" x ($tar_header_length-length($tar_contents));
 
     ######
     # Add the file contents
     # 
     $tar_contents .= $file_contents;
     if ($size>0) {
	 $tar_contents .= "\0" x (512 - ($size%512)) unless $size%512==0;
     }
     \$tar_contents;
}


#####
#
#
sub EOF
{
     my $self = shift;
     my $fh = $self->{FH};
     unless ($fh) {
        return undef if $self->{event} =~ /No open file handle/;
        $self->{event} .= "No open file handle\n";
        $self->{event} .= "\tArchive::TarGzip::EOF() $VERSION\n";
        if($self->{warn}) {
            warn($self->{event});
        }
        return undef;
     }
     eof($fh);
}

######
#
#
sub FILENO
{
     my $self = shift;
     my $fh = $self->{FH};
     unless ($fh) {
        return undef if $self->{event} =~ /No open file handle/;
        $self->{event} .= "No open file handle\n";
        $self->{event} .= "\tArchive::TarGzip::FILENO() $VERSION\n";
        if($self->{options}->{warn}) {
            warn($self->{event});
        }
        return undef;
     }
     fileno($fh);
}


#####
# 
#
sub GETC
{
     my $self = shift; 
     return undef if $self->{event} =~ /GETC not supported/;
     $self->{event} .= "GETC not supported.\n";
     $self->{event} .= "\tArchive::TarGzip::GETC() $VERSION\n";
     if($self->{options}->{warn}) {
         warn($self->{event});
     }
     undef;
}


########
# Determines if a file handle
#
# Lifted from Archive::Tar
#
sub is_handle
{
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my $fh = shift ;

    return ((UNIVERSAL::isa($fh,'GLOB') or UNIVERSAL::isa(\$fh,'GLOB')) 
		and defined fileno($fh)  )
}

######
#
#
sub new
{

     ####################
     # $class is either a package name (scalar) or
     # an object with a data pointer and a reference
     # to a package name. A package name is also the
     # name of a class
     #
     my $class = shift;
     $class = ref($class) if( ref($class) );

     $default_options = Tie::Layers->default() unless $default_options;
     my $options = $default_options->Data::Startup::override(@_);
    
     #######
     # Using the Archive::Tar class and putting layer around it.
     # Bypassing the compress in Archive::Tar and using the 
     # compress herein. In this way if the Compress::Zlib package
     # is not present, the class methods herein will try to fall
     # back onto the gzip operating system common. A lot of Unix
     # ISP do not install Compress:Zlib because the availability of
     # the gzip command.
     #
     my $self = {};
     $self->{options} = $options;
     bless $self,$class;

}


######
#
#
sub OPEN 
{
     my ($self, $tar_file, @options) = @_;

     my $event;
     unless (defined $tar_file) {
        $event = "No inputs\n";
        goto EVENT;
     }
     $tar_file =~ s/^\s*([<>+|]+)\s*//;
     my $flag = $1;
     $self->{flag} = $flag;
     $tar_file = shift @options unless $tar_file;
     $self->{file} = $tar_file;

     my $options = $self->{options};

     #######
     # Try to find a file by adding extension for the tar and gz
     #
     my ($compress) = $options->{compress};

     ######
     # Open the table file
     #    
     if( is_handle($tar_file) ) {
         $self->{file} = '';
         $self->{FH} = $tar_file; 
     }

     else {

         my ($tar_suffix,$gz_suffix) = ($options->{tar_suffix},$options->{gz_suffix});
         my $targz_suffix = $tar_suffix . $gz_suffix;  
         my $tar_length = length($tar_suffix);
         my $targz_length = length($targz_suffix);

         #########################
         # Always write to a file using the correct suffices. TarGzip follows very
         # strict rules on what it writes out.
         #
         if( $flag eq '>' ) {
             if( $compress ) {
                 $tar_file .= $gz_suffix if substr($tar_file, -$tar_length, $tar_length) eq $tar_suffix;
                 $tar_file .= $targz_suffix unless substr($tar_file, -$targz_length, $targz_length) eq $targz_suffix;
             }
             else {
                 $tar_file .= $tar_suffix unless substr($tar_file, -$tar_length, $tar_length) eq $tar_suffix;
             }
         }

         ################
         # TarGzip is lenient on the file extensions it accepts for reading.
         #
         else {
             unless( -e $tar_file ) {
                 if( $compress ) {
                     $tar_file .= $gz_suffix if substr($tar_file, -$tar_length, $tar_length) eq $tar_suffix;
                     $tar_file .= $targz_suffix unless substr($tar_file, -$targz_length, $targz_length) eq $targz_suffix;
                 }
                 else {
                     $tar_file .= $tar_suffix unless substr($tar_file, -$tar_length, $tar_length) eq $tar_suffix;
                 }
                 unless( -e $tar_file ) {
                     warn("Cannot find $tar_file\n");
                     return undef;
                 }
             }
         }

         ########
         # Use a tie to process the tar data before writing to a file
         # This is usually used to compress using the gzip compression
         # 
         if ($compress) {
             if( $compress =~ /^Tie::/ ) {
                 require File::Package;
                 my $package_error = File::Package->load_package( $compress );
                 if($package_error) {
                    warn( $package_error);
                    return undef;
                }
                tie *TAR, $compress;
             }
             else {  
                tie *TAR, 'Tie::Gzip';
             }
         }

         ######
         # Open tar file
         #
         unless (open TAR, "$flag $tar_file") {
             warn( "Cannot open $flag $tar_file\n");
             return undef;
         }
         binmode TAR;
         $self->{FH} = \*TAR;
     }
     return 1;

EVENT:
     $self->{event} = $event;
     $self->{event} .= "\tTie::Layers::OPEN() $VERSION\n";
     if($self->{warn}) {
         warn($self->{event});
     }
     undef;
}



######
# This is taken directly from big loop in Archive::Tar::read_tar
# Need to get it out of the loop for use in this module
#
sub parse_header
{
     ######
     # This subroutine uses no object data.
     #
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

     unless(@_) {
         warn "No arguments.\n";
         return undef;
     }

     my $tar_unpack_header 
         = 'A100 A8 A8 A8 A12 A12 A8 A1 A100 A6 A2 A32 A32 A8 A8 A155';

     my ($header) = @_;

     ########
     # Apparently this should really be two blocks of 512 zeroes,
     # but GNU tar sometimes gets it wrong. See comment in the
     # source code (tar.c) to GNU cpio.
     return { end_of_tar => 1 } if $header eq "\0" x 512; # End of tar file
        
     my ($name,		# string
	 $mode,		# octal number
	 $uid,		# octal number
	 $gid,		# octal number
	 $size,		# octal number
	 $mtime,		# octal number
	 $chksum,		# octal number
	 $typeflag,		# character
	 $linkname,		# string
	 $magic,		# string
	 $version,		# two bytes
	 $uname,		# string
	 $gname,		# string
	 $devmajor,		# octal number
	 $devminor,		# octal number
	 $prefix) = unpack($tar_unpack_header, $header);
	
     $mode = oct $mode;
     $uid = oct $uid;
     $gid = oct $gid;
     $size = oct $size;
     $mtime = oct $mtime;
     $chksum = oct $chksum;
     $devmajor = oct $devmajor;
     $devminor = oct $devminor;
     $name = $prefix."/".$name if $prefix;
     $prefix = "";
 
     #########
     # some broken tar-s don't set the typeflag for directories
     # so we ass_u_me a directory if the name ends in slash
     $typeflag = 5 if $name =~ m|/$| and not $typeflag;
		
     my $error = '';
     substr($header,148,8) = "        ";
     $error .= "$name: checksum error.\n" unless (unpack("%16C*",$header) == $chksum);
     $error .= "$name: wrong header length\n" unless( $tar_header_length == length($header));

     my $end_of_tar = 0;
     # Guard against tarfiles with garbage at the end
     $end_of_tar = 1 if $name eq '';

     warn( $error ) if $error;

     return {
         name => $name,
	 mode => $mode,
	 uid => $uid,
	 gid => $gid,
	 size => $size,
	 mtime => $mtime,
	 chksum => $chksum,
	 typeflag => $typeflag,
	 linkname => $linkname,
	 magic => $magic,
	 version => $version,
	 uname => $uname,
	 gname => $gname,
	 devmajor => $devmajor,
	 devminor => $devminor,
	 prefix => $prefix,
         error => $error,
         end_of_tar => $end_of_tar,
         header_only => 0,
         skip_file => 0,
         data => ''};
}



#######
# add a file to the TAR file
#
sub PRINT
{
     my ($self, $file_name, $file_contents) = @_;
     my $handle = $self->{FH};
     $! = 0;
     unless( defined $file_contents ) {
         unless (open FILE, $file_name) {
             warn "Cannot open $file_name\n";
             return undef;
         }
         binmode FILE;
         $file_contents = join '', <FILE>;
         close FILE;
 
         ############################
         # Do not add empty files to tar archive file
         #
         return 1 unless $file_contents;

     }
     my $tar_contents = $self->encode_tar($file_name,$file_contents);
     my $success = print $handle $$tar_contents; 
     unless($success || $!) {
         $self->{event} .= "Bad Print.\n\t$!\n";
         $self->{event} .= "\tArchive::TarGzip::PRINT() $VERSION\n";
         if($self->{options}->{warn}) {
             warn($self->{event});
         }
         $self->CLOSE();
         return undef;
     }
     $success;
}


#####
# 
#
sub PRINTF
{
     my $self = shift;   
     return undef if $self->{event} =~ /PRINTF not supported/;
     $self->{event} .= "PRINTF not supported.\n";
     $self->{event} .= "\tArchive::TarGzip::READ() $VERSION\n";
     if($self->{options}->{warn}) {
         warn($self->{event});
     }
     undef;
}


#####
#
sub READ
{
     my $self = shift; 
     return undef if $self->{event} =~ /READ not supported/;
     $self->{event} .= "READ not supported.\n";
     $self->{event} .= "\tArchive::TarGzip::READ() $VERSION\n";
     if($self->{options}->{warn}) {
         warn($self->{event});
     }
     undef;
}

#####
#
#
sub READLINE
{

     my $self = shift @_;

     ####### 
     # Add any @files to the extract selection hash
     # 
     my $extract_p = $self->{options}->{extract_files};
     FileList2Sel(@_, $extract_p);
     my $extract_count = keys %$extract_p;

     ########
     # Read header
     #
     my $data;
     return undef unless $self->target(\$data, $tar_header_length );

     ########
     # Parse header
     #
     my $file_position = undef;
     $file_position = tell $self->{FH};
     my $header = parse_header( $data );
     return undef if $header->{end_of_tar};
     $header->{file_position} = $file_position if $file_position;

     #######
     # Process header_only option
     # 
     $header->{data} = '';
     $header->{header_only} = 0;
     $header->{skip_file} = 0;
     my $buffer_p = \$header->{data};
     if ($self->{options}->{header_only}) {
         $buffer_p = undef;
         $header->{header_only} = 1;
     }

     #######
     # Process extract file list
     # 
     if( $extract_count && !$extract_p->{$header->{name}} ) {
         $buffer_p = undef;
         $header->{skip_file} = 1;
         $header->{name} = '';
     }

     #######
     # Process exclude file list
     # 
     my $exclude_p = $self->{options}->{extract_files};
     my $exclude_count = scalar(keys %$exclude_p);
     if( $exclude_count && $exclude_p->{$header->{name}} ) {
         $buffer_p = undef;
         $header->{skip_file} = 1;
         $header->{name} = '';
     }
    
     #######
     # Read file contents
     # 
     my $size = $header->{size};
     return $header unless $size;
     return undef unless $self->target($buffer_p, $header->{size});

     ######
     # Trash bye padding to put on 512 byte boundary
     #
     $size = ($size % 512);
     return $header unless $size;
     $self->target(undef, 512 - $size);
     $header;

}



#####
#
#
sub target
{
     my ($self, $buffer_p, $size) = @_;
     my $handle = $self->{FH};
     my $bytes;
     if( $buffer_p ) {
         $$buffer_p = '';
         $bytes = read( $handle, $$buffer_p, $size);
         return undef unless $bytes == $size;
     }
     else {
         seek $handle, $size, 1;
         $bytes = $size;
     }
     $size
}




#######
# Store a number of files in one archive file in the tar format
#
sub tar
{
     ######
     # This subroutine uses no object data; therefore,
     # drop any class or object.
     #
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

     ######
     # pop last argument if last argument is an option
     #
     my $options = pop @_ if ref($_[-1]);
     if( ref($options) eq 'ARRAY') {
          my %options = @{$options};
          $options = \%options;
     }

     ##############
     # Rest of the arguments are file names and must
     # have at least one file name
     #
     unless(@_) {
         warn "No files.\n";
         return undef;
     }

     ########
     # Create a new tar file
     #
     my $tar;  
     return undef unless $tar = new Archive::TarGzip($options);
     return undef unless $tar->OPEN('>', $options->{tar_file});

     #####
     # Bring in some needed program modules
     #   
     require File::Spec;
     require File::AnySpec;

     ######
     # Process dest_dir and src_dir options
     #
     $options->{dest_dir} = '' unless $options->{dest_dir};
     my $dest_dir = $options->{dest_dir};
     $dest_dir = File::AnySpec->os2fspec('Unix',$dest_dir,'nofile');
     $dest_dir .= '/' unless $dest_dir && substr($dest_dir, -1, 1) eq '/';

     $options->{src_dir} = '' unless $options->{src_dir};
     my $src_dir = $options->{src_dir};

     #####
     # change to the source directory
     #
     my $restore_dir = cwd();
     chdir $src_dir if $src_dir;
 
     ########
     # Add destination directory to the tar file
     #
     my $contents;     
     if( $dest_dir ) {
         unless ($tar->PRINT($dest_dir, '')) {
             chdir $restore_dir;
             return undef;
         }
     }


     ##########
     # Make a separate copy of @files. Because changes in
     # $file_name are reflected back into @files, if @files
     # is @_, this would be reflected back into the calling
     # @_.
     #
     my @files = @_;

     ##############
     # Keep track of the directories put in tar archive so
     # do not duplicate any.
     #
     my %dirs = (); 
     foreach my $file_name (@files) {
 
         #######
         # Add directory path to the archive file
         #
         (undef, my $file_dir) = File::Spec->splitpath( $file_name ) ;
         my @file_dirs = File::Spec->splitdir($file_dir);
         my $dir_name = $dest_dir;
         foreach $file_dir (@file_dirs) {
             $dir_name = File::Spec::Unix->catdir( $dir_name, $file_dir) if $dir_name;
             unless( $dirs{$dir_name} ) {
                 $dirs{$dir_name} = 1;
                 $dir_name .= '/';
                 unless ($tar->PRINT($dir_name, '')) { # add a directory name, no content
                     chdir $restore_dir;
                     return undef;
                 }
             }
         }

         ########
         # Read the contents of the file
         #
         unless( open( CONTENT, "< $file_name") ) {
             $file_name = File::Spec->rel2abs($file_name);
             warn "Cannot read contents of $file_name\n";
             chdir $restore_dir;
             $tar->CLOSE( );
             return undef;
         }
         binmode CONTENT;
         my $file_contents = join '',<CONTENT>;
         close CONTENT;

         #######
         # Add the file to the tar archive file
         #  
         $file_name = File::AnySpec->os2fspec('Unix', $file_name);
         $file_name =  File::Spec::Unix->catfile($dest_dir,$file_name) if $dest_dir;
         unless ($tar->PRINT($file_name, $file_contents)) {
             chdir $restore_dir;
             return undef;
         }
  
     }
     chdir $restore_dir;

     $tar->CLOSE( );
     return $options->{tar_file};
}


sub TIEHANDLE { new(@_) }


#######
#
#
sub untar
{
     ######
     # This subroutine uses no object data; therefore,
     # drop any class or object.
     #
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

     ######
     # pop last argument if last argument is an option
     #
     my $options  = {};
     my $tar;  
     if( ref($_[-1]) ) {

         $options = pop @_ ;
         if( ref($options) eq 'ARRAY') {
              my %options = @{$options};
              $options = \%options;
         }
         return undef unless $tar = new Archive::TarGzip($options);

         #######
         # Add any inputs files to the extract file hash
         #
         FileList2Sel(@_, $tar->{TarGzip}->{extract_files});
     }

     else {
         my %options = @_;
         $options = \%options;
         return undef unless $tar = new Archive::TarGzip($options);
     }

     ######
     # Process options
     #
     my $tar_file = $options->{tar_file};
     unless( $tar_file ) {
          warn( "No tar file\n" );
          return undef;
     }

     #####
     # Bring in some needed program modules
     #   
     require File::Spec;
     require File::AnySpec;
     require File::Path;
     File::Path->import( 'mkpath' );

     ########
     # Attach to an existing tar file
     #
     return undef unless $tar->OPEN('<', $options->{tar_file});

     ########
     # Change to the destination directory where place the 
     # extracted files.
     #
     my $restore_dir = cwd();
     if ($options->{dest_dir}) {
         mkpath($options->{dest_dir});
         chdir $options->{dest_dir};
     }

     my ($tar_dir, $file_name, $dirs);
     while( 1 ) {

         $tar_dir = $tar->READLINE( );
         last unless defined $tar_dir;
         last if $tar_dir->{end_of_tar};
         next if $tar_dir->{skip_file};
         my $data = $tar_dir->{data};
         my $typeflag = $tar_dir->{typeflag};
         my $name = $tar_dir->{name};
         $typeflag = 5 if( substr($name,-1,1) eq '/' && !$data);
         $name = File::AnySpec->fspec2os('Unix', $name);
         if( $typeflag == 5 ) {
              mkpath( $name );
              next;
         }

         #######
         # Just in  case the directories where not
         # put in correctly, create them for files
         #
         (undef, $dirs) = File::Spec->splitpath($name);
         mkpath ($dirs);

         ########
         # Extract the file
         #
         open FILE, "> $name";
         binmode FILE;
         print FILE $data;
         close FILE;
     }

     $tar->CLOSE( );
     chdir $restore_dir;

     1
}



sub FileList2Sel
{
     my ($list_p, $select_p) = @_;

     #######
     # Add any inputs files to the extract file hash
     #
     $select_p = {} unless $select_p;
     foreach my $item (@$list_p) {
         $item = File::AnySpec->os2fspec( 'Unix', $item );     
         $select_p->{$item} = 1
     };   
}



1


__END__


=head1 NAME

Archive::TarGzip - save and restore files to and from compressed tape archives (tar)

=head1 SYNOPSIS

 ######
 # Subroutine Interface
 #  
 use Archive::TarGzip qw(parse_header tar untar);

 $tar_file = tar(@file, \@options);
 $tar_file = tar(@file);

 $success = untar(@file);
 $success = untar(@file, \@options);

 \%tar_header = parse_header($buffer);

 ######
 # File subroutines
 # 
 use Archive::TarGzip;

 tie *TAR_FILEHANDLE, 'Tie::Layers'
 tie *TAR_FILEHANDLE, 'Tie::Layers', @options

 $success = open(TAR_FILEHANDLE, $tar_file);
 $success = open(TAR_FILEHANDLE, $mode, $tar_file);

 $success = print TAR_FILEHANDLE $file_name; 
 $success = print TAR_FILEHANDLE $file_name, $file_contents;

 \%tar_header = <TAR_FILEHANDLE>;

 $success = close(TAR_FILEHANDLE);

 ######
 # Object 
 # 
 tie *TAR_FILEHANDLE, 'Tie::Layers';
 tie *TAR_FILEHANDLE, 'Tie::Layers', @options;

 $tar = tied \*TAR_FILEHANDLE; 
 $tar = new Archive::TarGzip( ); 
 $tar = new Archive::TarGzip(@options); 

 $success = $tar->OPEN( $tar_file, \@options);
 $success = $tar->OPEN( $mode, $tar_file, \@options);

 $success = $tar->PRINT($file_name);
 $success = $tar->PRINT($file_name, $file_contents);

 \%tar_header = $tar->READLINE(\@options);
 \%tar_header = $tar->READLINE(@file, \@options);

 $status = $tar->target( \$buffer, $size);
 $success = $tar->CLOSE();


=head1 DESCRIPTION

The C<Archive::TarGzip> module provides C<tar> subroutine to archive a list of files
in an archive file in the tar format. 
The archive file may be optionally compressed using the gzip compression routines.
The C<Archive::TarGzip> module also provides a C<untar> subroutine that can extract
the files from the tar or tar/gzip archive files.
The C<tar> and C<untar> top level subroutines use methods from the C<Archive::TarGzip>
class. 

The C<Archive::TarGzip> class has many similarities to the
very mature L<Archive::Tar|Archive::Tar> class being at least
three years older.
The newer C<Archive::TarGzip> relied very heavy on the
work of the author of the L<Archive::Tar|Archive::Tar> and
in many instance the L<Archive::Tar|Archive::Tar> is a
better solution. 

Altough the underlying tar file format is the same and similar code is used
to access the data in the underlying tar files, the interace bewteen
the two are completely different.
The C<Archive::TarGzip> is built on a Tie File Handle type interface.
The nthe C<Archive::TarGzip> provide means
to access individual files within the archive file without bringing the entire
archive file into memory. When the gzip compression option is active, the
compression is performed on the fly without creating an intermediate uncompressed
tar file. 

=head1 METHODS

=head2 tar 

 $tar_file = Archive::TarGzip->tar(@file, [\%options or\@options]);
 $tar_file = tar(@file, [\%options or\@options]); # only if imported

The tar subroutine creates a tar archive file containing the files
in the @file list. The name of the file is $option{tar_file}.
The tar subroutine will enforce that the $option{tar_file} has
the .tar or .tar.gz extensions 
(uses the $option{compress} to determine which one).

The tar subroutine will add directories to the @file list in the
correct order needed to create the directories so that they will
be available to extract the @files files from the tar archive file.

If the $option{src_dir} is present, the tar subroutine will change
to the $option{src_dir} before reading the @file list. 
The subroutine will restore the original directory after 
processing.

If the $option{dest_dir} is present, the tar subroutine will
add the $option{dest_dir} to each of the files in the @file list.
The $options{dest_dir} name is only used for the name stored
in the tar archive file and not to access the files from the
site storage.

=head2 untar

 $success = Archive::TarGzip->untar([@file], \%options or\@options or @options);
 $success = untar([@file], \%options or\@options or @options); # only if imported

The untar subroutine extracts directories and files from a tar archive file.
The untar subroutine does not assume that the directories are stored in the
correct order so that they will be present as needed to create the files.

The name of the file is $option{tar_file}.
If tar subroutine that cannot find the $option{tar_file},
it will look for file with the .tar or .tar.gz extension 
(uses the $option{compress} to determine which one).

If the $option{dest_dir} is present, the tar subroutine will change
to the $option{dest_dir} before extracting the files from the tar archive file. 
The subroutine will restore the original directory after 
processing.

If the @file list is present or the @{$option{extract_file}} list is present,
the untar subroutine will extract only the files in these lists.

If the @{$option{exclude_file}} list is present, the untar subroutine will not
extract files in this list.

=head2 new

 $tar = new Archive::TarGzip( );
 $tar = new Archive::TarGzip( $filename or filehandle, [$compress]);

 $tar = new Archive::TarGzip( \%options or\@options);

The new method creates a new tar object. 
The Archive::TarGzip::new method is the only methods that hides
a  Archive::Tar method with the same name.

The new method passes $filename and $compress inputs to the
Archive::Tar::new method which will read the entire
tar archive file into memory. 

The new method with the $filename is better
when using only the Archive::TarGzip methods.

=head2 OPEN

 $tar_handle = $tar->taropen( $tar_file, $compress, [\%options or\@options]);

The taropen method opens a $tar_file without bringing
any of the files into memory.

If $options{tar_flag} is '>', the taropen method
creats a new $tar_file; otherwise, 
it opens the $tar_file for reading.

=head2 PRINT

 $success = $tar->taradd($file_name, $file_contents);

The taradd method appends $file_contents using
the name $file_name 
to the end of the tar archive file taropen for writing.
If $file_contents is undefined, 
the taradd method will use the
contents from the file $file_name.

The tarwrite method will remove the first file
in the Archive::Tar memory and append it
to the end of the tar archive file taropen for writing.

The tarwrite method uses the $option{compress} to
decide whether use gzip compress or normal writing
of the tar archive file.

=head2 READLINE

 \%tar_header = $tar->tarread(@file, [\%options or\@options]);
 \%tar_header = $tar->tarread(\%options or\@options);

The tarread method reads the next file from the tar archive file
taropen for reading. 
The tar file header and file contents are returned in
the %tar_header hash along with other information needed
for processing by the Archive::Tar and Archive::TarGzip
classes.

If the $option{header_only} exists the tarread method
skips the file contents and it is not return in the
%tar_header.

If either the @file or the @{$option{extract_files}} list is 
present, the tarread method will check to see if
the file is in either of these lists.
If the file name is not in the @files list or
the @{$option{extract_files}} list,
the tarread method will set the $tar_header{skip_file} key
and all other %tar_header keys are indetermined.

If the @{$option{exclude_files}} list is 
present, the tarread method will check to see if
the file is in this list.
If the file name is in the list,
the tarread method will set the $tar_header{skip_file} key
and all other %tar_header keys are indetermined.

If the tarread method reaches the end of the tar archive
file, it will set the $tar_header{end_of_tar} key and
all other %tar_header keys are indermeined.

The $tar_header keys are as follows:

 name
 mode
 uid
 gid
 size
 mtime
 chksum
 typeflag
 linkname
 magic
 version
 uname
 gname
 devmajor
 devminor
 prefix
 error
 end_of_tar
 header_only
 skip_file
 data
 file_position

=head2 target

 $status = $tar->target( \$buffer, $size);

The target method gets bytes in 512 byte chunks from
the tar archive file taropen for reading.
If \$buffer is undefined, the target method skips
over the $size bytes and any additional bytes to pad out
to 512 byte boundaries.

The target method uses the $option{compress} to
decide whether use gzip uncompress or normal reading
of the tar archive file.

=head2 CLOSE

 $success = $tar->CLOSE( );

This closes the tar archive opened by the OPEN subroutine.

=head2 parse_header

 \%tar_header = Archive::TarGzip->parse_header($buffer) ;
 \%tar_header = parse_header($buffer);  # only if imported

The C<parse_header> subroutine takes the pack 512 byte tar file
header and parses it into a the C<Archive::Tar> header hash
with a few additional hash keys.
This is the return for the C<READLINE> subroutine.

=head1 REQUIREMENTS

Someday

=head1 DEMONSTRATION

 #########
 # perl TarGzip.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

     use File::Package;
     use File::AnySpec;
     use File::SmartNL;
     use File::Spec;
     use File::Path;

     my $fp = 'File::Package';
     my $snl = 'File::SmartNL';
     my $uut = 'Archive::TarGzip'; # Unit Under Test
     my $loaded;

 ##################
 # Load UUT
 # 

 my $errors = $fp->load_package($uut)
 $errors

 # ''
 #
      my @files = qw(
          lib/Data/Str2Num.pm
          lib/Docs/Site_SVD/Data_Str2Num.pm
          Makefile.PL
          MANIFEST
          README
          t/Data/Str2Num.d
          t/Data/Str2Num.pm
          t/Data/Str2Num.t
      );
      my $file;
      foreach $file (@files) {
          $file = File::AnySpec->fspec2os( 'Unix', $file );
      }
      my $src_dir = File::Spec->catdir('TarGzip', 'expected');

     unlink 'TarGzip.tar.gz';
     rmtree (File::Spec->catfile('TarGzip', 'Data-Str2Num-0.02'));

 ##################
 # tar files into compressed archive
 # 

 Archive::TarGzip->tar( @files, {tar_file => 'TarGzip.tar.gz', src_dir  => $src_dir,
             dest_dir => 'Data-Str2Num-0.02', compress => 1} )

 # 'TarGzip.tar.gz'
 #

 ##################
 # Untar compressed archive
 # 

 Archive::TarGzip->untar( {dest_dir=>'TarGzip', tar_file=>'TarGzip.tar.gz', compress => 1, umask => 0} )

 # 1
 #
 $snl->fin(File::Spec->catfile('TarGzip', 'Data-Str2Num-0.02', 'MANIFEST'))

 # 'lib/Docs/Site_SVD/Data_Str2Num.pm
 #MANIFEST
 #Makefile.PL
 #README
 #lib/Data/Str2Num.pm
 #t/Data/Str2Num.d
 #t/Data/Str2Num.pm
 #t/Data/Str2Num.t'
 #
 $snl->fin(File::Spec->catfile('TarGzip', 'expected', 'MANIFEST'))

 # 'lib/Docs/Site_SVD/Data_Str2Num.pm
 #MANIFEST
 #Makefile.PL
 #README
 #lib/Data/Str2Num.pm
 #t/Data/Str2Num.d
 #t/Data/Str2Num.pm
 #t/Data/Str2Num.t'
 #

=head1 QUALITY ASSURANCE

Running the test script C<TarGzip.t> verifies
the requirements for this module.
The C<tmake.pl> cover script for L<Test::STDmaker|Test::STDmaker>
automatically generated the
C<TarGzip.t> test script, C<TarGzip.d> demo script,
and C<t::Archive::TarGzip> Software Test Description (STD) program module POD,
from the C<t::Archive::TarGzip> program module contents.
The C<tmake.pl> cover script automatically ran the
C<TarGzip.d> demo script and inserted the results
into the 'DEMONSTRATION' section above.
The  C<t::Tie::TarGzip> program module
is in the distribution file
F<Archive-TarGzip-$VERSION.tar.gz>.
=head1 NOTES

=head2 Author

The holder of the copyright and maintainer is

E<lt> support@SoftwareDiamonds.com E<gt>

=head2 Copyright Notice

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 Binding Requirements Notice

Binding requirements are indexed with the

pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
In accordance with the License for 'Tie::Gzip', 
Software Diamonds
is not liable for meeting any requirement, 
binding or otherwise.

=head2 License

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code must retain
the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=item 3

Commercial installation of the binary or source
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://softwarediamonds.com
and provide means
for the installer to actively accept
the list of conditions; 
otherwise, a license fee must be paid to
Softwareware Diamonds.

=back

SOFTWARE DIAMONDS, http://www.softwarediamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE. 

=head1 SEE ALSO

=over 4

=item L<Docs::Site_SVD::Archive_TarGzip|Docs::Site_SVD::Archive_TarGzip>

=item L<Test::STDmaker|Test::STDmaker>

=item L<Archive::Tar|Archive::Tar>

=back

=cut

### end of file ###
