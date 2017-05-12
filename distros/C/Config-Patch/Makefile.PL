######################################################################
# Makefile.PL for Config::Patch
# 2005, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/config-patch-perl',
        },
    }
};

WriteMakefile(
    'NAME'         => 'Config::Patch',
    'VERSION_FROM' => 'lib/Config/Patch.pm', # finds $VERSION
    'EXE_FILES'    => ['eg/config-patch'],
    'PREREQ_PM'    => { Pod::Usage    => 0,
                        MIME::Base64  => 0,
                        Set::IntSpan  => 0,
                        Log::Log4perl => 0,
                      }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Config/Patch.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
