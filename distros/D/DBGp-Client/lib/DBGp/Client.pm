package DBGp::Client;

use strict;
use warnings;

=head1 NAME

DBGp::Client - simple client for the DBGp debugger protocol

=head1 SYNOPSIS

    $listener = DBGp::Client::Listener->new(port => 9000);
    $listener->listen;

    while (my $client = $listener->accept) {
        # set a conditional breakpoint that never triggers,
        # but has side-effects in the condition
        $command = 'require Data::Dumper; print Data::Dumper::Dumper($var);';
        $res = $client->send_command(
            'breakpoint_set', '-t', 'conditional',
                              '-f', 'file:///path/to/file.pl',
                              '-n', $line,
                              '--',
                              encode_base64("$command; 0"),
        );
        die $res->message if $res->is_error;

        # continue execution
        $res = $client->send_command('run');
        die $res->message if $res->is_error;
    }

=head1 DESCRIPTION

A simple client for the DBGp debugger protocol; it can be used for
testing a debugger implementation or scripting a program through the
debugger interface.

See L<DBGp::Client::Listener> and L<DBGp::Client::Connection> for API
documentation.

=cut

our $VERSION = '0.12';

1;

__END__

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

Copyright (c) 2015-2016 Mattia Barbon. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
