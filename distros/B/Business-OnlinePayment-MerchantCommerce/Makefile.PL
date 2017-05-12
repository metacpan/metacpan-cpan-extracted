use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		    => 'Business::OnlinePayment::MerchantCommerce',
    'VERSION_FROM'	=> 'MerchantCommerce.pm',
	'AUTHOR'        => 'Tim McIntyre <tmac@transport.com>',
	'NORECURS'      => 1,
    'PREREQ_PM'		=> {'Business::OnlinePayment' => 0},	
);


