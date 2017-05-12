use 5.006;
use Test::Roo;
use MooX::Types::MooseLike::Base qw/:all/;

use MongoDB 0.45;
use MongoDBx::Queue;

has client => (
    is => 'lazy',
    isa => InstanceOf['MongoDB::MongoClient'],
);

has db_name => (
    is => 'ro',
    isa => Str,
    default => sub { 'test_dancer_plugin_queue_mongodb' },
);

sub _build_client {
    MongoDB::MongoClient->new;
}

sub _build_options {
    my ($self) = @_;
    return { db_name => $self->db_name };
}

sub BUILD {
    my ($self) = @_;
    eval { $self->client }
        or plan skip_all => "No MongoDB on localhost";
}

before setup => sub {
    my $self = shift;
    my $db   = $self->client->get_database($self->db_name);
    my $coll = $db->get_collection('queue');
    $coll->drop;
};

after teardown => sub {
    my $self = shift;
    my $db   = $self->client->get_database($self->db_name);
    $db->drop;
};

with 'Dancer2::Plugin::Queue::Role::Test';

run_me({ backend => 'MongoDB' });
done_testing;
