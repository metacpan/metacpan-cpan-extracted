use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Array::OrdHash',
    VERSION_FROM      => 'lib/Array/OrdHash.pm', # finds $VERSION
	 LICENSE				 => 'perl',
    PREREQ_PM         => {},
	 INSTALLDIRS 	=> 'site',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Array/OrdHash.pm', # retrieve abstract from module
       AUTHOR         => 'Vladimir Surin <brexs@yandex.ru>') : ()),
);
