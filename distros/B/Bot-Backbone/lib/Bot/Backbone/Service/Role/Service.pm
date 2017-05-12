package Bot::Backbone::Service::Role::Service;
$Bot::Backbone::Service::Role::Service::VERSION = '0.161950';
use Moose::Role;

# ABSTRACT: Role implemented by all bot services


has name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);


has bot => (
    is          => 'ro',
    isa         => 'Bot::Backbone::Bot',
    required    => 1,
    weak_ref    => 1,
    handles     => {
        get_service => 'get_service',
    },
);


requires qw( initialize );


sub shutdown { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::Role::Service - Role implemented by all bot services

=head1 VERSION

version 0.161950

=head1 DESCRIPTION

All bot services must implement this role.

=head1 ATTRIBUTES

=head2 name

This is the name of the service configured for the bot. It will be unique for
that bot.

=head2 bot

This is a back link to the L<Bot::Backbone::Bot> that owns this service.

=head1 REQUIRED METHODS

=head2 initialize

This method will be called after construction, but before the event loop starts.
This is where the service should initalize connections, prepare to receive
messages, etc.

It will be passed no arguments.

=head1 METHODS

=head2 shutdown

This method will be called just before the bot destroys the service and exits.
If called, your service is expected to terminate any pending jobs, kill any
child processes, and clean up so that the bot will exit cleanly.

A default implementation is provided, which does nothing.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
