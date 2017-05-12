use strict;
use ExtUtils::MakeMaker;
use Config;

my @ppd;

if ($] >= 5.00503) {
  @ppd = (
    AUTHOR    => 'Peter S. Housel <housel@acm.org>',
    ABSTRACT  => 'Perl module implementing CORBA 2.x via omniORB'
  );
}

my @OBJECTS     = qw(omniORB.o interfaces.o types.o server.o errors.o exttypes.o util.o);
my $CC          = "";
my $CCFLAGS     = "";
my $DEFINE      = "";
my $OPTIMIZE    = "-g";
my $OMNIORBPREFIX  = "";
my $OMNIORBVERSION = "";
my $OMNIORBINC     = "";
my $OMNIORBLIBS    = "";
my $LDDLFLAGS   = "";
my $XSOPT       = "-C++";

sub ReadConfFile {
    # comment : read configuration file containing 'PARAM = VALUE' lines
    # input   : config filename
    # output  : ref. to param/value hash if successfull, undef otherwise
    
    my $FileName    = shift;    
    my $Parameters  = {};
    my @Elements;
        
    open (FILEHANDLE, $FileName) or return (undef);
    while (<FILEHANDLE>) {
        chomp;          
        s/#(.*)//;              # remove comments
        s/^\s+//g;              # remove leading space
        s/\s+$//g;              # remove trailing space
        next unless ($_);       # ignore empty lines
        
        @Elements = split (/\s*=\s*/, $_, 2);       # split 'PARAM = VALUE' pairs
        $Parameters->{$Elements[0]} = $Elements[1]  # if valid, add them to the result hash
            if (scalar(@Elements) > 0 and $Elements[0] =~ /^\w+$/);
    }
    return ($Parameters);
}

print STDERR "\n--- Generating Makefile for a $Config{'osname'} system\n\n";


# *******************************************************************
# Win32 specific stuff is performed here
# *******************************************************************


if ($Config{'osname'} eq "MSWin32") {
    my $Win32Config     = undef;    # params from the CONFIG.win32 file
    my $WinMsg          = "\nPlease refer to the instructions in the README.win32 file!\n";
    
    # fetch omniORB's root source directory ("OMNIORBPREFIX" parameter) from the CONFIG.win32 file
    $Win32Config = ReadConfFile ('CONFIG.win32')
        or die ("\nFailed to open file 'CONFIG.win32'$WinMsg");
    exists ($Win32Config->{'OMNIORBPREFIX'})
        or die ("\nOMNIORBPREFIX has not been set!$WinMsg");
    $OMNIORBPREFIX = $Win32Config->{'OMNIORBPREFIX'};
    
    # try to locate omniORB lib
    my $omniorblibpath = "$OMNIORBPREFIX/lib/x86_win32/";

    # win32 specific compiler/linker settings
    $OMNIORBINC    = "-I$OMNIORBPREFIX/include";
    $OMNIORBLIBS   = [ "-L$omniorblibpath " . $Win32Config->{'OMNIORBLIBS'} ];
    $CCFLAGS    = $Win32Config->{'CCFLAGS'};
    $OPTIMIZE   = $Win32Config->{'OPTIMIZE'};
    $LDDLFLAGS  = $Win32Config->{'LDDLFLAGS'};
    $DEFINE     = $Win32Config->{'DEFINE'};
    $XSOPT      = $Win32Config->{'XSOPT'};
}


# *******************************************************************
# Unix specific stuff is performed here
# *******************************************************************

else {
    $CC = 'g++';

    use Getopt::Long qw(:config gnu_compat);
    my $ssl_libpath;
    GetOptions( "with-ssl:s" => \$ssl_libpath );
    
    $OMNIORBINC    = `pkg-config --cflags omniDynamic4 omnithread3`;
    chomp $OMNIORBINC;
    $OMNIORBLIBS   = `pkg-config --libs omniDynamic4 omnithread3`;
    chomp $OMNIORBLIBS;

    #There was some strange Perl version:
    #$CCFLAGS .= '-DPERL_GCC_BRACE_GROUPS_FORBIDDEN';

    # ssl 
    if( defined $ssl_libpath ) {
        $ssl_libpath = '/usr/lib' if $ssl_libpath eq '';
	$OMNIORBLIBS .= " -L$ssl_libpath -lssl -lcrypto";
    }
}


# *******************************************************************
# This is for everybody
# *******************************************************************

WriteMakefile(
    'CC'            => $CC,
    'NAME'          => 'CORBA::omniORB',
    'VERSION_FROM'  => 'omniORB.pm',
    'LIBS'          => $OMNIORBLIBS,   
    'DEFINE'        => $DEFINE . " -DHAS_PPPORT_H",
    'INC'           => $OMNIORBINC,
    'OBJECT'        => join (" ", @OBJECTS),
    'OPTIMIZE'      => $OPTIMIZE,
    'XSOPT'         => $XSOPT,
    'CCFLAGS'       => $CCFLAGS,
    'MAP_TARGET'    => 'omniORBperl',
    'dist'          => { COMPRESS=>"gzip", SUFFIX=>"gz" },
    'clean'         => { FILES=>"account.ref ChangeLog.bak" },
    'PREREQ_PM'		=> {
      'Error'       => 0.13,
    },
    'EXE_FILES' => [ 'ir2pm' ],
    @ppd
);
