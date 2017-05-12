use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'DateTime::Calendar::Hebrew',
    'VERSION_FROM'	=> 'Hebrew.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'DateTime::TimeZone::Floating' => '0',
		'DateTime'	=> '0',
		'DateTime::Event::Sunrise'	=> '0',
		'DateTime::Duration'	=> '0',
	},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Hebrew.pm', # retrieve abstract from module
       AUTHOR     => 'Steven J. Weinberger <perl@psycomp.com>') : ()),
);
