use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Business::OnlinePayment::TCLink',
    'VERSION_FROM' => 'TCLink.pm', # finds $VERSION
    'AUTHOR'       => 'Dan Helfman <developer@trustcommerce.com>',
    #'NORECURS'     => 1, # dont descend into subdirectories
    'PREREQ_PM'    => { 'Net::TCLink' => 0,
                        'Business::OnlinePayment' => 0,
                      },
    #'dist'         => {CI => 'ci -l'},
);
