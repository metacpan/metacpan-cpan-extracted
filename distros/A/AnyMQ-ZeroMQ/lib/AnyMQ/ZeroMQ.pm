package AnyMQ::ZeroMQ;

=head1 NAME

AnyMQ::ZeroMQ - AnyMQ adaptor for ZeroMQ

=cut

our $VERSION = '0.06';


=head1 SYNOPSIS

  # create a subscriber
  my $sub_bus = AnyMQ->new_with_traits(
      traits            => [ 'ZeroMQ' ],
      subscribe_address => 'tcp://localhost:4001',
  );
  # subscribe to topic
  my $sub_topic = $sub_bus->topic('ping');
  my $listener = $sub_bus->new_listener($sub_topic);
  $listener->poll(sub { "got ping event!" });

  # create a publisher
  my $pub_bus = AnyMQ->new_with_traits(
      traits  => ['ZeroMQ'],
      publish_address => 'tcp://localhost:4000',  # accepts any address that ZeroMQ supports
  );
  my $pub_topic = $pub_bus->topic('ping');
  $pub_topic->publish({ foo => 'bar' });


=head1 AUTHOR

Mischa Spiegelmock, C<< <revmischa at cpan.org> >>

=head1 BUGS

Please use the GitHub issue tracker

=head1 SEE ALSO

L<AnyMQ>, L<ZeroMQ::PubSub>


=head1 ACKNOWLEDGEMENTS

L<AnyMQ>, L<AnyEvent::ZeroMQ>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mischa Spiegelmock.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of AnyMQ::ZeroMQ
