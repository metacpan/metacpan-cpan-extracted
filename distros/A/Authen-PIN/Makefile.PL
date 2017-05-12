use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Authen::PIN',
    'VERSION_FROM' => 'PIN.pm', # finds $VERSION
	      'PREREQ_PM' => {
		  'Business::CreditCard' => 0,
		  'Digest::MD5' => 0,
		  'Number::Encode' => 0,
	      },
);
