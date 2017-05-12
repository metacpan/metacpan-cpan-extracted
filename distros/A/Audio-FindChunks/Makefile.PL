use 5.00503;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

$define = '';
$define .= ' -DNATIVE_LE_SHORTS'	# s! was introduced on v5.6
 if pack('v', 0x0102) eq (eval {pack 's!', 0x0102} or pack 's', 0x0102);

WriteMakefile(
    NAME              => 'Audio::FindChunks',
    VERSION_FROM      => 'FindChunks.pm', # finds $VERSION
    PREREQ_PM         => {Data::Flow => 0.09,
			  # Perl => 5.00503, # Does not work...
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'FindChunks.pm', # retrieve abstract from module
       AUTHOR         => 'Ilya Zakharevich <cpan@ilyaz.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => $define, # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES)', # link all the C files too
    clean             => {FILES => '*.tmp tmp.*'},
);
