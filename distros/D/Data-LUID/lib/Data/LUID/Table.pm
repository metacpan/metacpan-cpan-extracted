package Data::LUID::Table;

use Moose;
use Data::LUID::Carp;

use BerkeleyDB qw/DB_NOTFOUND/;
use Path::Class;

has path => qw/is ro lazy_build 1/;
sub _build_path {
    return './luid';
}

has bdb_manager => qw/is ro lazy_build 1/;
sub _build_bdb_manager {
    require BerkeleyDB::Manager;
    my $self = shift;
    my $home = dir $self->path;
    $home->mkpath unless -d $home;
    return BerkeleyDB::Manager->new( home => $home, create => 1 );
}

sub bdb_table {
    my $self = shift;
    return $self->bdb_manager->open_db( 'table', class => 'BerkeleyDB::Hash' );
}

has generator => qw/is rw lazy_build 1/; # initializer _initialize_generator/;
sub _build_generator {
    require Data::LUID::Generator::TUID;
    return Data::LUID::Generator::TUID->new;
}
sub _initialize_generator {
    my ( $self, $value, $set );
    croak "What are you doing?!";
}

sub luid_key ($) {
    return join '', 'luid:', shift;
}

sub take {
    my $self = shift;
    my $key = shift;
    croak "No key given to take" unless defined $key;
    $self->store( luid_key $key );
}

sub taken {
    my $self = shift;
    my $key = shift;
    croak "No key given to check if taken" unless defined $key;
    return $self->exists( luid_key $key )
}

sub make {
    my $self = shift;
    # TODO Add throttle
    $self->bdb_manager->txn_do( sub {
        while( 1 ) {
            my $key = $self->generator->next;
            croak "Got undefined value from luid generator ", $self->generator unless defined $key;
            next if $self->taken( $key );
            $self->take( $key );
            return $key;
        }
    } );
}

sub next {
    my $self = shift;
    return $self->make;
}

sub store {
    my $self = shift;
    my $key = shift;
    my $value = shift || 1;

    my $status = $self->bdb_table->db_put( $key, $value );
    croak "Problem storing \"$key\" => \"$value\": $status" if $status;
    return $value;
}

sub exists {
    my $self = shift;
    my $key = shift;

    my $value;

    my $status = $self->bdb_table->db_get( $key, $value );
    return 0 if $status == DB_NOTFOUND;
    return 1 unless $status;
    croak "Problem checking existence of \"$key\": $status";
}

sub delete {
    my $self = shift;
    my $key = shift;

    my $status = $self->bdb_table->db_del( $key );
    return if $status == DB_NOTFOUND;
    croak "Problem deleting \"$key\": $status" if $status;
}

1;
