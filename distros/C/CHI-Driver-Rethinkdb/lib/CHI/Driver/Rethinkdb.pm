package CHI::Driver::Rethinkdb;
$CHI::Driver::Rethinkdb::VERSION = '0.1.2';
use Moose;
use Moose::Util::TypeConstraints;
use Carp qw(croak);

use Rethinkdb;
use Rethinkdb::IO;

extends 'CHI::Driver';


=head1 NAME

CHI::Driver::Rethinkdb - Rethinkdb driver for CHI

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

    my $cache = CHI->new(
        driver  => 'Rethinkdb'
        host    => 'lothal', # default localhost
        port    => 32770, # default 28015
        db_name => 'dev', # default test
    );

=head1 DESCRIPTION

This driver uses the Rethinkdb module(s) to communicate
with Rethinkdb database.

Rethinkdb is an open-source nosql database.

L<https://www.rethinkdb.com/>

=head1 AUTHOR

Dan Burke C<< dburke at addictmud.org >>

=head1 BUGS

If you encounter any bugs, or have feature requests, please create an issue
on github. https://github.com/dwburke/perl-CHI-Driver-Rethinkdb/issues

Pull requests also welcome.

=head1 LICENSE AND COPYRIGHT

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut



# Should be 127, but CHI Driver tests failed. some value in between might be ok
has '+max_key_length'   => ( default => sub { 120 } );
has db_name      => ( is => 'rw', isa => 'Str', default => sub { 'test' } );
has host         => ( is => 'rw', isa => 'Str', default => sub { 'localhost' } );
has port         => ( is => 'rw', isa => 'Int', default => sub { 28015 } );
has table_prefix => ( is => 'rw', isa => 'Str', default => sub { 'chi_' } );
has rethink_io   => ( is => 'rw', isa => 'Rethinkdb::IO', lazy => 1, builder => '_build_rethink_io' );


__PACKAGE__->meta->make_immutable;

sub _build_rethink_io {
    my $self = shift;
    
    my $io = Rethinkdb::IO->new;
    $io->host( $self->host );
    $io->port( $self->port );
    $io->default_db( $self->db_name );
    $io->connect;
    $io;
}

sub _table {
    my ($self) = @_;
    return $self->table_prefix . $self->namespace();
}


sub BUILD {
    my ( $self, $args ) = @_;

    my $response = r->db( $self->db_name )
        ->table_create( $self->_table )
        ->run($self->rethink_io);

    if ($response && $response->type > 5) {
        unless ($response->response->[0] =~ /already exists/i) {
            croak $response->response->[0]  . '(' . $response->type . ')';
        }
    }

    return;
}

sub fetch {
    my ( $self, $key ) = @_;

    my $response = r->table( $self->_table )->get( $key )->run($self->rethink_io);

    if ($response->type > 5) {
        croak $response->response->[0]  . '(' . $response->type . ')';
    }

    if (my $data = $response->response) {
        return $data->{data};
    }

}

sub store {
    my ($self, $key, $data) = @_;

    my $response = r->table( $self->_table )->get( $key )->replace({
        id => $key,
        data => $data
        })->run($self->rethink_io);
    if ($response->type > 5) {
        croak $response->response->[0]  . '(' . $response->type . ')';
    }

    return;
}

sub remove {
    my ( $self, $key ) = @_;

    my $response = r->table( $self->_table )->get( $key )->delete->run($self->rethink_io);

    if ($response->type > 5) {
        croak $response->response->[0]  . '(' . $response->type . ')';
    }

    return;
}

sub clear {
    my ($self) = @_;

    my $response = r->table( $self->_table )->delete->run($self->rethink_io);

    if ($response->type > 5) {
        croak $response->response->[0]  . '(' . $response->type . ')';
    }

    return;
}

sub get_keys {
    my ($self) = @_;

    my $response = r->table( $self->_table )->run($self->rethink_io);

    if ($response->type > 5) {
        croak $response->response->[0]  . '(' . $response->type . ')';
    }

    my @keys = map { $_->{id} } @{ $response->response };
    return @keys;
}

sub get_namespaces {
    croak 'not supported';
}

1;
