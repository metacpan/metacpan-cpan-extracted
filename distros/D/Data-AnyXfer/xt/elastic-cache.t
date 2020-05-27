use Data::AnyXfer::Test::Kit;
use Data::AnyXfer::Elastic::Cache;

use lib 't/lib';
use Employee::IndexInfo;

my $employee = Employee::IndexInfo->new;
my $cache
    = Data::AnyXfer::Elastic::Cache->new( index_info => $employee );

{
    note 'full methods';
    my $id = 12345;
    my $data = { name => 'Marvin the Paranoid Android' };
    is $cache->get( id => $id ), undef, 'undef returned for missing document';
    my $res = $cache->set( id => $id, callback => sub {$data} );
    is_deeply $res, $data, 'data set and returned';
    is_deeply $cache->get( id => $id ), $data, 'data get';
}

{
    note 'short cut method';
    my $id = 54321;
    my $data = { answer => 42 };
    is $cache->get( id => $id ), undef, 'undef returned for missing document';
    my $res = $cache->get_or_set(
        id       => $id,
        callback => sub {$data}
    );
    is_deeply $res, $data, 'data set and returned';
    is_deeply $cache->get( id => $id ), $data, 'data get';
}


END {
    $employee->get_index->elasticsearch->indices->delete(
        index => $employee->alias . '*' );
}

done_testing;
