use 5.00001;
use ExtUtils::MakeMaker;
#
#  WARNING: Do not try to "make dist" under Windows; it destroys the Upper/lower CaSe of some files.
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#
# Many thanks to Randy Kobes for helping me figure out how to make this work on Win32, which
# also laid the foundation for me getting it to work nicely on Linux and Macintosh
#
use Config;
use IO::Socket ();	# For checking net connectivity
my $os_src = ($^O =~ /Win32/) ? 'win/win' : 'linux/linux';
my $o = $Config{obj_ext};
my $c='.c';
my $mxbase='matrixssl-1-8-6-open';
my $mxfiles="$mxbase.files";

my $online_flag = 't/online.enabled';


# Apply cumulative patch, if any
if (-r "$mxbase.patch") {
    system("cd \Q$mxbase\E; patch -p1 -N -i ../$mxbase.patch");
}

=for ver1-82
# Increase default const to allow more than 8 certificates:
{
    local $^I   = q{};
    local @ARGV = "$mxbase/matrixCommon.h";
    while (<>) {
        s/^(\s*#define\s+MAX_CHAIN_LENGTH\s*\s)\d+(\s*$)/${1}192${2}/;
        print;
    }
}

=cut

# Increase default const to allow more than 8 certificates:
unless(-f "$mxbase/src/pki/matrixPki.h.ori") { # only do once
    rename("$mxbase/src/pki/matrixPki.h","$mxbase/src/pki/matrixPki.h.ori");
}

    open(IN,"<$mxbase/src/pki/matrixPki.h.ori") or die "Can't fix MAX_CHAIN_LENGTH: $!";
    open(OUT,">$mxbase/src/pki/matrixPki.h") or die "Can't fix MAX_CHAIN_LENGTH: $!";
    while(my $line=<IN>) {
      $line=~s/^(\s*#define\s+MAX_CHAIN_LENGTH\s*\s)\d+(\s*$)/${1}192${2}/;
      print OUT $line;
    }
    close(IN); close(OUT);



=for removal 

# Fix Macintosh line ends tht  don't compile under Win32
sub chompnl {	# Warning: don't stuff up $1
  chop $_[0] while((substr($_[0],-1) eq "\015")||(substr($_[0],-1) eq "\012"));
} # chompnl
unless(-f "$mxbase/matrixCommon.h.ori") { # only do once
    rename("$mxbase/matrixCommon.h","$mxbase/matrixCommon.h.ori");
    open(IN,"<$mxbase/matrixCommon.h.ori") or die "Can't fix MAC Line ends: $!";
    open(OUT,">$mxbase/matrixCommon.h") or die "Can't fix MAC Line ends: $!";
    while(my $line=<IN>) {
      &chompnl($line);
      print OUT $line . "\n";	# "\n" on unix, "\r\n" on Dos, ??? on Mac.
    }
    close(IN); close(OUT);
}

=cut

# NOTE: For future versions of MatrixSSL (this is v1.8.6) - if the below routine failes - you might need to do this;
#       1. cd matrixssl-x-y-z/src
#       2. make all; cd ..
#       3. find . -name '*.o' -print >/tmp/objs
#       4. vi ../Makefile.PL
#       5. include the file /tmp/objs - eg:   ":r /tmp/objs"
#       6. change all the ".o" endings to "$mxext"
#       7. change all the leading "./" to $mxbase/
#       8. join them all on to one line and assign them all to "$mxfiles"; be careful NOT to expand the "$mxext" or "$mxbase" (eg: use single quotes)
#       9. replace the os/linux/linux$mxext one with os/$os_src$mxext


# Autogenerate list with object files produced by MatrixSSL because it's
# different between MatrixSSL versions.
if (! -r $mxfiles) {
    if ($^O =~ /Win32/) {
        # TODO  I don't have windoze with installed perl and C compiler,
        #       so I can't realize this feature for Win32.
        die "$mxfiles autogeneration not supported under Win32 yet.\n";
    }
    else {
        system("
            cd \Q$mxbase\E/src &&
            make all &&
            cd ../.. &&
            find \Q$mxbase\E -name '*.o' | sed 's/\.o\$//' > \Q$mxfiles\E
            ") and die "system: $? $!";
    }
}
# Prepare list of object & C MatrixSSL files for usage in Makefile later.
open my $files, '<', $mxfiles or die "open: $!";
chomp(my @files = <$files>);
close $files;
s{linux/linux|win/win}{$os_src} for @files;
# These are all the object files we need for our release
my $mxobjs  = join ' ', map { $_.$o } @files;
# These are the .c files that built the above objects.
# Note that the peersec "Makefile" did this for us, via "make all" in the
# "./matrixssl" subdirectory.
my $mxc     = join ' ', map { $_.$c } @files;

# Here, we fudge the replacement of the original MatrixSSL source code for the clean
sub MY::clean_subdirs {
#Was:  return "clean_subdirs :\t$(NOECHO) $(NOOP)\n";
  return qq ~clean_subdirs :\n\t\$(CP) "$mxbase/src/pki/matrixPki.h.ori" "$mxbase/src/pki/matrixPki.h"\n~;
}

# FIXME If this code not needed anymore, then it should be deleted
#       together with $mxc var above.
sub MY::postamble {

return '';

        return "

libmatrixssl.lib: $mxbase/src/Makefile $mxc
	cd $mxbase/src && \$(MAKE) all
	ar -rc libmatrixssl.lib $mxobjs

";
#     'OBJECT'		=> 'matrixssl/src/libmatrixssl.so matrixssl/src/cipherSuite.c matrixssl/src/matrixSsl.c matrixssl/src/sslEncode.c matrixssl/src/sslDecode.c matrixssl/src/sslv3.c matrixssl/src/crypto/peersec/base64.c matrixssl/src/crypto/peersec/arc4.c matrixssl/src/crypto/peersec/asn1.c matrixssl/src/crypto/peersec/des3.c matrixssl/src/crypto/peersec/md2.c matrixssl/src/crypto/peersec/md5.c matrixssl/src/crypto/peersec/mpi.c matrixssl/src/crypto/peersec/rsa.c matrixssl/src/crypto/peersec/sha1.c matrixssl/src/os/psMalloc.c matrixssl/src/os/linux/linux.c', # link all the C files too

}

# The MatrixSSL code requires _WIN32_WINNT=0x0400 in order to correctly pick up the wincrypt.h header
my $defines = ($^O =~ /Win32/) ? '/D_WIN32_WINNT=0x0400' : '-DLINUX';
# Some Linicies seem to require '-lpthread' - if you're having problems, try removing this:-
my $libs = ($^O =~ /Win32/) ? '' : '-lpthread';

=for comment

Win32 inline mod snippet

=cut

=head1 NAME

matrixssl_win32_inline - win32 compiler support script

=head1 SYNOPSIS

 reads  < ./matrixssl/*.h  writes > ./*.h

=head1 DESCRIPTION

Converts the MatrixSSL header files so that Win32 compilations work "inline"
(that is: so they don't need a "perl" loading DLL and a MatrixSSL functions
DLL - everything is instead put all inside the one DLL)

=head2 Changes

 1. Comment all '#ifdef __cplusplus'...'#endif' blocks.

 2. Inside '#ifdef WIN32'...'#endif' blocks replace
        #define ... extern __declspec(dllimport)
        #define ... extern __declspec(dllexport)
    with
        #define ... extern /* __declspec(dllimport) */
        #define ... extern /* __declspec(dllexport) */

=head1 BUGS

Searches for hardcoded stuff instead of "parsing the header file"; should be OK,
but might one day fail if peersec make dramatic changes to their header files.

=cut

for my $header (qw( matrixCommon.h  matrixSsl.h )) {
    open my $in,  '<', "$mxbase/$header" or die "open: $mxbase/$header: $!";
    open my $out, '>', $header           or die "open: $header: $!";
    while (<$in>) {
        s/\r?\n//;
        # BUG   Nested if[n]def's doesn't supported.
        if (/^\s*#ifdef\s+__cplusplus\s*$/ ... /^\s*#endif\s*$/) {
            $_ = "/* $_ */";
        }
        if (/^\s*#ifdef\s+WIN32\s*$/ ... /^\s*#endif\s*$/) {
            s{(__declspec\(dll(?:import|export)\))}{/* $1 */};
        }
        print {$out} $_,"\n";
    }
    close $out;
    close $in;
}


=for comment

End of Win32 inline mod snippet

=cut

WriteMakefile(
    'NAME'		=> 'Crypt::MatrixSSL',
    'VERSION_FROM'	=> 'MatrixSSL.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'MatrixSSL.pm', # retrieve abstract from module
       AUTHOR     => 'C. N. Drake <christopher@pobox.com>') : ()),
    'LIBS'		=> [$libs], # e.g., '-lm'
    'DEFINE'		=> $defines, # e.g., '-DHAVE_SOMETHING'
    'INC'		=> "-I. -I$mxbase", # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> 'libmatrixssl.lib matrixssl/src/*.o MatrixSSL.o',
    # 'OBJECT'		=> "libmatrixssl.lib $mxobjs MatrixSSL.o", # link all the C files too
    'OBJECT'		=> "$mxobjs MatrixSSL$o", # link all the C files too
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
    clean               => {FILES => "$online_flag $mxobjs Matrixssl$o"},
);



if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (
    # Return code in user validation callback.
    qw(
        SSL_ALLOW_ANON_CONNECTION
    ),
    # Max size for message in matrixSslEncode().
    qw(
        SSL_MAX_PLAINTEXT_LEN
    ),
    # Flags for matrixSslNewSession().
    qw(
        SSL_FLAGS_SERVER
        SSL_FLAGS_CLIENT_AUTH
    ),
    # Options for matrixSslSetSessionOption().
    # NOTE: In commercial MatrixSSL version there exists two more options:
    #   SSL_OPTION_ENABLE_CLIENT_AUTH
    #   SSL_OPTION_DISABLE_CLIENT_AUTH
    qw(
        SSL_OPTION_DELETE_SESSION
    ),
    # matrixSslDecode() return values.
    qw(
        SSL_SUCCESS
        SSL_ERROR
        SSL_FULL
        SSL_PARTIAL
        SSL_SEND_RESPONSE
        SSL_PROCESS_DATA
        SSL_ALERT
        SSL_FILE_NOT_FOUND
        SSL_MEM_ERROR
    ),
    # alertLevel:
    qw(
        SSL_ALERT_LEVEL_WARNING
        SSL_ALERT_LEVEL_FATAL
    ),
    # alertDescription:
    qw(
        SSL_ALERT_CLOSE_NOTIFY
        SSL_ALERT_UNEXPECTED_MESSAGE
        SSL_ALERT_BAD_RECORD_MAC
        SSL_ALERT_DECOMPRESSION_FAILURE
        SSL_ALERT_HANDSHAKE_FAILURE
        SSL_ALERT_NO_CERTIFICATE
        SSL_ALERT_BAD_CERTIFICATE
        SSL_ALERT_UNSUPPORTED_CERTIFICATE
        SSL_ALERT_CERTIFICATE_REVOKED
        SSL_ALERT_CERTIFICATE_EXPIRED
        SSL_ALERT_CERTIFICATE_UNKNOWN
        SSL_ALERT_ILLEGAL_PARAMETER
    ),
  );
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Crypt::MatrixSSL',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}




#
# Check if we have internet connection
# (I lifted this code from Net::DNS, who got it from LWP... )
#
my $online_tests;
my $s = IO::Socket::INET->new( PeerAddr => 'www.google.com:80', Timeout => 10 );
if ($s) {
    close($s);
    print "\n\nYou appear to be directly connected to the Internet.\n";
    print "I have a test that grabs https://www.google.com/\n\n";
    $online_tests = prompt('Do you want to enable this test?', 'y') =~ /^y/i;
} # s
if ($online_tests) {
    open(my $tmp, '>', $online_flag)    or die "Can't touch ./$online_flag $!";
    close($tmp)                         or die "Can't touch ./$online_flag $!";
}
else {
    # clean up the online testing flag file.
    unlink($online_flag);
}





package MY;

sub c_o {
  my $inherited = shift->SUPER::c_o(@_);
  if($^O =~ /darwin/) {	# Mac
    # cc -Os -DLINUX -DOSX -isystem -I/usr/include   -c -o sslv3.o sslv3.c
    $inherited =~ s{\$\*.c\n}{\$\*.c -DOSX -isystem -I/usr/include -o\$\*.o\n}mg;
  } elsif($^O =~ /Win32/) {	# Microsoft
    $inherited =~ s{\$\*.c\n}{\$\*.c -Fo\$\*.obj\n}mg;
  } else {			# linux/other unicies: Tell the Makefile to put the .o files with the .c ones
    $inherited =~ s{\$\*.c\n}{\$\*.c -o\$\*.o\n}mg;
  }
  return $inherited;
}


