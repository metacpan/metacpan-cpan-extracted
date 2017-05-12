package CHI::Driver::MongoDB;
# vim:syntax=perl:tabstop=4:number:noexpandtab:
$CHI::Driver::MongoDB::VERSION = '0.0001';
# ABSTRACT: MongoDB driver for CHI

use Moo;
use MongoDB;
use URI::Escape::XS;
use Try::Tiny;
use Time::Moment;

use strict;
use warnings;

extends 'CHI::Driver';

has 'mongodb' => (
	is       => 'ro',
	lazy     => 1,
	init_arg => undef,
	builder  => '_build_mongodb',
);

has 'mongodb_options' => (
	is      => 'rw',
	default => sub { {} },
);

has 'connection_uri' => (
	is      => 'ro',
	lazy    => 1,
	default => sub { 'mongodb://127.0.0.1:27017' },
);

has 'db_name' => (
	is      => 'ro',
	lazy    => 1,
	default => sub {'_CHI_'},
);

has '_coll' => (
	is        => 'rw',
	lazy      => 1,
	predicate => 1,
	init_arg  => undef,
	builder   => '_build_coll',
	clearer   => 1,
);


sub BUILD {
	my ( $self, $params ) = @_;
	foreach my $param (qw/ mongodb_options connection_uri db_name /) {
		if ( exists $params->{$param} ) {
			delete $params->{$param};
		}
	}
	my $codec = MongoDB::BSON->new( dt_type => 'Time::Moment' );

	my %options = (
		bson_codec => $codec,
		%{ $self->mongodb_options() },
		%{ $self->non_common_constructor_params($params) },
	);
	$self->mongodb_options( \%options );
}


sub _build_mongodb {
	my $self = shift;

	my %opts = %{ $self->mongodb_options() };
	my $uri  = $self->connection_uri;

	return MongoDB->connect( $uri, \%opts );
}


sub _build_coll {
	my $self = shift;

	my $ns = sprintf( "%s.%s", $self->db_name, encodeURIComponent( $self->namespace ) );

	my $coll = $self->mongodb->get_namespace($ns);

	if ( $self->expires_on_backend ) {
		$coll->indexes->create_one( [ expireAt => 1 ], { expireAfterSeconds => 0 } );
	}

	return $coll;
}


sub fetch {
	my ( $self, $key ) = @_;

	$key = encodeURIComponent($key);
	my $doc = $self->_coll->find_id( $key, { payload => 1 } );

	return "" . $doc->{'payload'} if defined($doc) and ref($doc) eq 'HASH';
	return undef;
}


sub fetch_multi_hashref {
	my ( $self, $keys ) = @_;

	my @esc = map { encodeURIComponent($_) } @{$keys};
	my $qresult = $self->_coll->find(
		{ _id => { '$in' => \@esc } },
		{
			batchSize  => 100,
			projection => {
				_id     => 1,
				payload => 1
			}
		}
	)->result;

	my %ret = ();
	while ( my @batch = $qresult->batch ) {
		map { my $k = decodeURIComponent( $_->{'_id'} ); $ret{$k} = "" . $_->{'payload'} } @batch;
	}

	return \%ret;
}


sub store {
	my ( $self, $key, $data, $expires_in ) = @_;

	$key = encodeURIComponent($key);
	my $doc = {
		_id     => $key,
		payload => MongoDB::BSON::Binary->new( data => $data ),
	};
	if ( defined $expires_in ) {
		$doc->{'expireAt'} = Time::Moment->from_epoch( time() + $expires_in );
	}
	my $result = $self->_coll->update_one( { _id => $key }, { '$set' => $doc }, { upsert => 1 } );

	warn "update_one() operation failed: unexpected result"
		unless ref($result) eq 'MongoDB::UnacknowledgedResult'
		or ref($result) eq 'MongoDB::UpdateResult';
	try {
		$result->assert if $result->acknowledged;
	}
	catch {
		warn "update_one() operation failed: deletion not asserted";
	};

	return undef;
} ## end sub store

# TODO
#sub store_multi {
#	my ( $self, $key_data, $options ) = @_;
#}


sub remove {
	my ( $self, $key ) = @_;

	$key = encodeURIComponent($key);
	my $result = $self->_coll->delete_one( { _id => $key } );

	warn "delete_one() operation failed: unexpected result"
		unless ref($result) eq 'MongoDB::UnacknowledgedResult'
		or ref($result) eq 'MongoDB::DeleteResult';
	try {
		$result->assert if $result->acknowledged;
	}
	catch {
		warn "delete_one() operation failed: deletion not asserted";
	};

	return undef;
}


sub clear {
	my ($self) = @_;

	my $coll = $self->_coll;
	$self->_clear_coll;
	$coll->drop;

	return undef;
}


sub get_keys {
	my ($self) = @_;

	my @allKeys = ();
	my $qresult = $self->_coll->find(
		{},
		{
			batchSize  => 100,
			projection => { _id => 1 }
		}
	)->result;
	while ( my @batch = $qresult->batch ) {
		push @allKeys, map { decodeURIComponent( $_->{'_id'} ) } @batch;
	}
	return @allKeys;
}


sub get_namespaces {
	my $self = shift;
	return $self->mongodb->get_database( $self->db_name )->collection_names;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

CHI::Driver::MongoDB - MongoDB driver for CHI

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use CHI;
 
    my $cache = CHI->new (
        driver          => 'MongoDB',
        namespace       => 'foo',
        # optional, default: _CHI_
        db_name         => '...',
        # optional, default: mongodb://127.0.0.1:27017
        connection_uri  => '...',
        # optional
        mongodb_options => { ... },
    );

=head1 DESCRIPTION

Driver to use L<MongoDB> as storage back end for L<CHI>.

L<CHI> C<namespace>s are translated to L<MongoDB> collections, so you 
can use the same database name for all CHI instances (or simply use 
the default and omit the parameter).

The driver supports the C<expires_on_backend> option, but be aware that
the expiration actually happens within a short but unspecified time 
frame B<after> the exact expiration timeout (cf. L</"FAILING TESTS">).

By default the MongoDB server is expected to be available on localhost,
port 27017. Pass the C<connection_uri> param to override this.
For testing purposes, set the C<MONGODB_CONNECTION_URI> environment
variable.

=head1 WARNING

This module is currently considered to be a B<beta release>.

While the (mostly) succeeding test suite shows that there probably
are no major issues endangering your data it has only been tested
with MongoDB 3.2.x and the MongoDB Perl module v1.4.5.

Please open a bug report on L<https://rt.perl.org/> or send me a
mail if you encounter any problems.

=head1 CONSTRUCTOR OPTIONS

=over 4

=item C<connection_uri>: String

Where the MongoDB server is listening. By default, 
C<mongodb://127.0.0.1:27017> is used.

See L<MongoDB::MongoClient/"CONNECTION-STRING-URI"> for details.

=item C<db_name>: String

The database name inside MongoDB. Defaults to C<_CHI_>.
The name is arbitrary but should of course not clash with your other
databases.

=item C<mongodb_options>: HASHREF

Arbitrary options which are passed to the constructor of the underlying
L<MongoDB::MongoClient> object.

=back

=head1 FAILING TESTS

Currently, you should expect four failing tests from the CHI test suite:
94, 205-206, 904.

=over 4

=item B<94>: C<Failed test 'threw Regexp ((?^:discard timeout .* reached))'>

I do not know yet, why the test functions succeeds while it is supposed
to C<die>.

=item B<205>: C<Failed test 'cannot get_object(key0) after expire'>

=item B<206>: C<Failed test 'cannot get_object(key1) after expire'>

MongoDB uses a dedicated thread to remove documents whose lifetime has
expired. It checks the stored documents periodically but that means
there is a short period of time between the moment a document expires
and the moment it is actually removed.
This should be no problem for our caching purposes but is the reason
why these tests fail.

=item B<904> C<Failed test 'test_serializers died (Insecure dependency in eval while running with -T switch...>

No idea yet what is wrong here.

=back

Fixing the second and third failing test may not be possible at all,
but I haven't yet found a way to disable indiviual tests.

Other than these four, 944 subtests succeed while 67 are skipped.

I have seen test runs where for some unknown reason a large number of
tests fail. I do not know why that happens. The MongoDB database is
dropped and recreated on every run of the test suite.
On simply re-running the whole test usually only the four tests shown
above fail.

=head1 TODO

In no particular order:

=over 4

=item Allow passing in a preconfigured L<MongoDB> object.

=item Allow using L<Mango> instead of L<MongoDB>.

=item Implement C<store_multi ( $key_data, $options )> method.

=item Implement LRU discard policy.

=item Implement support for size awareness in the back end.

B<Caveat>: As of version 3.2 MongoDB supports collections that either
have a finite size (in bytes or in number of stored documents) or 
support the automatic expiration handling but not both!

=back

=head1 SEE ALSO

L<CHI>, L<CHI::Driver::Development>, L<MongoDB>

=head1 AUTHOR

Heiko Jansen <hjansen@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Heiko Jansen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
