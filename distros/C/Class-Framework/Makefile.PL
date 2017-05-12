use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=>'Class::Framework',
	VERSION_FROM	=>'lib/Class/Framework.pm',
	ABSTRACT_FROM	=>'lib/Class/Framework.pm',
	AUTHOR		=>'Timothy Hinchcliffe',
	PREREQ_PM	=>{
		"NEXT"=>0,
		"Class::Accessor"=>0,
		"fields"=>0,
	},
);
