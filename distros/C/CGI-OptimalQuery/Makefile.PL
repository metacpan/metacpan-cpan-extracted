

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'CGI::OptimalQuery',
    VERSION_FROM => 'lib/CGI/OptimalQuery.pm', # finds \$VERSION
    AUTHOR       => 'Philip Collins (Philip.Collins@unh.edu)',
    ABSTRACT     => 'rich HTML viewer for your SQL select queries',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'DBI' => 0,
                     'JSON::XS' => 0,
                     'Mail::Sendmail' => 0
                    },
);
