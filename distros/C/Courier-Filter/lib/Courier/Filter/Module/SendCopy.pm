#
# Courier::Filter::Module::SendCopy class
#
# (C) 2006-2008 Michael Buschbeck <michael@buschbeck.net>
# $Id: SendCopy.pm 211 2008-03-23 01:25:20Z julian $
#
###############################################################################

=head1 NAME

Courier::Filter::Module::SendCopy - Pseudo-filter for the Courier::Filter
framework that sends a copy of certain messages to additional recipients

=cut

package Courier::Filter::Module::SendCopy;

use warnings;
use strict;

use base 'Courier::Filter::Module';

use IO::File;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

=head1 SYNOPSIS

    use Courier::Filter::Module::SendCopy;
    
    my $module = Courier::Filter::Module::SendCopy->new(
        # One or more of the following criteria:
        match_sender                => qr/\@office\.example\.net$/,
        match_recipients            => qr/\@customer\.example\.com$/,
        match_authenticated_user    => 'my-smtp-user-name',
        
        # One or several copy recipients:
        copy_recipients => [
            'el-cheffe@office.example.net',
            'archives@customer.example.com',
        ],
        
        # Send a copy to the sender? (always/never/indifferent)
        copy_to_sender  => TRUE,    # TRUE/FALSE/undef
    )
    
    my $filter = Courier::Filter->new(
        ...
        modules     => [ $module ],
        ...
    );

=head1 DESCRIPTION

This class is a filter module for use with Courier::Filter.  If a message
matches a given set of criteria, a blind carbon copy of the message is sent to
a configured list of additional recipients by adding them to the message's
control file.  This module never matches.

=cut

# Implementation:
###############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Courier::Filter::Module::SendCopy>

Creates a new B<SendCopy> filter module.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<match_sender>

A pattern matched against the message's envelope sender.  If not specified,
any sender qualifies.

=item B<match_recipients>

A pattern matched against all of the message's envelope recipients.  Any of
the envelope recipients may match.  If no pattern is specified, any recipient
qualifies.

=item B<match_authenticated_user>

A pattern matched against the user name that was used for authentication
during submission of the message.  If no pattern is specified, any user or
none at all qualifies.  If a pattern is specified and no authentication took
place during submission of the message, the message does not qualify.

=item B<copy_recipients>

One or several addresses a copy of every matching message is sent to in
addition to the original recipients.  A single address can be specified as a
simple scalar; a list of several addresses must be specified as an array
reference.  Any address matching I<exactly> one of the original recipient
addresses is skipped.

=item B<copy_to_sender>

Specifies whether a copy of the message should be sent to its envelope sender.
If B<false>, no message is ever sent back in copy to its sender, even if the
sender is included in the C<copy_recipients> list.  If B<true>, the sender is
always sent a copy of the message.  If B<undef> (the default), the sender must
be included in the C<copy_recipients> list to receive a copy of the message.

=back

Patterns may either be simple strings (for exact, case-sensitive matches) or
regular expression objects created by the C<qr//> operator (for partial
matches).

All options of the B<Courier::Filter::Module> constructor are also supported.
Please see L<Courier::Filter::Module/new> for their descriptions.

=back

=head2 Instance methods

See L<Courier::Filter::Module/"Instance methods"> for a description of the
provided instance methods.

=cut

sub match {
    my ($self, $message) = @_;
    
    my $envelope = {
        sender              => [ $message->sender             ],
        recipients          => [ $message->recipients         ],
        authenticated_user  => [ $message->authenticated_user ],
    };
    
    foreach my $field (keys(%$envelope)) {
        my $pattern = $self->{"match_$field"};
        next
            unless defined($pattern);
        my $matched =
            UNIVERSAL::isa($pattern, 'Regexp') ?
                grep { defined and $_ =~ $pattern } @{$envelope->{$field}}
            :   grep { defined and $_ eq $pattern } @{$envelope->{$field}};
        return undef
            unless $matched;
    }
    
    my @copy_recipients;
    if (defined($self->{copy_recipients})) {
        @copy_recipients =
            UNIVERSAL::isa($self->{copy_recipients}, 'ARRAY') ?
                @{$self->{copy_recipients}}
            :     $self->{copy_recipients};
    }
    
    my $copy_recipients = { map { $_ => TRUE } @copy_recipients     };
    my $skip_recipients = { map { $_ => TRUE } $message->recipients };
    
    if (defined($self->{copy_to_sender})) {
        $self->{copy_to_sender} ?
            $copy_recipients->{$message->sender} = TRUE
        :   $skip_recipients->{$message->sender} = TRUE;
    }
    
    return undef
        unless %$copy_recipients;
    
    # In case of several control files, take the last one.
    my $control_file_name = ($message->control_file_names)[-1];
    
    my $control_file_handle = IO::File->new($control_file_name, '>>')
        or return undef;
    foreach my $copy_recipient (keys(%$copy_recipients)) {
        next if $skip_recipients->{$copy_recipient};
        $control_file_handle->print("r$copy_recipient\n");
        $control_file_handle->print("R\n");
        $control_file_handle->print("N\n");
    }
    $control_file_handle->close();
    
    return undef;
}

=head1 SEE ALSO

L<Courier::Filter::Module>, L<Courier::Filter::Overview>.

For AVAILABILITY, SUPPORT and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Michael Buschbeck <michael@buschbeck.net>

=cut

TRUE;
