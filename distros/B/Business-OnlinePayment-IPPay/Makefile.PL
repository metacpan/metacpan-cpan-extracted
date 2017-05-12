use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Business::OnlinePayment::IPPay',
    'VERSION_FROM' => 'IPPay.pm', # finds $VERSION
    'AUTHOR'       => 'Ivan Kohler <ivan-ippay@freeside.biz>',
    'PREREQ_PM'    => { 'Business::OnlinePayment' => 3,
                        'Business::OnlinePayment::HTTPS' => 0.09,
                        'Locale::Country'         => 2,
			'Test::More'              => 0.42,
                        'Tie::IxHash'             => 0,
                        'XML::Simple'             => 0,
                        'XML::Writer'             => 0,
                      },
);
