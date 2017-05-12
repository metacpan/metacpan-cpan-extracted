######################################################################
# Makefile.PL for Archive::Tar::Wrapper
# 2005, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
          repository  => 'http://github.com/mschilli/archive-tar-wrapper-perl',
        },
    }
};

WriteMakefile(
    'NAME'         => 'Archive::Tar::Wrapper',
    'VERSION_FROM' => 'lib/Archive/Tar/Wrapper.pm', # finds $VERSION
    'PREREQ_PM'    => {
        File::Temp    => 0,
        Cwd           => 0,
        Log::Log4perl => 0,
        IPC::Run      => 0,
        File::Which   => 0,
                      }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Archive/Tar/Wrapper.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
