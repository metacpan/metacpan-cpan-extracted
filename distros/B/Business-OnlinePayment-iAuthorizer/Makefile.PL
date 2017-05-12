use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile('NAME'         => 'Business::OnlinePayment::iAuthorizer',
              'VERSION_FROM' => 'iAuthorizer.pm', # finds $VERSION
              'AUTHOR'       => 'Daniel Brooks <db48x@yahoo.com>', 
              'PREREQ_PM'    => {'Net::SSLeay' => 1,
                                 'Business::OnlinePayment' => 1,
                                },
             );

