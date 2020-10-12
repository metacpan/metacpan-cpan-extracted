
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME             => 'Acme::Sub::Parms',
    VERSION_FROM     => 'lib/Acme/Sub/Parms.pm',
    MIN_PERL_VERSION => '5.006',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'  => 'mit', ) : ()),
    PREREQ_PM      => {
       'Carp'               => 0,
       'warnings'           => 0,
       'Filter::Util::Call' => '1.06',
    }, 
    META_MERGE => {
       'meta-spec' => { version => 2 },
        resources => {
           bugtracker => {
                web  => 'https://github.com/JerilynFranz/perl-Acme-Sub-Parms/issues',
            },
            homepage => 'https://github.com/JerilynFranz/perl-Acme-Sub-Parms',
            repository => {
                type => 'git',
                url  => 'https://github.com/JerilynFranz/perl-Acme-Sub-Parms.git',
                web  => 'https://github.com/JerilynFranz/perl-Acme-Sub-Parms',
            },
        },
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Acme/Sub/Parms.pod', # retrieve abstract from module
       AUTHOR         => 'Jerilyn Franz <cpan@jerilyn.info>') : ()),

       PL_FILES       => {},
);

