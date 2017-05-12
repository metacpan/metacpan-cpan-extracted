package Data::CouchDB::Handler;

use Moose;

our $VERSION = '0.14';

use Data::CouchDB;
use YAML::XS;
use feature 'state';

has couchdb_databases => (
    is         => 'rw',
    isa        => 'HashRef',
    #default    => sub { {} },
);

sub couchdb {
    my $self    = shift;
    my $db      = shift;
    my $ua      = shift;
    my $db_name = $self->couchdb_databases->{$db} || $db;

    if ($ua or not defined $self->_couch_cache->{$db_name}) {
        my $params = $self->_build_couchdb_params($db_name);

        # For normal usage we dont expect to pass ua(user_agent).
        # So dont cache if ua is passed.
        if ($ua) {
            $params->{ua} = $ua;
            return Data::CouchDB->new(%$params);
        }

        $self->_couch_cache->{$db_name} = Data::CouchDB->new(%$params);
    }

    return $self->_couch_cache->{$db_name};
}

has couchdb => (
    is     => 'ro',
    reader => '_couchdb_configuration'
);

sub _build_couchdb_params {
    my $self    = shift;
    my $db_name = shift;

    my $params->{db} = $db_name;

    state $config = YAML::XS::LoadFile('/etc/couchdb.yml');
    if ($config->{master}->{ip} ne '127.0.0.1') {
        $params->{master_host}     = $config->{master}->{ip};
        $params->{master_port}     = 6984;
        $params->{master_protocol} = 'https://';
    }
    $params->{couchdb} = $config->{password};

    return $params;
}

has '_couch_cache' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {}; },
);

__PACKAGE__->meta->make_immutable;

1;

