package Authen::NZRealMe::LogonStrength;
$Authen::NZRealMe::LogonStrength::VERSION = '1.22'; # TRIAL
use strict;
use warnings;
use Carp;

use constant URN_PREFIX => 'urn:nzl:govt:ict:stds:authn:deployment:GLS:SAML:2.0:ac:classes:';

use constant STRENGTH_LOW          => URN_PREFIX . 'LowStrength';
use constant STRENGTH_MODERATE     => URN_PREFIX . 'ModStrength';
use constant STRENGTH_MODERATE_SID => URN_PREFIX . 'ModStrength::OTP:Token:SID';
use constant STRENGTH_MODERATE_SMS => URN_PREFIX . 'ModStrength::OTP:Token:SMS';


my %word_to_urn = (
    low      => STRENGTH_LOW,
    mod      => STRENGTH_MODERATE,
    moderate => STRENGTH_MODERATE,
);

my %strength_score = (
    &STRENGTH_LOW          => 10,
    &STRENGTH_MODERATE     => 20,
    &STRENGTH_MODERATE_SID => 20,
    &STRENGTH_MODERATE_SMS => 20,
);


sub new {
    my $class = shift;
    my $urn   = shift || 'low';

    $urn = $word_to_urn{$urn} if $word_to_urn{$urn};

    if(not exists $strength_score{$urn}) {
        my @match = grep /\Q$urn\E$/i, keys %strength_score;
        croak "Can't find a match for logon strength '$urn'" if @match == 0;
        croak "Ambiguous logon strength '$urn'"              if @match > 1;
        $urn = $match[0];
    }

    return bless { urn => $urn }, $class;
}


sub urn   { shift->{urn};                    }
sub score { $strength_score{ shift->{urn} }; }


sub assert_match {
    my $self     = shift;
    my $required = shift || 'low';
    my $match    = shift || 'minimum';

    my $class = ref($self);
    $required = $class->new($required);

    my $provided_urn = $self->urn;
    my $required_urn = $required->urn;
    return if $required_urn eq $provided_urn;

    my $provided_score = $self->score;
    my $required_score = $required->score;
    return if $required_urn eq STRENGTH_MODERATE and $provided_score == 20;

    if($match eq 'minimum') {
        return if $provided_score > $required_score;
    }
    elsif($match ne 'exact') {
        die "Unrecognised password strength match type: '$match'";
    }

    die "Invalid logon strength.\n"
        . "Required: $required_urn\n"
        . "Provided: $provided_urn\n"
        . "Comparison: $match\n";
}

1;

__END__

=head1 NAME

Authen::NZRealMe::LogonStrength - Manipulate NZ RealMe Login service AuthnContextClassRef values

=head1 DESCRIPTION

The NZ RealMe Login service supports the notion of logon strength.  For example
a user session authenticated with a username and password is a 'low strength'
logon.  Whereas authenticating with a user, password and SecurID token will
result in a moderate strength logon.  The different logon strengths are
represented by URNs which will be present in the initial SAML AuthnRequest
message as well as the assertion in the resulting ArtifactResponse.

This class is used to encapsulate the URNs and to provide methods for comparing
the strength of one URN to another.

=head1 CONSTANTS

The following constants are defined for referring to URNs:

=over 4

=item Authen::NZRealMe::LogonStrength::STRENGTH_LOW

=item Authen::NZRealMe::LogonStrength::STRENGTH_MODERATE

=item Authen::NZRealMe::LogonStrength::STRENGTH_MODERATE_SID

=item Authen::NZRealMe::LogonStrength::STRENGTH_MODERATE_SMS

=back

=head1 METHODS

=head2 new( strength )

Creates an object from the named strength identifier which might be a word
(e.g.: 'low'), a URN (see the RealMe Login service SAML v2.0 Messaging
Specification), or a URN fragment matching the last portion of a URN (e.g.:
'OTP:Token:SID').

=head2 urn( )

Returns the URN for the selected logon strength.

=head2 score( )

Returns the strength score (currently either 10 or 20) which is used when
comparing strengths using the 'minimum' match type.

=head2 assert_match( required_strength, strength_match )

This method returns if the provided logon strength matches the required
strength, or dies if the strength does not meet the specified requirement.

The C<required_strength> will default to 'low' if not provided.

The C<strength_match> parameter must be 'exact' or 'minimum' (default
'minimum').  When comparing different logon strengths, the rules outlined in
the RealMe Login service SAML v2.0 Messaging Specification are used.


=head1 SEE ALSO

See L<Authen::NZRealMe> for documentation index.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2022 Enrolment Services, New Zealand Electoral Commission

Written by Grant McLean E<lt>grant@catalyst.net.nzE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

