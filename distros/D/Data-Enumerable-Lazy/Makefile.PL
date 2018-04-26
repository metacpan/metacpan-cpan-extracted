use 5.018002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::Enumerable::Lazy',
    VERSION_FROM      => 'lib/Data/Enumerable/Lazy.pm', # finds $VERSION
    LICENSE           => 'perl_5',
    PREREQ_PM         => {
      'Test::More'      => '0',
      'Test::Exception'	=> '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/Enumerable/Lazy.pm', # retrieve abstract from module
       AUTHOR         => 'Oleg S <me@whitebox.io>') : ()),
    META_MERGE        => {
      'meta-spec'     => { version => 2 }, 
      resources       => {
        homepage      => 'https://github.com/icanhazbroccoli/Data-Enumerable-Lazy',
        bugtracker    => 'https://github.com/icanhazbroccoli/Data-Enumerable-Lazy/issues',
        repository    => {
          type => 'git',
          url  => 'https://github.com/icanhazbroccoli/Data-Enumerable-Lazy.git',
          web  => 'https://github.com/icanhazbroccoli/Data-Enumerable-Lazy',
        },
      },
    },
);
