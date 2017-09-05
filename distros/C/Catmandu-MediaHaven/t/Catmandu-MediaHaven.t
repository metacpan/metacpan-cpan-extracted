use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::MediaHaven';
    use_ok $pkg;
}
require_ok $pkg;

my $url  = $ENV{MEDIAHAVEN_URL} || "";
my $user = $ENV{MEDIAHAVEN_USER} || "";
my $pwd  = $ENV{MEDIAHAVEN_PWD} || "";

SKIP: {
    skip "No Mediahaven server environment settings found (MEDIAHAVEN_URL,"
	 . "MEDIAHAVEN_USER,MEDIAHAVEN_PWD).",
	100 if (! $url || ! $user || ! $pwd);

    my $mh = Catmandu::MediaHaven->new(url => $url, username => $user, password => $pwd);

    ok $mh , 'got a MediaHaven handle';

    my $res = $mh->search();

    ok $res , 'got a search result';

    is ref($res) , 'HASH' , 'search result is a hash';

    ok $res->{totalNrOfResults} >= 0 , 'got more than one answer';

    my $num_of_result = $res->{totalNrOfResults};

    my $result_list = $res->{mediaDataList};

    is int(@$result_list) , $num_of_result , 'got enough results';

    if ($num_of_result) {
        my $id = $result_list->[0]->{externalId};

        ok $id , 'got an record identifier';

        $res = $mh->record($id);

        ok $res , 'got a record result';

        is ref($res) , 'HASH' , 'record result is a hash';

        is $res->{externalId} , $id , 'got the correct record';
    }
}

done_testing;
