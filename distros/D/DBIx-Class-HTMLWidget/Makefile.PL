use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'DBIx::Class::HTMLWidget',
    'VERSION_FROM' => 'lib/DBIx/Class/HTMLWidget.pm',
    'PREREQ_PM'    => {
        HTML::Widget        => '1.10',
        DBIx::Class         => 0.05,
    },
);
