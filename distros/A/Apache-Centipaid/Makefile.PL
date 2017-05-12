use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'ABSTRACT' => 'Micropayment module with interface to centipaid.com payment gateway',
    'AUTHOR' => 'Adonis El Fakih (me@centipaid.com)',
    'NAME'	=> 'Apache::Centipaid',
    'PREREQ_PM' => {
	'Apache' => 1.02,
	'Apache::File' => 1.01,
	'IO::Socket' => 1.26,
	'Net::hostent' => 0,
	'DBI' => 1.21,
	'DBD::mysql' => 2.0419,
	'CGI::Cookie' => 1.21
	},
    'VERSION_FROM' => 'Centipaid.pm', # finds $VERSION
    dist => {
	SUFFIX => 'gz',
	COMPRESS => 'gzip -9',
    }
);
