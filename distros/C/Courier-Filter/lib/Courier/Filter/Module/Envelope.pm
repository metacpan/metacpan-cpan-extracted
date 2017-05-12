#
# Courier::Filter::Module::Envelope class
#
# (C) 2004-2008 Julian Mehnle <julian@mehnle.net>
# $Id: Envelope.pm 210 2008-03-21 19:30:31Z julian $
#
###############################################################################

=head1 NAME

Courier::Filter::Module::Envelope - Message envelope filter module for the
Courier::Filter framework

=cut

package Courier::Filter::Module::Envelope;

use warnings;
use strict;

use base 'Courier::Filter::Module';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

=head1 SYNOPSIS

    use Courier::Filter::Module::Envelope;

    my $module = Courier::Filter::Module::Envelope->new(
        fields      => {
            # One or more of the following fields:
            sender              => 'paul.greenfield@unisys.com',
            recipient           => 'julian@mehnle.net',
            remote_host         => '216.250.130.2',
            remote_host_name    => qr/(^|\.)php\.net$/,
            remote_host_helo    => qr/^[^.]*$/
        },

        # Optionally the following:
        response    => $response_text,

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

This class is a filter module class for use with Courier::Filter.  It matches a
message if one of the message's envelope fields matches the configured
criteria.

=cut

# Implementation:
###############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Courier::Filter::Module::Envelope>

Creates a new B<Envelope> filter module.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<fields>

I<Required>.  A reference to a hash containing the message envelope field names
and patterns (as key/value pairs) that messages are to be matched against.
Field names are matched case-insensitively.  Patterns may either be simple
strings (for exact, case-sensitive matches) or regular expression objects
created by the C<qr//> operator (for inexact, partial matches).

The following envelope fields are supported:

=over

=item B<sender>

The message's envelope sender (from the "MAIL FROM" SMTP command).

=item B<recipient>

Any of the message's envelope recipients (from the "RCPT TO" SMTP commands).

=item B<remote_host>

The IP address of the SMTP client that submitted the message.

=item B<remote_host_name>

The host name (gained by Courier through a DNS reverse lookup) of the SMTP
client that submitted the message, if available.

=item B<remote_host_helo>

The HELO string that the SMTP client specified, if available.

=back

So for instance, to match any message with a sender of
C<paul.greenfield@unisys.com>, directed at C<julian@mehnle.net> (possibly among
other recipients), you could set the C<fields> option as follows:

    fields      => {
        sender      => 'paul.greenfield@unisys.com',
        recipient   => 'julian@mehnle.net'
    }

=item B<response>

A string that is to be returned literally as the match result in case of a
match.  Defaults to B<< "Prohibited <field>: <value>" >>.

=back

All options of the B<Courier::Filter::Module> constructor are also supported.
Please see L<Courier::Filter::Module/"new()"> for their descriptions.

=back

=head2 Instance methods

See L<Courier::Filter::Module/"Instance methods"> for a description of the
provided instance methods.

=cut

sub match {
    my ($self, $message) = @_;
    
    my $envelope = {
        sender              => [$message->sender],
        recipient           => [$message->recipients],
        remote_host         => [$message->remote_host],
        remote_host_name    => [$message->remote_host_name],
        remote_host_helo    => [$message->remote_host_helo]
    };
    
    my $fields = $self->{fields};
    foreach my $field (keys(%$fields)) {
        my $pattern = $fields->{$field};
        my $matcher =
            UNIVERSAL::isa($pattern, 'Regexp') ?
                sub { defined($_[0]) and $_[0] =~ $pattern }
            :   sub { defined($_[0]) and $_[0] eq $pattern };
        
        foreach my $value ( @{$envelope->{$field}} ) {
            if ($matcher->($value)) {
                my $field_human_readable = $field;
                $field_human_readable =~ tr/_/ /;
                return
                    'Envelope: ' . (
                        $self->{response} ||
                        "Prohibited $field_human_readable detected: $value"
                    );
            }
        }
    }
    
    return undef;
}

=head1 SEE ALSO

L<Courier::Filter::Module::Header>, L<Courier::Filter::Module>,
L<Courier::Filter::Overview>.

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
