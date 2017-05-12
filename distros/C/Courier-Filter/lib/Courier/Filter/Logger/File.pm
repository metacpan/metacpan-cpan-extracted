#
# Courier::Filter::Logger::File class
#
# (C) 2003-2008 Julian Mehnle <julian@mehnle.net>
# $Id: File.pm 210 2008-03-21 19:30:31Z julian $
#
###############################################################################

=head1 NAME

Courier::Filter::Logger::File - File logger for the Courier::Filter framework

=cut

package Courier::Filter::Logger::File;

=head1 SYNOPSIS

    use Courier::Filter::Logger::File;

    my $logger = Courier::Filter::Logger::File->new(
        file_name => $file_name
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

=cut

use warnings;
use strict;

use base 'Courier::Filter::Logger::IOHandle';

use Error ':try';

use Courier::Error;

use IO::File;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

=head1 DESCRIPTION

This class is a file logger class for use with Courier::Filter and its filter
modules.  It is derived from B<Courier::Filter::Logger::IOHandle>.

=cut

# Implementation:
###############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Courier::Filter::Logger::File>; throws
I<Courier::Error>

Creates a new logger that logs messages as lines to a file.  Opens the file for
writing, creating it if necessary.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<file_name>

I<Required>.  The name of the file to which log messages should be written.

=item B<timestamp>

A boolean value controlling whether every log message line should be prefixed
with a timestamp (in local time, in ISO format).  Defaults to B<false>.

=back

=cut

sub new {
    my ($class, %options) = @_;
    
    my $handle = IO::File->new($options{file_name}, '>>')
        or throw Courier::Error("Unable to open log file '$options{file_name}' for writing");
    
    return $class->SUPER::new(
        %options,
        handle  => $handle
    );
}

=back

=head2 Instance methods

The following instance methods are provided, as inherited from
B<Courier::Filter::Logger::IOHandle>:

=over

=item B<log_error($text)>: throws Perl exceptions

Logs the error message given as C<$text> (a string which may contain newlines).
Prefixes each line with a timestamp if the C<timestamp> option has been set
through the constructor.

=item B<log_rejected_message($message, $reason)>: throws Perl exceptions

Logs the B<Courier::Message> given as C<$message> as having been rejected due
to C<$reason> (a string which may contain newlines).

=back

=head1 SEE ALSO

L<Courier::Filter::Logger::IOHandle>, L<Courier::Filter::Logger>,
L<Courier::Filter::Overview>.

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
