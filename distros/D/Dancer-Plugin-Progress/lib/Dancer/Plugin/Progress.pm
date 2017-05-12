# vim:ts=4:sw=4:expandtab
package Dancer::Plugin::Progress;
# ABSTRACT: Dancer plugin to display a progress bar during long-running requests

use strict;
use warnings;

our $VERSION = '0.1';

use Dancer ':syntax';
use Dancer::Plugin;

my %ops;

sub _get_id {
    my ($name) = @_;

    my $running = session('_running');
    if (!exists($running->{$name})) {
        die "Long running action $name not found in session!";
    }
    return $running->{$name};
}

register long_running => sub {
    my ($name, $max, $init) = @_;

    my $state = {
        _name => $name,
        _max => $max,
        _progress => 0,
    };

    $init->($state);

    # Generate a unique identifier, similar to build_id in
    # Dancer::Session::Abstract
    my $id = "";
    for my $seed (rand(1000), rand(1000), rand(1000)) {
        my $c = 0;
        $c += ord($_) for (split //, File::Spec->rel2abs(File::Spec->curdir));
        my $current = int($seed * 1000000000) + time + $$ + $c;
        $id .= $current;
    }

    $ops{$id} = $state;
    my $running = session('_running');
    $running ||= {};
    $running->{$name} = $id;
    session '_running' => $running;
};

sub _progress {
    my ($name, $progress, $data) = @_;

    my $id = _get_id($name);

    if (!defined($progress)) {
        # We should return the progress, not update
        my $result = {
            progress => $ops{$id}->{_progress},
            max => $ops{$id}->{_max},
            data => $ops{$id}->{_data},
        };
        delete $ops{$id} unless defined($result->{progress});
        return $result;
    }

    # Update progress
    $ops{$id}->{_progress} = $progress;
    $ops{$id}->{_data} = $data if defined($data);
}

register progress => sub { _progress(@_) };

register finished => sub {
    my ($name) = @_;
    my $id = _get_id($name);
    undef $ops{$id}->{_progress};
};

get '/_progress/:name' => sub {
    header 'Content-Type' => 'application/json';
    to_json(_progress(params->{name}));
};

register_plugin;

1;

=pod

=head1 NAME

Dancer::Plugin::Progress - Dancer plugin to display a progress bar during
long-running requests

=head1 VERSION

version 0.1

=head1 DESCRIPTION

This plugin helps you displaying a progress bar during long-running requests
(routes that take multiple seconds to finish, for example due to network
latency to a backend).

=head1 SYNOPSIS

    use Dancer::Plugin::Progress;
    use AnyEvent;

    get '/some_timer' => sub {
        long_running 'some_timer', 5, sub {
            my $state = shift;

            $state->{timer} =
            AnyEvent->timer(after => 1, interval => 1, cb => sub {
                if (++$state->{cnt} == 5) {
                    undef $state->{timer};
                    finished 'some_timer';
                } else {
                    progress 'some_timer' => $state->{cnt};
                }
            });
        };

        template 'progressbar', { name => 'some_timer' };
    };

Then set up a template like this:

    <div id="progress">Please enable JavaScript</div>

    <script type="text/javascript">
    function pollProgress(name, interval) {
        $.getJSON('/_progress/' + name, function(pg) {
            if (pg.progress === null) {
                $('#progress').text('done!');
                return;
            }
            $('#progress').text('progress: ' + pg.progress + ' / ' + pg.max);
            setTimeout(function() {
                    pollProgress(name, interval);
                }, interval);
        });
    }

    $(document).ready(function() {
        pollProgress('<% name %>', 1000);
    });
    </script>

=head1 METHODS

=head2 long_running($name, $max, $init)

Sets up the necessary state. The C<$name> identifies this request in the user's
session, so you need to chose different C<$name>s for different operations.
C<$max> specifies the maximum progress, so if you plan to make 5 requests to
your backend until this operation is complete, set C<$max> to 5. If you don't
need it, just set it to 0.

C<$init> should be a CodeRef to trigger your operation (to initialize a timer,
some asynchronous HTTP request, etc.). It will be called with a HashRef to the
initial state that L<Dancer::Plugin::Progress> keeps for this operation, so you
can put your AnyEvent guards in there for example.

=head2 progress($name[, $progress[, $data]])

If called with a single argument, this returns a hash describing the current
progress:

    {
        progress => 1,
        max => 5,
        data => "some data"
    }

If called with a C<$progress> argument, it updates the progress. You can use
any scalar here, L<Dancer::Plugin::Progress> will just use it without making
any assumptions.

Additionally, you can pass C<$data>. While there is no difference between
C<$progress> and C<$data> (both are arbitrary scalars), it makes the separation
between a linear progress (step 2 of 5) plus an additional status message
("requesting http://www.slashdot.org/") more clear.

=head2 finished($name)

Marks the operation as finished. At the next request polling the progress, null
is returned as 'progress' member of the hash and the state is cleaned up (that
means you must not poll the request after receiving a hash with
'progress':null).

When calling C<finished>, you should also undef your guard objects, if any.

=head1 INNER WORKINGS

L<Dancer::Plugin::Progress> keeps state by generating a unique ID for every
call of C<long_running> with the same C<$name> parameter and stores the ID
in the user's session under the key '_running'.

A route handler is installed for '/_progress/:name', which should be polled
(we resort to polling due to the lack of better mechanisms in Dancer/jQuery)
by the user.

=head1 AUTHOR

Michael Stapelberg, C<< <michael at stapelberg.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-progress at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-Progress>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Progress

You can also look for information at:

=over 2

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-Progress>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Michael Stapelberg.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
