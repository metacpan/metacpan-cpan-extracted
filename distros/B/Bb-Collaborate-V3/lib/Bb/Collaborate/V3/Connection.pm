package Bb::Collaborate::V3::Connection;
use warnings; use strict;

use Bb::Collaborate::V3;
use Class::Accessor;
use Class::Data::Inheritable;
use Scalar::Util;

use SOAP::Lite;
use MIME::Base64;

use Carp;
use YAML::Syck;

use parent qw{Elive::Connection};

use Elive;
use Elive::Util;

=head1 NAME

Bb::Collaborate::V3::Connection -  Manage Collaborate SOAP V3 endpoint connections.

=head1 DESCRIPTION

This module handles logical connections to the C<.../webservice.event> endpoint
on the Collaborate server. This endpoint implements the Standard Bridge API.

=cut

our %KnownCommands = (

    BuildRecordingUrl => 'r',
    BuildSessionUrl => 'r',

    ClearSessionChairList => 'u',
    ClearSessionNonChairList => 'u',

    ConvertRecording => 'r',

    GetQuotaLimits => 'r',
    GetSchedulingManager => 'r',
    GetServerConfiguration => 'r',
    GetServerVersions => 'r',
    GetTelephony => 'r',
    GetTelephonyLicenseInfo => 'r',
 
    ListRepositoryMultimedia => 'r',
    ListRepositoryPresentation => 'r',
    ListRecordingLong => 'r',
    ListRecordingShort => 'r',
    ListSession => 'r',
    ListSessionAttendance => 'r',
    ListSessionTelephony => 'r',
    ListSessionMultimedia => 'r',
    ListSessionPresentation => 'r',

    RemoveRepositoryMultimedia => 'd',
    RemoveRepositoryPresentation => 'd',
    RemoveSession => 'd',
    RemoveRecording => 'd',
    RemoveSessionMultimedia => 'd',
    RemoveSessionPresentation => 'd',
    RemoveSessionTelephony => 'd',

    SetApiCallbackUrl => 'r',
    SetRecordingSecureSignOn => 'r',
    SetSession => 'c',
    SetSessionMultimedia => 'u',
    SetSessionPresentation => 'u',
    SetTelephony => 'u',

    UpdateSession => 'u',
    UpdateSessionAttendees => 'u',
    UploadRepositoryMultimedia => 'c',
    UploadRepositoryPresentation => 'c',

    );

__PACKAGE__->mk_classdata(known_commands => \%KnownCommands);

#
# cache singleton records
#
__PACKAGE__->mk_accessors( qw{_scheduling_manager _server_configuration _server_versions _quota_limits
                              _telephony_license _authoriz _proxy} );

=head2 connect

    my $con = Bb::Collaborate::V3::Connection->connect('https://xx-sas.bbcollab.com/site/external/adapter/default/v3',
                                                     'user1', 'pass1', debug => 1,
    );

    my $url = $con->url;   #  'https://xx-sas.bbcollab.com/site/external/adapter/default/v3.3/webservice.event'

Establishes a SOAP connection. Retrieves the server configuration, to verify
connectivity, authentication and basic operation.

=cut

sub connect {
    my ($class, $url, $user, $pass, %opt) = @_;

    die "url $url does not contain the string: 'v3'"
	unless $url =~ 'v3';

    my $self = $class->SUPER::_connect($url, $user, $pass, %opt);
    bless $self, $class;

    $self->scheduling_manager
	if $opt{ping};

    return $self;
}

=head2 disconnect

Closes a connection and frees any resources related to the connection.

=cut

sub disconnect {
    my $self = shift;

    $self->SUPER::disconnect;

    $self->_scheduling_manager(undef);
    $self->_server_configuration(undef);
    $self->_server_versions(undef);

    return;
}

=head2 call

    my $som = $self->call( $cmd, %params );

Performs a Collaborate SOAP method call. Returns the response as a
SOAP::SOM object.

=cut

=head2 soap

    my $soap_lite_obj = $connection->soap;

Returns the underlying L<SOAP::Lite> object for the connection.

=cut

sub soap {
    my ($self) = shift;

    my $soap = $self->_soap;

    unless ($soap) {

	my $debug = $self->debug;

	SOAP::Lite::import($debug >= 3
			   ? (+trace => 'debug')
			   : ()
	    );

	my $proxy = $self->url;
	warn "connecting to ".$proxy
	    if ($debug);

	$soap = SOAP::Lite->new();
	$soap->ns( "http://schemas.xmlsoap.org/soap/envelope" => "soapenv");
	$soap->ns( "http://sas.elluminate.com/" => "sas");

	my %proxy_opts;

	$self->_proxy($proxy);
	$soap->proxy($proxy);
	#
	# authentication adapted from www.perlmonks.org/index.pl?node_id=657873
	#
	my $authoriz = 'Basic '.MIME::Base64::encode_base64($self->user.':'.$self->pass);
	$self->_authoriz( $authoriz );

	$soap->transport->http_request->headers->push_header(Authorization => $authoriz);

	$self->_soap($soap);
    }

    return $soap;
}

=head2 scheduling_manager

Returns the scheduling manager for this connection (see L<Bb::Collaborate::V3::SchedulingManager>).

=cut

sub scheduling_manager {
    my $self = shift;

    my $scheduling_manager = $self->_scheduling_manager;

    unless ($scheduling_manager) {

	require Bb::Collaborate::V3::SchedulingManager;

	$scheduling_manager = Bb::Collaborate::V3::SchedulingManager->get(connection => $self);
	$self->_scheduling_manager($scheduling_manager);
    }

    return $scheduling_manager;
}

=head2 server_configuration

Returns the server configuration for this connection (see L<Bb::Collaborate::V3::Server::Configuration>).

=cut

sub server_configuration {
    my $self = shift;

    my $server_configuration = $self->_server_configuration;

    unless ($server_configuration) {

	require Bb::Collaborate::V3::Server::Configuration;

	$server_configuration = Bb::Collaborate::V3::Server::Configuration->list(connection => $self);
	$self->_server_configuration($server_configuration);
    }

    return wantarray ? @$server_configuration: $server_configuration->[0];
}

=head2 server_versions

Returns the server versions for this connection (see L<Bb::Collaborate::V3::Server::Version>).

=cut

sub server_versions {
    my $self = shift;

    my $server_versions = $self->_server_versions;

    unless ($server_versions) {

	require Bb::Collaborate::V3::Server::Version;

	$server_versions = Bb::Collaborate::V3::Server::Version->list(connection => $self);
	$self->_server_versions($server_versions);
    }

    return wantarray ? @$server_versions : $server_versions->[0];
}

=head2 quota_limits

Returns a list of available quotas and current usages.

=cut

sub quota_limits {
    my $self = shift;

    my $quota_limits = $self->_quota_limits;

    unless ($quota_limits) {

	require Bb::Collaborate::V3::Server::QuotaLimits;

	$quota_limits = Bb::Collaborate::V3::Server::QuotaLimits->list(connection => $self);
	$self->_quota_limits($quota_limits);
    }

    return wantarray ? @$quota_limits : $quota_limits;
}

=head2 telephony_license

Returns the servers's telephony license, as a string. One of:

=over 4

=item (*) thirdParty - You must use your own teleconference
provider. You must manually configure the teleconference connection information.

=item (*) integrated - The teleconference service is provided
by Blackboard Collaborate. Teleconference phone
numbers and PINs are automatically generated
during session creation and anyone in the session can
initiate the connection between the session and the
teleconference by simply dialing in to the
teleconference.

=item (*) none - No teleconferencing is supported.

=back

=cut

sub telephony_license {
    my $self = shift;

    my $telephony_license = $self->_telephony_license;

    unless ($telephony_license) {
	my $som = $self->call('GetTelephonyLicenseInfo');
	my $results = Bb::Collaborate::V3->_get_results( $som, $self );

	$telephony_license = @$results && $results->[0];
	$self->_telephony_license( $telephony_license );
    }

    return $telephony_license;
}

sub _preamble {
    my ($self, $cmd) = @_;

    die "Not logged in"
	unless ($self->user);

    my @preamble = (
    );

    push (@preamble, SOAP::Data->prefix('sas')->name($cmd))
	if $cmd;

    return @preamble;
};

=head2 version

Equivalent to C<$self-E<gt>server_versions-E<gt>versionName>.

=cut

sub version {
    return (my $self = shift)->server_versions->versionName;
}

=head2 url

Return the SOAP end-point URL.

=cut

sub url {
    my $self = shift;
    return $self->SUPER::url(@_) . '/v3/webservice.event';
}

sub _check_for_errors {
    my $class = shift;
    my $som = shift;

    croak "No response from server"
	unless $som;

    $class->SUPER::_check_for_errors( $som );

    my $body = $som->body;

    if ( Elive::Util::_reftype( $body ) eq 'HASH'
	 && (my $error_resp = $body->{DefaultAdapterErrorResponse}))  {

	unless (Elive::Util::_reftype( $error_resp ) eq 'HASH') {
	    Carp::cluck ("Unexpected response: ". YAML::Syck::Dump($body));
	    croak "error parsing DefaultAdapterErrorResponse";
	}

	my $command = $error_resp->{command};
	my $message = $error_resp->{message};
	my $success = $error_resp->{success};

	my $msg = join(': ', grep {$_} ($command, $message));

	if ($success) {
	    Carp::carp $msg
	}
	else {
	    Carp::croak $msg
	}
    }

    return;
}

1;
