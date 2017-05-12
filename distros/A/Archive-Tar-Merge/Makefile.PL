######################################################################
# Makefile.PL for Archive::Tar::Merge
# 2007, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Archive::Tar::Merge',
    'VERSION_FROM' => 'Merge.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Archive::Tar::Wrapper => 0.10,
        Sysadm::Install       => 0.24,
        File::Temp            => 0,
        Digest::MD5           => 0,
        Test::More            => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Merge.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
