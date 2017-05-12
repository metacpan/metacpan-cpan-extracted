
use ExtUtils::MakeMaker;


WriteMakefile(
    AUTHOR => 'Gordon Van Amburg',
    ABSTRACT => 'Development tools for CGI::Application::Structured',
    NAME         => 'CGI::Application::Structured::Tools',
    VERSION_FROM => 'lib/CGI/Application/Structured/Tools/Starter.pm',   # finds \$VERSION
    PREREQ_PM  => {
        'CGI::Application::Structured' => 0.006,
	'DBIx::Class::Schema::Loader' => 0,
	'ExtUtils::Command'           => 0,
	'File::Basename'              => 0,
	'File::Spec'                  => 0,
	'FindBin'                     => 0,
	'File::Slurp'                 => 0,
	'HTML::Template'              => 0,
	'Module::Signature'           => 0,
	'Test::WWW::Mechanize::CGIApp'=> 0,
	'Module::Starter'             => 1.50,
        'Module::Starter::Simple'     => 1.50,
	'Module::Starter::Plugin::Template' => 1.50,
	'Pod::Coverage'               => '0.18',
	'Pod::Usage'                  => 0,
	'Test::More'                  => 0,
	'Test::Pod'                   => '1.22',
	'Test::Pod::Coverage'         => '1.08',
        'Probe::Perl'                 => 0,
    },
    INSTALLDIRS => 'site',
    PL_FILES    => {},
    EXE_FILES => ['scripts/cas-starter.pl'],
    LICENSE => 'perl',
    );
