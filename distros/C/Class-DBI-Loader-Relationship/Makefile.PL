use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::DBI::Loader::Relationship',
    'VERSION_FROM'	=> 'Relationship.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        Class::DBI::Loader => 0,
        Lingua::EN::Inflect::Number => 1,
    }, # e.g., Module::Name => 1.1
);
