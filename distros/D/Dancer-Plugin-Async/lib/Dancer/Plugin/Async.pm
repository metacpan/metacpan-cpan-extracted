# vim:ts=4:sw=4:expandtab
package Dancer::Plugin::Async;
# ABSTRACT: Dancer plugin to build async route handlers with Twiggy

use strict;
use warnings;

our $VERSION = '0.1';

use Dancer ':syntax';
use Dancer::Plugin;
use Data::Dumper;
use v5.10;

register async => \&async;

register respond => sub { request->env->{'twiggy.respond'} };

sub async {
    my ($method, $pattern, @rest) = @_;

    #say "async route handler for $pattern with rest = " . Dumper(\@rest);

    # Ensure we got an arrayref
    $method = [ $method] unless ref($method) eq 'ARRAY';

    any $method => $pattern => sub {
        # call the original route
        $rest[0]->();

        # return the special 'HTTP status code' -1
        return Dancer::Response->new(status => -1);
    };
}

sub app {
    return sub {
        my $env = shift;
        say "uri = " . $env->{REQUEST_URI};
        return sub {
            my $respond = shift;

            $env->{'twiggy.respond'} = $respond;
            my $request = Dancer::Request->new($env);
            my $result = Dancer->dance($request);
            # We respond immediately if the route handler returned a valid status code
            $respond->($result) if $result->[0] != -1;
        };
    };
}

register_plugin;

1;

=pod

=head1 NAME

Dancer::Plugin::Async - Dancer plugin to write async request handlers with Twiggy

=head1 VERSION

version 0.1

=head1 DESCRIPTION

This plugin helps you to write async web applications (or partly async web
apps) using Twiggy and Dancer. It provides the C<async> keyword and a default
Application that you can use with Plack.

=head1 SYNOPSIS

In your lib/myapp.pm:

    use Dancer::Plugin::Async;
    use AnyEvent;

    # Async request handler, responds when the timer triggers
    async 'get' => '/timer' => sub {
        my $respond = respond;

        my $t; $t = AnyEvent->timer(after => 1, cb => sub {
            $respond->([ 200, [], [ 'foo!' ]]);
        });
    };

    # Normal Dancer route handler, blocking
    get '/blocking' => sub {
        redirect '/timer';
    };

In your bin/app.pl:

    use Dancer;
    use Dancer::Plugin::Async;
    use Twiggy;
    use AnyEvent;
    use myapp;
    use EV;

    my $server = Twiggy::Server->new(
        host => '0.0.0.0',
        port => 3000,
    );

    $server->register_service(Dancer::Plugin::Async::app());

    EV::loop

=head1 PROBLEMS

In the callbacks (for example of the timer in the C<SYNOPSIS>), you cannot use
many of the normal Dancer keywords such as template, redirect, etc. This is due
to Dancer accessing Dancer::SharedData, which is not available later on. If
anyone has a good idea on how to solve this problem, suggestions/patches are
very welcome.

=head1 AUTHOR

Michael Stapelberg, C<< <michael at stapelberg.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-async at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-Async>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Async

You can also look for information at:

=over 2

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-Async>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Michael Stapelberg.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
