package Data::Generator::FromDDL::Builder;
use strict;
use warnings;
use Carp qw(croak);
use Class::Data::Inheritable;
use Data::Generator::FromDDL::RecordSet;
use Data::Generator::FromDDL::Util qw(need_quote_data_type);
use Class::Accessor::Lite (
    new => 1,
    rw => [qw(table recordsets)],
);

use base qw(Exporter Class::Data::Inheritable);
our @EXPORT = qw(datatype);

__PACKAGE__->mk_classdata('dispatch_table', {});


sub generate {
    my ($self, $n) = @_;
    my $table = $self->table;
    my $recordset = Data::Generator::FromDDL::RecordSet->new($table, $n);
    for my $field ($table->get_fields) {
        my @values = $self->generate_field_values($field, $n);
        $recordset->set_column_values($field, \@values);
    }
    return $recordset;
}

sub generate_field_values {
    my ($self, $field, $n) = @_;
    my $data_type = lc($field->data_type);

    my @values = $self->dispatch($data_type, $field, $n);

    if (need_quote_data_type($data_type)) {
        @values = map { q{'} . $_ . q{'} } @values;
    }
    return @values;
}

sub dispatch {
    my ($self, $data_type, $field, $n) = @_;
    my $class = ref $self;
    my $code = $class->dispatch_table->{$data_type};
    croak "Unsupported data type: $data_type \n"
        unless $code;
    
    return $code->($self, $field, $n, $self->recordsets);
}

sub redispatch {
    my ($self, $new_data_type, $field, $n) = @_;
    return $self->dispatch($new_data_type, $field, $n);
}

## DSL
sub datatype($&) {
    my ($data_types, $code) = @_;
    my ($class) = caller;

    # update dispatch table
    my $dispatch_table = $class->dispatch_table;
    for my $data_type (split /,\s*/, $data_types) {
        $dispatch_table->{$data_type} = $code;
    }
    $class->dispatch_table($dispatch_table);
}

1;
