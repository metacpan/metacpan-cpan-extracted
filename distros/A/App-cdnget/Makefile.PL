use strict;
use warnings;
use ExtUtils::MakeMaker;


WriteMakefile(
	NAME				=> 'App::cdnget',
	VERSION_FROM		=> 'lib/App/cdnget.pm',
	MIN_PERL_VERSION	=> '5.014',
	PREREQ_PM			=> {
		'threads'		=> '1.72',
		'threads::shared' => '1.28',
		'forks'			=> '0.29',
		'SUPER'			=> '1.16',
		'Thread::Semaphore'	=> '2.13',
		'Time::HiRes'	=> '1.9740',
		'DateTime'		=> '1.42',
		'FCGI'			=> '0.78',
		'Digest::MD5'	=> '2.55',
		'LWP::UserAgent' => '6.15',
		'GD'			=> '2.56',
		'CSS::Minifier::XS'	=> '0.09',
		'JavaScript::Minifier::XS' => '0.11',
		'Lazy::Utils'	=> '1.08',
		'Object::Base'	=> '1.11',
	},
	EXE_FILES			=> [qw(
	)],
	AUTHOR				=> 'Orkun Karaduman <orkunkaraduman@gmail.com>',
	ABSTRACT			=> 'CDN Reverse Proxy',
	LICENSE				=> 'gpl_3',
	META_MERGE			=> {
		'meta-spec'		=> {
			version		=> 2,
		},
		resources => {
			homepage	=> 'https://metacpan.org/release/App-cdnget',
			license		=> 'https://www.gnu.org/licenses/gpl-3.0.html',
			repository	=> {
				type	=> 'git',
				url		=> 'git://git@github.com:orkunkaraduman/p5-cdnget.git',
				web		=> 'https://github.com/orkunkaraduman/p5-cdnget',
			},
			bugtracker	=> {
				web		=> 'https://github.com/orkunkaraduman/p5-cdnget/issues',
				mailto	=> 'bug-App-cdnget@rt.cpan.org',
			},
		},
	},
);
