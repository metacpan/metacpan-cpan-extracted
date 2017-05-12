#
# Courier::Filter::Module::SPFout class
#
# (C) 2005-2008 Julian Mehnle <julian@mehnle.net>
# $Id: SPFout.pm 211 2008-03-23 01:25:20Z julian $
#
###############################################################################

=head1 NAME

Courier::Filter::Module::SPFout - Outbound SPF filter module for the
Courier::Filter framework

=cut

package Courier::Filter::Module::SPFout;

use warnings;
use strict;

use base 'Courier::Filter::Module';

use Error ':try';

use Mail::SPF;
use Mail::SPF::MacroString;
use Mail::SPF::Util;
use Net::Address::IP::Local;

use Courier::Filter::Util qw(
    ipv4_address_pattern
    ipv6_address_pattern
    loopback_address_pattern
);

use Courier::Error;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant match_on_default => ['fail', 'permerror', 'temperror'];

=head1 SYNOPSIS

    use Courier::Filter::Module::SPFout;
    
    my $module = Courier::Filter::Module::SPFout->new(
        match_on            => ['fail', 'permerror', 'temperror'],
        default_response    => $default_response_text,
        force_response      => $force_response_text,
        outbound_ip_addresses
                            => ['129.257.16.1', '2001:6ag:10e1::1'],
        spf_options         => {
            # any Mail::SPF::Server options
        },
        
        logger      => $logger,
        inverse     => 0,
        trusting    => 0,
        testing     => 0,
        debugging   => 0
    );
    
    my $filter = Courier::Filter->new(
        ...
        modules     => [ $module ],
        ...
    );

=head1 DESCRIPTION

This class is a filter module for use with Courier::Filter.  It matches a
message if any of the receiving (local) machine's outbound IP addresses are
I<not> authorized to send mail from the envelope sender's (MAIL FROM) domain
according to that domain's DNS SPF (Sender Policy Framework) record.  This is
I<outbound> SPF checking.

The point of inbound SPF checking is for message submission agents (MSAs,
smarthosts) to protect I<others> against forged envelope sender addresses in
messages submitted by the MSA's users.

=cut

# Implementation:
###############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Courier::Filter::Module::SPFout>

Creates a new B<SPFout> filter module.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<trusting>

I<Disabled>.  Since I<outbound> SPF checking, as opposed to I<inbound> SPF
checking, is applied to trusted (authenticated) messages only, setting this
module to be B<trusting> does not make sense.  This property is thus locked to
B<false>.  Also see the description of
L<< Courier::Message's C<trusted> property | Courier::Message/trusted >>.

=item B<match_on>

A reference to an array containing the set of SPF result codes which should
cause the filter module to match a message.  Possible result codes are C<pass>,
C<fail>, C<softfail>, C<neutral>, C<none>, C<permerror>, and C<temperror>.  See
the SPF specification for details on the meaning of those.  If C<temperror> is
listed, an C<temperror> result will by definition never cause a I<permanent>
rejection, but only a I<temporary> one.  Defaults to B<['fail', 'permerror',
'temperror']>.

I<Note>:  With early SPF specification drafts as well as the obsolete
Mail::SPF::Query module, the C<permerror> and C<temperror> result codes were
known as C<unknown> and C<error>, respectively; the old codes are now
deprecated but still supported for the time being.

=item B<default_response>

A string that is to be returned as the module's match result in case of a
match, that is when the C<match_on> option includes the result code of the SPF
check (by default when a message fails the SPF check).  However, this default
response is used only if the (claimed) envelope sender domain does not provide
an explicit response.  See L<Mail::SPF::Server/default_authority_explanation>
for more information.

SPF macro substitution is performed on the default response, just like on
explanations provided by domain owners.  If B<undef>,
L<< Mail::SPF's default explanation | Mail::SPF::Server/default_authority_explanation >>
will be used.  Defaults to B<undef>.

=item B<force_response>

Instead of merely specifying a default response for cases where the sender
domain does not provide an explicit response, you can also specify a response
to be used in I<all> cases, even if the sender domain does provide one.  This
may be useful if you do not want to confuse your own users with I<3rd-party>
provided explanations when in fact they are only dealing with I<your> server
not wanting to relay their messages.  Defaults to B<undef>.

=item B<outbound_ip_addresses>

A reference to an array containing the local system's set of outbound IP
addresses that will be assumed as the sender IP address in outbound SPF
checks.  This set should include I<all> public IP addresses that are used for
relaying mail.  By default, automatic discovery of one public IP address that
is "en route" to "the internet" is attempted for each of IPv4 and IPv6.
Auto-discovery does not work from behind NATs.

=item B<spf_options>

A hash-ref specifying options for the Mail::SPF server object used by this
filter module.  See L<Mail::SPF::Server/new> for the supported options.

=back

All options of the B<Courier::Filter::Module> constructor (except for the
B<trusting> option) are also supported.  Please see
L<Courier::Filter::Module/new> for their descriptions.

=cut

sub new {
    my ($class, %options) = @_;
    
    $options{trusting} = FALSE;  # Locked to FALSE.
    
    $options{scope}         ||= 'mfrom';
        # The "scope" option has been deliberately left undocumented because
        # outbound SPF checking does not make sense for the HELO identity and
        # we do not want to promote the use of the PRA identity for outbound
        # checking.
        # TODO: Croak on scope = 'helo'?  What about 'pra'?
    
    $options{match_on}      ||= $class->match_on_default;
    
    my $spf_options = $options{spf_options} || {};
    
    foreach my $spf_option (keys(%$spf_options)) {
        if (not Mail::SPF->can($spf_option)) {
           $class->warn("Ignoring unsupported \"$spf_option\" SPF option. Perhaps newer Mail::SPF required?");
        }
    }
    
    my $spf_server = Mail::SPF::Server->new(
        default_authority_explanation => $options{default_response},
        %$spf_options
    );
    
    if (defined($options{force_response})) {
        $options{force_response} = Mail::SPF::MacroString->new(
            text            => $options{force_response},
            is_explanation  => TRUE
        );
    }
    
    if (not defined($options{outbound_ip_addresses})) {
        # Attempt auto-discovery of public IP addresses:
        $options{outbound_ip_addresses} = \my @outbound_ip_addresses;
        try { push(@outbound_ip_addresses, Net::Address::IP::Local->public_ipv4) };
        try { push(@outbound_ip_addresses, Net::Address::IP::Local->public_ipv6) };
    }
    
    my $self = $class->SUPER::new(
        %options,
        spf_server => $spf_server
    );
    return $self;
}

=back

=head2 Instance methods

See L<Courier::Filter::Module/"Instance methods"> for a description of the
provided instance methods.

=cut

sub match {
    my ($self, $message) = @_;
    
    return undef
        if not $message->trusted;
        # This filter module applies to trusted (authenticated) messages only.
    
    return undef
        if $message->remote_host =~ / ^ ${\loopback_address_pattern} $ /x;
        # Exempt IPv4/IPv6 loopback addresses, i.e., self submissions.

    my $scope           = $self->{scope};
    my $identities      = {
        helo    => undef,  # No outbound HELO checks supported.
        mfrom   => $message->sender
    };
    my $identity        = $identities->{$scope};
    my $helo_identity   = Mail::SPF::Util->hostname;  # Local system's host name.
    
    return undef
        if $identity eq '';
        # Empty identity (esp. empty MAIL FROM, i.e., bounces) on submission??  Weird. O_o
    
    return undef
        if $identity =~ / ^ \[ (?: ${\ipv4_address_pattern} | ${\ipv6_address_pattern} ) \] $ /x;
        # Exempt IP address literals ("[<ip-address>]").
    
    my %match_on;
    @match_on{ @{$self->{match_on}} } = ();  # Hash-ify match-on result codes list.
    
    foreach my $ip_address (@{ $self->{outbound_ip_addresses} }) {
        my $request     = Mail::SPF::Request->new(
            scope           => $scope,
            identity        => $identity,
            ip_address      => $ip_address,
            helo_identity   => $helo_identity
        );
        
        my $result      = $self->{spf_server}->process($request);
        my $result_code = $result->code;
        
        if (exists($match_on{$result_code})) {
            # Match!
            
            my $response;
            if (defined($self->{force_response})) {
                $response = $self->{force_response}->expand($self->{spf_server}, $request);
            }
            else {
                $response =
                    $result->can('authority_explanation') ?
                        $result->authority_explanation
                    :   $result->local_explanation;
            }
            
            return "SPF: $response", ($result_code eq 'temperror' ? 451 : ());
        }
    }
    
    return undef;
}

=head1 SEE ALSO

L<Courier::Filter::Module::SPF>, L<Courier::Filter::Module>,
L<Courier::Filter::Overview>, L<Mail::SPF>.

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 REFERENCES

=over

=item B<SPF website> (Sender Policy Framework)

L<http://www.openspf.org>

=item B<SPF specification>

L<http://www.openspf.org/Specifications>

=back

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
