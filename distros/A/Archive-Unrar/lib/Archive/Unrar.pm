package Archive::Unrar;

use 5.010000;
use strict;
use base qw(Exporter);
use Exporter;
use Win32::API;
use Win32API::Registry 0.21 qw( :ALL );
use File::Spec;
use Encode;

use constant	{
COMMENTS_BUFFER_SIZE => 16384,
ERAR_END_ARCHIVE =>10,
ERAR_NO_MEMORY =>11, 
ERAR_BAD_DATA  =>12, #"CRC failed.File corrupt";
ERAR_BAD_ARCHIVE =>13,
ERAR_UNKNOWN_FORMAT =>14,
ERAR_EOPEN  =>15,
ERAR_ECREATE   => 16, #"Cannot create directory. Total path and file name length must not exceed 260 characters"; 
ERAR_ECLOSE  => 17,
ERAR_EREAD => 18,
ERAR_EWRITE  => 19,
ERAR_SMALL_BUF=> 20,
ERAR_UNKNOWN  => 21,
ERAR_MISSING_PASSWORD => 22,
ERAR_MAP_DIR_YES=>1,
ERAR_READ_HEADER=>' file header is corrupt',
ERAR_MULTI_BRK => 'multipart but first volume is broken',
ERAR_ENCR_WRONG_PASS => '(headers encrypted) password not correct or file corrupt',
ERAR_WRONG_PASS=>'password not correct or file corrupt',
ERAR_CHAIN_FOUND=>'found in chain.already processed',
ERAR_GENERIC_ALL_ERRORS=> 'if not password protected then file is corrupt.if password protected then password is not correct or file is corrupt',
ERAR_WRONG_FORMAT=>"Check file format........probably it's another format i.e ZIP disguised as a RAR",
RAR_TEST=>1,
RAR_EXTRACT=>2
};

our @EXPORT = qw(process_file ERAR_BAD_DATA ERAR_ECREATE ERAR_MULTI_BRK ERAR_ENCR_WRONG_PASS ERAR_WRONG_PASS
ERAR_CHAIN_FOUND ERAR_GENERIC_ALL_ERRORS ERAR_WRONG_FORMAT ERAR_MAP_DIR_YES ERAR_MISSING_PASSWORD ERAR_READ_HEADER RAR_TEST RAR_EXTRACT) ;

our @EXPORT_OK = qw(list_files_in_archive %donotprocess $ANSI_CP $OEM_CP);

our $VERSION = '3.1';

our (%donotprocess,$ANSI_CP,$OEM_CP);

read_registry() unless ($ANSI_CP && $OEM_CP) ; 

################ PRIVATE METHODS ################ 

sub read_registry { ##Get system wide default encoding values 
	my $key;
	my $type;
	RegOpenKeyEx( HKEY_LOCAL_MACHINE,"SYSTEM\\CurrentControlSet\\Control\\Nls\\CodePage",0,KEY_READ,$key);
	RegQueryValueEx( $key, "ACP", [], $type, $ANSI_CP, [] ) or $ANSI_CP="1252";
	RegQueryValueEx( $key, "OEMCP", [], $type, $OEM_CP, [] ) or $OEM_CP="437";
	RegCloseKey($key);
	
	$ANSI_CP="cp".$ANSI_CP;
	$OEM_CP="cp".$OEM_CP;
}

sub declare_win32_functions {
	
	my $RAR_functions_ref = shift;
	
#fill hash byref
 %$RAR_functions_ref = (   
			RAROpenArchiveEx => new Win32::API( 'unrar.dll', 'RAROpenArchiveEx', 'P', 'N' ),
			RARCloseArchive =>  new Win32::API( 'unrar.dll', 'RARCloseArchive', 'N', 'N' ),
			RAROpenArchive => new Win32::API( 'unrar.dll', 'RAROpenArchive', 'P', 'N' ),
			RARReadHeader => new Win32::API( 'unrar.dll', 'RARReadHeader', 'NP', 'N' ),
			RARProcessFile => new Win32::API( 'unrar.dll', 'RARProcessFile', 'NNPP', 'N' ),
			RARSetPassword => new Win32::API( 'unrar.dll', 'RARSetPassword', 'NP', 'V' )
			);
		
		 
		 while ((undef, my $value) = each(%$RAR_functions_ref)){
                die "Cannot load function.Is unrar.dll in System32 directory?" if !defined($value) ;
		   }		       		 
		
		return 1;
}



sub extract_headers {

    my ($file,$password) = @_;
	die "Fatal error $! : $file" if (!-e $file);
	
    my $CmtBuf = pack('x'.COMMENTS_BUFFER_SIZE);
    my $continue;
	
	
	my %RAR_functions;
	declare_win32_functions(\%RAR_functions);
		
    my $RAROpenArchiveDataEx_struct =
      pack( 'pLLLPLLLLL32', $file, 0, 2, 0, $CmtBuf, COMMENTS_BUFFER_SIZE, 0, 0, 0,0 );
	
	
    my $handle = $RAR_functions{RAROpenArchiveEx}->Call($RAROpenArchiveDataEx_struct);

   my ( $CmtBuf1, $CmtSize, $CmtState, $flagsEX ) = 
						(unpack( 'pLLLP'.COMMENTS_BUFFER_SIZE.'LLLLL32', $RAROpenArchiveDataEx_struct ))[4,6,7,8];


	#is it really a RAR file? maybe it is a ZIP disguised as a RAR
	if ($handle == 0) {
	   return (undef,undef,ERAR_WRONG_FORMAT);
	}
	 else {
		!$RAR_functions{RARCloseArchive}->Call($handle) || die "Fatal error $!";
	 }

	my $RAROpenArchiveData_struct = pack( 'pLLPLLL', $file, 2, 0, undef, 0, 0, 0 );
	
    my $handle = $RAR_functions{RAROpenArchive}->Call($RAROpenArchiveData_struct);
	
	if ($handle == 0) {
	   return (undef,undef,ERAR_WRONG_FORMAT);
	}
	 
		
	my $RARHeaderData_struct = pack( 'x260x260LLLLLLLLLLPLLL',
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );

    my ( $arcname, $filename, $flags);

	unless ($flagsEX & 128){
		if ($RAR_functions{RARReadHeader}->Call( $handle, $RARHeaderData_struct )) {
				!$RAR_functions{RARCloseArchive}->Call($handle) || die "Fatal error $!";		
				return (undef,undef,ERAR_READ_HEADER);
		}
		else
		{	 
			( $arcname, $filename, $flags ) =  unpack( 'Z260Z260L', $RARHeaderData_struct );
			$arcname  =~s/\0//g;
			$filename =~s/\0//g;
		}
	}
	
	printf( "\nFile:    %s\n", $file );
	printf( "\nArchive: %s\n", $arcname );
		
		#transcoding
		my $filename=decode($OEM_CP,$filename);	
		my $filename=encode($ANSI_CP,$filename);	
		printf( "\n(First)Internal Filename: %s\n", $filename );
		
	printf( "\nPassword?:\t%s", 
	      ($flagsEX & 128)? "yes" :( $flags & 4 )     ? "yes" : "no" ); 
    printf( "\nVolume:\t\t%s",     ( $flagsEX & 1 )   ? "yes" : "no" );
    printf( "\nComment:\t%s",      ( $flagsEX & 2 )   ? "yes" : "no" );
    printf( "\nLocked:\t\t%s",     ( $flagsEX & 4 )   ? "yes" : "no" );
    printf( "\nSolid:\t\t%s",      ( $flagsEX & 8 )   ? "yes" : "no" );
    printf( "\nNew naming:\t%s",   ( $flagsEX & 16 )  ? "yes" : "no" );
    printf( "\nAuthenticity:\t%s", ( $flagsEX & 32 )  ? "yes" : "no" );
    printf( "\nRecovery:\t%s",     ( $flagsEX & 64 )  ? "yes" : "no" );
    printf( "\nEncr.headers:\t%s", ( $flagsEX & 128 ) ? "yes" : "no" );
    printf( "\nFirst volume:\t%s\n\n",
        ( $flagsEX & 256 ) ? "yes" : "no or older than 3.0" );

	if ($CmtState==1) {
			$CmtBuf1 = unpack( 'A' . $CmtSize, $CmtBuf1 );
			#there might be more than 16K wide comments but we print only the first 16K
			printf( "\nEmbedded Archive Comments (limited to first 16K) : <<<< %s", $CmtBuf1. " >>>>\n" );
		}
	
    if ( exists $donotprocess{$file} ) {
	    #found in the cache which means that the multipart archive has already been extracted.so not need to process this file 
        $continue = ERAR_CHAIN_FOUND;		
    } 
	elsif (!($flagsEX & 256) && !($flagsEX & 128) && ($flagsEX & 1)) {
            #if file is not blockencrypted and is not the first volume of a multi part archive
			#we do not need to process it
            $continue=ERAR_MULTI_BRK;
		}
	  		
   !$RAR_functions{RARCloseArchive}->Call($handle) || die "Fatal error $!";

  return ( $flagsEX & 128, $flags & 4 , $continue);
}

################ PUBLIC METHODS ################ 

sub list_files_in_archive {
	
   my $caller_sub = ( caller(1) )[3];
   my %params=@_;

	my ($file,$password) = @params{qw (file password)};
	
    my ( $blockencrypted, $pass_req, $continue ) = extract_headers($file);
	
    my $blockencryptedflag;
	my $errorcode;

	my %RAR_functions;
	declare_win32_functions(\%RAR_functions);
	
	my $RAROpenArchiveDataEx_struct =
      pack( 'pLLLPLLLLL32', $file, 0, 2, 0, undef, 0, 0, 0, 0,0 );
	   	     
    my $handle = $RAR_functions{RAROpenArchiveEx}->Call($RAROpenArchiveDataEx_struct);
        	
	if ($handle == 0 ) {
	 return ERAR_WRONG_FORMAT;
	 }
	 
      
	my $RARHeaderData_struct = pack( 'x260x260LLLLLLLLLLPLLL',
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, undef, 0, 0, 0 );
			
	 

     if ($blockencrypted) { 

         if ($password) {
             $RAR_functions{RARSetPassword}->Call( $handle, $password );
         }
         else {
			 !$RAR_functions{RARCloseArchive}->Call($handle) || die "Fatal error $!";
				 return ERAR_MISSING_PASSWORD;
         }
     }
	 elsif ($pass_req) {
	 
		    $RAR_functions{RARSetPassword}->Call( $handle, $password );
	 }

    while ( ( $RAR_functions{RARReadHeader}->Call( $handle, $RARHeaderData_struct ) ) == 0 ) {
	    $blockencryptedflag="yes";
        
		my $processresult = $RAR_functions{RARProcessFile}->Call( $handle, 0, 0, 0 );
        
		if ( $processresult != 0 ) {
            $errorcode=$processresult; 
            last;
        }
        else {	    
            my @files = unpack( 'Z260Z260', $RARHeaderData_struct );
			$files[0] =~  s/\0//g;
           	$donotprocess{ $files[0] } = 1;
			
			#Look up the stack and see who has called "list_files_in_archive"
			#if it is not "process_file" then print the contents of the current file on STDOUT.
			#This is done because "process_file" calls "list_files_in_archive"
			#for its own purposes (caching files); it is not interested in printing
			#the contents of the file on STDOUT
			if ($caller_sub !~ /process_file$/) {
				print "Archive contents : ", $files[1],"\n";	
				}
        }

    }
    
	if ($blockencrypted && (!defined($blockencryptedflag))) {
		$errorcode=ERAR_ENCR_WRONG_PASS;
	}
	
		
	!$RAR_functions{RARCloseArchive}->Call($handle) || die "Fatal error $!";
	return $errorcode;
}

sub process_file {
   my %params=@_;
   
   my ($file,$password,$output_dir_path,$selection,$callback,$mode) = @params{qw (file password output_dir_path selection callback mode) }; 
     
	my ( $blockencrypted, $pass_req, $continue) = extract_headers($file);
	
	my $errorcode;
	my $directory;
	
    my $blockencryptedflag;
	
	if (defined($output_dir_path)) {
	   $directory=$output_dir_path;
	   }
	
	
	if ($selection==ERAR_MAP_DIR_YES) {
		my (undef,$directories,$file) = File::Spec->splitpath( $file );
		my $temp;
		( $temp = $file ) =~ s/\.rar$//i;
		$directory=$directory."\\".$temp;
	}


	#if $mode is false (0 or '0' or undef) then default to RAR_EXTRACT else use its value (RAR_TEST or RAR_EXTRACT)	   
	$mode = $mode || RAR_EXTRACT;
	
    return ($errorcode=$continue,$directory) if ($continue);
					
	my %RAR_functions;
	declare_win32_functions(\%RAR_functions);

	my $RAROpenArchiveDataEx_struct =
      pack( 'pLLLPLLLLL32', $file, 0, 1, 0, undef, 0, 0, 0, 0,0 );
	     	     
    my $handle = $RAR_functions{RAROpenArchiveEx}->Call($RAROpenArchiveDataEx_struct);
     
 
	if ($handle == 0 ) {
	 	return (ERAR_WRONG_FORMAT,$directory);
	 }

    if ( $blockencrypted || $pass_req ) {

        if ($password) {
            $RAR_functions{RARSetPassword}->Call( $handle, $password );
		}
        else {
			!$RAR_functions{RARCloseArchive}->Call($handle) || die "Fatal error $!";
			return (ERAR_MISSING_PASSWORD,$directory);
        }
    }
	
	my $RARHeaderData_struct = pack( 'x260x260LLLLLLLLLLPLLL',
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, undef, 0, 0, 0 );

 
    my $processing_progress=0;
	my $processing=0;
	
	
	#transcoding
	my $OEM_directory=encode($OEM_CP,decode($ANSI_CP,$directory)); 
	
		
	while ( ( $RAR_functions{RARReadHeader}->Call( $handle, $RARHeaderData_struct ) ) == 0 ) {
	$blockencryptedflag="yes";
		
	
    	$processing++;
		if ($processing > 1) { print "...processing..."; print ++$processing_progress} ;
		print "\n";
		
		$callback->(@_) if defined($callback);
		
				
     	my $processresult = $RAR_functions{RARProcessFile}->Call( $handle, $mode,  $OEM_directory, 0 );
		
		if ( $processresult != 0 ) {
            $errorcode=$processresult; 
		    last;
        }
	
    }
	
	!$RAR_functions{RARCloseArchive}->Call($handle) || die "Fatal error $!";
	
		
	if ($blockencrypted && (!defined($blockencryptedflag))) {
	     $errorcode=ERAR_ENCR_WRONG_PASS;	 
	}
	elsif ($pass_req && defined($errorcode)) {
		$errorcode=ERAR_WRONG_PASS;
	}
	elsif (defined($errorcode)) {
		$errorcode;
		#placeholder for future use
		#just return catch all error ERAR_GENERIC_ALL_ERRORS;
	}
	elsif ($blockencrypted && (!defined($errorcode))) { print "xxxxx";sleep 2;
	       $errorcode=list_files_in_archive(  file=>$file, password=>$password );	
	} 
	elsif (!defined $errorcode) {
       $errorcode=list_files_in_archive(  file=>$file, password=>$password );	
	} 
	
	return ($errorcode,$directory);
}

 
1;
__END__

=head1 NAME

Archive::Unrar - is a procedural module that provides manipulation (extraction and listing of embedded information) of compressed RAR format archives by interfacing with the unrar.dll dynamic library for Windows.

=head1 SYNOPSIS

use Archive::Unrar;
	
	## Usage :
	
	list_files_in_archive(  file=>$file, password=>$password );	
	list_files_in_archive(  file=>"c:\\input_dir\\test.rar",  password=>"mypassword");
	
	process_file( 
		     file=>$file, 
		     password=>$password,
 		     output_dir_path=>$output_dir_path,
 		     selection=>$selection,
		     callback=>$callback 
	);

			
	## Optionally, provide selection and callback : 
	## If selection equals ERAR_MAP_DIR_YES then default to 'Map directory to Archive name'  
	## If selection does not equal ERAR_MAP_DIR_YES or is undefined then default 'Do not Map directory to Archive name'  

	process_file(
		    "c:\\input_dir\\test.rar",
		    password=>"mypassword",
 		    output_dir_path=>"c:\\outputdir",
		    selection=>ERAR_MAP_DIR_YES,
		    callback=>undef
	);

=head1 DESCRIPTION

B<Archive::Unrar> is a procedural module that provides manipulation (extraction and listing of embedded information) of compressed RAR format archives by interfacing with the unrar.dll dynamic library for Windows.

By default it exports function B<"process_file"> and some default B<error description constants> :

  @EXPORT = qw(
               process_file 
               ERAR_BAD_DATA 
               ERAR_ECREATE 
               ERAR_MULTI_BRK 
               ERAR_ENCR_WRONG_PASS
               ERAR_WRONG_PASS
               ERAR_CHAIN_FOUND 
               ERAR_GENERIC_ALL_ERRORS
               ERAR_WRONG_FORMAT
               ERAR_MAP_DIR_YES
               ERAR_MISSING_PASSWORD
               ERAR_READ_HEADER
             ) ;

And it explicitly exports function  B<"list_files_in_archive"> and hash structure B<%donotprocess> :

  @EXPORT_OK = qw(list_files_in_archive %donotprocess);


B<"list_files_in_archive"> lists details embedded into the archive (files bundled into the .rar archive,archive's comments and header info) 
It takes two parameters;the first is the file name and the second is the password required by the archive.
If no password is required then just pass undef or the empty string as the second parameter

B<"list_files_in_archive"> returns $errorcode.If $errorcode is undefined it means that
the function executed with no errors. If not, $errorcode will contain an error description.
$errorcode=list_files_in_archive($file,$password);
print "There was an error : $errorcode" if defined($errorcode);

B<"process_file"> takes five parameters;the first is the file name, the second is the password required by the archive, the third is the directory that the file's contents will be extracted to. The fourth dictates if a directory will created (pass ERAR_MAP_DIR_YES) with the
same as name as the archive (Map directory to archive name). The last one refers to a callback,optionally.
If no password is required then just pass undef or the empty string

B<"process_file"> returns $errorcode and $directory.If $errorcode is undefined it means that
the function executed with no errors. If not, $errorcode will contain an error description.
$directory is the directory where the archive was extracted to :

  ($errorcode,$directory) = 
             process_file( 
		          file=>$file, 
		          password=>$password,
 		          output_dir_path=>$output_dir_path,
 		          selection=>undef,
		          callback=>undef 
	         );

  print "There was an error : $errorcode" if defined($errorcode);

The callback parameter is invoked inside the loop that does the file processing : 

       $callback->(@_) if defined($callback)
	   
This gives the option to make the module call an user defined function 

=head1 PREREQUISITES

Must have unrar.dll in %SystemRoot%\System32 B<($ENV{"SYSTEMROOT"}."\\system32")>

Get UnRAR dynamic library for Windows software developers from L<http://www.rarlab.com/rar/UnRARDLL.exe>
This package includes the dll,samples,dll internals and error description 

After downloading place dll in %SystemRoot%\System32 directory B<($ENV{"SYSTEMROOT"}."\\system32")>

Module comes with installation test (in B<"mytest.pl">) that checks for dll's existence 

=head2 TEST AFTER INSTALLATION

run "mytest.pl" script (found inside module's distribution "test" directory) as :

perl mytest.pl

the script runs a test that checks for "unrar.dll" existence in the %SystemRoot%\System32 directory B<($ENV{"SYSTEMROOT"}."\\system32")> and also extracts some sample archives 

=head2 EXPORT

B<process_file> function and most error description constants, by default.
B<list_files_in_archive> and B<%donotprocess> explicitly.

=head1 AUTHOR

Nikos Vaggalis <F<nikosv@cpan.org>>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by Nikos Vaggalis

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License

=cut
