use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'CGI::Untaint::creditcard',
	AUTHOR        => 'Tony Bowden <tmtm@cpan.org>',
	VERSION_FROM  => 'lib/CGI/Untaint/creditcard.pm',
	ABSTRACT_FROM => 'lib/CGI/Untaint/creditcard.pm',
	PREREQ_PM     => {
		'CGI::Untaint'                 => 0.01,
		'Business::CreditCard::Object' => 0,
		'Test::More'                   => 0.10,
	},
);
