use 5.005;
use ExtUtils::MakeMaker;
# perldoc ExtUtils::MakeMaker for understanding this file

die "OS unsupported\n",
    "This module will only compile in the BS2000 Posix subsystem!!!\n"
    if $^O ne 'posix-bc' and not (defined $ARGV[0] and $ARGV[0] eq '--force');

# We need a special include lms_assert.h to make sure that the
# constants defined in LMS.pm are the same #define'd in the system
# include lms.h.  We generate this include from our constants in
# LMS.pm and let the C compiler compare them to the values of the
# system include.  If they are different, a compiler #error will
# occur:
$lms_assert = ('perl -n -e '."'".
	       'next unless /^use constant (LMSUP_[A-Z]+) => ([^;]+);/; '.
	       'print "'.
	       '#if $$1 != $$2\n'.
	       '#error \"assertion failed: $$1 != $$2\"\n'.
	       '#endif\n'.
	       '";'."'".' <$^ >$@');

WriteMakefile(
    'NAME'		=> 'BS2000::LMS',
    'VERSION_FROM'	=> 'lib/BS2000/LMS.pm', # finds $VERSION
    'PREREQ_PM'		=> {},
    ($] >= 5.006 ?
      (ABSTRACT_FROM => 'lib/BS2000/LMS.pm', # retrieve abstract from module
       AUTHOR     => 'Thomas Dorner <dorner (AT) pause.org>') : ()),
    # '-l BLSLIB' can not be used here as this is not a library file:
    'LIBS'		=> [''],
    # We must link our static perl executable with the LMS library in
    # native BS2000.  The only way to do this is to get the Posix
    # BINDER to access this PLAM library using '-l BLSLIB' and the
    # environment variable "export BLSLIB00=\$.SYSLNK.LMS.version", so
    # we must set this before starting make (you have read the README?):
    'LDFLAGS'		=> '-l BLSLIB',
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '-I.',
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
    clean => { FILES => 'lms_asserts.h' },
    depend => { 'LMS.o' => 'lms_asserts.h',
		'lms_asserts.h' => "lib/BS2000/LMS.pm\n\t$lms_assert" },
);
