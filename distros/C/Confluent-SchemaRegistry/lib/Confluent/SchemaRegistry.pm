package Confluent::SchemaRegistry;

=head1 NAME

Confluent::SchemaRegistry - A simple client for interacting with B<Confluent Schema Registry>.

=head1 SYNOPSIS

 use Confluent::SchemaRegistry;

 my $sr = Confluent::SchemaRegistry->new( { host => 'https://my-schema-registry.org' } );

=head1 DESCRIPTION

C<Confluent::SchemaRegistry> provides a simple way to interact with B<Confluent Schema Registry>
(L<https://docs.confluent.io/current/schema-registry/docs/index.html>) enabling writing into
B<Apache Kafka> (L<https://kafka.apache.org/>) according to I<Apache Avro> schema specification
(L<https://avro.apache.org/>).

=head2 HEAD UP

=over 4

=item Confluent Schema Registry documentation

Full RESTful API documentation of B<Schema Registry> is available here: 
L<https://docs.confluent.io/current/schema-registry/docs/api.html?_ga=2.234767710.1188695207.1526911788-1213051144.1524553242#>

=item Avro package

B<Avro> package is a dependency of I<Confluent::SchemaRegistry> but is not available in CPAN index.
Perhaps you may find and download it directly from GitHub repository at L<https://github.com/apache/avro/tree/master/lang/perl>.
Please, refer its documentation for installation.

=back


=cut

use 5.010;
use strict;
use warnings;

use JSON::XS;
use REST::Client;
use HTTP::Status qw/:is/;
use Try::Tiny;
use Aspect;
use Avro::Schema;


use version 0.77; our $VERSION = version->declare('v1.0.0');

our $COMPATIBILITY_LEVELS = [ qw/NONE FULL FORWARD BACKWARD/ ];


=head1 INSTALL

Installation of C<Kafka::Consumer::Avro> is a canonical:

  perl Makefile.PL
  make
  make test
  make install

=head2 TEST NOTES

Tests expect that in the target host is available Schema Registry listening on C<http://localhost:8081>, otherwise most of the test are skipped.

You can alternatively set a different URL by exporting C<CONFLUENT_SCHEMA_REGISTY_URL> environment variable.

=head1 USAGE

=head2 Constructor

=head3 new( [%config] )

Construct a new C<Confluent::SchemaRegistry>. Takes an optional hash that provides
configuration flags for the L<REST::Client> internal object.

The config flags, according to C<REST::Client::new> specs, are:

=over 4

=item host

The host at which I<Schema Registry> is listening.

The default is L<http://localhost:8081>

=item timeout

A timeout in seconds for requests made with the client.  After the timeout the
client will return a 500.

The default is 5 minutes.

=item cert

The path to a X509 certificate file to be used for client authentication.

The default is to not use a certificate/key pair.

=item key

The path to a X509 key file to be used for client authentication.

The default is to not use a certificate/key pair.

=item ca

The path to a certificate authority file to be used to verify host
certificates.

The default is to not use a certificates authority.

=item pkcs12

The path to a PKCS12 certificate to be used for client authentication.

=item pkcs12password

The password for the PKCS12 certificate specified with 'pkcs12'.

=item follow

Boolean that determins whether REST::Client attempts to automatically follow
redirects/authentication.

The default is false.

=item useragent

An L<LWP::UserAgent> object, ready to make http requests.

REST::Client will provide a default for you if you do not set this.

=back

=cut

sub new {
    my $this  = shift;
    my $class = ref($this) || $this;
	my %config = @_;
	my $self = {};

	# Creazione client REST
	$config{host} = 'http://localhost:8081' unless defined $config{host};
	$self->{_CLIENT} = REST::Client->new( %config );
	$self->{_CLIENT}->addHeader('Content-Type', 'application/vnd.schemaregistry.v1+json');
	$self->{_CLIENT}->{_ERROR}    = undef; # will be set in case of unsuccessfully responses
	$self->{_CLIENT}->{_RESPONSE} = undef; # will be set with normalized response contents

	$self = bless($self, $class);

	# Recupero la configurazione globale del registry per testare se le coordinate fanno
	# effettivamente riferimento ad un Confluent Schema Registry
	my $res = $self->get_top_level_config();
	return undef
		unless defined($res) && grep(/^$res$/, @$COMPATIBILITY_LEVELS);
		
	return $self;
}


#
# BEGIN Using Aspect to simplify error handling
#
my $rest_client_calls = qr/^REST::Client::(GET|PUT|POST|DELETE)/;

# Clear internal error and response before every REST::Client call
before {
	$_->self->{_RESPONSE} = undef;
	$_->self->{_ERROR} = undef;
	#print STDERR 'Calling ' . $_->sub_name . ' : ';
} call $rest_client_calls;

# Verify if REST calls are successfull 
after {
	if (is_success($_->self->responseCode())) {
		$_->self->{_RESPONSE} = _normalize_content( $_->self->responseContent() );
		$_->return_value(1); # success
	} else {
		$_->self->{_ERROR} = _normalize_content( $_->self->responseContent() );
		$_->return_value(0); # failure
	}
	#print STDERR $_->self->responseCode() . "\n";
} call $rest_client_calls;

#
# END Aspect
#



##############################################################################################
# CLASS METHODS
#

sub _normalize_content { 
	my $res = shift;
	return undef
		unless defined($res);
	return $res
		if ref($res) eq 'HASH';
	return try {
		decode_json($res);
	} catch {
		$res;
	}
} 

sub _encode_error {
	{ 
		error_code => $_[0],
		message => $_[1]
	}
}

##############################################################################################
# PRIVATE METHODS
#
 
sub _client       { $_[0]->{_CLIENT}                                      } # RESTful client
sub _set_error    { $_[0]->_client->{_ERROR} = _normalize_content($_[1]); } # get internal error
sub _get_error    { $_[0]->_client->{_ERROR}                              } # get internal error
sub _get_response { $_[0]->_client->{_RESPONSE}                           } # return http response



##############################################################################################
# PUBLIC METHODS
#
 
=head2 METHODS

C<Confluent::SchemRegistry> exposes the following methods.

=cut


=head3 get_response_content()

Returns the body (content) of the last method call to Schema Registry.

=cut

sub get_response_content { $_[0]->_get_response() }
	

=head3 get_error()

Returns the error structure of the last method call to Schema Registry.

=cut

sub get_error { $_[0]->_get_error() }
	

=head3 add_schema( %params )

Registers a new schema version under a subject.

Returns the generated id for the new schema or C<undef>.

Params keys are:

=over 4

=item SUBJECT ($scalar)

the name of the Kafka topic

=item TYPE ($scalar)

the type of schema ("key" or "value")

=item SCHEMA ($hashref or $json)

the schema to add

=back

=cut

sub add_schema {
	my $self = shift;
	my %params = @_;
	return undef
		unless	defined($params{SUBJECT})
				&& defined($params{TYPE})
				&& $params{SUBJECT} =~ m/^.+$/
				&& $params{TYPE} =~ m/^key|value$/;
	return undef
		unless	defined($params{SCHEMA});
	my $schema = _normalize_content($params{SCHEMA});
	$schema = encode_json({
		schema => encode_json($schema)
	});
	return $self->_get_response()->{id}
		if $self->_client()->POST('/subjects/' . $params{SUBJECT} . '-' . $params{TYPE} . '/versions', $schema);
	return undef;
}


# List all the registered subjects
#
# Returns the list of subjects (ARRAY) or C<undef>
sub get_subjects {
	my $self = shift;
	$self->_client()->GET('/subjects');
	return $self->_get_response();
}


# Delete a subject
#
# SUBJECT...: the name of the Kafka topic
# TYPE......: the type of schema ("key" or "value")
#
# Returns the list of versions for the deleted subject or C<undef>
sub delete_subject {
	my $self = shift;
	my %params = @_;
	return undef
		unless	defined($params{SUBJECT})
				&& defined($params{TYPE})
				&& $params{SUBJECT} =~ m/^.+$/
				&& $params{TYPE} =~ m/^key|value$/;
	$self->_client()->DELETE('/subjects/' . $params{SUBJECT} . '-' . $params{TYPE});
	return $self->_get_response()
}


# List the schema versions registered under a subject
#
# SUBJECT...: the name of the Kafka topic
# TYPE......: the type of schema ("key" or "value")
#
# Returns the list of schema versions (ARRAY)
sub get_schema_versions {
	my $self = shift;
	my %params = @_;
	return undef
		unless	defined($params{SUBJECT})
				&& defined($params{TYPE})
				&& $params{SUBJECT} =~ m/^.+$/
				&& $params{TYPE} =~ m/^key|value$/;
	$self->_client()->GET('/subjects/' . $params{SUBJECT} . '-' . $params{TYPE} . '/versions');
	return $self->_get_response();
}


# Fetch a schema by globally unique id
#
# SCHEMA_ID...: the globally unique id of the schema
#
# Returns the schema in Avro::Schema format or C<undef>
sub get_schema_by_id {
	my $self = shift;
	my %params = @_;
	return undef
		unless	defined($params{SCHEMA_ID})
				&& $params{SCHEMA_ID} =~ m/^\d+$/;
	if ( $self->_client()->GET('/schemas/ids/' . $params{SCHEMA_ID})) {
		if (exists $self->_get_response()->{schema}) {
			my $avro_schema;
			try {
				$avro_schema = Avro::Schema->parse($self->_get_response()->{schema});
			} catch {
				$self->_set_error( _encode_error(-2, $_->{'-text'}) );
			};
			return $avro_schema;
		}
	}
	return undef;
}


# Fetch a specific version of the schema registered under a subject
#
# SUBJECT...: the name of the Kafka topic
# TYPE......: the type of schema ("key" or "value")
# VERSION...: the schema version to fetch; if omitted the latest version is fetched
#
# Returns the schema in Avro::Schema format or C<undef>
sub get_schema {
	my $self = shift;
	my %params = @_;
	return undef
		unless	defined($params{SUBJECT})
				&& defined($params{TYPE})
				&& $params{SUBJECT} =~ m/^.+$/
				&& $params{TYPE} =~ m/^key|value$/;
	return undef
		if	defined($params{VERSION})
			&& $params{VERSION} !~ m/^\d+$/;
	$params{VERSION} = 'latest' unless defined($params{VERSION});
	if ($self->_client()->GET('/subjects/' . $params{SUBJECT} . '-' . $params{TYPE} . '/versions/' . $params{VERSION})) {
		my $sv = $self->_get_response();
		if (exists $sv->{schema}) {
			try {
				$sv->{schema} = Avro::Schema->parse($sv->{schema});
			} catch {
				$self->_set_error( _encode_error(-2, $_->{'-text'}) );
				return undef;
			};
		}
		return $sv;
	}
	return undef;
}


# Delete a specific version of the schema registered under a subject
#
# SUBJECT...: the name of the Kafka topic
# TYPE......: the type of schema ("key" or "value")
# VERSION...: the schema version to delete
#
# Returns the deleted version number (NUMBER) or C<undef>
sub delete_schema {
	my $self = shift;
	my %params = @_;
	return undef
		unless	defined($params{SUBJECT})
				&& defined($params{TYPE})
				&& $params{SUBJECT} =~ m/^.+$/
				&& $params{TYPE} =~ m/^key|value$/;
	return undef
		unless	defined($params{VERSION})
				&& $params{VERSION} =~ m/^\d+$/;
	$self->_client()->DELETE('/subjects/' . $params{SUBJECT} . '-' . $params{TYPE} . '/versions/' . $params{VERSION});
	return $self->_get_response();
}


# Delete all versions of the schema registered under subject "Kafka-value"
#
# SUBJECT...: the name of the Kafka topic
# TYPE......: the type of schema ("key" or "value")
#
# Returns the list of deleted versions or C<undef>
sub delete_all_schemas {
	my $self = shift;
	my %params = @_;
	return undef
		unless	defined($params{SUBJECT})
				&& defined($params{TYPE})
				&& $params{SUBJECT} =~ m/^.+$/
				&& $params{TYPE} =~ m/^key|value$/;
	$self->_client()->DELETE('/subjects/' . $params{SUBJECT} . '-' . $params{TYPE});
	return $self->_get_response();
}


# Check whether the schema $SCHEMA has been registered under subject "${SUBJECT}-${TYPE}"
#
# SUBJECT...: the name of the Kafka topic
# TYPE......: the type of schema ("key" or "value")
# SCHEMA....: the schema (HASH or JSON) to check for
#
# If found, returns the schema info (HASH) otherwise C<undef>
sub check_schema {
	my $self = shift;
	my %params = @_;
	return undef
		unless	defined($params{SUBJECT})
				&& defined($params{TYPE})
				&& $params{SUBJECT} =~ m/^.+$/
				&& $params{TYPE} =~ m/^key|value$/;
	return undef
		unless	defined($params{SCHEMA});
	my $schema = _normalize_content($params{SCHEMA});
	$schema = encode_json({
		schema => encode_json($schema)
	});
	$self->_client()->POST('/subjects/' . $params{SUBJECT} . '-' . $params{TYPE}, $schema);
	my $schema_info = $self->_get_response();
	return undef
		unless $schema_info;
	$schema_info->{schema} = Avro::Schema->parse($schema_info->{schema});
	return $schema_info;
}


# Test compatibility of the schema $SCHEMA with the version $VERSION of the schema under subject "${SUBJECT}-${TYPE}"
#
# SUBJECT...: the name of the Kafka topic
# TYPE......: the type of schema ("key" or "value")
# VERSION...: the schema version to test; if omitted latest version is used
# SCHEMA....: the schema (HASH or JSON) to check for
#
# returns TRUE if the providied schema is compatible with the latest one (BOOLEAN)
sub test_schema {
	my $self = shift;
	my %params = @_;
	return undef
		unless	defined($params{SUBJECT})
				&& defined($params{TYPE})
				&& $params{SUBJECT} =~ m/^.+$/
				&& $params{TYPE} =~ m/^key|value$/;
	return undef
		if	defined($params{VERSION})
			&& $params{VERSION} !~ m/^\d+$/;
	$params{VERSION} = 'latest' unless defined($params{VERSION});
	return undef
		unless	defined($params{SCHEMA});
	my $schema = _normalize_content($params{SCHEMA});
	$schema = {
		schema => encode_json($schema)
	};
	$self->_client()->POST('/compatibility/subjects/' . $params{SUBJECT} . '-' . $params{TYPE} . '/versions/' . $params{VERSION}, encode_json($schema));
	return undef
		unless defined $self->_get_response();
	return $self->_get_response()->{is_compatible}
		if exists($self->_get_response()->{is_compatible});
	return undef;
}


# Get top level config
#
# Return top-level compatibility level or C<undef>
sub get_top_level_config {
	my $self = shift;
	return $self->_get_response()->{compatibilityLevel}
		if $self->_client()->GET('/config');
	return undef;
}


# Update compatibility requirements globally
# $ curl -X PUT -H "Content-Type: application/vnd.schemaregistry.v1+json" \
#     --data '{"compatibility": "NONE"}' \
#     http://localhost:8081/config
#   {"compatibility":"NONE"}
sub set_top_level_config {
	my $self = shift;
	my %params = @_;
	$self->_set_error( _encode_error(-1, 'Unexpected value for COMPATIBILITY_LEVEL param') )
		and return undef
			unless	defined($params{COMPATIBILITY_LEVEL})
				&& grep(/^$params{COMPATIBILITY_LEVEL}$/, @$COMPATIBILITY_LEVELS);
	$self->_client()->PUT('/config', encode_json( { compatibility => $params{COMPATIBILITY_LEVEL} } ));
	return $self->_get_response()->{compatibility}
		if defined $self->_get_response();
	return undef;
}


# Get compatibility requirements under the subject
# 
# Return compatibility level for the subject or C<undef>
sub get_config {
	my $self = shift;
	my %params = @_;
	return undef
		unless	defined($params{SUBJECT})
				&& defined($params{TYPE})
				&& $params{SUBJECT} =~ m/^.+$/
				&& $params{TYPE} =~ m/^key|value$/;
	return $self->_get_response()->{compatibilityLevel}
		if $self->_client()->GET('/config/' . $params{SUBJECT} . '-' . $params{TYPE});
	return undef;
}

# Update compatibility requirements under the subject
# 
# Return the new compatibility level for the subject or C<undef>
sub set_config {
	my $self = shift;
	my %params = @_;
	$self->_set_error( _encode_error(-1, 'Bad SUBJECT or TYPE parameter') )
		and return undef
			unless	defined($params{SUBJECT})
					&& defined($params{TYPE})
					&& $params{SUBJECT} =~ m/^.+$/
					&& $params{TYPE} =~ m/^key|value$/;
	$self->_set_error( _encode_error(-1, 'Unexpected value for COMPATIBILITY_LEVEL param') )
		and return undef
			unless	defined($params{COMPATIBILITY_LEVEL})
				&& grep(/^$params{COMPATIBILITY_LEVEL}$/, @$COMPATIBILITY_LEVELS);
	$self->_client()->PUT('/config/' . $params{SUBJECT} . '-' . $params{TYPE}, encode_json( { compatibility => $params{COMPATIBILITY_LEVEL} } ));
	return $self->_get_response()->{compatibility}
		if defined $self->_get_response();
	return undef;
}

=head1 TODO

...

=head1 AUTHOR

Alvaro Livraghi, E<lt>alvarol@cpan.orgE<gt>

=head1 CONTRIBUTE

L<https://github.com/alivraghi/Confluent-SchemaRegistry>

=head1 BUGS

Please use GitHub project link above to report problems or contact authors.

=head1 COPYRIGHT AND LICENSE

Copyright 2018 by Alvaro Livraghi

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
