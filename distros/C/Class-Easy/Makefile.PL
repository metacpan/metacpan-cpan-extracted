use 5.008006;
use ExtUtils::MakeMaker 6.48;

WriteMakefile(
	NAME => "Class::Easy",
	VERSION_FROM => "lib/Class/Easy.pm",
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	AUTHOR => 'Ivan Baktsheev <dot.and.thing@gmail.com>',
	MIN_PERL_VERSION => '5.8.6', # mac os x 10.4.11 at least, i don't want any older shit
	META_MERGE      => {
		resources => {
			license     =>      'http://dev.perl.org/licenses/',
			homepage    =>      'http://perlhug.com',
			bugtracker  =>      'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Easy',
			repository  =>      'git://web-app.git.sourceforge.net/gitroot/perl-easy/perl-easy',
#			MailingList =>      'makemaker@perl.org',
		},
	},
	PREREQ_PM => {
		'Time::HiRes'   => 0,
	},
	PL_FILES => {'Import.pm.PL' => '$(INST_LIB)/Class/Easy/Import.pm'},
	clean    => {FILES => '$(INST_LIB)/Class/Easy/Import.pm'},
	CONFIGURE_REQUIRES => {
		# this cannot be changed because of availability MIN_PERL_VERSION and OS X fixes
		'ExtUtils::MakeMaker' => '6.48',
	}
);
