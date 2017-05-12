use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'AxKit::XSP::Wiki',
    'VERSION_FROM' => 'lib/AxKit/XSP/Wiki.pm',
    'PREREQ_PM' => { 
    		AxKit => 1.52, 
		DBD::SQLite => 0, 
		Pod::SAX => 0.04,
		Text::WikiFormat::SAX => 0,
                XML::SAX::Writer => 0,
                XML::LibXML => 1.52,
		},
    'ABSTRACT_FROM' => 'lib/AxKit/XSP/Wiki.pm',
    'AUTHOR' => 'Matt Sergeant <matt@sergeant.org>',
);
