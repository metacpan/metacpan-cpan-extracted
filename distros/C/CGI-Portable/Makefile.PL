use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME	=> 'CGI::Portable',
	VERSION => 0.51,
	PREREQ_PM => {
		'File::VirtualPath' => 1.011,
		'CGI::MultiValuedHash' => 1.09,
		'HTML::EasyTags' => 1.071,
		'HTML::FormTemplate' => 2.021,  # for Demo* modules only
		'Net::SMTP' => 1,  # I don't know what version; for Demo* only
		'Apache' => 1,  # I don't know what version; for AdapterCGI under mod_perl
		'IO::Socket' => 1,  # I don't know what version; for AdapterSocket
	},
);
