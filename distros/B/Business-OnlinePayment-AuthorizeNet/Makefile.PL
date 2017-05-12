use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Business::OnlinePayment::AuthorizeNet',
    'VERSION_FROM' => 'AuthorizeNet.pm', # finds $VERSION
    'AUTHOR'       => 'Ivan Kohler <ivan-authorizenet@420.am>', #really just
                                                                #the maintainer
    'PREREQ_PM'    => { 'Text::CSV_XS' => 0,
                        'Business::OnlinePayment' => 3,
                        'Business::OnlinePayment::HTTPS' => 0,
                        'Net::HTTPS::Any' => 0,
			'Test::More' => 0.42,
                        'Tie::IxHash' => 0,
                        'XML::Simple' => 0,
                        'XML::Writer' => 0,
                      },
);
