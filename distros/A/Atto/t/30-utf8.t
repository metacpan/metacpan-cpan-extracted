#!perl

use strict;
use warnings;
use utf8;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS;

use Atto qw(faces);

my $faces = q{◎ܫ◎ ಠﭛಠ ⊙_ʘ ♨_♨ ಠ_ಠ};

sub faces {
    return $faces;
}

my $app = Atto->psgi;


my $test = Plack::Test->create($app);
my $json = JSON::MaybeXS->new->utf8->allow_nonref;

my $res = $test->request(POST "/faces");
ok $res->is_success, "request to endpoint succeeded";

is $json->decode($res->content), $faces, "request returned expected response";

done_testing;

