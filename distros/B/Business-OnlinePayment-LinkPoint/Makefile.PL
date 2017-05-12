use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Business::OnlinePayment::LinkPoint',
    'VERSION_FROM' => 'LinkPoint.pm', # finds $VERSION
    'AUTHOR'       => 'Ivan Kohler <ivan-linkpoint@420.am>',
    'PREREQ_PM'    => { 'Business::OnlinePayment' => 0,
                        'lpperl' => 0,
                      },
    #'NORECURS'     => 1, # dont descend into subdirectories
);
