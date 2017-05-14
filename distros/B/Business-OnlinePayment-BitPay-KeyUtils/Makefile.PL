# File : Makefile.PL
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'    => 'Business::OnlinePayment::BitPay::KeyUtils',            # Name of package
	'AUTHOR'  => 'BitPay, Inc.',
	'VERSION' => '2.0.1',
	'LIBS'    => ['-lm -lssl -lcrypto'],         # Name of custom libraries
	'OBJECT'  => 'key_utils.o key_utils_wrap.o', # Object files
	'LICENSE' => 'MIT'
);
