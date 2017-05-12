package AnyMQ::Pg;

use 5.006;

use strict;
use warnings;

=head1 NAME

AnyMQ::Pg - Use built-in PostgreSQL 'LISTEN' and 'NOTIFY' commands for message-passing.

=cut

our $VERSION = '0.01';

=head1 ABOUT

Enables the use of PostgreSQL as a backend for message queueing functionality with L<AnyMQ>.

Many people are probably unaware that PostgreSQL has a built-in asynchronous publish/subscribe mechanism, but it does.

L<http://www.postgresql.org/docs/9.1/interactive/sql-listen.html>

=head1 SYNOPSIS

    my $bus = AnyMQ->new_with_traits(
        traits     => ['Pg'],
        dsn        => 'dbname=postgres user=postgres',
        on_connect => sub { ... },
        on_error   => sub { ... },
    );

    # see AnyMQ docs for usage
    my $topic = $bus->topic('my_event');
    my $listen_watcher = $bus->new_listener($topic);
    $listen_watcher->poll(sub {
        my ($evt) = @_;
        warn "Got notified of my_event: " . Dumper($evt);
    });
    $topic->publish({ foo => 123 });
    AE::cv->recv;

=head1 SEE ALSO

L<AnyEvent::Pg>, L<Web::Hippie>, L<Web::Hippie::PubSub>

=head1 AUTHOR

Mischa Spiegelmock, C<< <revmischa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mischa Spiegelmock.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
