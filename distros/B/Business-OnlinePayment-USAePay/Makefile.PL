use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Business::OnlinePayment::USAePay',
    'VERSION_FROM' => 'USAePay.pm', # finds $VERSION
    'AUTHOR'       => 'Jeff Finucane <jeff@cmh.net>',
    'PREREQ_PM'    => { 
                        'Business::OnlinePayment' => 3,
                        'Business::OnlinePayment::HTTPS' => 0.04,
                        'Business::CreditCard' => 0.27,
                      },
);
