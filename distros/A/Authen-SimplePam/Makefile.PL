use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'		=> 'Authen::SimplePam',
	      'VERSION_FROM'	=> 'SimplePam.pm', 
	      'PREREQ_PM'	=> { Authen::PAM => 0.13 },
	      'EXE_FILES'       => [qw( bin/auth_user.pl bin/change_password.pl bin/chngpwd )],
	      ($] >= 5.005 ?
	       (ABSTRACT_FROM => 'SimplePam.pm',
		AUTHOR     => 'Raul Dias  <raul@dias.com.br>') : ()),
);
