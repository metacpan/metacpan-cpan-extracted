use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Business::OnlinePayment::Cardcom',
    'VERSION_FROM' => 'Cardcom.pm', # finds $VERSION
    'AUTHOR'       => 'Erik Levinson <levinse@freeside.biz>',
    'PREREQ_PM'    => {
                        'Business::OnlinePayment' => 0,
                        'Tie::IxHash' => 0,
                        'Net::HTTPS::Any' => 0,
                      },
);

