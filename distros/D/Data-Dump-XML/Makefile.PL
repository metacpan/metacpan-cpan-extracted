use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "Data::Dump::XML",
	VERSION_FROM => "lib/Data/Dump/XML.pm",
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	AUTHOR => 'Ivan Baktsheev <dot.and.thing@gmail.com>',
	PREREQ_PM => {
		'Class::Easy'  => 0.16, # try_to_use support
		'XML::LibXML'  => 1.60,
		'IO::Easy'     => 0.01,
	},
	XS => {
		'XML.xs' => 'XML.c',
		'Parser.xs' => 'Parser.c',
	}
);
