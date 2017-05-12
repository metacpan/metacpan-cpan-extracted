use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	(MM->can('signature_target') ? (SIGN => 1) : () ), # sign it at make dist time
    NAME         => 'CGI::NoPoison',
    VERSION_FROM => 'lib/CGI/NoPoison.pm', # finds $VERSION
    AUTHOR       => 'Scott R. Godin (nospam@webdragon.net)',
    ABSTRACT_FROM	=> 'lib/CGI/NoPoison.pm',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
					 'CGI'			=> 3.10,
                    },
);
