package AnyEvent::Atom::Stream;

use strict;
use 5.008_001;
our $VERSION = '0.02';

use base qw( XML::Atom::Stream );
use AnyEvent::Atom::Stream::UserAgent;

sub connect {
    my($self, $url) = @_;
    $self->{ua} = AnyEvent::Atom::Stream::UserAgent->new($self->{timeout}, $self->{on_disconnect});
    $self->SUPER::connect($url);

    defined wantarray && AnyEvent::Util::guard { delete $self->{ua} };
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

AnyEvent::Atom::Stream - XML::Atom::Stream with AnyEvent

=head1 SYNOPSIS

  use AnyEvent::Atom::Stream;

  my $url = "http://updates.sixapart.com/atom-stream.xml";
  my $cv  = AnyEvent->condvar;

  # API is compatible to XML::Atom::Stream
  my $client = AnyEvent::Atom::Stream->new(
      callback  => \&callback,
      timeout   => 30,
      on_disconnect => $cv,
  );
  my $guard = $client->connect($url);

  $cv->recv;

  sub callback {
      my($atom) = @_;
      # $atom is a XML::Atom::Feed object
  }

=head1 DESCRIPTION

AnyEvent::Atom::Stream is an XML::Atom::Stream subclass that uses
AnyEvent::HTTP and thus allows you to run the stream listener using
any of AnyEvent event loop implementation.

=head1 METHODS

=over 4

=item new

  $client = AnyEvent::Atom::Stream->new(
      callback => \&callback,
      timeout  => 30,
      on_disconnect => $cv,
  );

Creates a new AnyEvent::Atom::Stream instance. The API is compatible
to XML::Atom::Stream, but it doesn't support C<reconnect> parameter,
because that's something you can easily control with the new
I<on_disconnect> AnyEvent callback.

=item connect

  $guard = $client->connect($url);

Connects and receives Atom update stream.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::Atom::Stream>, L<AnyEvent::HTTP>, L<http://updates.sixapart.com/>

=cut
