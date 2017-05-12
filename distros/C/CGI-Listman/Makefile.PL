use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'CGI::Listman',
    'VERSION_FROM'	=> 'Listman.pm', # finds $VERSION
    'dist'		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    'PREREQ_PM'		=> { 'Text::CSV_XS' => '0.22',
			     'DBI' => '1.00'},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Listman.pm',
       AUTHOR     => 'Wolfgang Sourdeau <Wolfgang@Contre.COM>') : ()),
);

