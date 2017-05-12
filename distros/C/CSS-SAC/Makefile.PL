use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'CSS::SAC',
    'VERSION_FROM'  => 'SAC.pm',
    'PREREQ_PM'     => {
                        Text::Balanced      => '1.84',
                        Class::ArrayObjects => '0.04',
                       },

    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'SAC.pm', # retrieve abstract from module
       AUTHOR         => 'Robin Berjon') : ()),

    LICENSE           => 'perl',
    'dist'            => {
      PREOP     => 'chmod 600 Makefile.PL',
      TARFLAGS	=> '--group=cpan --owner=bjoern -cvf',
    },

);
