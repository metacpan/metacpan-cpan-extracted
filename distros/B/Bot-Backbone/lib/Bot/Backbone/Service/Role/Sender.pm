package Bot::Backbone::Service::Role::Sender;
$Bot::Backbone::Service::Role::Sender::VERSION = '0.161950';
use Moose::Role;

# ABSTRACT: Marks a service as one that may send messages


requires qw( send_message send_reply );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::Role::Sender - Marks a service as one that may send messages

=head1 VERSION

version 0.161950

=head1 DESCRIPTION

A sender is a service that provides C<send_message> and C<send_reply> methods.

=head1 REQUIRED METHODS

=head2 send_reply

  $chat->send_reply($message, \%options);

This is often just a wrapper provided around C<send_message>.  The first
argument is the original L<Bot::Backbone::Message> that this is in reply to. 

The second argument is the options to describe the reply being sent.

=head2 send_message

  $chat->send_message(%options);

The options describe the to send.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
