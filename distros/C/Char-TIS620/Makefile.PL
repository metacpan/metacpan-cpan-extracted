use strict;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'             => 'TIS620',
    'VERSION_FROM'     => 'TIS620.pm', # finds $VERSION
    ($] >= 5.005 ?                   # Add these new keywords supported since 5.005
      ('PREREQ_PM'     => {},        # e.g., Module::Name => 1.1
       'ABSTRACT_FROM' => 'TIS620.pm', # retrieve abstract from module
       'AUTHOR'        => 'ina <ina@cpan.org>',
       'test'          => { 'TESTS' => 't/*/*.t' },
      )
      :
      ()
    ),
);
__END__
