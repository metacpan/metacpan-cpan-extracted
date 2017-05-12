package Bot::Backbone::Bot::Role::GroupChat;
$Bot::Backbone::Bot::Role::GroupChat::VERSION = '0.161950';
use v5.10;
use Moose::Role;

use List::Util qw( first );

use namespace::autoclean;

# ABSTRACT: Provides some group related help tools


sub list_group_names {
    my $self = shift;
    return map { $_->group } 
          grep { $_->isa('Bot::Backbone::Service::GroupChat') }
                 $self->list_services;
}


sub find_group {
    my ($self, $name) = @_;
    return first { $_->isa('Bot::Backbone::Service::GroupChat')
               and $_->group eq $name } $self->list_services;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Bot::Role::GroupChat - Provides some group related help tools

=head1 VERSION

version 0.161950

=head1 SYNOPSIS

  service group_foo => (
      service => 'GroupChat',
      chat    => 'jabber_chat',
      group   => 'foo',
  );

  service group_bar => (
      service => 'GroupChat',
      chat    => 'jabber_chat',
      group   => 'bar',
  );

  ...

  for my $name ($bot->list_group_names) { say " * $name" }

  my $chat = $bot->find_group('foo');
  $chat->send_message({ text => 'just to group foo' });

=head1 DESCRIPTION

This role is automatically applied to any bot that has one or more L<Bot::Backbone::Service::GroupChat> services.

=head1 METHODS

=head2 list_group_names

Returns the names of all the groups that this bot has joined or intends on joining.

=head2 find_group

  my $chat = $bot->find_group('foo');

Returns the L<Bot::Backbone::Service::GroupChat> that entered the named group.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
