use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Store::File::MediaHaven;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::MediaHaven::Index';
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

    my $store = Catmandu->store('File::MediaHaven',url => $url, username => $user, password => $pwd);

    ok $store , 'got a MediaHaven handle';

    my $index = $store->index();

    ok $index , 'got the index bag';

    my $array = $index->to_array;

    ok $array , 'list got a response';

    ok int(@$array) > 0 , 'got more than zero results';

    my $id0 = $array->[0]->{_id};

    ok $id0 , 'got at least one test result';

    ok $index->exists($id0), "exists($id0)";

    my $rec = $index->get($id0);

    ok $rec , "get($id0)";

    is $rec->{_id} , $id0 , "got the correct record";

    throws_ok { $index->add( { id => '1234'}) }  qr/is not supported/ , 'add() not supported';

    throws_ok { $index->delete($id0) } qr/is not supported/ , 'delete() not supported';

    throws_ok { $index->delete_all } qr/is not supported/ , 'delete_all() not supported';
}

done_testing;
