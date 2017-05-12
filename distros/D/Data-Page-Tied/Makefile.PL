use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Data::Page::Tied',
    'VERSION_FROM'	=> 'lib/Data/Page/Tied.pm', # finds $VERSION
    'LICENSE' => 'perl',
    'PREREQ_PM'		=> { 'Test::More' => '0',
                             'Data::Page' => '2.00', },
                             # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Data/Page/Tied.pm', # retrieve abstract from module
       AUTHOR     => 'Steffen Mueller <smueller@cpan.org>') : ()),
);

