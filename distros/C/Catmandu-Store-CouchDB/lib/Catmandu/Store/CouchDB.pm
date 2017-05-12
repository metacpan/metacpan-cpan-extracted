package Catmandu::Store::CouchDB;

use Catmandu::Sane;
use Moo;
use Catmandu::Store::CouchDB::Bag;
use Store::CouchDB;

with 'Catmandu::Store';

=head1 NAME

Catmandu::Store::CouchDB - A searchable store backed by CouchDB

=head1 NAME

A searchable store backed by CouchDB.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Catmandu::Store::CouchDB;

    my $store = Catmandu::Store::CouchDB->new;

    my $obj1 = $store->bag->add({ name => 'Patrick' });

    printf "obj1 stored as %s\n" , $obj1->{_id};

    # Force an id in the store
    my $obj2 = $store->bag->add({ _id => 'test123' , name => 'Nicolas' });

    my $obj3 = $store->bag->get('test123');

    $store->bag->delete('test123');

    $store->bag->delete_all;

    # All bags are iterators
    $store->bag->each(sub { ... });
    $store->bag->take(10)->each(sub { ... });

=head1 METHODS

=head2 new(host => 'localhost', port => '5984', ...)

Create a new Catmandu::Store::CouchDB store.

=head2 bag($name)

Create or retieve a bag with name $name. Returns a Catmandu::Bag.

=cut

my $CLIENT_ARGS = [qw(
    debug
    host
    port
    ssl
    user
    pass
)];

has couch_db => (is => 'ro', lazy => 1, builder => '_build_couch_db');

sub _build_couch_db {
    my ($self) = @_;
    my $db = Store::CouchDB->new;
    $db->config(delete $self->{_args});
    $db;
}

sub BUILD {
    my ($self, $args) = @_;
    $self->{_args} = {};
    for my $key (@$CLIENT_ARGS) {
        $self->{_args}{$key} = $args->{$key} if exists $args->{$key};
    }
}

=head1 SEE ALSO

L<Catmandu::Bag>

=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
