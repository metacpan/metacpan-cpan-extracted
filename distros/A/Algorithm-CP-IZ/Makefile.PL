use strict;

use 5.009000; # need Newx in XS
use ExtUtils::MakeMaker;

use Getopt::Std;
use File::Spec;
use Config;

my $DEFAULT_IZ_LIB_DIR = "../izC/lib";
my $DEFAULT_IZ_INC_DIR = "../izC/include";

our $opt_L = $ENV{IZ_LIB_DIR} || $DEFAULT_IZ_LIB_DIR;
our $opt_I = $ENV{IZ_INC_DIR} || $DEFAULT_IZ_INC_DIR;

getopts('L:I:');

#
# determine paths
#

sub get_izlib_name {
    my $ext = $Config{'so'};
    if ($ext =~ /^dll$/i) { # windows?
	return "iz.$ext";
    }

    return "libiz.$ext";
}

sub show_how_to_path_set {
    print "*** iZ-C not found. ***\n";
    my $libname = get_izlib_name;

    print "iz.h and $libname are needed to build this module.\n";
    print "Specify -I<dir> and -L<dir> correctly.\n";
    exit 2;
}

sub get_iz_lib_dir {
    my @dirs = ($opt_L,
		'/usr/local/lib', '/usr/lib',
		"$ENV{HOME}/lib",
		"$ENV{HOME}/izC", "$ENV{HOME}/izC/lib");

    my $libname = get_izlib_name;

    for my $d (@dirs) {
	my $libiz = File::Spec->catfile($d, $libname);
	if (length($d) > 0 && -d $d && -f $libiz) {
	    print "library: $libiz\n";
	    return $d;
	}
    }

    show_how_to_path_set;
}

sub get_iz_inc_dir {
    my @dirs = ($opt_I,
		'/usr/local/include', '/usr/include',
		"$ENV{HOME}/include",
		"$ENV{HOME}/izC", "$ENV{HOME}/izC/include");

    for my $d (@dirs) {
	my $izh = File::Spec->catfile($d, "iz.h");
	if (length($d) > 0 && -d $d && -f $izh) {
	    print "header: $izh\n";
	    return $d;
	}
    }

    show_how_to_path_set;
}

my $iz_lib_dir = get_iz_lib_dir;
my $iz_inc_dir = get_iz_inc_dir;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Algorithm::CP::IZ',
    VERSION_FROM      => 'lib/Algorithm/CP/IZ.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => { UNIVERSAL => 0, "Scalar::Util" => 0,}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Algorithm/CP/IZ.pm', # retrieve abstract from module
    AUTHOR            => 'Toshimitsu FUJIWARA <tttfjw at gmail.com>',
    LICENSE           => 'artistic_2',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    LIBS              => ["-L$iz_lib_dir -liz"], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-I$iz_inc_dir", # e.g., '-I. -I/usr/include/other'
    # Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    clean             => {FILES => "cs_reif2.inc cs_vadd.inc cs_vmul.inc cs_vsub.inc"},
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (
      qw(
CS_ERR_NONE
CS_ERR_GETVALUE
CS_ERR_OVERFLOW
CS_ERR_NO_MEMORY
CS_VALUE_SELECTOR_MIN_TO_MAX
CS_VALUE_SELECTOR_MAX_TO_MIN
CS_VALUE_SELECTOR_LOWER_AND_UPPER
CS_VALUE_SELECTOR_UPPER_AND_LOWER
CS_VALUE_SELECTOR_MEDIAN_AND_REST
CS_VALUE_SELECTION_EQ
CS_VALUE_SELECTION_NEQ
CS_VALUE_SELECTION_LE
CS_VALUE_SELECTION_LT
CS_VALUE_SELECTION_GE
CS_VALUE_SELECTION_GT
IZ_VERSION_MAJOR
IZ_VERSION_MINOR
IZ_VERSION_PATCH
      ));

  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Algorithm::CP::IZ',
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

# VAdd
unless (-f "cs_vadd.inc") {
    open (my $fh, ">", "cs_vadd.inc") or die "cs_vadd.inc: cannot create: $!";

    for my $i (3..10) {
	print $fh "void*\n";
	print $fh "cs_VAdd$i(";

	print $fh join(", ", map { "vint$_" } (1..$i));

	print $fh ")\n";

	print $fh map { "    void* vint$_\n" } (1..$i);

	print $fh "CODE:\n";
	print $fh "    RETVAL = cs_VAdd($i, ";
	print $fh join(", ", map { "vint$_" } (1..$i));
	print $fh ");\n";
	print $fh "OUTPUT:\n";
	print $fh "    RETVAL\n\n";
    }
    close($fh);
}

# VMul
unless (-f "cs_vmul.inc") {
    open (my $fh, ">", "cs_vmul.inc") or die "cs_vmul.inc: cannot create: $!";

    for my $i (3..10) {
	print $fh "void*\n";
	print $fh "cs_VMul$i(";

	print $fh join(", ", map { "vint$_" } (1..$i));

	print $fh ")\n";

	print $fh map { "    void* vint$_\n" } (1..$i);

	print $fh "CODE:\n";
	print $fh "    RETVAL = cs_VMul($i, ";
	print $fh join(", ", map { "vint$_" } (1..$i));
	print $fh ");\n";
	print $fh "OUTPUT:\n";
	print $fh "    RETVAL\n\n";
    }
    close($fh);
}

# VSub
unless (-f "cs_vsub.inc") {
    open (my $fh, ">", "cs_vsub.inc") or die "cs_vsub.inc: cannot create: $!";

    for my $i (3..10) {
	print $fh "void*\n";
	print $fh "cs_VSub$i(";

	print $fh join(", ", map { "vint$_" } (1..$i));

	print $fh ")\n";

	print $fh map { "    void* vint$_\n" } (1..$i);

	print $fh "CODE:\n";
	print $fh "    RETVAL = cs_VSub($i, ";
	print $fh join(", ", map { "vint$_" } (1..$i));
	print $fh ");\n";
	print $fh "OUTPUT:\n";
	print $fh "    RETVAL\n\n";
    }
    close($fh);
}

# Reif*
unless (-f "cs_reif2.inc") {
    open (my $fh, ">", "cs_reif2.inc") or die "cs_reif2.inc: cannot create: $!";

    my @names = qw(Eq Neq Lt Le Gt Ge);

    for my $name (@names) {
	print $fh "void*\n";
	print $fh "cs_Reif$name(vint1, vint2)\n";
	print $fh "    void* vint1\n";
	print $fh "    void* vint2\n";
	print $fh "CODE:\n";
	print $fh "    RETVAL = cs_Reif$name(vint1, vint2);\n";
	print $fh "OUTPUT:\n";
	print $fh "    RETVAL\n\n";
    }

    my @names2 = map { uc $_ } @names;

    for my $name (@names2) {
	print $fh "void*\n";
	print $fh "cs_Reif$name(vint, val)\n";
	print $fh "    void* vint\n";
	print $fh "    int val\n";
	print $fh "CODE:\n";
	print $fh "    RETVAL = cs_Reif$name(vint, val);\n";
	print $fh "OUTPUT:\n";
	print $fh "    RETVAL\n\n";
    }

    close($fh);
}
