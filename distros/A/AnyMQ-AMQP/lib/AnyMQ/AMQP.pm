package AnyMQ::AMQP;

use strict;
use 5.008_001;
our $VERSION = '0.30';

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

AnyMQ::AMQP - AMQP binding for AnyMQ

=head1 SYNOPSIS

  use AnyMQ;
  my $bus = AnyMQ->new_with_traits(traits => ['AMQP'],
                                   host   => 'localhost',
                                   port   => 5672,
                                   user   => 'guest',
                                   pass   => 'guest',
                                   vhost  => '/',
                                   exchange => 'foo',
                               );
  my $client = $bus->new_listener($bus->topic("foo"));
  $client->poll(sub { my $msg = shift;
                      # ...
                    });

=head1 DESCRIPTION

AnyMQ::AMQP is L<AnyMQ> trait to work with AMQP servers.

=head1 AUTHOR

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
