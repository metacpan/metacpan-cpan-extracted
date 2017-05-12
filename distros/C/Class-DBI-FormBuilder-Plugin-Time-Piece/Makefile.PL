use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::DBI::FormBuilder::Plugin::Time::Piece',
    VERSION_FROM      => 'lib/Class/DBI/FormBuilder/Plugin/Time/Piece.pm', # finds $VERSION
    PREREQ_PM         => { Class::DBI::FormBuilder => 0.32 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Class/DBI/FormBuilder/Plugin/Time/Piece.pm', # retrieve abstract from module
       AUTHOR         => 'James Tolley <james@bitperfect.com>') : ()),
);
