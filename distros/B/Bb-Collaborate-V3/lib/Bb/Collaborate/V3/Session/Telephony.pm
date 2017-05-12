package Bb::Collaborate::V3::Session::Telephony;
use warnings; use strict;

use Mouse;

extends 'Bb::Collaborate::V3';

use Scalar::Util;
use Carp;

use Elive::Util;

=head1 NAME

Bb::Collaborate::V3::Session::Telephony - Session Telephony instance class

=head1 DESCRIPTION

This class is used to setup telephony information for an existing session

=cut

__PACKAGE__->entity_name('Telephony');

=head1 PROPERTIES

=head2 sessionId (Int)

The identifier of the session.

=cut

has 'sessionId' => (is => 'rw', isa => 'Int', required => 1);
__PACKAGE__->_isa('Session');
__PACKAGE__->primary_key('sessionId');

=head2 telephonyType (Str)

The type of telephony to configure.

=over 4

=item thirdParty - You are using your own teleconference provider. You
must manually configure the teleconference connection information.

=item integrated - The teleconference service is provided by
Blackboard Collaborate.  Teleconference phone numbers and PINs are
automatically generated during session creation and anyone in the
session can initiate the connection between the session and the
teleconference by simply dialing in to the teleconference.

=item none - Telephony is disabled for this session.

=back

=cut

has 'telephonyType' => (is => 'rw', isa => 'Str',
                        documentation => 'The type of telephony to configure.',
    );

=head2 chairPhone (Str)

The phone number for the session chair (also known as a session moderator) when the session is running.

=cut

has 'chairPhone' => (is => 'rw', isa => 'Str',
		     documentation => 'The phone number for the session chair'
    );

=head2 chairPIN (Str)

The PIN for the chairPhone.

=cut

has 'chairPIN' => (is => 'rw', isa => 'Str',
		   documentation => 'The PIN for the chairPhone'
    );

=head2 nonChairPhone (Str)

The phone number used by the session non-chair users (also known as a session participants). The information is for display purposes only in the session (so participants know what telephone number and PIN to use to connect to the teleconference).

=cut

has 'nonChairPhone' => (is => 'rw', isa => 'Str',
		     documentation => 'The phone number for the non-chair participants'
    );

=head2 nonChairPIN (Str)

The PIN for the nonChairPhone.

=cut

has 'nonChairPIN' => (is => 'rw', isa => 'Str',
		      documentation => 'The PIN for the nonChairPhone participants'
    );

=head2 isPhone (Bool)

Used to indicate if the C<sessionSIPPhone> field should be validated as a Session Initiation Protocol (SIP) or phone number.

=cut

has 'isPhone' => (is => 'rw', isa => 'Bool',
		  documentation => 'true if a simple phone, false if also using Session Initiation Protocol (SIP)?',
    );


=head2 sessionSIPPhone (Str)

The Session Initiation Protocol (SIP) or phone number used by the session. Sometimes referred to as the session bridge or teleconference bridge.
For accepted phone number and SIP formats, see Notes About Session Telephony Validation on page 67.

=cut

has 'sessionSIPPhone' => (is => 'rw', isa => 'Str',
		     documentation => 'The phone number used by SIP participants'
    );

=head2 sessionPIN (Str)

The PIN for the C<sessionSIPPhone>.

=cut

has 'sessionPIN' => (is => 'rw', isa => 'Str',
		      documentation => 'The PIN number for SIP participants',
    );


=head1 METHODS

=cut

=head2 update

    my $session_telephony = $session->telephony;

    my %telephony_data = (
	chairPhone => '(03) 5999 1234',
	chairPIN   => '6342',
	nonChairPhone => '(03) 5999 2234',
	nonChairPIN   => '7722',
	isPhone => '1',
	sessionSIPPhone => '(03) 6999 2222',
	sessionPIN => '1234',
	);

    $session_telephony->update(\%telephony_data);

Updates a session's telephony characteristics.

=cut

# custom unpacker for GetTelephonyResponse

sub _get_results {
    my $class = shift;
    my $som = shift;
    my $connection = shift;

    $connection->_check_for_errors($som);

    my $resp = $som->body->{GetTelephonyResponse} || $som->body->{SetTelephonyResponse};

    if ($resp) {

        my %rec = %{ $resp };
        my $items = delete $rec{TelephonyResponseItem};
        my $is_phone = 0;

        if ($items) {
            my $types = {moderator => 'chair', participant => 'nonChair', serverSIP => 'session', serverPhone => 'session'};

	    for (@$items) {
                my %item = %$_;
                $is_phone = 1 if $item{itemType} eq 'serverPhone';

                my $type = $types->{ delete $item{itemType} };
                unless ($type) {
		    require YAML::Syck; my $item_yaml = YAML::Syck::Dump($_);
		    warn "skipping telephony item: $item_yaml";
		    next;
                }

		$rec{$type . 'PIN'} = delete $item{pin} if $item{pin};
                $type .= 'SIP' if $type eq 'session';
		$rec{$type . 'Phone'} = delete $item{uri} if $item{uri};

                if (%item) {
		    require YAML::Syck; my $item_yaml = YAML::Syck::Dump(\%item);
		    warn "unprocessed telephony item data: $item_yaml";
                }
	    }
        }

	$rec{isPhone} = $is_phone;

        return [ \%rec ]
    }

    warn "problems unpacking Telephony response";
    return $class->SUPER::_get_results( $som, $connection );
}

sub update {
    my $self = shift;
    my $updates = shift;
    my %opt = @_;

    # include the entire record
    my @properties = grep { defined $self->$_ } ($self->properties);

    return $self->SUPER::update($updates, %opt, changed => \@properties);
}

1;
