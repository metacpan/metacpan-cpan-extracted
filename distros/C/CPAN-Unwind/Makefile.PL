######################################################################
# Makefile.PL for CPAN::Unwind
# 2005, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/cpan-unwind-perl',
        },
    }
};

WriteMakefile(
    'NAME'         => 'CPAN::Unwind',
    'VERSION_FROM' => 'lib/CPAN/Unwind.pm', # finds $VERSION
    'EXE_FILES'         => [ qw(eg/cpan-unwind eg/cpan-download) ],
    'PREREQ_PM'    => {
        CPAN                           => 0,
        File::Temp                     => 0,
        Pod::Usage                     => 0,
        Log::Log4perl                  => 0,
        Data::Dumper                   => 0,
        LWP::Simple                    => 0,
        Module::Depends::Intrusive     => 0,
        Archive::Tar                   => 0,
        Storable                       => 0,
        Cache::FileCache               => 0,
        Cache::Cache                   => 0,
        Algorithm::Dependency::Ordered => 0,
    }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/CPAN/Unwind.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
