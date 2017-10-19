use strict;
use warnings;
use Catmandu::Store::OAI;
use Test::More;
use Test::Exception;

my $store = Catmandu::Store::OAI->new(
    url => 'http://biblio.ugent.be/oai',
);

ok $store, 'got a store';

my $bag = $store->bag;

ok $bag, 'got a bag';

# skip live testing by default (mock server instead)
if ($ENV{RELEASE_TESTING}) {

    ok $bag->first , 'generator';

    ok $bag->count , 'count';

    ok $bag->get('oai:archive.ugent.be:323892') , 'get';

    throws_ok { $bag->add({a=>'b'}) } 'Catmandu::NotImplemented' , 'add throws exception';

    throws_ok { $bag->delete(1234) } 'Catmandu::NotImplemented' , 'delete throws exception';

    throws_ok { $bag->delete_all } 'Catmandu::NotImplemented' , 'delete_all throws exception';

    ok $bag->commit , 'commit';
}

done_testing;
