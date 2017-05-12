package Beanstalk::Pool;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

our $VERSION = "0.00_01";

BEGIN {
  __PACKAGE__->mk_accessors(
    qw(servers clients default_tube mode _current retries _watching _use)
  );
}

sub _connect {
  my $self = shift;
  my $client = shift;

  $client->connect;
  if (defined (my $use = $self->_use)) {
    $client->use($use);
  }
  if (my $watching = $self->_watching) {
    $client->watch_only(keys %watching);
  }
}

sub next_client {
  my $self = shift;
  my $disconnect = shift;

  my $current = $self->_current;
  my $clients = $self->clients;

  my $mode = $self->mode;

  if ($mode eq 'random') {
    $current = int rand(scalar @$clients);
  }
  else { # if ($mode eq 'round-robin') {
    ++$current;
    $current = 0 if $current >= @$clients;
  }

  $self->_current($current);
  my $client = $clients->[$current];
  _connect($self, $client) unless $client->socket;
  return $client;
}


sub new {
  my $proto = shift;
  my $opt = shift || {};
  my $self = $proto->SUPER::new({
    mode => 'round-robin',
    retries => 3,
    %$opt,
  });
}

sub connect {
  my $self = shift;

  my $default_tube = $self->default_tube;

  my @clients;

  foreach my $server (@{ $self->servers }) {
    my $client = Beanstalk::Client->new({
      server => $server,
      default_tube => $default_tube,
    });
    _connect($self, $client);
  }
  $self->clients(\@clients);
  1;
}



1;

__END__

=head1 NAME

Beanstalk::Pool - Use a pool of beanstalkd servers

=head1 SYNOPSIS

=head1 DESCRIPTION

This class is not currently implemented

L<Beanstalk::Pool> connects to a pool of beanstalkd servers using
L<Beanstalk::Client>.

For worker clients, all servers will be checked for jobs. For
producer jobs will be sent only to one server. How jobs are distributed
over the pool of servers is determined by the mode.  It can be one
of C<round-robin>, C<random>, C<failover>

=head1 METHODS

=head2 Constructor

=head2 Methods

=head1 SEE ALSO

http://xph.us/software/beanstalkd/

L<Beanstalk::Client>, L<Beanstalk::Job>, L<Beanstalk::Stats>

=head1 AUTHOR

Graham Barr <gbarr@pobox.com>

=head1 COPYRIGHT

Copyright (C) 2008 by Graham Barr.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

