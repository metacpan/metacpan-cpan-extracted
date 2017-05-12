use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'AxKit::XSP::Sendmail',
    'VERSION_FROM' => 'Sendmail.pm', # finds $VERSION
    'PREREQ_PM' => { AxKit => 1.4,
                     Mail::Sendmail => 0,
                     Email::Valid => 0,
                   },
);
