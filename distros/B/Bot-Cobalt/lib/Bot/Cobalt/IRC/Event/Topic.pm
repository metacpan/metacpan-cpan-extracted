package Bot::Cobalt::IRC::Event::Topic;
$Bot::Cobalt::IRC::Event::Topic::VERSION = '0.021003';
use strictures 2;
use Bot::Cobalt::Common qw/:types :string/;

use Moo;
extends 'Bot::Cobalt::IRC::Event::Channel';

has topic => (
  required  => 1,
  is        => 'rw',
  isa       => Str, 
);

has stripped => (
  lazy      => 1,
  is        => 'ro', 
  isa       => Str, 
  default   => sub {
    strip_color( strip_formatting( $_[0]->topic ) )
  },
);

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::IRC::Event::Topic - IRC Event subclass for topic changes

=head1 SYNOPSIS

  my $new_topic = $topic_ev->topic;

=head1 DESCRIPTION

This is the L<Bot::Cobalt::IRC::Event::Channel> subclass for channel topic 
changes.

=head2 topic

Returns the new channel topic, as an (undecoded and non-stripped) 
string.

=head2 stripped

Returns the color- and formatting-stripped topic string.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
