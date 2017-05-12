package <% dist_module %>::Schema::Result::User;
use strict;
use warnings;
use parent 'CatalystX::Crudite::Schema::ResultBase';
__PACKAGE__->setup_user_class;

sub is_used {
    # my $self = shift;
    # $self->some_has_many_relationship->count;
}

1;
