use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Acme::Web20::Validator',
    VERSION_FROM      => 'lib/Acme/Web20/Validator.pm',
    PREREQ_PM         => {
        'Class::Data::Inheritable' => 0.01,
        'Class::Accessor' => 0.01,
        'LWP::UserAgent'  => 0.01,
        'Feed::Find'      => 0.01,
        'Module::Pluggable' => 0.01,
        'Text::ASCIITable' => 0.01,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Acme/Web20/Validator.pm', # retrieve abstract from module
       AUTHOR         => 'Naoya Ito <naoya@bloghackers.net>') : ()),
);
