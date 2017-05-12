use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Business::OnlinePayment::BankOfAmerica',
    'VERSION_FROM' => 'BankOfAmerica.pm', # finds $VERSION
    'AUTHOR'       => 'Ivan Kohler <ivan-bankofamerica@420.am>',
    #'NORECURS'     => 1, # dont descend into subdirectories
    'PREREQ_PM'    => { 'Net::SSLeay' => '0',
                        'Business::OnlinePayment' => '0',
                      },
    #'dist'         => {CI => 'ci -l'},
);
