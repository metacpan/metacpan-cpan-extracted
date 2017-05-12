use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Atom-JavaScript',
    'DISTNAME'		=> 'Atom-JavaScript',
    'ABSTRACT'		=> 'Extension to XML::Atom for JavaScript output.',
    'VERSION_FROM'	=> 'lib/XML/Atom/Feed/JavaScript.pm', 
    'PMLIBDIRS'		=> [ qw( lib/ ) ],
    'AUTHOR'		=> 'David Jacobs <globaldj@mac.com>',
    'PREREQ_PM'		=> { 
			    'XML::Atom'		=> 0.08,
			    'DateTime'		=> 0,
			    }
);
