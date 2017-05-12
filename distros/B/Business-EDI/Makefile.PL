

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Business::EDI',
    VERSION_FROM => 'lib/Business/EDI.pm', # finds \$VERSION
    AUTHOR       => 'Joe Atzberger (atz@esilibrary.com)',
    ABSTRACT     => 'Top level generator of U.N. EDI objects',
    PREREQ_PM    => {
                     'CGI' => 3.1,
                     'Test::More' => 0.94,
                     'Test::Simple' => 0.88,
                     'Exporter::Easy' => 0.14,
                     'List::MoreUtils' => 0.22,
                     'File::Find::Rule' => 0.32,
                     'UNIVERSAL::require' => 0.10,
                     'JSON::XS' => 2.01,
                    },
);
