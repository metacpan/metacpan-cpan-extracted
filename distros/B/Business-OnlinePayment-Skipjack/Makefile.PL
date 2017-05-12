use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Business::OnlinePayment::Skipjack',
    'VERSION_FROM' => 'Skipjack.pm',
    'AUTHOR'       => 'See README',
    'PREREQ_PM'    => {
                       'Text::CSV_XS' => 0,
                       'Business::OnlinePayment' => 3
                      },
    'dist'         => {CI => 'ci -l'},
);
