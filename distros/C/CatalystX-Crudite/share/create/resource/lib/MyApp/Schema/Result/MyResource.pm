package <% dist_module %>::Schema::Result::<% resource_name %>;
use strict;
use warnings;
use parent 'CatalystX::Crudite::Schema::ResultBase';
__PACKAGE__->table('<% resource_symbols %>s');
__PACKAGE__->common_setup;
__PACKAGE__->add_columns(name => { data_type => 'varchar', is_nullable => 0 });
__PACKAGE__->add_unique_constraint([qw(name)]);
sub is_used {
    # my $self = shift;
    # $self->some_has_many_relationship->count;
}
1;
