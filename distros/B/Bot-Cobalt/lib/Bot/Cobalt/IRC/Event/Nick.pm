package Bot::Cobalt::IRC::Event::Nick;
$Bot::Cobalt::IRC::Event::Nick::VERSION = '0.021003';
use strictures 2;

use Bot::Cobalt::Common qw/:types/;
require Bot::Cobalt::Core;

use IRC::Utils qw/eq_irc/;

use Moo;
extends 'Bot::Cobalt::IRC::Event';

has old_nick => (
  lazy      => 1,
  is        => 'rw',
  isa       => Str,
  predicate => 'has_old_nick',
  default   => sub { $_[0]->src_nick },
);

has new_nick => (
  required  => 1,
  is        => 'rw',
  isa       => Str,
);

has channels => (
  required  => 1,
  is        => 'rw',
  isa       => ArrayObj,
  coerce    => 1,
  trigger   => sub {
    my ($self, $value) = @_;
    $self->_set_common($value) if $self->has_common;
  },
);

## ...just to remain compat with ::Quit:
has common   => (
  is        => 'ro',
  lazy      => 1,
  predicate => 'has_common',
  writer    => '_set_common',
  default   => sub { $_[0]->channels },
);

## Changing src on a Nick event makes no sense, as far as I can tell.
## ...but you can do it!
after 'src' => sub {
  my ($self) = @_;
  $self->old_nick( $self->src_nick ) if $self->has_old_nick;
};

sub equal {
  my ($self) = @_;

  my $casemap;
  if (Bot::Cobalt::Core->has_instance) {
    $casemap = core->get_irc_casemap($self->context) || 'rfc1459';
  } else {
    $casemap = 'rfc1459';
  }

  eq_irc($self->old_nick, $self->new_nick, $casemap)
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::IRC::Event::Nick - IRC Event subclass for nick changes

=head1 SYNOPSIS

  my $old = $nchg_ev->old_nick;
  my $new = $nchg_ev->new_nick;

  if ( $nchg_ev->equal ) {
    ## Case change only
  }

  my $common_chans = $nchg_ev->channels;

=head1 DESCRIPTION

This is the L<Bot::Cobalt::IRC::Event> subclass for nickname changes.

=head2 new_nick

Returns the new nickname, after the nick change.

=head2 old_nick

Returns the previous nickname, prior to the nick change.

=head2 channels

Returns a L<List::Objects::WithUtils::Array> containing the list of channels
we share with the user that changed nicks (at the time of the nickname
change).

=head2 equal

Returns a boolean value indicating whether or not this was simply a
case change (as determined via the server's announced casemapping and
L<IRC::Utils/eq_irc>)

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
