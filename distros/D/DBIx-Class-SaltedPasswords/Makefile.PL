use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::Class::SaltedPasswords',
    VERSION_FROM      => 'lib/DBIx/Class/SaltedPasswords.pm', # finds $VERSION
    PREREQ_PM         => {DBIx::Class => 0.07003, Digest::MD5 => 2.36}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBIx/Class/SaltedPasswords.pm', # retrieve abstract from module
       AUTHOR         => 'Moritz Onken <onken@houseofdesign.de>') : ()),
);
