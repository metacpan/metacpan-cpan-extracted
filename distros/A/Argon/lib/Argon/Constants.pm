package Argon::Constants;
# ABSTRACT: Constants used by Argon classes
$Argon::Constants::VERSION = '0.18';

use strict;
use warnings;
use Const::Fast;
use parent 'Exporter';


#-------------------------------------------------------------------------------
# Defaults
#-------------------------------------------------------------------------------
const our $EOL => "\015\012";


#-------------------------------------------------------------------------------
# Priorities
#-------------------------------------------------------------------------------
const our $HIGH   => 0;
const our $NORMAL => 1;
const our $LOW    => 2;


#-------------------------------------------------------------------------------
# Commands
#-------------------------------------------------------------------------------
const our $ID    => 'ID';
const our $PING  => 'PING';
const our $ACK   => 'ACK';
const our $ERROR => 'ERROR';
const our $QUEUE => 'QUEUE';
const our $DENY  => 'DENY';
const our $DONE  => 'DONE';
const our $HIRE  => 'HIRE';

#-------------------------------------------------------------------------------
# Exports
#-------------------------------------------------------------------------------
our %EXPORT_TAGS = (
  defaults   => [qw($EOL)],
  priorities => [qw($HIGH $NORMAL $LOW)],
  commands   => [qw($ID $PING $ACK $ERROR $QUEUE $DENY $DONE $HIRE)],
);

our @EXPORT_OK = map { @$_ } values %EXPORT_TAGS;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Argon::Constants - Constants used by Argon classes

=head1 VERSION

version 0.18

=head1 DESCRIPTION

Constants used by Argon.

=head1 EXPORT TAGS

=head2 :defaults

=head3 $EOL

End of line character (C<"\015\012">).

=head2 :priorities

Priority levels for L<Argon::Message>s.

=head3 $HIGH

=head3 $NORMAL

=head3 $LOW

=head2 :commands

Command verbs used in the Argon protocol.

=head3 $ID

Used by L<Argon::SecureChannel> to identify itself to the other side of the
line.

=head3 $PING

Used internally to identify when a worker or the manager becomes unavailable.

=head3 $ACK

Response when affirming a prior command. Used in response to C<$HIRE> and
C<$PING>.

=head3 $ERROR

Response when the prior command failed due to an error. Generally used only
with C<$QUEUE>.

=head3 $QUEUE

Queues a message with the manager. If the service is at capacity, elicits a
response of C<$DENY>.

=head3 $DENY

Response sent after an attempt to C<$QUEUE> when the system is at max capacity.

=head3 $DONE

Response sent after C<$QUEUE> when the task has been completed without error.

=head3 $HIRE

Used internally by the L<Argon::Worker> to announce its capacity when
registering with the L<Argon::Manager>.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
