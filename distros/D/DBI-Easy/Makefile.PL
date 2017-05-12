use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "DBI::Easy",
	VERSION_FROM => "lib/DBI/Easy.pm",
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	AUTHOR => 'Ivan Baktsheev <dot.and.thing@gmail.com>',
	META_MERGE      => {
		resources => {
			license     =>      'http://dev.perl.org/licenses/',
			homepage    =>      'http://perlhug.com',
			bugtracker  =>      'http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBI-Easy',
			repository  =>      'git://web-app.git.sourceforge.net/gitroot/perl-easy/perl-easy',
#			MailingList =>      'makemaker@perl.org',
		},
	},
	PREREQ_PM => {
		'Class::Easy' => "0.17",
		'DBI'         => "1.611",
		'DBD::SQLite' => "1.25",
		'Time::Piece' => "1.20",
	}
);
