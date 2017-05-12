package Business::CyberSource::Client;
use 5.010;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
with 'MooseY::RemoteHelper::Role::Client';

use Type::Utils                   qw( duck_type      );
use Type::Params                  qw( compile Invocant );
use MooseX::Types::Common::String qw( NonEmptyStr NonEmptySimpleStr );

use Config;
use Module::Runtime qw( use_module );
use Module::Load    qw( load       );

use XML::Compile::SOAP::WSS 1.04;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;
use File::ShareDir::ProjectDistDir 1.000
	dist_file => defaults => {  strict => 1 };

our @CARP_NOT = ( __PACKAGE__, qw( Class::MOP::Method::Wrapped ) );

sub submit { ## no critic ( Subroutines::RequireArgUnpacking )
	state $check = compile( Invocant, duck_type(['serialize']));
	my ( $self, $request ) = $check->( @_ );

	if ( $self->has_rules && ! $self->rules_is_empty ) {
		my $result;
		RULE: foreach my $rule ( @{ $self->_rules } ) {
			$result = $rule->run( $request );
			last RULE if defined $result;
		}
		return $self->_response_factory->create( $result, $request )
			if defined $result
			;
	}

	my %request = (
		merchantID            => $self->user,
		clientEnvironment     => $self->env,
		clientLibrary         => $self->name,
		clientLibraryVersion  => $self->version,
		%{ $request->serialize },
	);

	if ( $self->debug >= 1 ) {
		load 'Carp';
		load 'Data::Printer', alias => 'Dumper';

		Carp::carp( 'REQUEST HASH: ' . Dumper( \%request ) );
	}

	my ( $answer, $trace ) = $self->_soap_client->( %request );

	if ( $self->debug >= 2 ) {
		Carp::carp "\n> " . $trace->request->as_string;
		Carp::carp "\n< " . $trace->response->as_string;
	}

	$request->_http_trace( $trace );

	if ( $answer->{Fault} ) {
		die ## no critic ( ErrorHandling::RequireCarping )
			use_module('Business::CyberSource::Exception::SOAPFault')
			->new( $answer->{Fault} );
	}

	if ( $self->debug >= 1 ) {
		Carp::carp( 'RESPONSE HASH: ' . Dumper( $answer ) );
	}

	return $self->_response_factory->create( $answer->{result}, $request );
}

sub _build_soap_client {
	my $self = shift;
	# order in this subroutine matters changing it may break stuff

	my $wss = XML::Compile::SOAP::WSS->new( version => '1.1' );

	my $wsdl = XML::Compile::WSDL11->new( $self->cybs_wsdl );
	$wsdl->importDefinitions( $self->cybs_xsd );

	$wss->basicAuth(
		username => $self->user,
		password => $self->pass,
	);

	my $call = $wsdl->compileClient('runTransaction');

	return $call;
}

sub _build_cybs_wsdl {
	my $self = shift;

	my $dir = $self->test ? 'test' : 'production';

	return dist_file(
			'Business-CyberSource',
			$dir
			. '/'
			. 'CyberSourceTransaction_'
			. $self->_version_for_filename
			. '.wsdl'
		);
}

sub _build_cybs_xsd {
	my $self = shift;

	my $dir = $self->test ? 'test' : 'production';

	return dist_file(
			'Business-CyberSource',
			$dir
			. '/'
			. 'CyberSourceTransaction_'
			. $self->_version_for_filename
			. '.xsd'
		);
}

sub _build__rules {
	my $self = shift;

	return [] if ! $self->has_rules || $self->rules_is_empty;

	my @rules
		= map {
			$self->_rule_factory->create( $_, { client => $self } ) if defined $_
		} $self->list_rules;

	return \@rules;
}

sub _version_for_filename {
	my $self = shift;
	my $version = $self->cybs_api_version;
	$version =~ s/\./_/xms;
	return $version;
}

has _soap_client => (
	isa      => 'CodeRef',
	is       => 'ro',
	lazy     => 1,
	init_arg => undef,
	builder  => '_build_soap_client',
);

has _response_factory => (
	isa      => 'Object',
	is       => 'ro',
	lazy     => 1,
	default  => sub {
		return
			use_module('Business::CyberSource::Factory::Response')
			->new;
	},
);

has _rule_factory => (
	isa      => 'Object',
	is       => 'ro',
	lazy     => 1,
	default  => sub {
		return use_module('Business::CyberSource::Factory::Rule')->new;
	},
);

has rules => (
	isa       => 'ArrayRef[Str]',
	predicate => 'has_rules',
	traits    => ['Array'],
	is        => 'ro',
	reader    => undef,
	default   => sub { [qw( ExpiredCard RequestIDisZero )] },
	handles   => {
		list_rules     => 'elements',
		rules_is_empty => 'is_empty',
	},
);

has _rules => (
	isa        => 'ArrayRef[Object]',
	is         => 'ro',
	lazy_build => 1,
	traits     => ['Array'],
);

has version => (
	required => 0,
	lazy     => 1,
	init_arg => undef,
	is       => 'ro',
	isa      => 'Str',
	default  => sub {
		my $version
			= $Business::CyberSource::VERSION ? $Business::CyberSource::VERSION
			                                  : '0'
			;
		return $version;
	},
);

has name => (
	required => 0,
	lazy     => 1,
	init_arg => undef,
	is       => 'ro',
	isa      => 'Str',
	default  => sub { return 'Business::CyberSource' },
);

has env => (
	required => 0,
	lazy     => 1,
	init_arg => undef,
	is       => 'ro',
	isa      => 'Str',
	default  => sub {
		return "Perl $Config{version} $Config{osname} $Config{osvers} $Config{archname}";
	},
);

has cybs_api_version => (
	required => 0,
	lazy     => 1,
	is       => 'ro',
	isa      => 'Str',
	default  => '1.71',
);

has cybs_wsdl => (
	lazy      => 1,
	is        => 'ro',
	isa       => 'Str',
	builder   => '_build_cybs_wsdl',
);

has cybs_xsd => (
	lazy     => 1,
	is       => 'ro',
	isa      => 'Str',
	builder  => '_build_cybs_xsd',
);


__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: User Agent Responsible for transmitting the Response

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Client - User Agent Responsible for transmitting the Response

=head1 VERSION

version 0.010008

=head1 SYNOPSIS

	use Business::CyberSource::Client;

	my $request = 'Some Business::CyberSource::Request Object';

	my $client = Business::CyberSource::Request->new({
		user => 'Merchant ID',
		pass => 'API KEY',
		test => 1,
	});

	my $response = $client->run_transaction( $request );

=head1 DESCRIPTION

A service object that is meant to provide a way to run the requested
transactions.

=head1 WITH

L<MooseY::RemoteHelper::Role::Client>

=head1 METHODS

=head2 submit

	my $response = $client->submit( $request );

Takes a L<Business::CyberSource::Request> subclass as a parameter and returns
a L<Business::CyberSource::Response>

=head1 ATTRIBUTES

=head2 user

CyberSource Merchant ID

=head2 pass

CyberSource API KEY

=head2 test

Boolean value when false your requests will go to the live server, when
true they will go to the testing server.

=head2 debug

Integer value that causes the HTTP request/response to be output to STDOUT
when a transaction is run. defaults to value of the environment variable

=over

=item value 0

no output (default)

=item value 1

request/response hashref

=item value 2

1 plus actual HTTP and XML

=back

=head2 rules

ArrayRef of L<Rule Names|Business::CyberSource::Rule>. Rules names are modules
prefixed by L<Business::CyberSource::Rule>. By default both
L<Business::CyberSource::Rule::ExpiredCard> and
L<Business::CyberSource::Rule::RequestIDisZero> are included. If you decide to
add more rules remember to add C<qw( ExpiredCard RequestIDisZero )> to the
new ArrayRef ( if you want them ).

=head2 name

Client Name defaults to L<Business::CyberSource>

=head2 version

Client Version defaults to the version of this library

=head2 env

defaults to specific parts of perl's config hash

=head2 cybs_wsdl

A L<Path::Class::File> to the WSDL definition file

=head2 cybs_xsd

A L<Path::Class::File> to the XSD definition file

=head2 cybs_api_version

CyberSource API version, currently 1.71

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hostgator/business-cybersource/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Caleb Cushing <xenoterracide@gmail.com>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
