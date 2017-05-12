use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Business::OnlinePayment::SecureHostingUPG',
    'VERSION_FROM' => 'SecureHostingUPG.pm', # finds $VERSION
    'AUTHOR'       => 'Ivan Kohler <ivan-securehostingupg@420.am>',
    #'NORECURS'     => 1, # dont descend into subdirectories
    'PREREQ_PM'    => {
                        'Business::OnlinePayment' => 0,

                        # for HTTPS (maybe it should be a separate dist?)
                        'URI::Escape' => 0,
                        'Tie::IxHash' => 0,
                       
                        # 'Net::SSLeay' => 0,
                        # or 'Crypt::SSLeay' => 0,
                        #    'URI

                      },
    #'dist'         => {CI => 'ci -l'},
);

