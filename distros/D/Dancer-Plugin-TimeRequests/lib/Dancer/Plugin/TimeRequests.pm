package Dancer::Plugin::TimeRequests;

use strict;
use Dancer::Plugin;
use Dancer qw(:syntax);
use HTML::Table;
use List::Util;
use List::MoreUtils;
use Time::HiRes;

our $VERSION = '0.06';

=head1 NAME

Dancer::Plugin::TimeRequests - log how long requests take and which routes are slow

=head1 DESCRIPTION

A simple Dancer plugin to log how long each request took to process, and also to
gather stats on the average response time for each route - so you can see at a
glance which routes are taking longer than you'd like, therefore where you ought
to start looking to improve performance.

Provides a statistics page giving you a list of your routes, along with their
response times.


=head1 SYNOPSIS

In your Dancer app, load this module:

    use Dancer::Plugin::TimeRequests;

Then, when your app is logging in debug mode, log messages will be generated
showing how logn each request took:

    Request to /foo completed in 4.0011 seconds in ....

To see which routes are slow, hit the URL C</plugin-timerequests>. 

=cut

my %request_times;

hook before => sub {
    my $route_handler = shift;
    var current_handler => $route_handler;
    var request_start_time => Time::HiRes::time();
};

hook after => sub {
    Dancer::Logger::debug(sprintf "Request to %s completed in %.4f seconds",
        request->path,
        Time::HiRes::time() - vars->{request_start_time}
    );
    push @{ $request_times{ vars->{current_handler} } }, 
        Time::HiRes::time() - vars->{request_start_time};
};

get '/plugin-timerequests' => sub {
    # Get the list of routes, and for each one, match up the coderef with our
    # recorded times, and add the timing info, so we can then sort routes by
    # average execution time to produce the output
    my $routes = _get_routes();
    for my $route (@$routes) {
        my $route_times = $request_times{ $route->{route} };
        next unless defined $route_times && scalar @$route_times;

        my ($min, $max) = List::MoreUtils::minmax(@$route_times); 
        $route->{times} = {
            avg => List::Util::sum(@$route_times) / @$route_times,
            min => $min,
            max => $max,
        };
    }

    # Now, we can loop through all routes, slowest first, and output the timing
    # info
    my $table = HTML::Table->new;
    $table->addRow('Route pattern', 'Average', 'Best', 'Worst');
    $table->setRowHead(1);
    for my $route (
        sort { $b->{times}{avg} <=> $a->{times}{avg} }
        grep { exists $_->{times} } @$routes
    ) {
        next unless exists $route->{times};
        my $times = $route->{times};
        $table->addRow(
            $route->{pattern},
            map { sprintf '%.3f', $_ || 0 } @$times{qw(avg min max)},
        );
    }
    return $table->getTable;

};

# Fetch all routes defined.  (Loosely based on code lovingly stolen with no
# shame from Dancer::Plugin::SiteMap - cheers James Ronan (JNRONAN)
# Returns an arrayref of hashrefs describing all routes (with keys pattern 
# and handler)
sub _get_routes {
    my $version = (exists &dancer_version) ? int( dancer_version() ) : 1;
    my @apps    = ($version == 2) ? @{ runner->server->apps }
                                  : Dancer::App->applications;
 
    my @routes;
    for my $app ( @apps ) {
        my $app_routes = ($version == 2) ? $app->routes
                                         : $app->{registry}->{routes};
        
        for my $route_type (keys %$app_routes) {
            for my $route (@{ $app_routes->{$route_type} }) {
                my ($pattern, $handler);
                if ($version == 2) {
                    $pattern = $route->spec_route;
                    $handler = $route->handler;
                } else {
                    $pattern = $route->pattern;
                    $handler = $route->code;
                }
                push @routes, {
                    route   => $route,
                    pattern => $pattern, 
                    handler => $handler,
                };
            }
        }
    }
    debug "list of routes being returned:", \@routes;
    return \@routes;
}


=head1 AUTHOR

David Precious, C<< <davidp at preshweb.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-timerequests at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-TimeRequests>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::TimeRequests


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-TimeRequests>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-TimeRequests>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-TimeRequests>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-TimeRequests/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 David Precious.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Dancer::Plugin::TimeRequests
