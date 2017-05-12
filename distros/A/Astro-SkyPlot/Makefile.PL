use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Astro::SkyPlot',
    VERSION_FROM      => 'lib/Astro/SkyPlot.pm', # finds $VERSION
    PREREQ_PM         => {
      'Astro::MapProjection' => '0.01',
      'PostScript::Simple' => '0.07',
      'Class::XSAccessor' => '1.05',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Astro/SkyPlot.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
    #LIBS              => [''], # e.g., '-lm'
    #DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    #INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
