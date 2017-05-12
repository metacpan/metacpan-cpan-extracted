use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Class::DBI::ConceptSearch',
    VERSION_FROM      => 'lib/Class/DBI/ConceptSearch.pm',
    PREREQ_PM         => {
                           Class::DBI => 0.94,
                           XML::XPath => 1.13,
                         },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Class/DBI/ConceptSearch.pm',
       AUTHOR         => 'Allen Day <allenday@ucla.edu>') : ()),
);
