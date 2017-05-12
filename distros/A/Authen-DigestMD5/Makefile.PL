use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Authen::DigestMD5',
	       VERSION_FROM => 'DigestMD5.pm',
	       PREREQ_PM => {},
	       ABSTRACT_FROM => 'DigestMD5.pm',
	       AUTHOR => 'Salvador Fandiño <sfandino@yahoo.com>' );
