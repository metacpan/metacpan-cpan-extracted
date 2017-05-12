use 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker;

use constant MIN_APACHE_TEST_VERSION => 1.13;

use constant HAVE_APACHE_TEST => eval {
	require Apache::Test;
	Apache::Test->VERSION(MIN_APACHE_TEST_VERSION);
	1;
};

if (HAVE_APACHE_TEST) {
	require Apache::TestMM;
	Apache::TestMM->import(qw(test clean));

	Apache::TestMM::filter_args();
	Apache::TestMM::generate_script('t/TEST');
} else {
	package MY;
	no warnings 'once';
	*test = sub {
		my $rule = $_[0]->SUPER::test;
		$rule =~ s/^(test\s*::?)(\s*)/$1 apache_test_warning$2/m;
		return $rule;
	};
}

sub MY::postamble {
	return <<"EOF";

apache_test_warning :
	\@echo
	\@echo \\*** Skipping Apache tests, which require Apache::Test \\(@{[ MIN_APACHE_TEST_VERSION ]} or later\\).
	\@echo \\*** If you want to run these tests, install Apache::Test and
	\@echo \\*** run \\"perl Makefile.PL\\" again.
	\@echo
EOF
}

WriteMakefile(
    NAME              => 'Apache::Request::I18N',
    VERSION_FROM      => 'I18N.pm',
    PREREQ_PM         => {
    				'Apache::Test'		=> MIN_APACHE_TEST_VERSION,
				# libapreq
    				'Apache::Request'	=> 0.32,
				# mod_perl 1.x
    				'Apache::Constants'	=> 0,
    				'Apache::Table'		=> 0,
				# libwww-perl
				'HTTP::Headers::Util'	=> 0,
				'HTTP::Request'		=> 0,
    			},
    clean             => { FILES => 't/TEST' },
    test              => { TESTS => HAVE_APACHE_TEST ? '' : 't/00_load.t' },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'I18N.pm',
       AUTHOR         => 'Frédéric Brière <fbriere@fbriere.net>') : ()),
);
