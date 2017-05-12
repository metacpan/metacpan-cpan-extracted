use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Data::Dumper::HTML',
    VERSION_FROM      => 'lib/Data/Dumper/HTML.pm', 
    PREREQ_PM         => {
        'version'      => 0,
        'Text::InHTML' => 0,
        'Data::Dumper' => 0,
    },
    ($] >= 5.005 ?    
      (ABSTRACT_FROM  => 'lib/Data/Dumper/HTML.pm',
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>') : ()),
);
