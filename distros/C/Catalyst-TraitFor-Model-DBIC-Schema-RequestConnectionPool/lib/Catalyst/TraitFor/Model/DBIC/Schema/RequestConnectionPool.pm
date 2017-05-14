package Catalyst::TraitFor::Model::DBIC::Schema::RequestConnectionPool;
# ABSTRACT: Create a schema for each unique calling context, defined by your model

use Moose::Role;
use MooseX::MarkAsMethods autoclean => 1;

with 'Catalyst::Component::InstancePerContext';

use Scalar::Util qw/blessed/;

requires qw/build_connect_key build_connect_info/;

has storage_pool => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[DBIx::Class::Storage]',
    default => sub { {} },
    handles => {
        set_storage  => 'set',
        get_storage  => 'get',
        },
    );

my $default_key = __PACKAGE__.'::default_connection';

sub build_per_context_instance {
    my ($self, $c) = @_;

    return $self unless blessed $c;

    my $key = $self->build_connect_key($c);

    if (!$key){
        # If they don't give us a key, then just return the normal schema
        if (my $storage = $self->get_storage($default_key)){
            # Which might need to be reset if we've already connected to another
            $self->schema->storage( $storage );
            }
        return $self;
        }

    if (!$self->get_storage($default_key)){
        $self->set_storage( $default_key => $self->storage );
        }

    if (my $storage = $self->get_storage($key)){
        $self->schema->storage( $storage );
        }
    else {
        # This will create a new schema
        $self->schema->connection(
            $self->build_connect_info($c),
            );
        my $storage = $self->schema->storage;
        $self->set_storage( $key => $storage );
        }

    return $self;
    }

1;

=head1 NAME

Catalyst::TraitFor::Model::DBIC::Schema::RequestConnectionPool

=head1 SYNOPSIS

 package MyApp::Model::MyDB;

 use Moose;

 extends 'Catalyst::Model::DBIC::Schema';
 with 'Catalyst::TraitFor::Model::DBIC::Schema::RequestConnectionPool';

 sub build_connect_key {
    my ($self, $c) = @_;
    return $c->stash->{client}->name;
    }

 sub build_connect_info {
    my ($self, $c) = @_;
    return $c->stash->{client}->db_connect_info;
    }

 1;

=head1 DESCRIPTION

This role handles a pool of connections for your L<Catalyst::Model::DBIC::Schema> model.
For each request, your model defines a connection key with L</build_connect_key>.
This role then looks for the storage for that connection and applies it to your model's schema.
If no storage has been built previously for this connection key then your model returns
the connect_info for it from L<build_connect_info>.

Your model must implmeent both L<build_connect_key> and L<build_connect_info>.

=head1 REQUIRED METHODS

=head2 build_connect_key ($app, $c)

Must return a unique identifier for the schema connection this request should use.

=head2 build_connect_info ($app, $c)

Must return a list of the connect_info for L<DBIx::Class::Schema/connection>.

=head1 SEE ALSO

L<Catalyst::Model::DBIC::Schema>
L<DBIx::Class::Schema>

=head1 AUTHOR

Gareth Kirwan, C<gbjk at cpan.org>



=cut
