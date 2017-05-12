package Bot::Cobalt::IRC::Event;
$Bot::Cobalt::IRC::Event::VERSION = '0.021003';
## Base class for IRC events.

use Bot::Cobalt::Common;

use Moo;

has context => ( 
  required  => 1,
  is        => 'rw', 
  isa       => Str,
);

has src     => (
  required  => 1, 
  is        => 'rw', 
  isa       => Str, 
  trigger   => sub {
    ## If 'src' changes, reset nick/user/host as-needed.
    my ($self, $value) = @_;
    
    my @types  = qw/nick user host/;
    my %pieces;
    @pieces{@types} = parse_user($value);
    
    for my $type (@types) {
      my $meth    = '_set_src_'.$type;
      my $hasmeth = 'has_src_'.$type;
      $self->$meth($pieces{$type}) if $self->$hasmeth;
    }
  }
);

has src_nick => (  
  lazy      => 1,
  is        => 'rwp',
  predicate => 'has_src_nick',
  default   => sub { (parse_user($_[0]->src))[0] },
);

has src_user => (  
  lazy      => 1,
  is        => 'rwp',
  predicate => 'has_src_user',
  default   => sub { (parse_user($_[0]->src))[1] },
);

has src_host => (
  lazy      => 1,
  is        => 'rwp',
  predicate => 'has_src_host',
  default   => sub { (parse_user($_[0]->src))[2] },
);

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::IRC::Event - Base class for IRC event information

=head1 SYNOPSIS

  sub Bot_private_msg {
    my ($self, $core) = splice @_, 0, 2;
    my $msg = ${ $_[0] };
    
    my $context  = $msg->context;
    my $stripped = $msg->stripped;
    my $nickname = $msg->src_nick;
    . . . 
  }

=head1 DESCRIPTION

This is the base class for user-generated IRC events; Things Happening 
on IRC are generally turned into some subclass of this package.

=head1 METHODS

=head2 context

Returns the server context name.

=head2 src

Returns the full source of the message in the form of C<nick!user@host>

=head2 src_nick

The 'nick' portion of the message's L</src>.

=head2 src_user

The 'user' portion of the message's L</src>.

May be undefined if the message was "odd."

=head2 src_host

The 'host' portion of the message's L</src>.

May be undefined if the message was "odd."

=head1 SEE ALSO

L<Bot::Cobalt::IRC::Message>

L<Bot::Cobalt::IRC::Message::Public>

L<Bot::Cobalt::IRC::Event::Channel>

L<Bot::Cobalt::IRC::Event::Kick>

L<Bot::Cobalt::IRC::Event::Mode>

L<Bot::Cobalt::IRC::Event::Nick>

L<Bot::Cobalt::IRC::Event::Quit>

L<Bot::Cobalt::IRC::Event::Topic>

L<Bot::Cobalt::Manual::Plugins>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
