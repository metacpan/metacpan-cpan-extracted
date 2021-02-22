package Authen::NZRealMe::ResolutionResponse;
$Authen::NZRealMe::ResolutionResponse::VERSION = '1.21';
use warnings;
use strict;
use Carp      qw(croak);

use Authen::NZRealMe::CommonURIs qw(URI);


my $urn_success     = URI('saml_success');
my $urn_cancel      = URI('saml_auth_fail');
my $urn_timeout     = URI('rm_timeout');
my $urn_old_timeout = URI('gls_timeout');
my $urn_not_reg     = URI('saml_unkpncpl');


sub new {
    my $class = shift;
    my $xml   = shift;

    my $self = bless { xml => $xml }, $class;
    return $self;
}


sub xml               { return shift->{xml};                      }
sub service_type      { return shift->{service_type};             }
sub status_urn        { return shift->{status_urn};               }
sub status_message    { return shift->{status_message} || '';     }
sub is_success        { return shift->status_urn eq $urn_success; }
sub is_error          { return shift->status_urn ne $urn_success; }
sub is_timeout        { return $_[0]->status_urn eq $urn_timeout
                            || $_[0]->status_urn eq $urn_old_timeout; }
sub is_cancel         { return shift->status_urn eq $urn_cancel;  }
sub is_not_registered { return shift->status_urn eq $urn_not_reg; }
sub flt               { return shift->{flt};                      }
sub fit               { return shift->{fit};                      }
sub _icms_token       { return shift->{_icms_token_};             }
sub logon_strength    { return shift->{logon_strength};           }
sub date_of_birth     { return shift->{date_of_birth};            }
sub place_of_birth    { return shift->{place_of_birth};           }
sub country_of_birth  { return shift->{country_of_birth};         }
sub surname           { return shift->{surname};                  }
sub first_name        { return shift->{first_name};               }
sub mid_names         { return shift->{mid_names};                }
sub gender            { return shift->{gender};                   }
sub address_unit      { return shift->{address_unit};             }
sub address_street    { return shift->{address_street};           }
sub address_suburb    { return shift->{address_suburb};           }
sub address_town_city { return shift->{address_town_city};        }
sub address_postcode  { return shift->{address_postcode};         }
sub address_rural_delivery { return shift->{address_postcode};    }

sub set_status_urn {
    my $self = shift;
    $self->{status_urn} = shift or croak "No value provided to set_status_urn";
}

sub set_status_message {
    my $self = shift;
    my $msg  = shift or return;
    $self->{status_message} = $msg;
}

sub set_logon_strength {
    my $self = shift;
    $self->{logon_strength} = shift;
}

sub set_flt {
    my $self = shift;
    $self->{flt} = shift or croak "No value provided to set_flt";
}

sub set_date_of_birth {
    my($self, $dob) = @_;

    croak "Invalid Date of Birth: '$dob'" unless $dob =~ /\A\d\d\d\d-\d\d-\d\d\z/;
    $self->{date_of_birth} = $dob;
}

sub set_service_type            { $_[0]->{service_type}           = $_[1]; }
sub set_fit                     { $_[0]->{fit}                    = $_[1]; }
sub set_place_of_birth          { $_[0]->{place_of_birth}         = $_[1]; }
sub set_country_of_birth        { $_[0]->{country_of_birth}       = $_[1]; }
sub set_surname                 { $_[0]->{surname}                = $_[1]; }
sub set_first_name              { $_[0]->{first_name}             = $_[1]; }
sub set_mid_names               { $_[0]->{mid_names}              = $_[1]; }
sub set_gender                  { $_[0]->{gender}                 = $_[1]; }
sub set_address_unit            { $_[0]->{address_unit}           = $_[1]; }
sub set_address_street          { $_[0]->{address_street}         = $_[1]; }
sub set_address_suburb          { $_[0]->{address_suburb}         = $_[1]; }
sub set_address_town_city       { $_[0]->{address_town_city}      = $_[1]; }
sub set_address_postcode        { $_[0]->{address_postcode}       = $_[1]; }
sub set_address_rural_delivery  { $_[0]->{address_rural_delivery} = $_[1]; }
sub _set_icms_token             { $_[0]->{_icms_token_}           = $_[1]; }

sub address {
    my $self = shift;

    my %out;
    foreach my $key (qw(unit street suburb rural_delivery town_city postcode)) {
        if(my $value = $self->{"address_$key"}) {
            $out{$key} = $value;
        }
    }
    return keys(%out) ? \%out : undef;
}


sub as_string {
    my $self = shift;

    my @out;

    if($self->service_type eq "login") {
        push @out, "Login Service Response";
        push @out, "    status_urn: " . $self->status_urn;
        push @out, "    flt: " . $self->flt;
        push @out, "    logon_strength: " . $self->logon_strength;
    }

    if($self->service_type eq "assertion") {
        my $opaque_token = $self->_icms_token ? 'present' : 'not present';
        push @out, "Assertion Service Response";
        push @out, "    status_urn: " . $self->status_urn;
        push @out, "    fit: " . $self->fit;
        push @out, "    opaque-token: " . $opaque_token;
        if($self->{flt}) {
            push @out, "    flt: " . $self->flt;
        }
    }

    my @i_attr = grep { $self->{$_} } qw(
        surname first_name mid_names gender date_of_birth
        place_of_birth country_of_birth
    );
    if(@i_attr) {
        push @out, "Asserted Identity Attributes";
        foreach my $key (@i_attr) {
            push @out, "    $key: " . $self->{$key};
        }
    }

    my @a_attr = grep { $self->{$_} } qw(
        address_unit address_street address_rural_delivery address_suburb
        address_town_city address_postcode
    );
    if(@a_attr) {
        push @out, "Asserted Address Attributes";
        foreach my $key (@a_attr) {
            push @out, "    $key: " . $self->{$key};
        }
    }

    return join("\n", @out) . "\n";
}


1;

__END__

=head1 NAME

Authen::NZRealMe::ResolutionResponse - Encapsulates the response from the IdP to
the artifact resolution request

=head1 DESCRIPTION

This package is used by the L<Authen::NZRealMe::ServiceProvider> to represent the
response received from the Identity Provider.

The C<is_success> or C<is_error> methods can be used to determine whether the
user's logon was successful.

On success, the user's FLT can be retrieved using the C<flt> method.

On failure, the URN identifying the exact error can be determined using the
C<status_urn> method.  Convenience methods are also provided for identifying
common error codes that you might want to handle (see: C<is_cancel>,
C<is_timeout>, C<is_not_registered>).

=head1 METHODS

=head2 new

Constructor.  Should not be called directly.  Instead, call the
C<resolve_artifact> method on the service provider object.


=head2 xml

The raw XML response from the IdP.  Useful for logging and diagnostics.


=head2 service_type

Accessor for the type of service ("login" or "assertion") this response
originated from.


=head2 status_urn

The 'StatusCode' 'Value' (most specific if more than one) in the response from
the IdP.  You probably want to use the convenience methods (such as
C<is_cancel>) rather than querying this directly although in the case of errors
you will want to log this value.


=head2 status_message

In some error cases the IdP will return a human readable message relating to
the error condition.  If provided, you should include it in the error screen
you display to your users.  This routine will return an empty string if the
response contained no message.


=head2 is_success

Returns true if the artifact resolution was successful and an FLT is available.
Returns false otherwise.


=head2 is_error

Returns true if the artifact resolution was not successful.  Returns false
otherwise.


=head2 is_timeout

Returns true if the RealMe Login service timed out waiting for the user to enter
their account details.  After this error, it is safe to present the user with a
"try again" link.


=head2 is_cancel

Returns true if the user selected 'Cancel' or 'Return to agency site' rather
than logging in.  After this error, it is safe to present the user with a "try
again" link.


=head2 is_not_registered

Returns true if the logon was successful but the user's RealMe Login account
has not been associated with this service provider (agency web site).

This situation will only occur if the original authentication request specified
a false value for the C<allow_create> option.  Agency sites which use a
separate flow for the initial sign-up process will need to handle this error.


=head2 as_string

Returns a string listing all the attributes from the assertion (including the
FLT if requested).  This is useful for logging and debiugging purposes.


=head1 RESPONSE ATTRIBUTE METHODS

The following methods are available for querying attributes returned in the
response (after the artifact resolution has been completed successfully).

Note most of the attributes will only be available if they were requested
during your application's integration with the assertion service B<and> if the
user consented to those details being shared with your application.

=head2 flt

Returns the user's FLT (Federated Login Tag) - a token uniquely identifying the
relationship between the user, the login service and your application.

=head2 logon_strength

The URN indicating the logon strength returned by the Login Service IdP (not
available in responses from the assertion service).

Note: If you have specific logon strength requirements, you should specify them
using the C<logon_strength> and C<strength_match> options when calling the
service provider's C<resolve_artifact> method.

=head2 fit

Returns the user's FIT (Federated Identity Tag) - a token uniquely identifying
the relationship between the user, the assertion service and your application.

=head2 date_of_birth

Returns the user's date of birth as an ISO date string.

=head2 place_of_birth

Returns the user's place of birth as a string containing a town name.

=head2 country_of_birth

Returns the user's country of birth as a string containing a country name.

=head2 surname

Returns the user's surname.

=head2 first_name

Returns the user's first name (if they have one).

=head2 mid_names

Returns the user's midnames (if they have any).

=head2 gender

Returns the user's gender as "M" (Male), "F" (Female) or "U" (Unknown).

=head2 address

Returns all available details of the verified address (if one was available)
as a hashref with keys: "unit", "street", "suburb", "town_city" and "postcode".

If no address details are available, returns C<undef>.

=head2 address_unit

Returns the unit identifier (e.g.: "Flat 1") from the user's address if it has
one.

=head2 address_street

Returns the house number and street name (e.g.: "25 Example Street") from the
user's address.

=head2 address_rural_delivery

Returns the rural delivery identifier (e.g.: "RD 7") from the user's address
(if it has one).

=head2 address_suburb

Returns the suburb name (e.g.: "Herne Bay") from the user's address if it has
one.

=head2 address_town_city

Returns the town or city name (e.g.: "Auckland") from the user's address.

=head2 address_postcode

Returns the postcode (e.g.: "1001") from the user's address.


=head1 PRIVATE METHODS

The following methods are used by the service provider while setting up the
response object and are not intended for use by the calling application.

=over 4

=item set_service_type

=item set_status_urn

=item set_status_message

=item set_logon_strength

=item set_flt

=item set_fit

=item set_surname

=item set_first_name

=item set_mid_names

=item set_gender

=item set_date_of_birth

=item set_place_of_birth

=item set_country_of_birth

=item set_address_unit

=item set_address_street

=item set_address_rural_delivery

=item set_address_suburb

=item set_address_town_city

=item set_address_postcode

=back

=head1 SEE ALSO

See L<Authen::NZRealMe> for documentation index.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2019 Enrolment Services, New Zealand Electoral Commission

Written by Grant McLean E<lt>grant@catalyst.net.nzE<gt>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

