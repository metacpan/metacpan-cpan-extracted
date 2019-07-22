use v5.14;
use strict;
use Test::More 0.96;
use Test::Exception;

use DataLoader::Error;

subtest 'basic', sub {
    my $error = DataLoader::Error->new("foo");
    isa_ok($error, 'DataLoader::Error');
    is( $error->message, "foo" );
    throws_ok { $error->throw } qr/foo/;
};

subtest 'errors' => sub {
    throws_ok { DataLoader::Error->new("foo", "bar") } qr/too many arguments/;
    throws_ok { DataLoader::Error->new() } qr/message is required/;
    throws_ok { DataLoader::Error->new([]) } qr/message is not a string/;
};

done_testing;
