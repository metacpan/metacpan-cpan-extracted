use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::View::REST::Data::Serializer',
    AUTHOR    => 'Adam Jacob (adam@stalecoffee.org)',
    PREREQ_PM => {
        Catalyst           => '2.99',
        'Data::Serializer' => 0,
    },
    VERSION_FROM => 'Serializer.pm'
);
