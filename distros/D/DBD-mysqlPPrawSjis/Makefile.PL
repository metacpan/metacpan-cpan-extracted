use strict;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'             => 'DBD-mysqlPPrawSjis',
    'VERSION_FROM'     => 'DBD/mysqlPPrawSjis.pm', # finds $VERSION
    ($] >= 5.005 ?                                 # Add these new keywords supported since 5.005
      ('PREREQ_PM'     => {                        # e.g., Module::Name => 1.1
           'DBI'        => 1.0,                    # a minimum working version
           'Net::MySQL' => 0.08,                   # a minimum working version
       },
       'ABSTRACT_FROM' => 'DBD/mysqlPPrawSjis.pm', # retrieve abstract from module
       'AUTHOR'        => 'ina <ina@cpan.org>',
      )
      :
      ()
    ),
);
__END__
