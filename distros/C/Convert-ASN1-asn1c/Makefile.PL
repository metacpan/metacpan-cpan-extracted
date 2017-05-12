use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Convert::ASN1::asn1c',
    VERSION_FROM      => 'lib/Convert/ASN1/asn1c.pm', # finds $VERSION
    PREREQ_PM         => {
		"Test::More" => 0,
		"Carp" => 0,
		"File::Slurp" => 0,
		"IPC::Run" => 0,
		"File::Which" => 0,
		"FindBin" => 0,
		"ExtUtils::MakeMaker" => 0,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Convert/ASN1/asn1c.pm', # retrieve abstract from module
       AUTHOR         => 'Timo Schneider <timos@informatik.tu-chemnitz.de>',
	   LICENSE => "perl") : ()),
);
