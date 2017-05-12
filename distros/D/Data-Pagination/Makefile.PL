
# Data::Pagination Makefile maker

use 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Data::Pagination',
    VERSION_FROM => 'lib/Data/Pagination.pm',
    ABSTRACT_FROM => 'lib/Data/Pagination.pm',
    AUTHOR => 'Andrian Zubko <ondr@mail.ru>'
);
