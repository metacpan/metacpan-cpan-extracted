use strict;
use Test::More;
use Data::Generator::FromDDL::RecordSet;
use SQL::Translator::Schema::Field;

use constant RECORDS_PER_CHUNK => 100_000;

{
    package MockField;
    sub new {
        my ($class, $field_name) = @_;
        bless {
            field_name => $field_name
        }, $class;
    }
    sub name {
        shift->{field_name};
    }
}

sub _setup {
    my ($total_records, $field_name) = @_;

    my $recordset = Data::Generator::FromDDL::RecordSet->new(
        'test_table', $total_records,
    );
    my $field = MockField->new('foo');
    my @values = (1..$total_records);
    $recordset->set_column_values($field, \@values);

    return $recordset;
}

subtest 'save values into chunks' => sub {
    my $num_of_chunks = 10;
    my $total_records = RECORDS_PER_CHUNK * $num_of_chunks;
    my $recordset = _setup($total_records, 'foo');
    my $column = $recordset->columns->[0];
    my $chunks = $column->{chunks};

    is scalar(@$chunks), $num_of_chunks;
};

subtest 'get values from all chunks' => sub {
    my $total_records = RECORDS_PER_CHUNK * 10;
    my $recordset = _setup($total_records, 'foo');
    my @values = $recordset->get_column_values('foo');

    is scalar(@values), $total_records;
};

subtest 'iterate through chunks' => sub {
    my $num_of_chunks = 10;
    my $total_records = RECORDS_PER_CHUNK * $num_of_chunks;
    my $recordset = _setup($total_records, 'foo');

    my $iterate_count = 0;
    $recordset->iterate_through_chunks(sub {
        $iterate_count++;
    });

    is $iterate_count, $num_of_chunks;
};

done_testing;
