package DBSchema::Result::KeysByMethod;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

# # use Moose;
# use MooseX::NonMoose;
# extends 'DBIx::Class::Core';

__PACKAGE__->table("keysbymethod");
__PACKAGE__->add_columns(
    "dvd" => { data_type => 'integer' },
    "key1" => { data_type => 'varchar', size => 16 },
    "key2" => { data_type => 'varchar', size => 16 },
    "value" => { data_type => 'varchar', size => 16, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("dvd", "key1", "key2");

__PACKAGE__->belongs_to("dvd", "DBSchema::Result::Dvd", { dvd_id => "dvd" });

sub new {
    my $class = shift;
    my $attrs = shift;

    # remove non-column attribute 'combined_key'
    if ( ref $attrs eq 'HASH' && exists $attrs->{combined_key}) {
        # copy to avoid side effects cause by modifying the input params
        my %foreign_attrs = %$attrs;
        my $combined_key = delete $foreign_attrs{combined_key};
        my ($key1, $key2) = split('/', $combined_key);
        $foreign_attrs{key1} = $key1;
        $foreign_attrs{key2} = $key2;
        return $class->SUPER::new(\%foreign_attrs, @_);
    }

    return $class->SUPER::new($attrs, @_);
}

# sub FOREIGNBUILDARGS {
#     my $class = shift;
#     my $attrs = shift;
#
#     # remove non-column attribute 'combined_key'
#     if ( ref $attrs eq 'HASH' ) {
#         # copy to avoid side effects cause by modifying the input params
#         my %foreign_attrs = %$attrs;
#         delete $foreign_attrs{combined_key};
#         return \%foreign_attrs, @_;
#     }
#
#     return $attrs, @_;
# }

# has combined_key => (
#     is      => 'rw',
#     lazy    => 1,
#     default => sub {
#         my $self = shift;
#         return $self->key1 . '/' . $self->key2
#             if defined $self->key1 && defined $self->key2;
#         return;
#     },
#     trigger => sub {
#         my ( $self, $combined_value ) = @_;
#         my ($key1, $key2) = split('/', $combined_value);
#         $self->key1($key1);
#         $self->key2($key2);
#     }
# );

sub combined_key {
    my $self = shift;
    if (@_) {
        my $combined_value = shift;
        my ($key1, $key2) = split('/', $combined_value);
        $self->key1($key1);
        $self->key2($key2);
    }
    return $self->key1 . '/' . $self->key2;
}

# no Moose;
# __PACKAGE__->meta->make_immutable;

1;
