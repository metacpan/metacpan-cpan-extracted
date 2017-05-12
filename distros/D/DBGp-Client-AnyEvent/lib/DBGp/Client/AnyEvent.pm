package DBGp::Client::AnyEvent;

use strict;
use warnings;

=head1 NAME

DBGp::Client::AnyEvent - AnyEvent-based client for the DBGp debugger protocol

=head1 SYNOPSIS

    $connected = AnyEvent->condvar;
    $listener = DBGp::Client::AnyEvent::Listener->new(
        port          => 9000,
        on_connection => sub { $connected->send($_[0]) },
    );
    $listener->listen;

    $client = $connected->recv;
    $client->on_stream(sub {
        printf "Output from process (%s)\n---\n%s\n---\n",
            $_[0]->type, $_[0]->content;
    });
    $wait_res = $client->send_command(
        undef, # no callback
        'breakpoint_set', '-t', 'conditional',
                          '-f', 'file:///path/to/file.pl',
                          '-n', $line,
                          '--',
                          encode_base64("$command; 0"),
    );
    $res = $wait_res->recv;
    die $res->message if $res->is_error;

    # send and receive other commands

=head1 DESCRIPTION

A thin L<AnyEvent> wrapper on top of L<DBGp::Client>.

=cut

our $VERSION = '0.05';

1;

__END__

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

Copyright (c) 2016 Mattia Barbon. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
