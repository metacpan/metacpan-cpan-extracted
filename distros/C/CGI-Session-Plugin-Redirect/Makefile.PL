use ExtUtils::MakeMaker;

WriteMakefile(
	NAME            => 'CGI::Session::Plugin::Redirect',
	VERSION_FROM    => 'lib/CGI/Session/Plugin/Redirect.pm',
	PREREQ_PM       => {CGI::Session => 0},
);

