use ExtUtils::MakeMaker;

my $ABSTRACT = "Develope the wrong way";
my $VERSION = 0.1;

WriteMakefile(
 	'NAME'		=> 'Acme::WalkMethods',
	'ABSTRACT'	=> $ABSTRACT,
	'AUTHOR'	=> 'Leo Lapworth',
	'VERSION'	=> $VERSION, # finds $VERSION
	'PREREQ_PM'		=> {
		Test::More	=> 0,
    }, 
);
