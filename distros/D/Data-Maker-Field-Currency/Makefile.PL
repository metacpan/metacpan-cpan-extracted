use ExtUtils::MakeMaker;

WriteMakefile( 
        'VERSION'   => 0.23,
        'NAME'      => 'Data::Maker::Field::Currency',
        'PREREQ_PM' => {
          'Data::Maker' => 0.23,
          'Data::Money' => 0,
        }
);
