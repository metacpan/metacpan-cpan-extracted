package Bot::Backbone::SendPolicy;
$Bot::Backbone::SendPolicy::VERSION = '0.161950';
use v5.10;
use Moose::Role;

# ABSTRACT: Define policies to prevent flooding and other bot no-nos


has bot => (
    is          => 'ro',
    isa         => 'Bot::Backbone::Bot',
    required    => 1,
    weak_ref    => 1,
);


requires 'allow_send';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::SendPolicy - Define policies to prevent flooding and other bot no-nos

=head1 VERSION

version 0.161950

=head1 SYNOPSIS

  package MyBot;
  use v5.14;
  use Bot::Backbone;

  # This policy prevents the bot from sending more than once every 1.5 seconds
  send_policy no_flooding => (
      MinimumInterval => { interval => 1.5 },
  );

  # This policy does the same, but discards messages coming too fast
  send_policy no_flooding_with_prejedice => (
      MinimumInterval => { interval => 1.5, discard => 1 };
  );

  # This policy discards messages repeated within 5 minutes
  send_policy dont_repeat_yourself => (
      MinimumRepeatInterval => { interval => 5*60, discard => 1 };
  );

  service jabber_chat => (
      service => 'JabberChat',
      # your other settings...
      send_policy => 'no_flooding',
  );

  service group_foo => (
      service => 'GroupChat',
      chat    => 'jabber_chat',
      group   => 'foo',
      # your other settings...
      send_policy => 'no_flooding_with_prejudice',
  );

  # Policy that is shared
  my $do_not_repeat = [ 
      Bot::Backbone::SendPolicy::MinimumRepeatInterval->new(
          interval => 300, # 5 * 60
          discar   => 1,
      ),
  ];

  service wikipedia => (
      service => '.Wikipedia',
      chat    => 'group_foo',
      # your other settings...
      send_policies => $do_not_repeat,
  );

  service google_search => (
      service => 'GoogleSearch',
      chat    => 'group_foo',
      # your other settings...
      send_policies => $do_not_repeat,
  );

=head1 DESCRIPTION

Bots are fun and all, but they can easily become annoying. These controls for
preventing a bot from sending too often or repeating itself too frequently can
help to minimize that annoyance.

The purpose of the send policy framework is to allow the bot maintainer to set
policies against any service that may call C<send_message>. The policy set
against that service may delay any message being sent, cause a message to be
discarded, or alter the message.

The framework is designed to be extensible with a couple very useful policies
being provided with the backbone framework.

See L<Bot::Backbone::SendPolicy::MinimumInterval> and
L<Bot::Backbone::SendPolicy::MinimumRepeatInterval>. See L<Bot::Backbone> and
L<Bot::Backbone::Service> for more information on how send policies are defined
and applied.

The rest of this docuemntation describes how to build a send policy
implementation.

=head1 ATTRIBUTES

=head2 bot

This is a back reference to the bot.

=head1 REQUIRED METHODS

=head2 allow_send

  my $send_policy = $policy->allow_send({
      text => 'some message',
      ...
  });

Given a set of options passed to the C<send_message> method of
L<Bot::Backbone::Service::Role::Chat>, return a hash reference containing the
instrucitons on what to do with that message. The C<allow_send> method may also
modify the passed in options to alter the message being posted.

The result may contain the following keys:

=over

=item allow

This is a boolean value. If true, the message will be delivered to the chat. If
it is false, the message is immediately discarded.

This must be set. If not set, an exception will be thrown.

=item after

This is a numeric value that contains a number of fractional sections to wait
utnil the message should be delivered. The message will be put on hold and then
delivered after that amount of wait time has passed.

=back

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
