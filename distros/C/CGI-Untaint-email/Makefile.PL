use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'CGI::Untaint::email',
    'VERSION_FROM' => 'lib/CGI/Untaint/email.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.18,
	CGI::Untaint => 0.07,
	Email::Valid => 0.13,
	Mail::Address => 1.40,
    },
);
