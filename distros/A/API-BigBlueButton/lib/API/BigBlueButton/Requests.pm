package API::BigBlueButton::Requests;

=head1 NAME

API::BigBlueButton::Requests - processing of API requests

=cut

use 5.008008;
use strict;
use warnings;

use Digest::SHA1 qw/ sha1_hex /;
use Carp qw/ confess /;

use constant {
    REQUIRE_CREATE_PARAMS => [ qw/ meetingID / ],
    REQUIRE_JOIN_PARAMS   => [ qw/ fullName meetingID password / ],
    REQUIRE_ISMEETINGRUNNING_PARAMS  => [ qw/ meetingID / ],
    REQUIRE_END_PARAMS    => [ qw/ meetingID password / ],
    REQUIRE_GETMEETINGINFO_PARAMS    => [ qw/ meetingID password / ],
    REQUIRE_PUBLISHRECORDINGS_PARAMS => [ qw/ recordID publish / ],
    REQUIRE_DELETERECORDINGS_PARAMS  => [ qw/ recordID / ],
    REQUIRE_SETCONFIGXML_PARAMS      => [ qw/ meetingID configXML / ],
};

our $VERSION = "0.013";

=head1 VERSION
 
version 0.013

=cut

=head1 METHODS

=over

=item B<get_version($self)>

Getting the current version of the BigBlueButton

=cut

sub get_version {
    my ( $self ) = @_;

    my $url = $self->{use_https} ? 'https://' : 'http://';
    $url .= $self->{server} . '/bigbluebutton/api';

    return $self->request( $url );
}

=item B<create($self,%params)>

Create a meeting

%params:

name
    
    This parameter is optional.
    A name for the meeting.

meetingID
    
    This parameter is mandatory.
    A meeting ID that can be used to identify this meeting by the third party application.

attendeePW

    This parameter is optional.

moderatorPW

    This parameter is optional.

welcome
    
    This parameter is optional.

dialNumber

    This parameter is optional.

voiceBridge

    This parameter is optional.

webVoice

    This parameter is optional.

logoutURL

    This parameter is optional.

record
    
    This parameter is optional.

duration

    This parameter is optional.

meta

    This parameter is optional.

redirectClient

    This parameter is optional.

clientURL

    This parameter is optional.

SEE MORE L<https://code.google.com/p/bigbluebutton/wiki/API#create>

=cut

sub create {
    my ( $self, %params ) = @_;

    my $data = $self->_generate_data( 'create', \%params );
    return $self->abstract_request( $data );
}

=item B<join($self,%params)>

Joins a user to the meeting specified in the meetingID parameter.

%params:

fullName

    This parameter is mandatory.
    The full name that is to be used to identify this user to other conference attendees.

meetingID

    This parameter is mandatory.
    The meeting ID that identifies the meeting you are attempting to join.

password

    This parameter is mandatory.
    The password that this attendee is using. If the moderator password is supplied,
    he will be given moderator status (and the same for attendee password, etc)

createTime

    This parameter is optional.

userID

    This parameter is optional.

webVoiceConf

    This parameter is optional.

configToken

    This parameter is optional.

avatarURL

    This parameter is optional.

redirectClient

    This parameter is optional.

clientURL

    This parameter is optional.

SEE MORE L<https://code.google.com/p/bigbluebutton/wiki/API#join>

=cut

sub join {
    my ( $self, %params ) = @_;

    my $data = $self->_generate_data( 'join', \%params );
    return $self->abstract_request( $data );
}

=item B<ismeetingrunning($self,%params)>

This call enables you to simply check on whether or not a meeting is running by
looking it up with your meeting ID.

%params:

meetingID

    This parameter is mandatory.
    The meeting ID that identifies the meeting you are attempting to check on.

=cut

sub ismeetingrunning {
    my ( $self, %params ) = @_;

    my $data = $self->_generate_data( 'isMeetingRunning', \%params );
    return $self->abstract_request( $data );
}

=item B<end($self,%params)>

Use this to forcibly end a meeting and kick all participants out of the meeting.

%params:

meetingID

    This parameter is mandatory.
    The meeting ID that identifies the meeting you are attempting to end.

password

    This parameter is mandatory.
    The moderator password for this meeting. You can not end a meeting using the attendee password.

=cut

sub end {
    my ( $self, %params ) = @_;

    my $data = $self->_generate_data( 'end', \%params );
    return $self->abstract_request( $data );
}

=item B<getmeetinginfo($self,%params)>

This call will return all of a meeting's information,
including the list of attendees as well as start and end times.

%params:

meetingID

    This parameter is mandatory.
    The meeting ID that identifies the meeting you are attempting to check on.

password

    This parameter is mandatory.
    The moderator password for this meeting.
    You can not get the meeting information using the attendee password.

=cut

sub getmeetinginfo {
    my ( $self, %params ) = @_;

    my $data = $self->_generate_data( 'getMeetingInfo', \%params );
    return $self->abstract_request( $data );
}

=item B<getmeetings($self)>

This call will return a list of all the meetings found on this server.

=cut

sub getmeetings {
    my ( $self ) = @_;

    my $data = $self->_generate_data( 'getMeetings' );
    return $self->abstract_request( $data );
}

=item B<getrecordings($self,%params)>

Retrieves the recordings that are available for playback for a given meetingID (or set of meeting IDs).

%params:

meetingID

    This parameter is optional.

=cut

sub getrecordings {
    my ( $self, %params ) = @_;

    my $data = $self->_generate_data( 'getRecordings', \%params );
    return $self->abstract_request( $data );
}

=item B<publishrecordings($self,%params)>

Publish and unpublish recordings for a given recordID (or set of record IDs).

%params:

recordID

    This parameter is mandatory.
    A record ID for specify the recordings to apply the publish action.
    It can be a set of record IDs separated by commas.

publish

    This parameter is mandatory.
    The value for publish or unpublish the recording(s). Available values: true or false.

=cut

sub publishrecordings {
    my ( $self, %params ) = @_;

    my $data = $self->_generate_data( 'publishRecordings', \%params );
    return $self->abstract_request( $data );
}

=item B<deleterecordings($self,%params)>

Delete one or more recordings for a given recordID (or set of record IDs).

%params:

recordID

    This parameter is mandatory.
    A record ID for specify the recordings to delete.
    It can be a set of record IDs separated by commas.

=cut

sub deleterecordings {
    my ( $self, %params ) = @_;

    my $data = $self->_generate_data( 'deleteRecordings', \%params );
    return $self->abstract_request( $data );
}

=item B<getdefaultconfigxml($self)>

Retrieve the default config.xml.

SEE MORE L<https://code.google.com/p/bigbluebutton/wiki/API#getDefaultConfigXML>

=cut

sub getdefaultconfigxml {
    my ( $self ) = @_;

    my $data = $self->_generate_data( 'getDefaultConfigXML' );
    return $self->abstract_request( $data );
}

=item B<setconfigxml($self,%params)>

Associate an custom config.xml file with the current session.

%params:

meetingID

    This parameter is mandatory.
    A meetingID to an active meeting.

configXML

    This parameter is mandatory.
    A valid config.xml file

SEE MORE L<https://code.google.com/p/bigbluebutton/wiki/API#setConfigXML>

=cut

sub setconfigxml {
    my ( $self, %params ) = @_;

    my $data = $self->_generate_data( 'setConfigXML', \%params );
    return $self->abstract_request( $data );
}

=item B<generate_checksum($self,$request,$params)>

Create a checksum for the query

$request

    Name of query, e.g. 'create' or 'join'

$params:

    Query parameters

    my $chksum = $self->generate_checksum( 'create', \%params );

=cut

sub generate_checksum {
    my ( $self, $request, $params ) = @_;

    my $string = $request;
    $string .= $self->generate_url_query( $params ) if ( $params && ref $params );
    $string .= $self->{secret};

    return sha1_hex( $string );
}

=item B<generate_url_query($self,$params)>

Creating a query string

$params:

    Query parameters

    $params{checksum} = $self->generate_checksum( 'create', \%params );
    $params{request}  = 'create';
    my $url = $self->generate_url_query( \%params );

=cut

sub generate_url_query {
    my ( $self, $params ) = @_;

    my $string = CORE::join( '&', map { "$_=$params->{$_}" } sort keys %{ $params } );

    return $string;
}

sub _generate_data {
    my ( $self, $request, $params ) = @_;

    $self->_check_params( $request, $params ) if $params;
    $params->{checksum} = $self->generate_checksum( $request, $params );
    $params->{request}  = $request;

    return $params;
}

sub _check_params {
    my ( $self, $request, $params ) = @_;

    my $const = 'REQUIRE_' . uc $request . '_PARAMS';
    return unless $self->can( $const );

    for my $req_param ( @{ $self->$const } ) {
        confess "Parameter $req_param required!" unless $params->{ $req_param };
    }

    return 1;
}

=back

=head1 SEE ALSO

L<API::BigBlueButton>

L<API::BigBlueButton::Response>

L<BigBlueButton API|https://code.google.com/p/bigbluebutton/wiki/API>

=head1 AUTHOR

Alexander Ruzhnikov E<lt>a.ruzhnikov@reg.ruE<gt>

=cut

1;