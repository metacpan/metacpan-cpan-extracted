#
# Courier::Filter::Module::SPF class
#
# (C) 2004-2008 Julian Mehnle <julian@mehnle.net>
# $Id: SPF.pm 211 2008-03-23 01:25:20Z julian $
#
###############################################################################

=head1 NAME

Courier::Filter::Module::SPF - SPF filter module for the Courier::Filter
framework

=cut

package Courier::Filter::Module::SPF;

use warnings;
use strict;

use base 'Courier::Filter::Module';

use Courier::Filter::Util qw(
    ipv4_address_pattern
    ipv6_address_pattern
    loopback_address_pattern
);

use Mail::SPF;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant match_on_default => ['fail', 'permerror', 'temperror'];

=head1 SYNOPSIS

    use Courier::Filter::Module::SPF;
    
    my $module = Courier::Filter::Module::SPF->new(
        scope               => 'mfrom' || 'helo',
        match_on            => ['fail', 'permerror', 'temperror'],
        default_response    => $default_response_text,
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

This class is a filter module class for use with Courier::Filter.  By default,
it matches a message if the sending machine's IP address is I<not> authorized
to send mail from the envelope sender's (MAIL FROM) domain according to that
domain's SPF (Sender Policy Framework) DNS record.  This is classic I<inbound>
SPF checking.

The point of inbound SPF checking is for receivers to protect I<themselves>
against forged envelope sender addresses in messages sent by others.

=cut

# Implementation:
###############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Courier::Filter::Module::SPF>

Creates a new B<SPF> filter module.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<scope>

A string denoting the authorization scope, i.e., identity, on which the SPF
check is to be performed.  Defaults to C<'mfrom'>.
See L<Mail::SPF::Request/scope> for a detailed explanation.

=item B<match_on>

A reference to an array containing the set of SPF result codes which should
cause the filter module to match a message.  Possible result codes are C<pass>,
C<fail>, C<softfail>, C<neutral>, C<none>, C<permerror>, and C<temperror>.  See
the SPF specification for details on the meaning of those.  If C<temperror> is
listed, a C<temperror> result will by definition never cause a I<permanent>
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
response is used only if the (claimed) MAIL FROM or HELO domain does not
provide a result explanation of its own.
See L<Mail::SPF::Server/default_authority_explanation> for more information.

SPF macro substitution is performed on the default response, just like on
explanations provided by domain owners.  If B<undef>,
L<Mail::SPF's default explanation|Mail::SPF::Server/default_authority_explanation>
will be used.  Defaults to B<undef>.

=item B<spf_options>

A hash-ref specifying options for the Mail::SPF server object used by this
filter module.  See L<Mail::SPF::Server/new> for the supported options.  If any
of L<Mail::SPF::BlackMagic's additional options|Mail::SPF::Server/new>, such as
C<default_policy> (best-guess) or C<tfwl> (C<trusted-forwarder.org>
accreditation checking), are specified, a black-magic SPF server object will be
created instead.

=item B<fallback_guess>

=item B<trusted_forwarders>

I<Deprecated>.  These options should now be specified as C<default_policy> and
C<tfwl> keys of the L</spf_options> option instead, although these legacy
options will continue to work for the time being.  Furthermore, due to the move
from the obsolete L<Mail::SPF::Query> module to the L<Mail::SPF> reference
implementation, the L<Mail::SPF::BlackMagic> extension module is now required
when using these non-standard options.

=back

All options of the B<Courier::Filter::Module> constructor are also supported.
Please see L<Courier::Filter::Module/new> for their descriptions.

=cut

sub new {
    my ($class, %options) = @_;
    
    $options{scope}         ||= 'mfrom';
    
    if (defined($options{reject_on})) {
        $class->warn('"reject_on" option is deprecated! Use "match_on" option instead.');
        $options{match_on}  ||= $options{reject_on};
    }
    $options{match_on}      ||= $class->match_on_default;
    
    my $spf_options = $options{spf_options} || {};
    
    if (defined($options{fallback_guess})) {
        $class->warn('"fallback_guess" option is deprecated! Use "default_policy" key in "spf_options" option instead.');
        $spf_options->{default_policy} ||= $options{fallback_guess};
    }
    
    if (defined($options{trusted_forwarders})) {
        $class->warn('"trusted_forwarders" option is deprecated! Use "tfwl" key in "spf_options" option instead.');
        $spf_options->{tfwl} ||= $options{trusted_forwarders};
    }
    
    my $spf_server_class = 'Mail::SPF::Server';
    foreach my $spf_option (keys(%$spf_options)) {
        if (not Mail::SPF->can($spf_option)) {
            $spf_server_class = 'Mail::SPF::BlackMagic::Server';
            eval { require Mail::SPF::BlackMagic };
            if ($@) {
                $class->warn("Mail::SPF::BlackMagic not installed. Ignoring unsupported \"$spf_option\" SPF option.");
            }
            elsif (not $spf_server_class->can($spf_option)) {
                $class->warn("Ignoring unsupported \"$spf_option\" SPF option. Perhaps newer Mail::SPF or Mail::SPF::BlackMagic required?");
            }
        }
    }
    
    my $spf_server = $spf_server_class->new(
        default_authority_explanation => $options{default_response},
        %$spf_options
    );
    
    my $self = $class->SUPER::new(
        %options,
        spf_server => $spf_server
    );
    return $self;
}

=back

=head2 Instance methods

See L<Courier::Filter::Module/Instance methods> for a description of the
provided instance methods.

=cut

sub match {
    my ($self, $message) = @_;
    
    return undef
        if $message->remote_host =~ / ^ ${\loopback_address_pattern} $ /x;
        # Exempt IPv4/IPv6 loopback addresses.
    
    my $scope       = $self->{scope};
    my $identities  = {
        helo    => $message->remote_host_helo,
        mfrom   => $message->sender
    };
    my $identity    = $identities->{$scope};
    
    return undef
        if $identity eq '';
        # Exempt empty identities (esp. empty MAIL FROM, i.e., bounces).
    
    return undef
        if $identity =~ / ^ \[ (?: ${\ipv4_address_pattern} | ${\ipv6_address_pattern} ) \] $ /x;
        # Exempt IP address literals ("[<ip-address>]").
    
    my $request     = Mail::SPF::Request->new(
        scope           => $scope,
        identity        => $identity,
        ip_address      => $message->remote_host,
        helo_identity   => $message->remote_host_helo
    );
    
    my $result      = $self->{spf_server}->process($request);
    my $result_code = $result->code;
    my $response    =
        $result->can('authority_explanation') ?
            $result->authority_explanation
        :   $result->local_explanation;
    
    my %match_on;
    @match_on{ @{$self->{match_on}} } = ();  # Hash-ify match-on result codes list.
    
    return "SPF: $response", ($result_code eq 'temperror' ? 451 : ())
        if exists($match_on{$result_code});
    
    return undef;
}

=head1 SEE ALSO

L<Courier::Filter::Module>, L<Courier::Filter::Overview>, L<Mail::SPF>.

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
