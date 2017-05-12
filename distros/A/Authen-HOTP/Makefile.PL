use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Authen::HOTP',
    VERSION_FROM      => 'lib/Authen/HOTP.pm',
    PREREQ_PM         => {
	'Digest::SHA1' => 1,
	'Digest::HMAC' => 1,
	'Math::BigInt' => 1,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Authen/HOTP.pm',
       AUTHOR         => 'Iain Wade <iwade@optusnet.com.au>') : ()),
);
