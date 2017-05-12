use t::lib::Utils;
use Test::Requires qw(DBI DBD::SQLite);

use Test::More;
use Test::Fatal;

use t::lib::Data::Mapper;
use Data::Mapper::Adapter::DBI;

my $dbh = t::lib::Utils::dbh;
   $dbh->do('create table popo (id integer primary key, value text)');

my $adapter = Data::Mapper::Adapter::DBI->new({ driver => $dbh });
my $mapper  = t::lib::Data::Mapper->new({ adapter => $adapter });

subtest 'create' => sub {
    my $data = $mapper->create(popo => { value => 'test create' });

    ok     $data;
    isa_ok $data, 't::lib::Data::Mapper::Data::Popo';
    is_deeply $data, +{
        id    => 1,
        value => 'test create',
    };
};

subtest 'find' => sub {
    my $created = $mapper->create(popo => { value => 'test find' });
    my $found   = $mapper->find(popo => { id => $created->{id} });

    ok        $found;
    isa_ok    $found, 't::lib::Data::Mapper::Data::Popo';
    is_deeply $created, $found;

    note 'when not found';
    my $ret = $mapper->find(popo => { id => 'not found key' });
    ok !$ret;
};

subtest 'search' => sub {
    my $created1 = $mapper->create(popo => { value => 'test search' });
    my $created2 = $mapper->create(popo => { value => 'test search' });
    my $result  = $mapper->search(popo => {
        value => 'test search'
    }, {
        order_by => 'id desc'
    });

    ok $result;
    is ref $result, 'ARRAY';
    is scalar @$result, 2;

    for my $record (@$result) {
        isa_ok $record, 't::lib::Data::Mapper::Data::Popo';
    }

    is_deeply $result, [$created2, $created1];
};

subtest 'update' => sub {
    my $data = $mapper->create(popo => { value => 'test update' });

    is $data->{value}, 'test update';
    $data->{value} = 'test updated';

    my $ret = $mapper->update($data);

    ok     $ret;
    isa_ok $ret, 'DBI::st';
    is     $ret->rows, 1;

    my $updated = $mapper->find(popo => { id => $data->{id} });

    ok $updated;
    is $updated->{value}, 'test updated';
};

subtest 'delete' => sub {
    my $data = $mapper->create(popo => { value => 'test delete' });

    ok $data;

    my $ret = $mapper->delete($data);

    ok $ret;
    isa_ok $ret, 'DBI::st';
    is     $ret->rows, 1;

    my $deleted = $mapper->find(popo => { id => $data->{id} });
    ok !$deleted;
};

done_testing;
