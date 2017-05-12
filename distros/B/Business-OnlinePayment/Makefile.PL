use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Business::OnlinePayment',
    'VERSION_FROM' => 'OnlinePayment.pm', # finds $VERSION
    'AUTHOR'       => 'Ivan Kohler <ivan-business-onlinepayment@420.am>',
    'PMLIBDIRS'    => [ 'OnlinePayment', 'FraudDetect' ],
    'NORECURS'     => 1, # dont descend into subdirectories
    'PREREQ_PM'    => { 
                        'Tie::IxHash'     => 0,
                        'Net::HTTPS::Any' => 0,
                      },
    'META_MERGE'   => {
                        resources => {
                          homepage => 'http://perl.business/onlinepayment',
                        },
                      },
    #'dist'         => {CI => 'ci -l'},
);
