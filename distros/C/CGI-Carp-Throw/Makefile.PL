use 5.006002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::Carp::Throw',
    VERSION_FROM      => 'lib/CGI/Carp/Throw.pm', # finds $VERSION
    PREREQ_PM         => {
        CGI::Carp   =>  1,
        Exporter    =>  1,
        Test::More  =>  0.3,
        FileHandle  =>  1,
        File::Spec  =>  0.7,
        IPC::Open3  =>  1
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CGI/Carp/Throw.pm', # retrieve abstract from module
       AUTHOR         => 'Ronald Schmidt <ronaldxs@software-path.com>') : ()),
);
