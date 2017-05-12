package Crypt::OpenToken::Token;

use Moose;
use DateTime;
use Date::Parse qw(str2time);

# XXX: this could be a *lot* smarter; right now its just a glorified hashref
has 'version' => (
    is      => 'rw',
    default => 1,
);
has 'cipher'         => (is => 'rw');
has 'hmac'           => (is => 'rw');
has 'iv_length'      => (is => 'rw');
has 'iv'             => (is => 'rw');
has 'key_length'     => (is => 'rw');
has 'key'            => (is => 'rw');
has 'payload_length' => (is => 'rw');
has 'payload'        => (is => 'rw');
has 'data'           => (is => 'rw', default => sub { {} });

sub subject {
    my $self = shift;
    return $self->data->{subject};
}

sub is_valid {
    my $self = shift;
    my %args = @_;
    my $skew = $args{clock_skew} || 5;
    my $now  = DateTime->now(time_zone => 'UTC');

    my $not_before = $self->not_before;
    if ($not_before) {
        $not_before->subtract(seconds => $skew);
        return 0 if ($now < $not_before);
    }

    my $not_on_or_after = $self->not_on_or_after;
    if ($not_on_or_after) {
        $not_on_or_after->add(seconds => $skew);
        return 0 if ($now >= $not_on_or_after);
    }

    return 1;
}

sub requires_renewal {
    my $self = shift;
    my %args = @_;
    my $skew = $args{clock_skew} || 5;
    my $now  = DateTime->now(time_zone => 'UTC');

    my $renew_until = $self->renew_until;
    if ($renew_until) {
        $renew_until->add(seconds => $skew);
        return 1 if ($now > $renew_until);
    }

    return 0;
}

sub renew_until {
    my $self = shift;
    my $when = $self->data->{'renew-until'};
    return $when ? $self->_parse_iso8601_to_datetime($when) : undef;
}

sub not_before {
    my $self = shift;
    my $when = $self->data->{'not-before'};
    return $when ? $self->_parse_iso8601_to_datetime($when) : undef;
}

sub not_on_or_after {
    my $self = shift;
    my $when = $self->data->{'not-on-or-after'};
    return $when ? $self->_parse_iso8601_to_datetime($when) : undef;
}

sub _parse_iso8601_to_datetime {
    my ($self, $gmt_str) = @_;
    my $time_t = str2time($gmt_str);
    my $when   = DateTime->from_epoch(epoch => $time_t, time_zone => 'UTC');
    return $when;
}

no Moose;

1;

=head1 NAME

Crypt::OpenToken::Token - OpenToken data object

=head1 SYNOPSIS

  use Crypt::OpenToken;

  $factory = Crypt::OpenToken->new($password);
  $token   = $factory->parse($token_string);

  if ($token->is_valid(clock_skew => $allowable_skew)) {
     # token is valid, do something with the data
  }

  if ($token->requires_renewal(clock_skew => $allowable_skew)) {
     # token should be renewed by authenticating the User again
  }

=head1 DESCRIPTION

This module implements the data representation of an OpenToken.

=head1 METHODS

=over

=item subject()

Returns the "subject" field as specified in the token data.

=item is_valid(clock_skew => $allowable_skew)

Checks to see if the OpenToken is valid, based on the standard fields
specified in the IETF draft specification.

Can accept an optional C<clock_skew> parameter, which specifies the amount of
allowable clock skew (in seconds).  Defaults to "5 seconds".

=item requires_renewal(clock_skew => $allowable_skew)

Checks to see if the OpenToken is past its "renew-until" timestamp, and
requires that it be renewed by re-authenticating the User.  B<Not>
automatically renewed/reissued, but by B<re-authenticating> the User.

Can accept an optional C<clock_skew> parameter, which specifies the amount of
allowable clock skew (in seconds).  Defaults to "5 seconds".

=item renew_until()

Returns a C<DateTime> object representing the "renew-until" field specified in
the token data; the date/time at which the token B<must not> automatically be
re-issued without further authentication.

If no "renew-until" field was specified, this method returns C<undef>.

=item not_before()

Returns a C<DateTime> object representing the "not-before" field specified in
the token data; the date/time when the token was created.  A token received
before this date/time B<must> be rejected as invalid.

If no "not-before" field was specified, this method returns C<undef>.

=item not_on_or_after()

Returns a C<DateTime> object representing the "not-on-or-after" field
specified in the token data; the time/time at which the token will expire.  A
token received on or after this date/time B<must> be rejected as invalid.

If no "not-on-or-after" field was specified, this method returns C<undef>.

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT & LICENSE

C<Crypt::OpenToken> is Copyright (C) 2010, Socialtext, and is released under
the Artistic-2.0 license.

=cut
