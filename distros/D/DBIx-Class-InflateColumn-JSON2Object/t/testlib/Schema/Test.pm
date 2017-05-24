package testlib::Schema::Test;
use strict;
use warnings;

BEGIN {
    use base qw/DBIx::Class/;
};

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('test');
__PACKAGE__->source_name('Test');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'INT',
        is_auto_increment => 1,
        is_nullable       => 0,
        extras            => {unsigned => 1}
    },
    no_class => {
        data_type   => 'text',
        is_nullable => 0,
    },
    fixed_class => {
        data_type   => 'text',
        is_nullable => 0,
    },
    array => {
        data_type   => 'text',
        is_nullable => 0,
    },
    data => {
        data_type   => 'text',
        is_nullable => 0,
    },
    type => {
        data_type   => 'text',
        is_nullable => 0,
    },
);
__PACKAGE__->set_primary_key('id');


use DBIx::Class::InflateColumn::JSON2Object;

DBIx::Class::InflateColumn::JSON2Object->no_class({
    column=>'no_class',
});

DBIx::Class::InflateColumn::JSON2Object->fixed_class({
    column=>'fixed_class',
    class=>'testlib::Object::Fixed',
});

DBIx::Class::InflateColumn::JSON2Object->array_of_class({
    column=>'array',
    class=>'testlib::Object::Element',
});

DBIx::Class::InflateColumn::JSON2Object->class_in_column({
    class_column=>'type',
    data_column=>'data',
    namespace=>'testlib::Object::Various',
});

1;
