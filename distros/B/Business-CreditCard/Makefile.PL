use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Business::CreditCard',
    'VERSION_FROM' => 'CreditCard.pm', # finds $VERSION
    'LICENSE'      => 'perl',
    'PREREQ_PM'       => {
        'Test::More' => 0,
    }
);
