######################################################################
# Makefile.PL for Cache::Historical
# 2007, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/cache-historical-perl',
        },
    }
};

WriteMakefile(
    'NAME'         => 'Cache::Historical',
    'VERSION_FROM' => 'Historical.pm', # finds $VERSION
    'PREREQ_PM'    => {
                        DBD::SQLite              => 1.14,
                        DBI                      => 0,
                        Rose::DB                 => 0.735,
                        Rose::DB::Object::Loader => 0.764,
                        Log::Log4perl            => 1,
                      }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Historical.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
