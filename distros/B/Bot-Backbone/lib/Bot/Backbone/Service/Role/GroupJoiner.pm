package Bot::Backbone::Service::Role::GroupJoiner;
$Bot::Backbone::Service::Role::GroupJoiner::VERSION = '0.161950';
use v5.10;
use Moose::Role;

# ABSTRACT: Chat services that can join a chat group


requires 'join_group';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::Role::GroupJoiner - Chat services that can join a chat group

=head1 VERSION

version 0.161950

=head1 DESCRIPTION

This is only useful to chat services (probably).

=head1 REQUIRED METHODS

=head2 join_group

  $chat->join_group(\%options);

This method will cause the service to join the group described by the options in
the way described by the options. Generally, the options will include (but are
not limited to and all of these might not be supported):

=over

=item group

This is the name of the group to join. Every implementation must support this
option.

=item nickname

This is the nickname to give the bot within this group.

=back

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
