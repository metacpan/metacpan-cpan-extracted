use ExtUtils::MakeMaker;

WriteMakefile
        (
        'NAME'      => 'Bundle::WWW::Mechanize::Shell',
        'ABSTRACT'  => 'install all optional modules for WWW::Mechanize::Shell',
        'VERSION_FROM'   => 'lib/Bundle/WWW/Mechanize/Shell.pm',
 		'PREREQ_PM' => {
 			'Test::More'            => 0,
 			},
);

