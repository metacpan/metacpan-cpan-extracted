package My::Schema::User;
use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/CustomPrefetch Core/);
__PACKAGE__->table('users');
__PACKAGE__->add_columns(qw/id name/);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->resultset_class('DBIx::Class::ResultSet::CustomPrefetch');
__PACKAGE__->custom_relation(
    status => 'My::Schema::Status',
    { 'foreign.user_id' => 'self.id' }
);
__PACKAGE__->custom_relation(
    custom_status => sub {
        my ( $schema, $attrs ) = @_;
        return unless $attrs->{custom_status};
        $schema->resultset('Status')->search( { name => { -like => 'a%' } }, );
    },
    { 'foreign.user_id' => 'self.id' }
);

sub add_to_statuses {
    my $self = shift;
    my $args = shift || {};
    $self->result_source->schema->resultset('Status')
      ->create( { user_id => $self->id, %$args } );
}

1;
