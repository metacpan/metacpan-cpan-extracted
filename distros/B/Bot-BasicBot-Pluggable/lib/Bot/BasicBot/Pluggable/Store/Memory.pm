package Bot::BasicBot::Pluggable::Store::Memory;
$Bot::BasicBot::Pluggable::Store::Memory::VERSION = '1.20';
use warnings;
use strict;

use base qw( Bot::BasicBot::Pluggable::Store );

1;

__END__

=head1 NAME

Bot::BasicBot::Pluggable::Store::Memory - use memory (RAM) to provide a storage backend

=head1 VERSION

version 1.20

=head1 SYNOPSIS

  my $store = Bot::BasicBot::Pluggable::Store::Memory->new();
  $store->set( "namespace", "key", "value" );
  
=head1 DESCRIPTION

This is a L<Bot::BasicBot::Pluggable::Store> that uses memory (RAM)
to store the values set by modules. To spell the obvious out, this
means that your data won't persist between invocations of your bot. So
this is mainly for testing and storing data for a short time.

This module is just a bare bone subclass of
Bot::BasicBot::Pluggable::Store and does not implement any methods of
its own. In a perfect world Bot::BasicBot::Pluggable::Store would just
be a abstract base class, but it was implemented as normale in-memory
storage class. Due to Bot::BasicBot::Pluggable object creation you can
either specify a already created storage object or a string that is
simply appended to "Bot::BasicBot::Pluggable::Store::". So if you just
want to use memory storage you have to load it this way:

  my $bot => Bot::BasicBot::Pluggable->new ( store => Bot::BasicBot::Pluggable::Store->new() );

Now you can use load it as any other storage module:

  my $bot => Bot::BasicBot::Pluggable->new ( store => 'Memory' );

In this way we don't break any existing code.

=head1 AUTHOR

Mario Domgoergen <mdom@cpan.org>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
