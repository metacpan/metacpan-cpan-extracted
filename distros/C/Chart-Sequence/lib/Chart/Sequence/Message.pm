package Chart::Sequence::Message;

$VERSION = 0.000_1;

=head1 NAME

Chart::Sequence::Message - A message in a Chart::Sequence.

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Chart::Sequence::Object ();

@ISA = qw( Chart::Sequence::Object );

use strict;
use Carp ();

sub new {
    my $proto = shift;
    if ( @_ == 1 && ref $_[0] eq "ARRAY" ) {
        my @fields = qw( From To Name );
        @_ = map { ( shift @fields => $_ ) } @{shift()};
    }
    return $proto->SUPER::new( @_ );
}


__PACKAGE__->make_methods(qw(
    number
    send_time
    name
    from
    to
    description
    color
    URI
    _layout_info
));

sub recv_time {
    my $self = shift;
    Carp::croak "Too many parameters passed" if @_ > 1;
    $self->{RecvTime} = shift if @_;
    return defined $self->{RecvTime} ? $self->{RecvTime} : $self->{SendTime};
}

=head1 DATA MEMBERS

=over

=item number

(1..N) The number of the message in the sequence.  Assigned by the
Chart::Sequence as messages are added to it.

=item name

The name of the message.  This is displayed on the arrow

=item send_time

The time the message was sent: an integer or floating point value.  The time
format (ie the units for this value) is set in the parent sequence for now.
This may be seconds since the epoch, seconds since the start of the sequence,
or just a message order.

=item recv_time

The time the message was received.  Defaults to send_time if unset.

=item from

What entity sent the message.

=item to

What entity received the message.

=item description

A longer textual description, displayed according to the rendering.  NOTE:
we may well add some primitive HTML rendering to this, not sure.

=item color

What color to use for the font and the line.

=item URI

A URI to use when rendering clickable resources.

=back

=head1 LIMITATIONS

=head1 COPYRIGHT

    Copyright 2002, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, oir GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
