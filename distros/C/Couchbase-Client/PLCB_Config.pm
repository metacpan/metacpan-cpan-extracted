package PLCB_Config;
use strict;
use warnings;
use Dir::Self;
use File::Spec;
use Hash::Util qw(lock_keys);

#this perl 'hash' contains configuration information necessary
#to bootstrap and/or configure the perl couchbase client and run
#necessary tests.

my $params = {
    #URL from which to download the mock JAR file for tests
    COUCHBASE_MOCK_JARURL => 'https://github.com/downloads/mnunberg/' .
        'perl-Couchbase-Client/CouchbaseMock-0.5-SNAPSHOT.jar',

    #version numbers for libcouchbase and libvbucket
    LIBVBUCKET_RELEASE => '1.8.0.4',
    LIBCOUCHBASE_RELEASE => '1.0.4',

    LIBEVENT_RELEASE    => '2.0.17-stable',
};


#don't change these, or there may be bad consequences
$params->{SRC_DIR} = File::Spec->catfile(__DIR__, 'src');
$params->{SRC_INST} = File::Spec->catfile($params->{SRC_DIR}, 'inst');

lock_keys(%$params);

return $params; #return value
