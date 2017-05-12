#
# Courier::Filter::Logger abstract base class
#
# (C) 2003-2008 Julian Mehnle <julian@mehnle.net>
# $Id: Logger.pm 210 2008-03-21 19:30:31Z julian $
#
###############################################################################

=head1 NAME

Courier::Filter::Logger - Abstract base class for loggers used by the
Courier::Filter framework

=cut

package Courier::Filter::Logger;

use warnings;
use strict;

use Error ':try';

use Courier::Error;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

=head1 SYNOPSIS

=head2 Courier::Filter logging

    use Courier::Filter::Logger::My;  # Need to use a non-abstract sub-class.
    
    my $logger = Courier::Filter::Logger::My->new(%options);
    
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

=head2 Deriving new logger classes

    package Courier::Filter::Logger::My;
    use base qw(Courier::Filter::Logger);

=head1 DESCRIPTION

Sub-classes of B<Courier::Filter::Logger> are used by the B<Courier::Filter>
mail filtering framework and its filter modules for the logging of errors and
message rejections to arbitrary targets, like file handles or databases.

When overriding a method in a derived class, do not forget calling the
inherited method from your overridden method.

=cut

# Implementation:
###############################################################################

=head2 Constructor

The following constructor is provided and may be overridden:

=over

=item B<new(%options)>: returns I<Courier::Filter::Logger>

Creates a new logger using the %options given as a list of key/value pairs.
Initializes the logger, by creating/opening I/O handles, connecting to
databases, etc..

C<Courier::Filter::Logger::new()> creates a hash-ref as an object of the
invoked class, and stores the %options in it, but does nothing else.

=cut

sub new {
    my ($class, %options) = @_;
    $class ne __PACKAGE__
        or throw Courier::Error('Unable to instantiate abstract ' . __PACKAGE__ . ' class');
    my $self = { %options };
    return bless($self, $class);
}

=back

=head2 Destructor

The following destructor is provided and may be overridden:

=over

=item B<destroy>

Uninitializes the logger, by closing I/O handles, disconnecting from databases,
etc..

C<Courier::Filter::Logger::destroy()> does nothing.  Sub-classes may override
this method and define clean-up behavior.

=cut

sub destroy {
    my ($self) = @_;
    return;
}

=back

=head2 Instance methods

The following instance methods are provided and may be overridden:

=over

=item B<log_error($text)>

Logs the error message given as $text (a string which may contain newlines).

C<Courier::Filter::Logger::log_error()> does nothing and should be overridden.

=cut

sub log_error {
    my ($self, $text) = @_;
    return;
}

=item B<log_rejected_message($message, $reason)>

Logs the B<Courier::Message> given as $message as having been rejected due to
$reason (a string which may contain newlines).

C<Courier::Filter::Logger::log_rejected_message()> does nothing and should be
overridden.

=cut

sub log_rejected_message {
    my ($self, $message, $reason) = @_;
    return;
}

=back

=cut

BEGIN {
    no warnings 'once';
    *DESTROY = \&destroy;
}

=head1 SEE ALSO

L<Courier::Filter>, L<Courier::Filter::Module>.

For a list of prepared loggers that come with Courier::Filter, see
L<Courier::Filter::Overview/"Bundled Courier::Filter loggers">.

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
