#
# Courier::Filter::Logger::IOHandle class
#
# (C) 2004-2008 Julian Mehnle <julian@mehnle.net>
# $Id: IOHandle.pm 210 2008-03-21 19:30:31Z julian $
#
###############################################################################

=head1 NAME

Courier::Filter::Logger::IOHandle - I/O handle logger for the Courier::Filter
framework

=cut

package Courier::Filter::Logger::IOHandle;

use warnings;
use strict;

use base 'Courier::Filter::Logger';

use IO::Handle;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

=head1 SYNOPSIS

    use Courier::Filter::Logger::IOHandle;
    
    my $logger = Courier::Filter::Logger::IOHandle->new(
        handle => $handle
    );
    
    # For use in an individual filter module:
    my $module = Courier::Filter::Module::My->new(
        ...
        logger => $logger,
        ...
    );
    
    # For use as a global Courier::Filter logger object:
    my $filter = Courier::Filter->new(
        ...
        logger => $logger,
        ...
    );

=head1 DESCRIPTION

This class is an I/O handle logger class for use with Courier::Filter and its
filter modules.

=cut

# Implementation:
###############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Courier::Filter::Logger::IOHandle>

Creates a new logger that logs messages as lines to an I/O handle.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<handle>

I<Required>.  The I/O handle or B<IO::Handle> object to which log messages
should be written.

=item B<timestamp>

A boolean value controlling whether every log message line should be prefixed
with a timestamp (in local time, in ISO format).  Defaults to B<false>.

=back

=cut

sub new {
    my ($class, %options) = @_;
    
    my $self = $class->SUPER::new(%options);
    
    $self->{autoflush} = TRUE
        if not defined($self->{autoflush});
    $self->{handle}->autoflush($self->{autoflush});
    
    return $self;
}

=back

=head2 Instance methods

The following instance methods are provided:

=over

=begin comment

=item B<log($text)>: throws Perl exceptions

Logs the text given as C<$text> (a string which may contain newlines).
Prefixes each line with a timestamp if the C<timestamp> option has been set
through the constructor.

=end comment

=cut

sub log {
    my ($self, $text) = @_;
    
    my $timestamp = '';
    if ($self->{timestamp}) {
        my ($y, $m, $d, $h, $n, $s) = (localtime)[5,4,3,2,1,0];
        $timestamp = sprintf(
            "%04d-%02d-%02d %02d:%02d:%02d ",
            $y+1900, $m+1, $d, $h, $n, $s
        );
    }
    
    my @lines = split(/\n/, $text);
    $self->{handle}->print("$timestamp$_\n")
        foreach @lines;
    
    return;
}

=item B<log_error($text)>: throws Perl exceptions

Logs the error message given as C<$text> (a string which may contain newlines).
Prefixes each line with a timestamp if the C<timestamp> option has been set
through the constructor.

=cut

sub log_error {
    my ($self, $text) = @_;
    return $self->log($text);
}

=item B<log_rejected_message($message, $reason)>: throws Perl exceptions

Logs the B<Courier::Message> given as C<$message> as having been rejected due
to C<$reason> (a string which may contain newlines).

=cut

sub log_rejected_message {
    my ($self, $message, $reason) = @_;
    
    $reason =~ s/^/Reason: /gm;
    
    my $text = sprintf(
        "Rejected message sent from %s to %s through %s\n%s\n",
        '<' . $message->sender . '>',
        join(', ', map("<$_>", $message->recipients)),
        $message->remote_host . (
            $message->remote_host_name ?
                ' (' . $message->remote_host_name . ')'
            :   ''
        ),
        $reason
    );
    return $self->log($text);
}

=back

=head1 SEE ALSO

L<Courier::Filter::Logger>, L<Courier::Filter::Overview>.

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
