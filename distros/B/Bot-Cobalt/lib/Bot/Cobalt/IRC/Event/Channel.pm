package Bot::Cobalt::IRC::Event::Channel;
$Bot::Cobalt::IRC::Event::Channel::VERSION = '0.021003';
## Generic channel events.

use strictures 2;
use Bot::Cobalt::Common qw/:types/;

use Moo;
extends 'Bot::Cobalt::IRC::Event';

has 'channel' => ( is => 'rw', isa => Str, required => 1 );

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::IRC::Event::Channel - IRC Event subclass for channel events

=head1 SYNOPSIS

  my $channel = $irc_ev->channel;

=head1 DESCRIPTION

A class for Things Happening on an IRC channel.

A subclass of L<Bot::Cobalt::IRC::Event>.

=head2 channel

The only method added by this class is B<channel>, returning a string 
containing the channel name.

=head1 SEE ALSO

L<Bot::Cobalt::IRC::Event>

L<Bot::Cobalt::IRC::Event::Kick>

L<Bot::Cobalt::IRC::Event::Mode>

L<Bot::Cobalt::IRC::Event::Nick>

L<Bot::Cobalt::IRC::Event::Quit>

L<Bot::Cobalt::IRC::Event::Topic>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
