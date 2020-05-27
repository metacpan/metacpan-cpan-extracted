use Data::AnyXfer::Test::Kit;

use Data::AnyXfer::Elastic;
use Data::AnyXfer::Elastic::Logger;
use Data::AnyXfer::Elastic::Importer;
use Data::AnyXfer::Elastic::Import::DataFile;

my $western_file = Path::Class::file('t/data/western.datafile');
my $eastern_file = Path::Class::file('t/data/eastern.datafile');

for ( $western_file, $eastern_file ) {

    unless ( -e $_ ) {

        fail( 'File missing (aborting): ' . $_->stringify );
        exit(0);

    }

}

my $western_df = Data::AnyXfer::Elastic::Import::DataFile->new(
    file         => $western_file,
    connect_hint => 'readwrite',
);

my $eastern_df = Data::AnyXfer::Elastic::Import::DataFile->new(
    file         => $eastern_file,
    connect_hint => 'readwrite',
);

# create the importer. only one instance is used throughout the test. Call
# clean to clean caches and remove indexes from elasticsearch. Logger is not
# tested so is omitted.

sub get_fresh_importer() {
    clean();
    return Data::AnyXfer::Elastic::Importer->new(
        logger => Data::AnyXfer::Elastic::Logger->new(
            screen => 0,
            file   => 0,
        ),
    );
}

my $elasticsearch
    = Data::AnyXfer::Elastic->client_for( 'public_data', undef,
    'readwrite' );

note 'FAILED EXECUTION';

{
    my $importer = get_fresh_importer();
    my $res      = $importer->execute(
        datafile      => $western_df,
        elasticsearch => $elasticsearch,
        _sim_error    => 1,
    );

    ok !$res, 'datafile execute returned false status code ( failed )';
    is $importer->_count_cache,  1, 'one import cached ( failed )';
    is $importer->_count_errors, 1, 'one error cached ( failed )';

    $importer->cleanup();
    is $importer->_count_cache,  0, 'after cleanup() no import cached';
    is $importer->_count_errors, 0, 'after cleanup() no errors';

}

note 'SUCCESSFUL EXECUTION & FINALISE';
{

    my $importer = get_fresh_importer();

    ok $importer->document_id_field('name'), 'document id set to name field';

    my $res = $importer->execute(
        datafile      => $western_df,
        elasticsearch => $elasticsearch,
    );

    ok $res, 'datafile execute returned true status code ( successful )';
    is $importer->_count_cache,  1, 'one import cached ( success )';
    is $importer->_count_errors, 0, 'zero errors cached ( success )'
        or diag( $importer->errors );

    $res = $importer->execute(
        datafile      => $eastern_df,
        elasticsearch => $elasticsearch,
    );

    ok $res, 'datafile execute returned true status code ( successful )';
    is $importer->_count_cache,  2, 'one import cached ( success )';
    is $importer->_count_errors, 0, 'zero errors cached ( success )';

    $res = $importer->finalise;
    sleep(2);

    my $count = $elasticsearch->count( index => 'europe' )->{count};
    is $count, 12, 'All documents assigned to alias';

    is $importer->_count_cache,  0, 'one import cached ( success )';
    is $importer->_count_errors, 0, 'zero errors cached ( success )';

    my $expected_doc
        = superhashof(
        { _id => 'Ireland', _source => superhashof( { name => 'Ireland' } ) }
        );

    cmp_deeply $western_df->get_index->get( id => 'Ireland' ),
        $expected_doc,
        'document can be retrieved by document_id_field';

    throws_ok(
        sub {
            $importer->cleanup;
        },
        qr/Can not call automatic cleanup as finalise/,
        "Clean up croaks after finalise"
    );

    throws_ok(
        sub {
            $importer->execute();
        },
        qr/Can not call execute\(\) as finalise/,
        'execute() croaks after finalise'
    );

    throws_ok(
        sub {
            $importer->finalise();
        },
        qr/Can not call finalise\(\) twice/,
        'finalise() croaks after finalise'
    );

}

clean();

done_testing;

sub clean {

    sleep(1);

    foreach ( $western_df, $eastern_df ) {

        eval { $elasticsearch->indices->delete( index => $_->index ) };
    }

    sleep(1);
}

1;
