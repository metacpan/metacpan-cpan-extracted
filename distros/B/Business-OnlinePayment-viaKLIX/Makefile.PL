use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Business::OnlinePayment::viaKLIX',
    'VERSION_FROM' => 'viaKLIX.pm', # finds $VERSION
    'AUTHOR'       => 'Jeff Finucane <jeff@cmh.net>',
    'PREREQ_PM'    => { 
                        'Business::OnlinePayment' => 3.00_06,
                        'Business::OnlinePayment::HTTPS' => 0.04,
                      },
);
