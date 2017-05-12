package BusyBird;
use v5.8.0;
use strict;
use warnings;
use BusyBird::Main;
use BusyBird::Main::PSGI qw(create_psgi_app);
use Exporter 5.57 qw(import);

our $VERSION = '0.12';

our @EXPORT = our @EXPORT_OK = qw(busybird timeline end);

my $singleton_main;

sub busybird {
    return defined($singleton_main)
        ? $singleton_main : ($singleton_main = BusyBird::Main->new);
}

sub timeline {
    my ($timeline_name) = @_;
    return busybird()->timeline($timeline_name);
}

sub end {
    return create_psgi_app(busybird());
}

1;

__END__

=pod

=head1 NAME

BusyBird - a multi-level Web-based timeline viewer

=head1 DESCRIPTION

L<BusyBird> is a personal Web-based timeline viewer application.
You can think of it as a Twitter client, but L<BusyBird> is more generic and focused on viewing.

L<BusyBird> accepts data called B<Statuses> from its RESTful Web API.
The received statuses are stored to one or more B<Timelines>.
You can view those statuses in a timeline by a Web browser.

    [ Statuses ]
         |       +----------------+
         |       |    BusyBird    |
        HTTP     |                |
        POST --> | [ Timeline 1 ]----+
                 | [ Timeline 2 ] |  |
                 |       ...      | HTTP
                 +----------------+  |
                                     v
                              [ Web Browser ]
                                     |
                                    YOU

=head2 Features

=over

=item *

L<BusyBird> is extremely B<programmable>.
You are free to customize L<BusyBird> to view any statuses, e.g.,
Twitter tweets, RSS feeds, IRC chat logs, system log files etc.
In fact L<BusyBird> is not much of use without programming.

=item *

L<BusyBird> has well-documented B<Web API>.
You can easily write scripts that GET/POST statuses from/to a L<BusyBird> instance.
Some endpoints support real-time notification via HTTP long-polling.

=item *

L<BusyBird> maintains B<read/unread> states of individual statuses.
You can mark statuses as "read" via Web API.

=item *

L<BusyBird> renders statuses based on their B<< Status Levels >>.
Statuses whose level is below the threshold are dynamically hidden,
so you can focus on more relevant statuses.
Status levels are set by you, not by L<BusyBird>.

=back

=head1 SCREENSHOTS

L<https://github.com/debug-ito/busybird/wiki/Screenshots>

=head1 QUICK START

Example in Ubuntu Linux.

=over

=item *

Install C<gcc>, C<make> and C<curl>

    $ sudo apt-get install build-essential curl

=item *

Install

    $ curl -L http://cpanmin.us/ | perl - -n BusyBird
    $ export PERL5LIB="$HOME/perl5/lib/perl5:$PERL5LIB"
    $ export PATH="$HOME/perl5/bin:$PATH"

=item *

Run

    $ busybird
    Twiggy: Accepting connections at http://127.0.0.1:5000/

=item *

Open timelines

    $ firefox http://localhost:5000/

=item *

Post a status

    $ curl -d '{"text":"hello, world!"}' http://localhost:5000/timelines/home/statuses.json

=back

See L<BusyBird::Manual::Tutorial> for detail.

=head1 DOCUMENTATION

=over

=item L<BusyBird::Manual::Tutorial>

If you are new to L<BusyBird>, you should read this first.

=item L<BusyBird::Manual::WebAPI>

Reference manual of L<BusyBird> Web API.

=item L<BusyBird::Manual::Status>

Object structure of L<BusyBird> statuses.

=item L<BusyBird::Manual::Config>

How to configure L<BusyBird>.

=item L<BusyBird::Manual::Config::Advanced>

Advanced topics about configuring L<BusyBird>.

=item ...and others.

Documentation for various L<BusyBird> modules may be helpful when you customize
your L<BusyBird> instance.

=back

=head1 AS A MODULE

Below is detailed documentation of L<BusyBird> module.
Casual users need not to read it.

As a module, L<BusyBird> maintains a singleton L<BusyBird::Main> object,
and exports some functions to manipulate the singleton.
That way, L<BusyBird> makes it easy for users to write their C<config.psgi> file.

=head1 SYNOPSIS

In your C<~/.busybird/config.psgi> file...

    use BusyBird;
    
    busybird->set_config(
        time_zone => "+0900",
    );
    
    timeline("twitter_work")->set_config(
        time_zone => "America/Chicago"
    );
    timeline("twitter_private");
    
    end;


=head1 EXPORTED FUNCTIONS

The following functions are exported by default.

=head2 $main = busybird()

Returns the singleton L<BusyBird::Main> object.

=head2 $timeline = timeline($timeline_name)

Returns the L<BusyBird::Timeline> object named C<$timeline_name> from the singleton.
If there is no such timeline, it automatically creates the timeline.

This is equivalent to C<< busybird()->timeline($timeline_name) >>.

=head2 $psgi_app = end()

Returns a L<PSGI> application object from the singleton L<BusyBird::Main> object.
This is supposed to be called at the end of C<config.psgi> file.

This is equivalent to C<< BusyBird::Main::PSGI::create_psgi_app(busybird()) >>.

=head1 TECHNOLOGIES USED

=over

=item *

L<jQuery|http://jquery.com/>

=item *

L<Bootstrap|http://getbootstrap.com/>, which includes L<Glyphicon|http://glyphicons.com/>

=item *

L<q.js|https://github.com/kriskowal/q>

=item *

L<spin.js|http://fgnass.github.io/spin.js/>

=item *

... and a lot of Perl modules

=back

=head1 REPOSITORY

L<https://github.com/debug-ito/busybird>

=head1 BUGS AND FEATURE REQUESTS

Please report bugs and feature requests to my Github issues
L<https://github.com/debug-ito/busybird/issues>.

Although I prefer Github, non-Github users can use CPAN RT
L<https://rt.cpan.org/Public/Dist/Display.html?Name=BusyBird>.
Please send email to C<bug-BusyBird at rt.cpan.org> to report bugs
if you do not have CPAN RT account.


=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>

=head1 CONTRIBUTORS

=over

=item *

Keisuke Minami

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
