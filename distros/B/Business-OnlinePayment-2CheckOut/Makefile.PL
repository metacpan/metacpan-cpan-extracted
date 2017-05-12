use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Business::OnlinePayment::2CheckOut',
    'VERSION_FROM'	=> '2CheckOut.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Net::SSLeay' => 0,
			     'Text::CSV_XS' => 0,
			     'Business::OnlinePayment' => 0,
			   },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => '2CheckOut.pm', # retrieve abstract from module
       AUTHOR     => 'Alexey Khobov <alex@stork.ru>') : ()),
);
