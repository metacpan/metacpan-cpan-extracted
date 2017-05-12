package DBIx::Class::BatchUpdate::Update;
$DBIx::Class::BatchUpdate::Update::VERSION = '1.004';
use Moo;
use autobox::Core;
use true;

use Storable qw/ nfreeze /;
use Carp;

use DBIx::Class::BatchUpdate::Batch;



has rows => ( is => "ro", required => 1 );

has result_source => ( is => "lazy" );
sub _build_result_source {
    my $self = shift;
    my $row = $self->rows->[0] or return undef;
    my $result_source = $row->result_source;
    return $result_source;
}

has resultset => (is => "lazy");
sub _build_resultset {
    my $self = shift;
    my $result_source = $self->result_source or return undef;
    return $result_source->resultset();
}

has pk_column => ( is => "lazy" );
sub _build_pk_column {
    my $self = shift;
    my $result_source = $self->result_source or return undef;

    my $result_source_name = ref($result_source);
    my @columns = $result_source->primary_columns;
    @columns > 1 and croak("DBIx::Class::BatchUpdate::Update does not work on result sources ($result_source_name) with multi-column PKs\n");

    return $columns[0];
}

has batches => ( is => "lazy");
sub _build_batches {
    my $self = shift;
    my $pk_column = $self->pk_column or return [];
    my $result_source = $self->result_source;
    my $result_source_name = ref($result_source);

    my $key_batch = {};
    for my $row ($self->rows->elements) {
        my $key_value = { $row->get_dirty_columns };
        my $batch_key = $self->batch_key($key_value) or next;

        exists $key_value->{$pk_column} and croak("Primary key ($key_value->{$pk_column}) for ResultSource ($result_source_name) is dirty, can't BatchUpdate");

        my $batch = $key_batch->{ $batch_key } //= DBIx::Class::BatchUpdate::Batch->new({
            key_value => $key_value,
            resultset => $self->resultset,
            key       => $batch_key,
            pk_column => $pk_column,
        });
        $batch->ids->push( $row->id );
    };

    # Sort to get some semblance of determinism wrt insert ordering
    return [ sort { $a->key cmp $b->key } $key_batch->values ];
}

sub batch_key {
    my $self = shift;
    my ($key_value) = @_;
    keys %$key_value or return undef;

    # sort hash keys for a stable representation
    local $Storable::canonical = 1;
    return nfreeze(
        {
            # Assume the pk isn't dirty
            map {
                my $value = $key_value->{$_};
                $_ => defined($value) ? "$value" : undef;
            }
            keys %$key_value,
        },
    );
}

sub update {
    my $self = shift;
    for my $batch ( $self->batches->elements ) {
        $batch->update();
    }
}
