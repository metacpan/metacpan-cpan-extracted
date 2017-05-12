package Bot::Cobalt::IRC::Event::Quit;
$Bot::Cobalt::IRC::Event::Quit::VERSION = '0.021003';
use strictures 2;

use Bot::Cobalt::Common qw/:types/;

use Moo;
extends 'Bot::Cobalt::IRC::Event';

has reason => ( 
  lazy      => 1, 
  is        => 'rw', 
  isa       => Str, 
  default   => sub {''},
);

has common => ( 
  lazy      => 1,
  is        => 'rw', 
  isa       => ArrayObj,
  coerce    => 1,
  default   => sub {[]},
);

1;
__END__
=pod

=head1 NAME

Bot::Cobalt::IRC::Event::Quit - IRC Event subclass for user quits

=head1 SYNOPSIS

  my $reason = $quit_ev->reason;
  
  my $shared_chans = $quit_ev->common;

=head1 DESCRIPTION

This is the L<Bot::Cobalt::IRC::Event> subclass for user quit events.

=head2 reason

Returns the displayed reason for the quit.

=head2 common

Returns a L<List::Objects::WithUtils::Array> containing the list of channels
previously shared with the user.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
