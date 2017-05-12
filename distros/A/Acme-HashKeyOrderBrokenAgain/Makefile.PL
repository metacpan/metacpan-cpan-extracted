######################################################################
# Makefile.PL for Acme::HashKeyOrderBrokenAgain
# 2014, Mike Schilli <m@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 
              'http://github.com/mschilli/acme-hashkeyorderbrokenagain-perl',
        },
    }
};

WriteMakefile(
    'NAME'         => 'Acme::HashKeyOrderBrokenAgain',
    'VERSION_FROM' => 'lib/Acme/HashKeyOrderBrokenAgain.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Test::Simple => 0.31,
    }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Acme/HashKeyOrderBrokenAgain.pm',
       AUTHOR     => 'Mike Schilli <m@perlmeister.com>') : ()),
);
