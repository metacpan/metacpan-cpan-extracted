use 5.00;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> 'Authen::PhoneChallenge',
	VERSION_FROM	=> 'lib/Authen/PhoneChallenge.pm',
	($] >= 5.005 ?
		(
		AUTHOR => 'Scott Peshak <speshak@randomscrews.net>') : ()),
);
