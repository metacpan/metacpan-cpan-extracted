

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'CouchDB::ExternalProcess',
    VERSION_FROM => 'lib/CouchDB/ExternalProcess.pm', # finds \$VERSION
    AUTHOR       => 'Mike Walker (mike-cpan-couchdb-externalprocess@napkindrawing.com)',
    ABSTRACT     => 'Write CouchDB External Processes quickly & easily',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'JSON::Any' => 1.17,
                    },
);
