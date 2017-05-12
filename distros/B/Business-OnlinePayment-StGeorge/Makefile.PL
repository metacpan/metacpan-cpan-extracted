use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Business::OnlinePayment::StGeorge',
    'VERSION_FROM' => 'StGeorge.pm', # finds $VERSION
    'AUTHOR'       => 'Ivan Kohler <ivan-stgeorge@420.am>',
    'PREREQ_PM'    => { 'Business::OnlinePayment' => 0, },
    #'NORECURS'     => 1, # dont descend into subdirectories
    #'test'         => { 'TESTS' => 't*/*.t' },
);
