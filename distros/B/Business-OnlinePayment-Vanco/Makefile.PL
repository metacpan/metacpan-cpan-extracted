use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Business::OnlinePayment::Vanco',
    'VERSION_FROM' => 'Vanco.pm', # finds $VERSION
    'AUTHOR'       => 'Jeff Finucane <vanco@weasellips.com>',
    'PREREQ_PM'    => { 'Business::OnlinePayment' => 3,
#                        'Business::OnlinePayment::HTTPS' => 0,
                        'Crypt::SSLeay'           => 0,
                        'Date::Calc'              => 0,
                        'HTTP::Request'           => 0,
                        'HTTP::Request::Common'   => 0,
                        'LWP::UserAgent'          => 0,
                        'Text::CSV_XS' => 0,
			'Test::More'              => 0.42,
                        'Tie::IxHash'             => 0,
                        'XML::Simple'             => 0,
                        'XML::Writer'             => 0,
                      },
);
