use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Crypt::YAPassGen',
    VERSION_FROM      => 'lib/Crypt/YAPassGen.pm', # finds $VERSION
    PREREQ_PM         => {
        Config                      =>  0,
        'Class::Data::Inheritable'  =>  0,
        'File::Spec'                =>  0,
        Storable                    =>  0,
        'Test::More'                =>  0,
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Crypt/YAPassGen.pm', # retrieve abstract from module
       AUTHOR         => 'Giulio Motta <GIULIENK@CPAN.ORG>') : ()),
);
