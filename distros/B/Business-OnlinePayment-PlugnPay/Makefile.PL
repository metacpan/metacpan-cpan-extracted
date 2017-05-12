use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Business::OnlinePayment::PlugnPay',
    'VERSION_FROM' => 'PlugnPay.pm', # finds $VERSION
    'AUTHOR'       => 'Jeff Finucane <jeff@cmh.net>',
    'PREREQ_PM'    => { 
                        'Business::OnlinePayment' => 3,
                        'Business::OnlinePayment::HTTPS' => 0.04,
                      },
);
