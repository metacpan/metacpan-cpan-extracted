use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Attribute::Deprecated',
    'VERSION_FROM'	=> 'Deprecated.pm',
    'PREREQ_PM'		=> {'Attribute::Handlers' => '0.70', },
);
