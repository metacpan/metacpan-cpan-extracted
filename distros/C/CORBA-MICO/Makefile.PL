use strict;
use ExtUtils::MakeMaker;
use Config;

my @OBJECTS     = qw(MICO.o interfaces.o types.o server.o errors.o exttypes.o dispatcher.o util.o);
my $CC          = "";
my $CCFLAGS     = "";
my $DEFINE      = "";
my $OPTIMIZE    = "-g";
my $MICOPREFIX  = "";
my $MICOVERSION = "";
my $MICOINC     = "";
my $MICOLIBS    = "";
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
    my $Win32MakeVars   = undef;    # params from the MakeVars.win32 file (in MICO's source dir)
    my $WinMsg          = "\nPlease refer to the instructions in the README.win32 file!\n";
    
    # fetch MICO's root source directory ("MICOPREFIX" parameter) from the CONFIG.win32 file
    $Win32Config = ReadConfFile ('CONFIG.win32')
        or die ("\nFailed to open file 'CONFIG.win32'$WinMsg");
    exists ($Win32Config->{'MICOPREFIX'})
        or die ("\nMICOPREFIX has not been set!$WinMsg");
    $MICOPREFIX = $Win32Config->{'MICOPREFIX'};
    
    # fetch MICO's version number from MICO's MakeVars.win32 file
    $Win32MakeVars = ReadConfFile ("$MICOPREFIX/MakeVars.win32")
        or die ("\nFailed to access MICO's MakeVars.win32 file!$WinMsg");
    exists ($Win32MakeVars->{'VERSION'})
        or die ("\nNo VERSION parameter found in $MICOPREFIX/MakeVars.win32\nDid you actually build MICO?\n");
    $MICOVERSION = $Win32MakeVars->{'VERSION'};
    
    # try to locate MICO lib
    my $micolibpath = 
      ( -f "$MICOPREFIX/mico$MICOVERSION.lib" ) ? "$MICOPREFIX" :
      ( -f "$MICOPREFIX/orb/mico$MICOVERSION.lib" ) ? "$MICOPREFIX/orb" :
      ( -f "$MICOPREFIX/lib/mico$MICOVERSION.lib" ) ? "$MICOPREFIX/lib" :
      ( die "\nFailed to locate mico$MICOVERSION.lib" );

    # win32 specific compiler/linker settings
    $MICOINC    = "-I$MICOPREFIX/include";
    $MICOLIBS   = [ "-L$micolibpath -lmico$MICOVERSION" ];
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

    use Getopt::Long qw(:config gnu_compat);
    my $ssl_libpath;
    GetOptions( "with-ssl:s" => \$ssl_libpath );
    
    my $mico_setup  = undef;
    my $gtk_cflags  = undef;
    
    # Find MICO libraries
    for (split ':', $ENV{PATH}) {
        if (m!/bin$! && -f "$_/mico-c++") {
            s#/bin$##;
            $MICOPREFIX = $_;
            if (-f "$MICOPREFIX/lib/mico-setup.sh") {
                $mico_setup = "$MICOPREFIX/lib/mico-setup.sh";
                last;
            }
        }
    }

    if (defined $mico_setup) {
        ($MICOVERSION) = `. $mico_setup ; echo \$MICOVERSION`;
        chomp $MICOVERSION;
    } else {
        die "MICO not found\n";
    }

    $CC         = "$MICOPREFIX/bin/mico-c++",
    $MICOINC    = "-I$MICOPREFIX/include";
    $MICOLIBS   = "-L$MICOPREFIX/lib -lmico$MICOVERSION";

    #There was some strange Perl version:
    #$CCFLAGS .= '-DPERL_GCC_BRACE_GROUPS_FORBIDDEN';

    # Use Gtk or Not ?
    $gtk_cflags = `gtk-config --cflags`;
    undef $gtk_cflags if $?;
    
    if (defined $gtk_cflags) {
        print STDERR "Including GTK support\n";
        push @OBJECTS, 'gtkmico.o';
        $MICOINC    .= " $gtk_cflags";
        $DEFINE     .= ' -DHAVE_GTK';
    }
    
    # ssl 
    if( defined $ssl_libpath ) {
        $ssl_libpath = '/usr/lib' if $ssl_libpath eq '';
	$MICOLIBS .= " -L$ssl_libpath -lssl -lcrypto";
    }
    
    # some OS specific additions
    if( $Config{'osname'} eq "solaris" ) {
       $MICOLIBS .= " -R$MICOPREFIX/lib";
    }
    if( $Config{'osname'} eq "aix" ) {
       $MICOLIBS .= ' -lC_r -lm';
    }
    
    # compiler option specific
    if( $Config{'cc'} =~ /gcc/i || $Config{'osname'} eq "linux" ) {
      $OPTIMIZE .= ' -Wall';
      $MICOLIBS .= ' -lstdc++';
    }
}


# *******************************************************************
# This is for everybody
# *******************************************************************

# old Perl compats
if ($] < 5.0045) {
    print STDERR "Using compatibility macros/routines for Perl 5.004\n";
    push @OBJECTS,'constsub.o';
    $DEFINE .= ' -DPERL5004_COMPAT';
}

# debug purpose only
if( exists $ENV{CORBAMICO_DEBUG} ) {
    $DEFINE .= ' -DCORBAMICO_DEBUG';
}

WriteMakefile(
    'CC'            => $CC,
    'NAME'          => 'CORBA::MICO',
    'VERSION_FROM'  => 'MICO.pm',
    'LIBS'          => $MICOLIBS,   
    'DEFINE'        => $DEFINE,
    'INC'           => $MICOINC,
    'OBJECT'        => join (" ",@OBJECTS),
    'OPTIMIZE'      => $OPTIMIZE,
    'XSOPT'         => $XSOPT,
    'CCFLAGS'       => $CCFLAGS,
    'MAP_TARGET'    => 'micoperl',
    'MAKEAPERL'     => 1,
    'dist'          => { COMPRESS=>"gzip", SUFFIX=>"gz" },
    'clean'         => { FILES=>"account.ref ChangeLog.bak" },
    'PREREQ_PM'		=> {
      'Error'       => 0.13,
    }, 
);
