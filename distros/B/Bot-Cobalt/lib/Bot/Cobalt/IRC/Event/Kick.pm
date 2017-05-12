package Bot::Cobalt::IRC::Event::Kick;
$Bot::Cobalt::IRC::Event::Kick::VERSION = '0.021003';
use strictures 2;
use Bot::Cobalt::Common qw/:types/;

use Moo;
extends 'Bot::Cobalt::IRC::Event::Channel';

has kicked => ( is => 'rw', isa => Str, required => 1 );
has reason => ( is => 'rw', isa => Str, required => 1 );

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::IRC::Event::Kick - IRC Event subclass for kick events

=head1 SYNOPSIS

  my $kicked_user = $kick_ev->kicked;
  my $reason      = $kick_ev->reason;

=head1 DESCRIPTION

This is the L<Bot::Cobalt::IRC::Event::Channel> subclass for channel kick 
events.

=head2 kicked

Returns the kicked user's nickname.

=head2 reason

Returns the supplied kick reason string.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
