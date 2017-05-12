use 5.000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

#
# --- The following lines need to be adjusted !!!!!
#

# --- installation path of EMBOSS (--PREFIX during EMBOSS' configure)
#        (if you did no "make install" of EMBOSS,
#         put here the path to the source code)

$EMB_ROOT     = "";
#$EMB_ROOT     = "/usr/local";


# --- external libraries required by EMBOSS
#     XLIB and LIBS from the EMBOSS Makefile 
#     (<emboss-build-dir>/emboss/Makefile)

$EMB_EXT_LIBS = "";
#$EMB_EXT_LIBS = "-L/usr/X11R6/lib -lX11 -lm  -lgd -lpng -lz";
#$EMB_EXT_LIBS = "-L/usr/openwin/lib -lX11 -lsocket -lm -lnsl -lgd -lpng -lz";


# --- overwrite EMB_ROOT=xxx etc. from command-line if given
@ARGV = extract_global_params (\@ARGV, qw (EMB_ROOT EMB_EXT_LIBS EMB_SRC_ROOT));

#
# --- Look at these settings if building fails ....
#

# --- path to EMBOSS' sources (for the *.h files)

#$EMB_SRC_ROOT = "/usr/local/src/EMBOSS-2.7.1";


# --- DEFS from the EMBOSS Makefile; maybe not needed

$EMB_DEFS = "";
# $EMB_DEFS = " -DPACKAGE_NAME=\"\" -DPACKAGE_TARNAME=\"\" .....";


# --- Change the following lines only, if EMBOSS libraries
#     or EMBOSS includes weren't found.
#
#     $EMB_LIBS: The nucleus, ajaxg, ajax and plplot libraries are taken
#                from the lib/ subdirectory in $EMB_ROOT by default.
#     $EMB_INC:  The *.h files are taken from the subdirectories
#                nucleus, ajax and plplot in $EMB_SRC_ROOT by default,
#                or the include subdirectory in $EMB_ROOT.
#
@emb_libs = qw(nucleus ajax ajaxg eplplot);
@emb_lib_dirs = qw(plplot ajax nucleus);

if (-d "$EMB_ROOT/lib") {
    @lib_search_dirs = qw(lib);
} elsif (-d "$EMB_ROOT/ajax/.libs") {
    @lib_search_dirs = qw(plplot/.libs ajax/.libs nucleus/.libs);
} else {
    @lib_search_dirs = qw(plplot ajax nucleus);
}

warn ("warning: **** \$EMB_ROOT not set\n") unless -d $EMB_ROOT;
if ($EMB_EXT_LIBS eq "" and $EMB_ROOT ne "") {
    my $themakefile = $EMB_SRC_ROOT ? $EMB_SRC_ROOT : $EMB_ROOT;
    $themakefile .= "/emboss/Makefile";

    warn "\n\$EMB_EXT_LIBS not defined.\n".
	"Usually this variable must be set to a combined value\n".
	"of XLIB and LIBS from the EMBOSS Makefile:\n\n";

    if (-f $themakefile) {
	my $grepres = `$^X -ne 'print if /^(X_\\w+LIBS|LIBS|XLIB)\\b/' $themakefile`;	warn $grepres . "\n";
    } else {
	warn "$themakefile (file not found)\n".
	    "Can not find EMBOSS source to guess XLIB and LIBS\n".
	    "Use parameter EMB_SRC_ROOT to set EMBOSS source location\n\n";
    }
}

$EMB_LIBS = join (" ", map { "-L$EMB_ROOT/$_" } @lib_search_dirs) .  " " .
            join (" ", map { "-l$_" } @emb_libs) .  " " .
            $EMB_EXT_LIBS;
if ($ENV{OSTYPE} eq "solaris") {
     $EMB_LIBS = join (" ", map { "-R$EMB_ROOT/$_" } @lib_search_dirs) .
          " " . $EMB_LIBS;
}

if (-d "$EMB_ROOT/include") {
    $EMB_INC = "-I$EMB_ROOT/include";
} else {
    $EMB_INC =  join " ", map { "-I$EMB_ROOT/$_" } grep { -d "$EMB_ROOT/$_"} @emb_lib_dirs;
}

print "Searching EMBOSS libraries in $EMB_LIBS\n";
print "Searching EMBOSS headers in $EMB_INC\n";


# --- look for EMBOSS in $EMB_ROOT and $EMB_SRC_ROOT
#     (disable if you change $EMB_LIBS or $EMB_INC manually)
# ---- check function needs update
$check_installation = 0;


# --- trying to get the EMBOSS version from the application 'embossversion'
#     (if this doesn't work, set $EMB_VERSION here to e.g. "2.5.1"
$embossversion = "$EMB_ROOT/bin/embossversion";
$embossversion = "$EMB_ROOT/emboss/embossversion" unless -x $embossversion;

$EMB_VERSION = `$embossversion -stdout -auto`; # e.g. 2.5.1


# --- solving name conflicts Perl <-> Emboss:

# --- some Perl defines need to be undefined for EMBOSS
@emboss_undefs = qw(ELSE WORD apply);
# --- some EMBOSS terms need to be redefined, because they are
#     already used by Perl
@emboss_redefs = qw(regexp OP_NOT OP_REF OP_REVERSE);


# --- include functions that have been declared "deprecated"
$INCLUDE_DEPRECATED_FUNCTIONS = 1;

#
# --- END of adjustments
#


# --- list of modules in this package
@modules_lib = qw(
Emboss_acd
Emboss_align
Emboss_arr
Emboss_assert
Emboss_base
Emboss_call
Emboss_cod
Emboss_dan
Emboss_dmx
Emboss_domain
Emboss_feat
Emboss_file
Emboss_fmt
Emboss_graph
Emboss_hist
Emboss_index
Emboss_list
Emboss_math
Emboss_matrices
Emboss_mem
Emboss_mess
Emboss_nam
Emboss_nexus
Emboss_pdb
Emboss_pdbio
Emboss_phylo
Emboss_range
Emboss_reg
Emboss_report
Emboss_seq
Emboss_seqabi
Emboss_seqdb
Emboss_seqread
Emboss_seqtype
Emboss_seqwrite
Emboss_sort
Emboss_str
Emboss_sys
Emboss_table
Emboss_time
Emboss_translate
Emboss_tree
Emboss_util
Emboss_vector

Emboss_embcom
Emboss_embcons
Emboss_embdata
Emboss_embdbi
Emboss_embdmx
Emboss_embdomain
Emboss_embest
Emboss_embexit
Emboss_embgroup
Emboss_embiep
Emboss_embindex
Emboss_embinit
Emboss_embmat
Emboss_embmisc
Emboss_embmol
Emboss_embnmer
Emboss_embpatlist
Emboss_embpdb
Emboss_embprop
Emboss_embread
Emboss_embshow
Emboss_embword

		  );

@depre_modules_lib = qw(
deprecated_Emboss_acd
deprecated_Emboss_hist
deprecated_Emboss_list
deprecated_Emboss_seq
deprecated_Emboss_seqwrite
deprecated_Emboss_str
deprecated_Emboss_sys
deprecated_Emboss_table
deprecated_Emboss_time
deprecated_Emboss_util
			);

push (@modules_lib, @depre_modules_lib) if $INCLUDE_DEPRECATED_FUNCTIONS;


@sub_modules_lib = qw(
);

# --- library modules plus main module
@modules = ("Emboss", @modules_lib);

# --- create %XS hash (input .xs files)
#     create @OBJECTS (.o files for the library)
foreach $mod (@modules) {
    $XS{"$mod.xs"} = "$mod.c";
    push (@OBJECTS, $mod . '$(OBJ_EXT)');
}
$OBJECT = join (" ", @OBJECTS);

# --- list of .xs files in @modules_lib
$xs_modules = join(" \\\n   ", map ("$_.xs", @modules_lib), @sub_modules_lib);

# --- output of scripts/get_boot_for_modules.pl
#     included by Emboss.xs
$emboss_boot = "emboss-boot-xs.inc emboss-boot-c.inc";

# --- stripping unused boots
$strip = join "\n", map { "\tstrip -N boot_Bio__$_ $_\$(OBJ_EXT)"} @modules_lib;


# --- add -DEMBOSS_VERSION_1=... to $EMB_DEFS
#     (major/minor/... version numbers)
chomp ($EMB_VERSION);

$config_header_file = "bio_emboss_config.h";
&write_config_h ($EMB_VERSION, $config_header_file);

if ($EMB_VERSION) {
    print "Using EMBOSS version $EMB_VERSION\n";
} else {
    warn ("warning: **** \$EMB_VERSION not set in $0\n");
}


# --- some Perl defines need to be undefined for EMBOSS
$emboss_undefs = join (" \\\n  --undef ", "", @emboss_undefs);
# --- some EMBOSS termes need to be redefined, because they are
#     already used by Perl
$emboss_redefs = join (" \\\n  --redef ", "", @emboss_redefs);



WriteMakefile(
    'NAME'		=> 'Bio::Emboss',
    'VERSION_FROM'	=> 'Emboss.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (
       # ABSTRACT_FROM => 'Emboss.pm', # retrieve abstract from module
       AUTHOR     => 'Peter Ernst <pernst@cpan.org>') : ()),

    'XS'                => \%XS,    # all the modules
    'OBJECT'            => $OBJECT, # all the modules

    'LIBS'		=> [$EMB_LIBS], # e.g., '-lm'

    'DEFINE'		=> $EMB_DEFS, # e.g., '-DHAVE_SOMETHING'

      # -I- inhibits the use of the current file directory as the
      # first search directory for "#include "file"" (search ./include
      # always before $EMB_INC)
    'INC'		=> "-I. $EMB_INC", 

    'clean'             => { FILES => $config_header_file },
);

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = ({name => EMBOSS_VERSION,
		type => PV},
	       {name => AJM_E,
		type => NV},
	       {name => AJM_PI,
		type => NV},
	       );
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Bio::Emboss',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
    if  ((eval {require File::Copy; import File::Copy; 1}) and
         (eval {require File::Spec; import File::Spec; 1}) ){
	my $file;
	foreach $file ('const-c.inc', 'const-xs.inc') {
	    my $fallback = File::Spec->catfile('fallback', $file);
	    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
	}
    } else {
	my $file;
	foreach $file ('const-c.inc', 'const-xs.inc') {
	    my $fallback = "fallback/$file";
	    system ("cp", $fallback, $file) and die "Can't copy $fallback to $file: $!";
	}
    }
}

# --- check adjustments
#     enable if you have problems while building
if ($check_installation) {
    my ($lib, $dmsg);
    foreach $lib (map { "$EMB_ROOT/lib/lib$_" } @emb_libs) {
	next if -r "$lib.so" or -r "$lib.a";
	$dmsg .= "couldn't find '$lib' in \$EMB_ROOT ($EMB_ROOT)\n";
    }

    my $incfile = $EMB_SRC_ROOT . "/nucleus/emboss.h";
    my $incfile2 = $EMB_ROOT . "/include/emboss.h";
    unless (-r $incfile or -r $incfile2 ) {
	$dmsg .= "couldn't find '$incfile' or '$incfile2' in \$EMB_SRC_ROOT or \$EMB_ROOT\n";
    }

    if ($dmsg) {
	warn ("\n" . $dmsg .
	      "\n***\n*** This module might not build properly\n" .
	      "*** Check $0\n***\n\n");
    }
}

exit(0);

#
# --- end of main
#


# --- add to Makefile
#     targets for:
#       lib/Bio/Emboss/Methods.pm
#       the bootstrap files included by Emboss.xs ($emboss_boot)
#       Ajax docum. in POD format ( blib/Bio/Emboss/Ajax.pod)

sub MY::postamble {
    my $ajax_dir = $EMB_SRC_ROOT ? $EMB_SRC_ROOT : $EMB_ROOT;
    $ajax_dir .= "/ajax";
    $ajax_dir = "" unless -d $ajax_dir;
    my $postamble = <<"MAKE_FRAG";

# --- recreate Methods.pm if any of the .xs files has changed
lib/Bio/Emboss/Methods.pm:  Emboss.xs \$(EMBOSS_XS_MODULES)
\t\$(PERL) scripts/get_methods.pl Emboss.xs \$(EMBOSS_XS_MODULES) > \$\@

EMBOSS_BOOT_FILES = $emboss_boot
EMBOSS_XS_MODULES = $xs_modules

# --- recompile if a boot include has changed
Emboss.c: \$(EMBOSS_BOOT_FILES)

# --- recreate the boot includes if any of the module .xs files has changed
\$(EMBOSS_BOOT_FILES): \$(EMBOSS_XS_MODULES)
\t\$(PERL) scripts/get_boot_for_modules.pl \$(EMBOSS_XS_MODULES)

# --- target to create additional POD format documentation
epods: \$(INST_LIB)/Bio/Emboss/Ajax.pod

# --- how to create Ajax POD
AJAX_DIR = $ajax_dir
\$(INST_LIB)/Bio/Emboss/Ajax.pod:
\tif test "\$(AJAX_DIR)" != ""  ; then \\
\t  if test -d "\$(AJAX_DIR)" ; then \\
\t     \$(PERL) scripts/extract_doc_for_pod.pl \$(AJAX_DIR)/*.c > \$\@ ;\\
\t  else \\
\t     echo " *** AJAX_DIR=\$(AJAX_DIR) directory not found" ;\\
\t  fi ;\\
\telse \\
\t  echo "\\n *** AJAX_DIR not defined" ;\\
\t  echo " *** You need to specify EMB_SRC_ROOT in Makefile.PL or AJAX_DIR in Makefile" ;\\
\tfi
#\ttest "$EMB_SRC_ROOT" != "" && \$(PERL) scripts/extract_doc_for_pod.pl $EMB_SRC_ROOT/ajax/*.c > \$\@

# --- wrapper for emboss.h with some undefs and redefs
#     (solve name conflicts between PERL and EMBOSS)
emboss_perl.h:
\t\$(PERL) scripts/create_cpp_undefs_redefs.pl$emboss_undefs$emboss_redefs > \$\@

strip: \$(OBJECT)
$strip
MAKE_FRAG

   return $postamble;
}


sub write_config_h {
    my ($eversion, $outfile) = @_;

    my $configh = "";

    $configh .= <<EOB if length($eversion);
#ifndef EMBOSS_VERSION
#define EMBOSS_VERSION "$eversion"
#endif
EOB
    my ($v);
    foreach $v (qw(
		  4.1.0
		  4.0.0
		  2.10.0
		  2.9.0
		  2.8.0
		  2.7.0
		  2.6.0
		  2.5.1)) {
	if (version_ge($eversion, $v)) {
	    my $label = $v;
	    $label =~ tr/./_/;
	    $configh .= "#define HAVE_EMBOSS_$label\n";
	}
    }

    open (CONFIGH, ">$outfile");
    print CONFIGH $configh;
    close(CONFIGH);
}


# --- overwrite EMB_ROOT=xxx etc. from command-line if given
sub extract_global_params {
    my ($argvref, @argv_params) = @_;
    my @nargv = ();
  ARGS: 
    foreach (@$argvref) {
	foreach my $p (@argv_params) {
	    if (/^$p=(.*)/) {
		eval "\$$p = \$1";
		next ARGS;
	    }
	}
	push (@nargv, $_);
    }
    return @nargv;
}

sub version_ge {
    my @a = split (/\./, $_[0], 3);
    my @b = split (/\./, $_[1], 3);

    my ($i);
    for ($i = 0; $i < 3; $i++) {
	return 0 if $a[$i] < $b[$i];
	return 1 if $a[$i] > $b[$i];
    }
    return 1;
}
