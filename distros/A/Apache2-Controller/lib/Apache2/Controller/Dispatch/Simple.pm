package Apache2::Controller::Dispatch::Simple;

=head1 NAME

Apache2::Controller::Dispatch::Simple - simple dispatch mechanism for A2C

=head1 VERSION

Version 1.001.001

=cut

use version;
our $VERSION = version->new('1.001.001');

=head1 SYNOPSIS

 <Location "/subdir">
     SetHandler modperl
     PerlInitHandler MyApp::Dispatch
 </Location>

 # lib/MyApp::Dispatch:

 package MyApp::Dispatch;
 use base qw(
     Apache2::Controller::Dispatch::Simple
 );

 # return hash reference from dispatch_map()
 sub dispatch_map { {            
     foo            => 'MyApp::C::Foo',
     'foo/bar'      => 'MyApp::C::Foo::Bar',
 } }

=head1 DESCRIPTION

Implements find_controller() for Apache2::Controller::Dispatch with
a simple URI-to-controller module mapping.  Your URI's are the keys
of the C<< dispatch_map() >> hash in your base package, and the values are
the Apache2::Controller modules to which those URI's should be dispatched.

This dispatches URI's in a case-insensitive fashion.  It searches from
longest known path to shortest.  For a site with many controllers and
paths, a trie could possibly be more efficient.  Consider that implementation
for another Dispatch plugin module.

=head1 METHODS

=cut

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw( Apache2::Controller::Dispatch );

use Apache2::Controller::X;
use Apache2::Controller::Funk qw( controller_allows_method check_allowed_method );

use Log::Log4perl qw(:easy);
use YAML::Syck;

my %search_uris     = ( );
my %uri_lengths     = ( );

# return, for the class, the dispatch_map hash, uri_length map, & search uri list
sub _get_class_info {
    my ($self) = @_;
    my $class = $self->{class};
    my $dispatch_map = $self->get_dispatch_map();
    my ($uri_length_map, $search_uri_list) = ();
    if (exists $uri_lengths{$class}) {
        $uri_length_map     = $uri_lengths{$class};
        $search_uri_list    = $search_uris{$class};
    }
    else {
        # search dispatch uri keys from longest to shortest
        my @uris = keys %{$dispatch_map};

        a2cx "Upper case characters not allowed in $class dispatch_map "
            ."when using ".__PACKAGE__." to dispatch URIs."
            if grep m/ \p{IsUpper} /mxs, @uris;

        $uri_length_map = $uri_lengths{$class} = { };
        $uri_length_map->{$_} = length $_ for @uris;

        $search_uri_list = $search_uris{$class} = [ 
            sort { $uri_length_map->{$b} <=> $uri_length_map->{$a} } @uris 
        ];

        DEBUG(sub{"search_uris:".Dump(\%search_uris)});
        DEBUG(sub{"uri_lengths:".Dump(\%uri_lengths)});
    }
    return ($dispatch_map, $uri_length_map, $search_uri_list);
}

=head2 find_controller

Find the controller and method for a given URI from the data
set in the dispatch class module.

=cut

sub find_controller {
    my ($self) = @_;

    my $class = $self->{class};

    my ($dispatch_map, $uri_length_map, $search_uri_list) 
        = $self->_get_class_info();

    # figure out what most-specific path matches this URI.
    my $r = $self->{r};

    my $location = $r->location();

    my $uri = $r->uri();
    DEBUG(sub{Dump({
        uri             => $uri,
        location        => $location,
    })});

    $uri = substr $uri, length $location;

    DEBUG("uri becomes '$uri'");

    if ($uri) {
        # trim duplicate /'s
        $uri =~ s{ /{2,} }{/}mxsg;

        # chop leading /
        $uri = substr($uri, 1) if substr($uri, 0, 1) eq '/';
    }
    else {
        # 'default' is the default URI for top-level requests
        $uri = 'default';
    }
    my $uri_len = length $uri;
    my $uri_lc  = lc $uri;

    my ($controller, $method, $relative_uri) = ();
    my @path_args = ();

    SEARCH_URI:
    for my $search_uri (
        grep $uri_length_map->{$_} <= $uri_len, @{$search_uri_list} 
        ) {
        my $len = $uri_length_map->{$search_uri};
        my $fragment = substr $uri_lc, 0, $len;
        DEBUG("search_uri '$search_uri', len $len, fragment '$fragment'");
        if ($fragment eq $search_uri) {

            DEBUG("fragment match found: '$fragment'");

            # if next character in URI is not / or end of string, this is not it,
            # only a partial (/foo/barrybonds/stats should not match /foo/bar)
            my $next_char = substr $uri, $len, 1;
            if ($next_char && $next_char ne '/') {
                DEBUG("only partial match.  next SEARCH_URI...");
                next SEARCH_URI;
            }

            $controller = $dispatch_map->{$search_uri} 
                || a2cx
                  "No controller assigned in $class dispatch map for $search_uri.";
            
            # extract the method and the rest of the path args from the uri
            if ($next_char) {
                my $rest_of_uri = substr $uri, $len + 1;
                my $first_arg;
                ($first_arg, @path_args) = split '/', $rest_of_uri;

                DEBUG sub { Dump({
                    rest_of_uri     => $rest_of_uri,
                    first_arg       => defined $first_arg 
                                    ?   "'$first_arg'" 
                                    :   '[undef]'
                                    ,
                    path_args       => \@path_args,
                }) };

                # if the first field in the rest of the uri is a valid method,
                # assume that is the thing to use.
                if  (   defined $first_arg 
                    &&  controller_allows_method($controller, $first_arg)
                    ) {
                    $method = $first_arg;
                }
                # else use the 'default' method
                else {
                    $method = 'default';
                    unshift @path_args, $first_arg if defined $first_arg;
                }
                $relative_uri = $search_uri;
            }
            last SEARCH_URI;
        }
    }

    DEBUG($controller ? "Found controller '$controller'" : "no controller found");
    DEBUG($method     ? "Found method '$method'"         : "no method found");

    if (!$controller) {
        DEBUG("No controller found.  Using default module from dispatch map.");

        $controller = $dispatch_map->{default} 
            || a2cx "No 'default' controller assigned in $class dispatch map.";

        my $first_arg;
        ($first_arg, @path_args) = split '/', $uri;
        if (controller_allows_method($controller => $first_arg)) {
            $method = $first_arg;
        }
        else {
            $method = 'default';
            unshift @path_args, $first_arg;
        }
    }

    a2cx "No controller module found." if !$controller;

    $method ||= 'default';

    # relative_uri can be blank.  i must have introduced a regression before
    # when trying to set it to $uri if it was blank.  that resulted in
    # 'default/default.html' in Apache2::Controller:Render::Template tests.

    check_allowed_method($controller, $method);

    DEBUG(sub {Dump({
        apache_location     => $r->location(),
        apache_uri          => $r->uri(),
        my_uri              => $uri,
        controller          => $controller,
        method              => $method,
        path_args           => \@path_args,
        relative_uri        => $relative_uri,
    })});

    my $pnotes_a2c = $r->pnotes->{a2c} ||= { };

    $pnotes_a2c->{method}       = $method;
    $pnotes_a2c->{relative_uri} = $relative_uri;
    $pnotes_a2c->{controller}   = $controller;
    $pnotes_a2c->{path_args}    = \@path_args;

    return $controller;
}

=head1 SEE ALSO

L<Apache2::Controller::Dispatch>

L<Apache2::Controller::Dispatch::HashTree>

L<Apache2::Controller>

=head1 AUTHOR

Mark Hedges, C<hedges +(a t)| formdata.biz>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Mark Hedges.  CPAN: markle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is provided as-is, with no warranty 
and no guarantee of fitness
for any particular purpose.

=cut


1;
