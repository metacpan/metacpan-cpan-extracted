#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/Makefile.PL,v 1.88 2011/07/29 13:05:27 tstapff Exp $
#
# ARSperl Makefile
#
# INSTRUCTIONS:
#    Set the following below:
#       1) path to API ($ARSAPI below)
#       2) libraries (uncomment/commentout appropriate $ARS_LIBS lines)
#       3) defines (see DEFINE OPTIONS)
#
#    run with "perl Makefile.PL" then type "make"
#

require 5.005;
use ExtUtils::MakeMaker;
use Config;
use Cwd;


$debug = 0;

###### There are FOUR (4) steps to complete. Complete all of them. ######

# STEP 1 -> Set the path to your ARS API directory

$ARSAPI      = "C:/Replication/Remedy/7.6.4";


# STEP 2 -> Choose architecture dependent suffix for library names, if necessary
$ARCHITECTURE = "";
#$ARCHITECTURE = "hpia32";   # HPUX Itanium 32-bit
#$ARCHITECTURE = "hpia64";   # HPUX Itanium 64-bit
#$ARCHITECTURE = "hppa64";   # HPUX PA-RISC 64-bit
#$ARCHITECTURE = "lx64";     # Linux 64-bit
#$ARCHITECTURE = "aixp64";   # AIX 64-bit
#$ARCHITECTURE = "solsp64";  # Solaris 64-bit


# STEP 3 -> Choose whether or not to enable encryption
#
# 0 -> No encryption library linking
# 1 -> Link against Remedy's encryption library
$ENCRYPT = 0;


# STEP 4 -> Some additional compilation options
#  
#   Change this only if you have good reason to do so.
#
%ADVANCED_CONFIG = (
	
	# you might try this if you experience memory violations
	UNDEF_PERL_MALLOC       => 0,

	# set to 1 if you need a backwards compatible version of ars_GetListGroup
	# (see the manual page of ars_GetListGroup for a more specific description)
	GETLISTGROUP_OLD_STYLE  => 0,
);


##############################
# unless you run into problems, you shouldn't need to read any further.
# if you do run into problems, and don't really know what this file
# does, try subscribing to the mailing list and ask for help there.
# subscription information is available at http://www.arsperl.org/


if( $ENV{ARSPERLTEST_PARAM} ){
	( $ARSVERSION, $ARSAPI, $ARSPERLTEST_SERVER, $ARSPERLTEST_USERNAME, $ARSPERLTEST_PASSWORD, $ARSPERLTEST_TCPPORT )
		= split( /;/, $ENV{ARSPERLTEST_PARAM} );
}
my $ra_arlibs = findArLibs($ARSAPI);
# use Data::Dumper;
# print "found ar libraries: ", Dumper($ra_arlibs);

$ARAPIVERSION = findAPIVersion($ARSAPI);
$ARSVERSION = ARSVersionString($ARAPIVERSION);

$WINDOWS = $^O eq 'MSWin32';
$GNU_WIN = ($^O eq 'MSWin32' || $^O eq 'cygwin') && $Config{'cc'} eq "gcc";


$AUTODEFINES = " -g ";
$AUTODEFINES = " -D_WIN32 " if($WINDOWS);
$AUTODEFINES .= "  -Wno-unused-variable -Wuninitialized " if $Config{'cc'} eq "gcc";
$AUTODEFINES .= " -D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_WARNINGS " if $WINDOWS && $ENV{ARSPERLTEST_PARAM};

$AUTODEFINES .= " -DARSPERL_UNDEF_MALLOC "   if $ADVANCED_CONFIG{UNDEF_PERL_MALLOC};
$AUTODEFINES .= " -DGETLISTGROUP_OLD_STYLE " if $ADVANCED_CONFIG{GETLISTGROUP_OLD_STYLE};

$AUTODEFINES .= " -DARSPERL_DEBUG " if $debug;


$ARS_STATIC_LIB = "";

$PM = { 'ARS.pm' => '$(INST_LIBDIR)/ARS.pm' };
foreach my $pm2install (qw{arerrno-h.pm  ar-h.pm  nparm.pm  OOform.pm  OOmsgs.pm  OOsup.pm}) {
	$PM->{'ARS/'.$pm2install} = '$(INST_LIBDIR)/ARS/'.$pm2install;
}

$LARCH = $ARCHITECTURE ? "_".$ARCHITECTURE : "";


if ($ARAPIVERSION >= ARS_VERSION_63) {
	$ARS_STATIC_LIB = "$ARSAPI/lib/libar$LARCH.a";
	$ARS_LIBS = "-larencrypt$LARCH -lcrypto_BMC_FIPS$LARCH " if $ENCRYPT;
	$ARS_LIBS .= " -lnsl ";
}else{
	$ARS_LIBS = " -lar$LARCH -lnsl ";
	$ARS_LIBS = " -lar$LARCH -larencrypt$LARCH -lnsl " if $ENCRYPT;
}

if ($GNU_WIN) {
	$ARS_LIBS = join(' ', map { "$ARSAPI/lib/" . $_ } @{$ra_arlibs});
} elsif ($WINDOWS) {
	$ARS_LIBS = join(' ', map { '-l' . $_ } @{$ra_arlibs});
} else {
	$ARS_LIBS .= " -lpthread ";
	$ARS_LIBS .= " -licuucbmc$LARCH -licui18nbmc$LARCH -licudatabmc$LARCH " if $ARAPIVERSION >= ARS_VERSION_70;
}
$AUTODEFINES .= " -DARS32 -DARS452 ";
if( ($ARAPIVERSION >= ARS_VERSION_50) && ($^O eq 'linux') && $LARCH !~ /64/ ){
	$AUTODEFINES .= " -malign-double ";
}



# e.g for 5.004_03 ..
#
# baserev = 5.0 ( = PERL_REVISION as of 5.6.0)
# PATCHLEVEL = 4
# SUBVERSION = 3 ( = PERL_SUBVERSION as of 5.6.0)
#
# baserev/SUBVERSION still work in 5.6.0, but who knows for how long.

print "Building against perl $]\n";

$AUTODEFINES .= " -DPERL_PATCHLEVEL_IS=$Config{'PATCHLEVEL'} -DPERL_SUBVERSION_IS=$Config{'SUBVERSION'} -DPERL_BASEREV_IS=".($Config{'baserev'}*10)." ";

if($Config{'baserev'} == 5 &&
   $Config{'PATCHLEVEL'} == 4 &&
   $Config{'SUBVERSION'} == 3) {
	print "\n\nWARNING: Perl-5.004_03 contained a buggy 'h2ph' application.\nYou should examine line 100 of perl's 'h2ph' script and be sure that it\n
produces correct syntax (it's missing a close-parenthesis)\n";
	print "\nsleeping for 5 seconds. press control-c to abort.\n\n";
	sleep 5;
}

if ($LARCH =~ /64/) {
	if ($Config{'cc'} =~ /cc/) {
		$REDUCE_SYMBOL_SCOPE = 1;
	}
	else {
		print "\n\nWARNING: Because of symbol name collisions (both -- perl and arapi -- use the xdr-functions),\n" .
		      "         it is necessary to reduce the symbol scope to symbols declared within the DSO.\n" .
		      "         ARSPerl wasn't tested on '$Config{'cc'}', if you run into trouble during 'make test'\n" .
		      "         please contact the developer/maintainer!\n\n";
	}
}

push(@extras, CAPI => 'TRUE') if ($] >= 5.005       &&
                                  $^O eq 'MSWin32'  && 
				  (($Config{archname} =~ /-object\b/i) ||
                                   ($Config{archname} =~ /-multi-thread\b/i))
                                 );
push(@extras, LDDLFLAGS => " -Wl,--exclude-symbols,\177arapi71_NULL_THUNK_DATA ") if $^O eq 'cygwin';
push(@extras, LDDLFLAGS => $Config{'lddlflags'}." -Wl,-Bsymbolic ") if ($REDUCE_SYMBOL_SCOPE);

if( $WINDOWS ){
  $ARS_LDPATH = qq{-L"$ARSAPI/lib"};
  $INCLUDES   = qq{-I"$ARSAPI/include"};
}else{
  $ARS_LDPATH = "-L$ARSAPI/lib";
  $INCLUDES   = "-I$ARSAPI/include";
}


GenerateSupportDotH("support-h.template", $INCLUDES);

print "Generating serverTypeInfoHints.h ..\n";

die "whoops. no file at ".$Config{'perlpath'} unless ( -f $Config{'perlpath'} );
$cmd = qq("$Config{'perlpath'}" infra/exsi.pl < "${ARSAPI}/include/ar.h" > serverTypeInfoHints.h);
$rv = system($cmd);
die "something went wrong when i ran \"$cmd\" (rv = $rv, expected 0)" unless ($rv == 0);

print "Converting C header files to perl modules ..\n";




foreach ("ar", "arerrno") {
	my $headerFile = "${ARSAPI}/include/${_}.h";

#	# arsystem >= 5.0 doesnt have nt libs/hdrs anymore
#	if( ($ARSVERSION >= 5.0) && /^nt/ ) {
#		open(FD, "> ARS/${_}-h.pm") || die "open: $!";
#		print FD "\# as of ARSystem 5.0, the NT (notifier) routines
## are retired. so this file is just stubbed.
#1;\n";
#		close(FD);
#		open (FD, "> ARS/artypes.ph") || die "open: $!";
#		print FD "\# hackaround for artypes.h. do not remove.\n1;\n";
#		close(FD);
#		next;
#	}

	# arsystem <= 6.0.3 doesnt have artypes.h

	next if ( ($ARAPIVERSION < ARS_VERSION_63) && /^artypes$/ );

	die "couldn't find $headerFile" if (! -e $headerFile);

#	# due to the endless confusion over h2ph, i'm including
#	# a known-good copy in the arsperl distribution. the 
#	# -d should make it create _h2ph_pre in the current 
#	# directory incase you never ran h2ph before (as root)

	if ($_ eq "artypes") {
		$rv = system("$Config{'perlpath'} infra/h2ph -d ./ARS < $headerFile > ARS/${_}.ph");
	} else {
		$rv = system("$Config{'perlpath'} infra/h2ph -d ./ARS < $headerFile > ARS/${_}-h.pm");
	}

#	unlink ('ARS/_h2ph_pre.ph');
#	open (FD, "> ARS/_h2ph_pre.ph") || die "open: $!";
#	print FD "1;\n";
#	close(FD);

	if((! -e "ARS/${_}-h.pm") || (-z "ARS/${_}-h.pm")) {
		open (FD, "> ARS/${_}-h.pm") || die "open: $!";
		print FD "\# your perl installation was either missing the 'h2ph'
\# utility or it was not in your path with you ran 'perl Makefile.PL'

1;\n";
		close (FD);
	}
}

print "Configuring with options:\n";
print "\tARSAPI        = $ARSAPI\n";
print "\tARSVERSION    = $ARSVERSION\n";
print "\tARAPIVERSION  = $ARAPIVERSION\n";
print "\tAUTODEFINES   = $AUTODEFINES\n";

die "FATAL: couldn't detect a supported api version!" if ($ARAPIVERSION eq "");
#$PM->{'ARS/_h2ph_pre.ph'} = '$(INST_LIBDIR)/ARS/_h2ph_pre.ph';

WriteMakefile(
	      'NAME'	=> 'ARS',
	      'VERSION_FROM' => 'ARS.pm',
	      'DISTNAME' => 'ARSperl',
	      'LICENSE'  => 'artistic_1',
	      'META_MERGE' => {
	        resources => {
	          repository => 'https://github.com/jeffmurphy/ARSperl',
	          bugtracker => 'https://github.com/jeffmurphy/ARSperl/issues',
	        },
	      },
	      'LIBS'	=> $GNU_WIN ? [""] : ["${ARS_LDPATH} ${ARS_LIBS}"],
	      'MYEXTLIB' => $WINDOWS ? ($GNU_WIN ? $ARS_LIBS : '') : $ARS_STATIC_LIB,
	      'OBJECT' => q[ARS$(OBJ_EXT) support$(OBJ_EXT) supportrev$(OBJ_EXT) supportrev_generated$(OBJ_EXT) ],
	      'INC'	=> "${INCLUDES}",
	
	      'PM' => $PM,

	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
               (ABSTRACT      => 'ARSperl is an integration kit for Perl5 and the Remedy Action Request System.',
                AUTHOR        => 'ARSPerl Dev Group <arsperl-devel@arsperl.org>') : ()),

	      @extras,

# DEFINE OPTIONS:
#  NOTE: these should automatically be detected and configured above.
#        see the $AUTODEFINES variable above.
#
#    -DPROFILE
#
#       Enable query profiling code (very little overhead).
#       See ars_GetProfileInfo() call for details.
#       Don't use this if you are compiling on _WIN32
#
#    -DARS20
#
#       If you are running ARS2.0.2 or anything less than 2.1, you should
#       add -DARS20 to the DEFINE line.
#
#    -DARS32
#       If you are compiling against ARS 3.2 API libraries defined this
#       because AdminExtension API routines were removed in as of
#       the 3.2 release.
#
#    -D_WIN32
#
#       If you are compiling ARSperl under windows, define this
#       and /don't/ define PROFILE.
#
#    -DSKIP_SV_ISA  (not automatically set)
#
#       If you get errors during compilation/runtime similar to 
#       "undefined symbol: sv_isa" then add this define.

	      'DEFINE'	=> ${AUTODEFINES},
#             'DEFINE'  => '-D_WIN32 ', # note: win32 -> no -DPROFILE


# if you have trouble under solaris when linking (bfd assertion 
# failures) try uncommenting the following:
#
#	      'LD' => "/usr/ccs/bin/ld",

# don't fiddle with this

              'realclean' => {
		 'FILES' => 'support.h ARS/ar-h.pm ARS/arerrno-h.pm ARS/_h2ph_pre.ph  t/config.cache serverTypeInfoHints.h *~ .purify ' 
	      } 
);

makeTestConfig();

print "
Type 'make' (windows: 'nmake') to build ARSperl.
Type 'make test' to test ARSperl before installing.
Type 'make install' to install ARSperl.

";

exit 0;

# ROUTINE
#   GenerateSupportDotH(template-file, includes-dir)
#
# DESCRIPTION
#   this routine extracts some information from the 
#   "ar.h" file and generates some "type maps" which help
#   us translate from code numbers to readable text.

sub GenerateSupportDotH {
    my ($tmpl, $incdir) = (shift, shift);
    my (@arh);

    $incdir =~ s/^-I//g;
    $incdir =~ s/^"//;
    $incdir =~ s/"$//;

    print "Generating support.h file..\n";

    die "not a directory ($incdir): $!" if(! -d $incdir);
    open(ARH, $incdir."/ar.h") || die "can't open $incdir/ar.h : $!";
    @arh = <ARH>;
    close(ARH);

    open(FD, "> support.h") || die "can't open temporary file: $!";
    open(TMPL, $tmpl) || die "can't open template ($tmpl): $!";

    print FD "/* THIS FILE WAS AUTOMATICALLY GENERATED BY Makefile.PL */\n";
    print FD "/*                  DO NOT EDIT                         */\n";
    print FD "\n\n";

    while(<TMPL>) {
	if(/CHARMENUREFRESHCODETYPEMAP/) {
	    print "\tProcessing AR_MENU_REFRESH codes..\n";
	    my($line, $code);
	    foreach $line (grep (/^\#define\s+AR_MENU_REFRESH.*/, @arh)) {
		$code = (split(/\s/, $line))[1];
		print "\t\t$code\n" if $debug;
		$code =~ /^AR_MENU_REFRESH_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	} 
	elsif(/CHARMENUDDTYPEMAP/) {
	    print "\tProcessing AR_CHAR_MENU_DD type codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_CHAR_MENU_DD_.*/, @arh)) {
		$code = (split(/\s/, $line))[1];
		print "\t\t$code\n" if $debug;
		$code =~ /^AR_CHAR_MENU_(\w+)/;
		last if ($1 eq "DD_DB_NAME");
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/CHARMENUDDNAMEMAP/) {
	    print "\tProcessing AR_CHAR_MENU_DD name codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_CHAR_MENU_DD_.*/, @arh)) {
		$code = (split(/\s/, $line))[1];
		print "\t\t$code\n" if $debug;
		$code =~ /^AR_CHAR_MENU_(\w+)/;
		next if ($1 eq "DD_NONE");
		next if ($1 eq "DD_FORM");
		next if ($1 eq "DD_FIELD");
		last if ($1 eq "DD_FORMAT_NONE");
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/CHARMENUDDVALUEMAP/) {
	    print "\tProcessing AR_CHAR_MENU_DD value format..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_CHAR_MENU_DD_FORMAT_.*/, @arh)) {
		$code = (split(/\s/, $line))[1];
		print "\t\t$code\n" if $debug;
		$code =~ /^AR_CHAR_MENU_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/CHARMENUTYPEMAP/) {
	    print "\tProcessing AR_CHAR_MENU codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_CHAR_MENU.*/, @arh)) {
		$code = (split(/\s/, $line))[1];
		print "\t\t$code\n" if $debug;
		$code =~ /^AR_CHAR_MENU_(\w+)/;
		next if ($1 =~ m/^DD_/);
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/STATUSRETURNTYPEMAP/) {
	    print "\tProcessing AR_RETURN codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_RETURN.*/, @arh)) {
		$code = (split(/\s/, $line))[1];
		print "\t\t$code\n" if $debug;
		$code =~ /^AR_RETURN_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/SERVERSTATTYPEMAP/) {
	    print "\tProcessing AR_SERVER_STAT codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_SERVER_STAT.*/, @arh)) {
		$code = (split(/\s/, $line))[1];
		print "\t\t$code\n" if $debug;
		$code =~ /^AR_SERVER_STAT_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/SCHEMAPERMISSIONTYPEMAP/) {
	    print "\tProcessing AR_PERMISSIONS (Schema) codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_PERMISSIONS.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		# _view & _change are field permissions
		# it would be nice if AR_PERM.. differentiated between
		# schema and field.

		if($code !~ /_VIEW|_CHANGE/) {
		    print "\t\t$code\n" if $debug;
		    $code =~ /^AR_PERMISSIONS_(\w+)/;
		    print FD "  { $code, \t\t\"\L$1\E\" },\n";
		}
	    }
	}
	elsif(/FIELDPERMISSIONTYPEMAP/) {
	    print "\tProcessing AR_PERMISSIONS (Field) codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_PERMISSIONS.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		# _visible & _hidden are schema permissions
		if($code !~ /_VISIBLE|_HIDDEN/) {
		    print "\t\t$code\n" if $debug;
		    $code =~ /^AR_PERMISSIONS_(\w+)/;
		    print FD "  { $code, \t\t\"\L$1\E\" },\n";
		}
	    }
	}
	elsif(/DATATYPEMAP/) {
	    print "\tProcessing AR_DATA_TYPE codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_DATA_TYPE.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_DATA_TYPE_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
        elsif(/SCHEMATYPEMAP/) {
            print "\tProcessing AR_SCHEMA codes..\n";
            my($code, $line);
            foreach $line (grep (/^\#define\s+AR_SCHEMA.*/, @arh)) {
		# another instance of poor naming conventions
		next if $line =~ /_DELETE/;
                $code = (split(/\s/, $line))[1];

                print "\t\t$code\n" if $debug;
                $code =~ /^AR_SCHEMA_(\w+)/;
                print FD "  { $code, \t\t\"\L$1\E\" },\n";
            }
        }
        elsif(/STRUCTITEMTYPEMAP/) {
            print "\tProcessing AR_STRUCT_ITEM codes..\n";
            my($code, $line);
            foreach $line (grep (/^\#define\s+AR_STRUCT_ITEM.*/, @arh)) {
                $code = (split(/\s/, $line))[1];

                print "\t\t$code\n" if $debug;
                $code =~ /^AR_STRUCT_ITEM_(\w+)/;
                print FD "  { $code, \t\t\"\L$1\E\" },\n";
            }
        }
	elsif(/BYTELISTTYPEMAP/) {
	    print "\tProcessing AR_BYTE_LIST codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_BYTE_LIST.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_BYTE_LIST_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/NOMATCHOPTIONMAP/) {
	    print "\tProcessing AR_NO_MATCH codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_NO_MATCH.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_NO_MATCH_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/MULTIMATCHOPTIONMAP/) {
	    print "\tProcessing AR_MULTI_MATCH codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_MULTI_MATCH.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_MULTI_MATCH_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/FUNCTIONMAP/) {
	    print "\tProcessing AR_FUNCTION codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_FUNCTION.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_FUNCTION_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/CONTAINERTYPEMAP/) {
	    print "\tProcessing ARCON codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+ARCON.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^ARCON_(\w+)/;
		last if ($1 eq "LAST_RESERVED");
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/CONTAINEROWNERMAP/) {
	    print "\tProcessing ARCONOWNER codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+ARCONOWNER.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^ARCONOWNER_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/REFERENCETYPEMAP/) {
	    print "\tProcessing ARREF codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+ARREF.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^ARREF_(\w+)/;
		next if ($1 eq "LAST_SERVER_OBJ");
		last if ($1 eq "LAST_RESERVED");
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/KEYWORDMAP/) {
	    print "\tProcessing AR_KEYWORD codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_KEYWORD.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_KEYWORD_(\w+)/;
		printf(FD "  { %s, \t\t\"\\0\L%s\E\\0\", \t\t%d },\n",
		       $code, $1, length($1)+2);
	    }
	}
	elsif(/SERVERINFOMAP/) {
	    print "\tProcessing AR_SERVER_INFO codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_SERVER_INFO.*/, @arh)) {
		$code = (split(/\s+/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_SERVER_INFO_(\w+)/;
		next if ($1 eq "MIN_AUDIT_LOG_FILE_SIZE");
		print FD "  { $code, \t\"$1\" },\n";
	    }
	}
	elsif(/DDEACTIONMAP/) {
	    print "\tProcessing AR_DDE codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_DDE.*/, @arh))
            {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_DDE_(\w+)/;
		print FD "  { $code, \t\"\L$1\E\" },\n";
	    }
	}
	elsif(/ACTIVELINKACTIONTYPEMAP/) {
	    print "\tProcessing AR_ACTIVE_LINK_ACTION codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_ACTIVE_LINK_ACTION.*/, @arh))
            {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_ACTIVE_LINK_ACTION_(\w+)/;
		last if ($1 eq "OPEN_DLG");
		print FD "  { $code, \t\"\L$1\E\" },\n";
	    }
	}
	elsif(/OPENWINDOWMODEMAP/) {
	    print "\tProcessing AR_ACTIVE_LINK_ACTION_OPEN codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_ACTIVE_LINK_ACTION_OPEN_.*/, @arh))
            {
		$code = (split(/\s/, $line))[1];
		print "\t\t$code\n" if $debug;
		$code =~ /^AR_ACTIVE_LINK_ACTION_(\w+)/;
		print FD "  { $code, \t\"\L$1\E\" },\n";
	    }
	}
	elsif(/COMPARMTYPEMAP/) {
	    print "\tProcessing AR_COM_PARM codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_COM_PARM.*/, @arh))
	    {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_COM_PARM_(\w+)/;
		print FD "  { $code, \t\"\L$1\E\" },\n";
	    }
	}
	elsif(/COMMETHODTYPEMAP/) {
	    print "\tProcessing AR_COM_METHOD codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_COM_METHOD.*/, @arh))
	    {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_COM_METHOD_(\w+)/;
		print FD "  { $code, \t\"\L$1\E\" },\n";
	    }
	}
	elsif(/FILTERACTIONTYPEMAP/) {
	    print "\tProcessing AR_FILTER_ACTION codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_FILTER_ACTION.*/, @arh))
	    {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_FILTER_ACTION_(\w+)/;
		print FD "  { $code, \t\"\L$1\E\" },\n";
	    }
	}
	elsif(/SIGNALTYPEMAP/) {
	    print "\tProcessing AR_SIGNAL codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_SIGNAL.*/, @arh))
	    {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_SIGNAL_(\w+)/;
		print FD "  { $code, \t\"\L$1\E\" },\n";
	    }
	} else {
	    print FD $_;
	}
    }
    close(TMPL);
    close(FD);

    print "\n";

}

sub makeTestConfig {
	my ($SERVER, $USERNAME, $PASSWORD, $TCPPORT);
	my ($S, $U, $P, $T) = ("", "", "", 0);

	if(-e "./t/config.cache") {
		do './t/config.cache';
		$S = &CCACHE::SERVER;
		$U = &CCACHE::USERNAME;
		$P = &CCACHE::PASSWORD;
		$T = &CCACHE::TCPPORT;
	}

	print "=== ARSperl 'make test' configuration. ===

Please enter the following information. This information will be
recorded in ./t/config.cache

If you want to skip the 'make test' step, just hit ENTER
three times. You can configure it later by either re-running
'perl Makefile.PL' or by editting ./t/config.cache

Fair warning: you probably don't want to run 'make test' against a 
production ARSystem server. 

";
	
	( $SERVER, $USERNAME, $PASSWORD ) = ( '', '', '' );	
	print "Server Name [$S]: ";
	chomp($SERVER = $ARSPERLTEST_SERVER || <STDIN>);
	if($SERVER eq "") {
		$SERVER = $S if ($S ne "");
	} 

	print "Admin Username [$U]: ";
	chomp($USERNAME = $ARSPERLTEST_USERNAME || <STDIN>);
	if($USERNAME eq "") {
		$USERNAME = $U if ($U ne "");
	} 

	print "Admin Password [$P]: ";
	chomp($PASSWORD = defined($ARSPERLTEST_PASSWORD) ? $ARSPERLTEST_PASSWORD : <STDIN>);
	if($PASSWORD eq "") {
		$PASSWORD = $P if ($P ne "");
	} 

	print "TCP Port [$T]: ";
	chomp($TCPPORT = defined($ARSPERLTEST_TCPPORT) ? $ARSPERLTEST_TCPPORT : <STDIN>);
	if($TCPPORT eq "") {
		$TCPPORT = $T if ($T ne "");
	} 
	$TCPPORT = 0 if ! $TCPPORT;

	#print "Storing $SERVER / $USERNAME / $PASSWORD ..\n";
	open (FD, "> ./t/config.cache") || die "open failed: $!";
	print FD "package CCACHE;\n";
	print FD "\# enter your server, admin username and password below.\n\n";
	print FD "sub SERVER { \"$SERVER\" ; }\n";
	print FD "sub USERNAME { \"$USERNAME\" ; }\n";
	print FD "sub PASSWORD { \"$PASSWORD\" ; }\n";
	print FD "sub TCPPORT { $TCPPORT ; }\n";
	print FD "1;\n";
	close(FD);

}



#
# given a path to the Api directory, go find ar.h and parse the value
#  of the AR_CURRENT_API_VERSION #define and return it.
# if the path to ar.h is, e.g.,
#  c:\Program Files\ARSystem6.0.1\Arserver\Api\include\ar.h
# then this method wants an appropriately quoted
#  c:\Program Files\ARSystem6.0.1\Arserver\Api
# as its first arg
#
sub findAPIVersion {
  my $path_to_api_dir = shift;

  my $ar_fname = join('/', $path_to_api_dir, 'include', 'ar.h');
  open ($ar_fh, '<'. $ar_fname) or
    die "couldn't open ar.h include file from: \"$ar_fname\": $!\n";

  my $api_version = undef;

  # the line we want to parse looks like:
  #
  ##define AR_CURRENT_API_VERSION       10  /* current api version */
  while (<$ar_fh>) {
    chomp;
    if (m/^\s*#define\s*AR_CURRENT_API_VERSION\s*(\d+)/) {
      $api_version = $1;
      last;
    }
  }

  close $ar_fh;
  return $api_version;
}


#
# given an API version from above, return the minimum server version
#  that supports it.
# That is, if an API version is supported by multiple releases of the
#  AR System Server, we return the chronologically first version
#  since compiling against that version will have been the first
#  time we have arsperl will have to change to support the API change.
#
# this whole strategy of deriving the server version from the api version
#  presumes that we won't have to distinguish between releases of the
#  same api version, which may or may not be correct.
#
# the api version can be the main variable arsperl uses to adjust
#  itself however.
#

sub serverReleaseFromAPIVersion {
  my $api_version = shift;

  # keys are server releases converted to floating point numbers;
  #  values are the api version that release produced.
  # add more values to this table as needed.
  my $rh_api_version_table =
    {
     4.5  => 7,
     4.51 => 7,
     4.52 => 7,
     5.0  => 8,
     5.01 => 8,
     5.1  => 9,
     5.11 => 9,
     5.12 => 9,
     6.0  => 10,
     6.01 => 10,
     6.3  => 11,
    };

  my @api_list = ();
  # make a sorted list from the api version / server release values
  #  that match our api version.
  while (($server_rel, $api) = each %{$rh_api_version_table}) {
    if ($api_version == $api) {
      push @api_list, $server_rel;
    }
  }

  # make sure the values are treated as numbers during the sort
  my @sorted = sort { ($a + 0) <=> ($b + 0) }@api_list;

  return $sorted[0];
}

sub findArLibs {
  my $path_to_api_dir = shift;

  my $cwd = getcwd();
  my $ar_lib_dir = join('/', $path_to_api_dir, 'lib');
  chdir($ar_lib_dir);

  # we want all of the files that end in .lib on win32
  my @libs = <*.lib>;
  chdir($cwd);

  return \@libs;
}

sub ARS_VERSION_45  {  7; }
sub ARS_VERSION_50  {  8; }
sub ARS_VERSION_51  {  9; }
sub ARS_VERSION_60  { 10; }
sub ARS_VERSION_63  { 11; }
sub ARS_VERSION_70  { 12; }
sub ARS_VERSION_71  { 13; }
sub ARS_VERSION_75  { 14; }
sub ARS_VERSION_760 { 15; }
sub ARS_VERSION_762 { 16; }
sub ARS_VERSION_763 { 17; }
sub ARS_VERSION_764 { 18; }
sub ARS_VERSION_80  { 19; }
sub ARS_VERSION_81  { 20; }
## @Devs: set the following constant always to the latest version supported by ARSPerl
sub ARS_MAX_API { ARS_VERSION_81; }

sub ARSVersionString {
	my $APIVersionID = shift;
	my $api2Version = {
		&ARS_VERSION_45 => '4.5',
		&ARS_VERSION_50 => '5.0',
		&ARS_VERSION_51 => '5.1',
		&ARS_VERSION_60 => '6.0',
		&ARS_VERSION_63 => '6.3',
		&ARS_VERSION_70 => '7.0',
		&ARS_VERSION_71 => '7.1',
		&ARS_VERSION_75 => '7.5',
		&ARS_VERSION_760 => '7.6',
		&ARS_VERSION_762 => '7.6',
		&ARS_VERSION_763 => '7.6.03',
		&ARS_VERSION_764 => '7.6.04',
		&ARS_VERSION_80 => '8.0',
		&ARS_VERSION_81 => '8.1',
	};
	if ($APIVersionID > ARS_MAX_API) { return "Unsupported API-Version: (using " . $api2Version{ARS_MAX_API} . ")"; }
	if (!$APIVersionID || $APIVersionID < ARS_VERSION_45) { return "Unsupported API version!"; }
	return $api2Version->{$APIVersionID};
};
