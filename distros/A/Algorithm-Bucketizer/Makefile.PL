use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/algorithm-bucketizer-perl.git',
        },
    }
};

WriteMakefile(
    'NAME'		=> 'Algorithm::Bucketizer',
    'VERSION_FROM'	=> 'Bucketizer.pm', # finds $VERSION
    'EXE_FILES'         => [ qw(eg/bucketize) ],
    'PREREQ_PM'		=> {
        Sysadm::Install => 0.23,
        Getopt::Std     => 0,
        Pod::Usage      => 0,
    }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Bucketizer.pm', # retrieve abstract from module
       AUTHOR     => 'Mike <cpan@perlmeister.com>') : ()),
);
