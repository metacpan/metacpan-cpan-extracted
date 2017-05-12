use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Class::Accessor::Fast::XS',
    AUTHOR            => 'Ruslan U. Zakirov <Ruslan.Zakirov@gmail.com>',
    VERSION_FROM      => 'lib/Class/Accessor/Fast/XS.pm',
    ABSTRACT_FROM     => 'lib/Class/Accessor/Fast/XS.pm',
    LICENSE           => 'perl',
    PREREQ_PM         => {
        'Class::Accessor::Fast' => '0',
    },
);

