use strict;
use warnings;
use Test::More;

use lib qw(t/lib);
use DBIO::Test;

plan tests => 1;

eval {
    package DBIO::Test::Namespace;
    use base qw/DBIO::Schema/;
    __PACKAGE__->load_namespaces(
        result_namespace => '+TestDBIO::Broken::Bogus',
        resultset_namespace => 'RSet',
    );
};

like ($@, qr/are you sure this is a real Result Class/, 'Clear exception thrown');
