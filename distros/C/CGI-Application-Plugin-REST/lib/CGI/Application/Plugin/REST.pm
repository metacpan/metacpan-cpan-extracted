
=head1 NAME

CGI::Application::Plugin::REST - Helps implement RESTful architecture in CGI applications

=head1 SYNOPSIS

    package WidgetView;
    use base qw( CGI::Application );
    use CGI::Application::Plugin::REST qw( rest_route rest_param );

    sub setup {
        my ($self) = @_;

        $self->rest_route({
            '/widget'                   => {
                'GET'    => 'showlist',
                'POST'   => {
                    'application/xml' => 'new_widget',
                },
            },
            '/widget/:id'               => {
                'GET'    => 'showdetail',
            },
        };
    }

    sub new_widget {
        my ($self) = @_;

        # make a new widget
   }

    sub showdetail {
        my ($self) = @_;

        my $id = $self->rest_param('id');

        # display the widget with the id $id.
   }

    sub showlist {
        my ($self) = @_;

        # show the entire list of widgets.
   }

   1;

=head1 ABSTRACT

If you use the L<CGI::Application|CGI::Application> framework, this plugin will help you create
a RESTful (that's the common term for "using REST") architecture by
abstracting out a lot of the busy work needed to make it happen.

=cut

package CGI::Application::Plugin::REST;

use warnings;
use strict;
use Carp qw( croak );
use English qw/ -no_match_vars /;
use REST::Utils qw/ media_type request_method /;

=head1 VERSION

This document describes CGI::Application::Plugin::REST Version 0.3

=cut

our $VERSION = '0.3';

our @EXPORT_OK =
  qw/ rest_error_mode rest_param rest_resource rest_route rest_route_info
  rest_route_prefix /;

our %EXPORT_TAGS = ( 'all' => [@EXPORT_OK] );

=head1 DESCRIPTION

REST stands for REpresentational State Transfer. It is an architecture for web
applications that tries to leverage the existing infrastructure of the World
Wide Web such as URIs, MIME media types, and HTTP instead of building up
protocols and functions on top of them.

This plugin contains a number of functions to support the various REST
concepts. They try to use existing L<CGI::Application|CGI::Application> functionality
wherever possible.

C<use>'ing this plugin will intercept L<CGI::Application|CGI::Application>'s standard dispatch
mechanism.  Instead of being selected based on a query parameter like C<rm>,
the run mode will be determined by comparing URI patterns defined in your app
with the L<rest_route|rest_route()> method.  (Referred from here on, as "routes".)
Optionally, specific HTTP methods or MIME media types can be defined in a
route too.  One by one, each entry in the reverse asciibetically sorted table
of defined routes is compared to the incoming HTTP request and the first
successful match is selected.  The run mode mapped to that route is then
called.

This is done via overriding L<CGI::Application|CGI::Application>'s C<mode_param()> function so
it should be compatible with other L<CGI::Application|CGI::Application> plugins.

=head2 DevPopup Support

If you are using L<C::A::P::DevPopup|CGI::Application::Plugin::DevPopup> (i.e. the environment
variable C<CAP_DEVPOPUP_EXEC> is set,) C<use>'ing this module will register a
callback which will add debug information about the current route (See L<rest_route_info|rest_route_info()>),
parameters (See L<rest_param|rest_param()>) etc.

=head1 FUNCTIONS

The following functions are available.  None of them are exported by default.
You can use the C<:all> tag to import all public functions.

=cut

# Plug in to CGI::Application and setup our callbacks
#
sub import {
    my $caller = scalar caller;

    $caller->add_callback(
        'init',
        sub {
            my ($self) = @_;
            $self->mode_param( \&_rest_dispatch );

            return;
        }
    );
    if ( exists $ENV{'CAP_DEVPOPUP_EXEC'} ) {
        $caller->add_callback( 'devpopup_report', \&_rest_devpopup );
    }
    goto &Exporter::import;
}

# Callback for CGI::Application::Plugin::DevPopup which provides debug info.
#
sub _rest_devpopup {
    my ( $self, $outputref ) = @_;

    my $report = "<table>\n";
    foreach my $key ( sort keys %{ $self->{'__r_params'} } ) {
        my $name = $key;
        $name =~ s/_/ /gmsx;
        $report .= join q{},
          (
            "<tr><td>$name: </td>",        '<td colspan="2">',
            $self->{'__r_params'}->{$key}, "</td></tr>\n"
          );
    }

    # This bit is complicated but necessary as rest_param needs a
    # nested table.
    my @params = rest_param($self);
    my $rows   = scalar @params;
    $report .= qq{<tr><td rowspan="$rows">parameters: </td>};
    foreach my $param (@params) {
        if ( $param ne $params[0] ) {
            $report .= '<tr>';
        }
        $report .= join q{},
          (
            qq{<td>$param: </td><td>},
            rest_param( $self, $param ),
            "</td></tr>\n"
          );
    }
    $report .= "</table>\n";

    $self->devpopup->add_report(
        title   => 'CGI::Application::Plugin::REST',
        summary => 'Information on the current REST dispatch',
        report  => $report,
    );

    return;
}

# mode_param() callback to set the run mode based on the request URI.
#
sub _rest_dispatch {
    my ($self) = @_;

    my $q    = $self->query;
    my $path = $q->path_info;

    # get the module name from the table
    if ( !exists $self->{'__rest_dispatch_table'} ) {
        $self->header_add( -status => '500 No Dispatch Table' );
        return rest_error_mode( $self, $EVAL_ERROR );
    }

    # look at each rule and stop when we get a match
    foreach my $rule ( reverse sort keys %{ $self->{'__rest_dispatch_table'} } )
    {
        my @names = ();

        # $rule will be transformed later so save the original form first.
        my $origrule = $rule;
        $rule = rest_route_prefix($self) . $rule;

        # translate the rule into a regular expression, but remember where
        # the named args are.
        # '/:foo' will become '/([^\/]*)'
        # and
        # '/:bar?' will become '/?([^\/]*)?'
        # and then remember which position it matches
        $rule =~ s{
                        (^ | /)                 # beginning or a /
                        (: ([^/?]+) ([?])?)     # stuff in between
                }{
                        push(@names, $3);
                        $1 . ( $4 ? '?( [^/]* )?' : '([^/]*)')
                }egsmx;

        # '/*' onwards will become '(.*)\$'
        if ( $rule =~ m{/[*] .* $}msx ) {
            $rule =~ s{(/[*] .* )$}{/(.*)\$}msx;
            push @names, 'dispatch_uri_remainder';
        }

        # if we found a match, then run with it
        if ( my @values = ( $path =~ m{^$rule$}msx ) ) {

            $self->{'__match'} = $path;
            my $table = $self->{'__rest_dispatch_table'}->{$origrule};

            # next check request method.
            my $method = request_method($q);

            if ( exists $table->{$method} ) {
                $table = $table->{$method};
            }
            elsif ( exists $table->{q{*}} ) {
                $table = $table->{q{*}};
            }
            else {
                $self->header_add(
                    -status => "405 Method '$method' Not Allowed",
                    -allow  => ( join q{, }, sort keys %{$table} ),
                );
                return rest_error_mode( $self, $EVAL_ERROR );
            }

            # then check MIME media type
            my @types = keys %{$table};
            my $preferred = media_type( $q, \@types );
            if ( !defined $preferred || $preferred eq q{} ) {
                $preferred = q{*/*};
            }
            my $rm_name = $table->{$preferred};

            if ( !defined $rm_name ) {
                $self->header_add( -status => '415 Unsupported Media Type' );
                return rest_error_mode( $self, $EVAL_ERROR );
            }

            my $sub;
            if ( ref $rm_name eq 'CODE' ) {
                $sub = $self->$rm_name;
            }
            else {
                $sub = eval { return $self->can($rm_name); };
            }
            if ( !defined $sub ) {
                $self->header_add(
                    -status => "501 Function '$rm_name' Doesn't Exist" );
                return rest_error_mode( $self, $EVAL_ERROR );
            }

            $self->param( 'rm', $rm_name );

            my %named_args;

            if (@names) {
                @named_args{@names} = @values;
                rest_param( $self, %named_args );
            }

            $self->{'__r_params'} = {
                'path_received' => $path,
                'rule_matched'  => $origrule,
                'runmode'       => $rm_name,
                'method'        => $method,
                'mimetype'      => $preferred,
            };

            return $rm_name;
        }
    }

    $self->header_add( -status => '404 No Route Found' );
    return rest_error_mode( $self, $EVAL_ERROR );
}

=head2 rest_error_mode()

This function gets or sets the run mode which is called if an error occurs
during the dispatch process.  In this run mode, you can do whatever error
processing or clean up is needed by your application.

If no error mode is defined, the start mode will be returned.

Example 1:

    $self->rest_error_mode('my_error_mode');
    my $em = $self->rest_error_mode; # $em equals 'my_error_mode'.

Why isn't the standard L<CGI::Application|CGI::Application> error mode mechanism used? The
problem is that at the point L<C::A::P::REST|CGI::Application::Plugin::REST>
plugs into the dispatch process, the error mode has not been defined.  You
might also want to use L<rest_error_mode|rest_error_mode()> in your own code to do a different
sort of handling for errors in your REST API (which will typically only
require setting the HTTP status code) as opposed to handling for end user
errors.

Your rest_error_mode handler function will receive as a parameter the value of C<$@>
if any.

=cut

sub rest_error_mode {
    my ( $self, $error_mode ) = @_;

    # First use?  Create new __rest_error_mode
    if ( !exists( $self->{'__rest_error_mode'} ) ) {
        $self->{'__rest_error_mode'} = $self->start_mode;
    }

    # If data is provided, set it.
    if ( defined $error_mode ) {
        $self->{'__rest_error_mode'} = $error_mode;
        $self->run_modes( [$error_mode] );
    }

    return $self->{'__rest_error_mode'};
}

=head2 rest_param()

The C<rest_param> function is used to retrieve or set named parameters
defined by the L<rest_route|rest_route()> function. it can be called in three ways.

=over 4

=item with no arguments.

Returns a sorted list of the defined parameters in list context or the number
of defined parameters in scalar context.

    my @params     = $self->rest_param();
    my $num_params = $self->rest_param();

=item with a single scalar argument.

The value of the parameter with the name of the argument will be returned.

    my $color = $self->rest_param('color');

=item with named arguments

Although you will mostly use this function to retrieve parameters, they can
also be set for one or more sets of  keys and values.

    $self->rest_param(filename => 'logo.jpg', height => 50, width => 100);

You could also use a hashref.

    my $arg_ref = { filename => 'logo.jpg', height => 50, width => 100 };
    $self->rest_param($arg_ref);

The value of a parameter need not be a scalar, it could be any any sort of
reference even a coderef.

    $self->rest_param(number => \&pick_a_random_number);

In this case, the function does not return anything.

=back

=cut

sub rest_param {
    my ( $self, @args ) = @_;

    if ( !exists $self->{'__rest_params'} ) {
        $self->{'__rest_params'} = {};
    }

    my $num_args = scalar @args;
    if ($num_args) {
        if ( ref $args[0] eq 'HASH' ) {    # a hashref
            %{ $self->{'__rest_params'} } =
              ( %{ $self->{'__rest_params'} }, %{ $args[0] } );
        }
        elsif ( $num_args % 2 == 0 ) {     # a hash
            %{ $self->{'__rest_params'} } =
              ( %{ $self->{'__rest_params'} }, @args );
        }
        elsif ( $num_args == 1 ) {         # a scalar
            if ( exists $self->{'__rest_params'}->{ $args[0] } ) {
                return $self->{'__rest_params'}->{ $args[0] };
            }
        }
        else {
            croak('Odd number of arguments passed to rest_param().');
        }
    }
    else {
        return wantarray
          ? sort keys %{ $self->{'__rest_params'} }
          : scalar keys %{ $self->{'__rest_params'} };
    }
    return;
}

=head2 rest_resource()

This function will set up a complete REST API for a collection of items with all
the CRUD (Create, Read, Update, Delete) operations in one call.  A collection
could be rows in a database, files etc.  The only assumption is that each item
has a unique identifier.

Example 1: basic usage of rest_resource()

    $self->rest_resource('widget');

is exactly equal to the following invocation of L<rest_route|rest_route()>:

    $self->rest_route(
        '/widget'                   => {
            'GET'     => 'widget_index',
            'POST'    => 'widget_create',
            'OPTIONS' => 'widget_options',
        },
        '/widget/:id'               => {
            'DELETE' => 'widget_destroy',
            'GET'    => 'widget_show',
            'PUT'    => 'widget_update',
        },
        '/widget/:id/edit'          => {
            'GET'    => 'widget_edit',
        },
        '/widget/new'               => {
            'GET'    => 'widget_new',
        },
    );

You are responsible for defining the widget_index, widget_create etc. run
modes in your app.

=over 4

=item *_create

Should be used to add a new item to the collection.

=item *_destroy

Should be used to remove the item with the id C<:id> from the collection.

=item *_edit

Should return a temporary copy of the resource with the id C<:id> which can be
changed by the user and then sent to C<*_update>.

=item *_index

Should be used to list the resources in the collection.

=item *_new

Should be used to return an input mechanism (such as an HTML form) which can be
filled in by the user and sent to C<*_create> to add a new resource to the
collection.

=item *_show

Should be used to display resource with the id C<:id>.

=item *_update

Should be used to alter the existing resource with the id C<:id>.

=item *_options

Should be used to retrieve metadata that describes the resource's available
interactions.

=back

Various aspects of the generated routes can be customized by passing this
method a hash (or hashref) of parameters instead of a scalar.

=over 4

=item resource

This parameter is required.  It is used to form the URI the route will match
to.

HINT: use L<rest_route_prefix|rest_route_prefix()> for more complicated URIs.

=item identifier

This parameter sets the name assigned to the unique identifier of an item in
the collection which is used in some generated routes.  It can be retrieved
with L<rest_param|rest_param()>.  It defaults to C<id>.

=item prefix

This parameter is prepended to an action to form a run mode name. It defaults
to C<resource>.

=item in_types, out_types

Both these parameters represent arrayrefs of MIME media types.  C<in_type>
defines acceptable MIME media types for data incoming to your API (i.e.
C<POST>s and C<PUT>s) and C<out_type> does the same for outgoing data (i.e.
C<GET>s and C<OPTIONS>.) C<DELETE> requests do not need MIME media types so
they are not covered.

The reason there are two separate parameters is that typically the number of
data formats a REST API will serve is different to the number and kind of
incoming data formats.

Both of these parameters default to '*/*' i.e. any MIME media type is accepted.

=back

Example 2: advanced usage of rest_resource()

    $self->rest_resource(resource => 'fidget', prefix => 'foo',
        identifier => 'num', in_types => [ 'application/xml' ],
        out_types => [ 'text/html', 'text/plain' ], );

is equal to the following invocation of L<rest_route|rest_route()>:

    $self->rest_route(
        '/fidget'                   => {
            'GET'    => {
                'text/html'  => 'foo_index',
                'text/plain' => 'foo_index',
            },
            'POST'   => {
                'application/xml' => 'foo_create',
            },
        },
        '/fidget/:num'               => {
            'DELETE' => {
                '*/*' => 'foo_destroy',
            },
            'GET'    => {
                'text/html'  => 'foo_show',
                'text/plain' => 'foo_show',
            },
            'PUT'    => {
                'application/xml' => 'foo_update',
            },
        },
        '/fidget/:num/edit'          => {
            'GET'    => {
                'text/html'  => 'foo_edit',
                'text/plain' => 'foo_edit',
            },
        },
        '/fidget/new'               => {
            'GET'    => {
                'text/html'  => 'foo_new',
                'text/plain' => 'foo_new',
            },
        },
    );

If you need more complicated mappings then this, use L<rest_route|rest_route()>.

L<rest_resource|rest_resource()> returns the map of routes and handlers that was created.

=cut

sub rest_resource {
    my ( $self, @args ) = @_;

    my ( $resource, $prefix, $id, $in_types, $out_types );
    my $num_args = scalar @args;

    if ($num_args) {
        if ( ref $args[0] eq 'HASH' ) {
            ( $resource, $prefix, $id, $in_types, $out_types ) =
              _resource_options( $args[0] );
        }
        elsif ( $num_args % 2 == 0 ) {    # a hash
            my %args = @args;
            ( $resource, $prefix, $id, $in_types, $out_types ) =
              _resource_options( \%args );
        }
        elsif ( $num_args == 1 ) {        # a scalar
            ( $resource, $prefix, $id, $in_types, $out_types ) =
              _resource_options( { resource => $args[0] } );
        }
    }
    else {
        croak "argument must be a scalar, hash, or hashref\n";
    }

    if ( !$resource ) {
        croak "Must specify resource name\n";
    }

    if ( !$prefix ) {
        $prefix = $resource;
    }

    if ( !$id ) {
        $id = 'id';
    }

    my $routes = {
        "/$resource" => {
            'GET'  => _make_resource_route( $prefix . '_index',  $out_types ),
            'POST' => _make_resource_route( $prefix . '_create', $in_types ),
            'OPTIONS' =>
              _make_resource_route( $prefix . '_options', $out_types ),
        },
        "/$resource/:$id" => {
            'DELETE' => _make_resource_route( $prefix . '_destroy', [q{*/*}] ),
            'GET' => _make_resource_route( $prefix . '_show',   $out_types ),
            'PUT' => _make_resource_route( $prefix . '_update', $in_types ),
        },
        "/$resource/:$id/edit" =>
          { 'GET' => _make_resource_route( $prefix . '_edit', $out_types ), },
        "/$resource/new" =>
          { 'GET' => _make_resource_route( $prefix . '_new', $out_types ), },
    };

    rest_route( $self, $routes );

    return $routes;
}

sub _resource_options {
    my ($args) = @_;

    my ( $resource, $prefix, $id, $in_types, $out_types );

    $resource = $args->{resource};
    $prefix   = $args->{prefix};
    $id       = $args->{identifier};
    if ( exists $args->{in_types} ) {
        if ( ref $args->{in_types} ne 'ARRAY' ) {
            croak "in_types must be an arrayref\n";
        }
        $in_types = $args->{in_types};
    }
    else {
        $in_types = [q{*/*}];
    }
    if ( exists $args->{out_types} ) {
        if ( ref $args->{out_types} ne 'ARRAY' ) {
            croak "out_types must be an arrayref\n";
        }
        $out_types = $args->{out_types};
    }
    else {
        $out_types = [q{*/*}];
    }

    return ( $resource, $prefix, $id, $in_types, $out_types );
}

sub _make_resource_route {
    my ( $rm, $types ) = @_;

    my $ret = {};

    foreach my $type ( @{$types} ) {
        $ret->{$type} = $rm;
    }

    return $ret;
}

=head2 rest_route()

When this function is given a hash or hashref, it configures the mapping of
routes to handlers (run modes within your L<CGI::Application|CGI::Application>).

It returns the map of routes and handlers.

=head4 Routes

Assume for the purpose of the following examples that your instance script has 
a base URI of C<http://localhost/>

HINT: Your web server might not execute CGI scripts unless they have an
extension of .cgi so your actual script might be C<http://localhost/app.cgi>.
However it is considered unRESTful to include infrastructural details in your
URLs.  Use your web servers URL rewriting features (i.e. mod_rewrite in
Apache) to hide the extension.

A route looks like a URI with segments seperated by /'s.

Example 1: a simple route

    /foo

A segment in a route is matched literally.  So if a request URI matches
http://localhost/foo, the run mode that handles the route in example 1 will
be used.

If you want to match the URI base itself, you can do it like this:

Example 2: route to a URI base

    /

This matches C<http://localhost/>.  Some people don't like the trailing slash;
they can be accomodated by using an empty string as the route as in Example 3.

Example 3: route to a URI base without the trailing /
    ''

This matches C<http://localhost>.

Routes can have more complex specifications.

Example 4: a more complex route

    /bar/:name/:id?/:email

If a segment of a route is prefixed with a :, it is not matched literally but
treated as a parameter name.  The value of the parameter is whatever actually
got matched.  If the segment ends with a ?, it is optional otherwise it is
required.  The values of these named parameters can be retrieved with the
L<rest_param|rest_param()> method.

In example 2, http://localhost/bar/jaldhar/76/jaldhar@braincells.com would
match.  C<rest_param('name')> would return 'jaldhar',  C<rest_param('id')>
would return 76, and C<rest_param('email')> would return
'jaldhar@braincells.com'.

If the request URI was http://localhost/bar/jaldhar/jaldhar@braincells.com/,
C<rest_param('email')> would return 'jaldhar@braincells.com' and
C<rest_param('name')> would return 'jaldhar'. C<rest_param('id')> would return
undef.

If the request URI was http://localhost/bar/jaldhar/76 or
http://localhost/jaldhar/, there would be no match at all because the required
parameter ':email' is missing.

Note: Each named parameter is returned as a scalar.  If you want ':email' to
actually be an email address, it is up to your code to validate it before use.

Example 5: a wild card route

    /baz/string/*

If the route specification contains /*, everything from then on will be
put into the special parameter 'dispatch_uri_remainder' which you can retrieve
with L<rest_param|rest_param()> just like any other parameter.  Only one wildcard can
be specified per route.  Given the request URI
http://localhost/baz/string/good, C<rest_param('dispatch_uri_remainder')>
would return 'good', with http://localhost/baz/string/evil it would return
'evil' and with http://localhost/baz/string/lawful/neutral/ it would return
'lawful/neutral/'.

=head4 Handlers

The most basic handler is a scalar or coderef.

Example 4: Basic Handlers

    my $routes = {
       '/foo'                    => 'wibble',
       '/bar/:name/:id?/:email'  => \&wobble,
       '/baz/string/*/'          => 'woop',
    };
    $self->rest_route($routes);

In example 4, a request to C<http://localhost/app/foo> will be dispatched to
C<wibble()>.  (It is upto you to make sure such a method exists.)  A request
to C<http://localhost/app/bar/jaldhar/76/jaldhar@braincells.com> will dispatch 
to C<wobble()>.  A request to C<http://localhost/login> will raise an error.

Example 5: More complex handlers

    $self->rest_route(
        '/quux'                   => {
            'GET'    => 'ptang',
            'DELETE' => 'krrang',
        },
        '/edna'                   => {
            'POST'   => 'blip',
            '*'      => 'blop',
        },
        '/grudnuk'                => {
            'GET'    => {
                'application/xml' => 'zip',
                '*/*'             => 'zap',
            },
            PUT      => {
                'application/xml' => 'zoom',
            },
        },
    );

If the handler is a hashref, the keys of the second-level hash are HTTP
methods and the values if scalars or coderefs, are run modes.  Supported
methods are C<HEAD>, C<GET>, C<POST>, C<PUT>, C<DELETE>, and C<OPTIONS>.  The key can also be C<*>
which matches all methods not explicitly specified.  If a valid method cannot
be matched, an error is raised and the HTTP status of the response is set to
405.  (See L<"DIAGNOSTICS">.)

In example 5, a C<GET> request to http://localhost/quux will be dispatched to
C<ptang()>.  A C<DELETE> to http://localhost/quux will dispatch to C<krrang()>.
An C<OPTIONS>) C<POST>, C<PUT> or C<HEAD> will cause an error.

A C<POST> request to http://localhost/edna will dispatch to C<zip()>
while any other type of request to that URL will dispatch to C<blop()>

The values of the second-level hash can also be hashes.  In this case the keys
of the third-level hash represent MIME media types.  The values are run modes.
The best possible match is made use C<best_match()> from L<REST::Utils|REST::Utils>.
according to the HTTP Accept header sent in the request.  If a valid MIME
media type cannot be matched C<*/*> is tried as a last resort.  If there is no
handler for even that, an error is raised and the HTTP status of the response
is set to 415.  (See L<"DIAGNOSTICS">)

In example 5, a C<GET> request to http://localhost/grudnuk with MIME
media type application/xml will dispatch to C<zip()>. If the same request is
made with any other MIME media type, the method C<zap()> will be called
instead. A C<PUT> request made to the same URL with MIME media type
application/xml will dispatch to C<zoom()>. Any other combination of HTTP
methods or MIME media types will cause an error to be raised.

If no URI can be matched, an error is raised and the HTTP status of the
response is set to 404 (See L<"DIAGNOSTICS">.)

=cut

sub rest_route {
    my ( $self, @routes ) = @_;

    my $rr_m = $self->{'__rest_dispatch_table'};

    my $num_routes = scalar @routes;
    if ($num_routes) {
        if ( ref $routes[0] eq 'HASH' ) {    # Hashref
            _method_hashref( $self, $routes[0] );
        }
        elsif ( ( $num_routes % 2 ) == 0 ) {    # Hash
            while ( my ( $rule, $dispatch ) = splice @routes, 0, 2 ) {
                _method_hashref( $self, { $rule => $dispatch } );
            }
        }
        else {
            croak(
'Odd number of elements passed to rest_route().  Not a valid hash'
            );
        }
    }

    return $self->{'__rest_dispatch_table'};
}

sub _method_hashref {
    my ( $self, $routes ) = @_;

    foreach my $rule ( keys %{$routes} ) {

        my @methods;
        my $route_type = ref $routes->{$rule};
        if ( $route_type eq 'HASH' ) {
            @methods = keys %{ $routes->{$rule} };
        }
        elsif ( $route_type eq 'CODE' ) {
            $routes->{$rule} = { q{*} => $routes->{$rule} };
            push @methods, q{*};
        }
        elsif ( $route_type eq q{} ) {    # scalar
            $routes->{$rule} = { q{*} => $routes->{$rule} };
            push @methods, q{*};
        }
        else {
            croak "$rule (", $routes->{$rule},
              ') has an invalid route definition';
        }

        my @request_methods =
          ( 'GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS', q{*}, );
        foreach my $req (@methods) {
            if ( scalar grep { $_ eq $req } @request_methods ) {
                my $subroute = $routes->{$rule}->{$req};
                _mime_hashref( $self, $subroute, $rule, $req );
            }
            else {
                croak "$req is not a valid request method\n";
            }
        }
    }

    return;
}

sub _mime_hashref {
    my ( $self, $subroute, $rule, $req ) = @_;

    my $subroute_type = ref $subroute;
    if ( $subroute_type eq 'HASH' ) {
        foreach my $type ( keys %{$subroute} ) {
            my $func = $subroute->{$type};
            $self->{'__rest_dispatch_table'}->{$rule}->{$req}->{$type} = $func;
            $self->run_modes( [$func] );
        }
    }
    elsif ( $subroute_type eq 'CODE' ) {
        my $func = $subroute;
        $self->{'__rest_dispatch_table'}->{$rule}->{$req}->{q{*/*}} = $func;
        $self->run_modes( [$func] );
    }
    elsif ( $subroute_type eq q{} ) {    # scalar
        my $func = $subroute;
        $self->{'__rest_dispatch_table'}->{$rule}->{$req}->{q{*/*}} = $func;
        $self->run_modes( [$func] );
    }
    else {
        croak "$subroute is an invalid route definition";
    }

    return;
}

=head2 rest_route_info()

This function can be called in a route handler.  It returns a reference to a
hash which contains some information about the current route.

=over 4

=item path_received

The value of the C<PATH_INFO> environment variable.

=item rule_matched

The rule that was successfully matched to determine this route.

=item runmode

The name of the function being called by this route.

=item method

The HTTP method that was matched by this route.

=item mimetype

The MIME media type that was matched by this route.

=back

Example 1:

    $self->rest_route(
         '/foo' => {
             'GET' => 'bar',
         },
    );

    ...

    sub bar() {
        my ($self) = @_;

        my $info = $self->rest_route_info;

        say $info->{method};  # prints 'GET'
	}

=cut

sub rest_route_info {
    my ($self) = @_;

    return $self->{'__r_params'};
}

=head2 rest_route_prefix()

Use this function to set a prefix for routes to avoid unnecessary repetition
when you have a number of similar ones.

Example 1:

    # matches requests to /zing
    $self->rest_route(
         '/zing' => {
             'GET' => 'zap',
         },
    );

    $self->rest_route_prefix('/app')
    # from now on requests to /app/zing will match instead of /zing

    my $prefix = $self->rest_route_prefix # $prefix equals '/app'

=cut

sub rest_route_prefix {
    my ( $self, $prefix ) = @_;

    # First use?  Create new __rest_route_prefix
    if ( !exists( $self->{'__rest_route_prefix'} ) ) {
        $self->{'__rest_route_prefix'} = q{};
    }

    # If data is provided, set it.
    if ( defined $prefix ) {

        # make sure no trailing slash is present on the root.
        $prefix =~ s{/$}{}msx;
        $self->{'__rest_route_prefix'} = $prefix;
    }

    return $self->{'__rest_route_prefix'};

}

=head1 OTHER DISPATCH PLUGINS COMPARED

There are several other modules that allow L<CGI::Application|CGI::Application> to dispatch to
a run mode based on the C<PATH_INFO> environment variable instead of the
traditional CGI parameter.  They each take a markedly different approach to
implementation.  Here is a comparison.

Executive summary:  L<C::A::P::REST|CGI::Application::Plugin::REST> is the best :-)

=head2 L<CGI::Application|CGI::Application> Itself

You can set the run mode with the C<path_info> option to C<mode_param()>.
This is limited to one segment (i.e. between C</>'s) of the path info.

Dispatch based on HTTP method or MIME media type is not supported.

=head2 L<CGI::Application::Dispatch|CGI::Application::Dispatch>

This module has influenced most of the other dispatchers including this one.
It replaces L<CGI::Application|CGI::Application> as the base class for your application.

It has extensive capabilities for matching path info.  It can capture variable
segments in the URI with : ? and * tokens. They are retrievable in run
modes as L<CGI::Application|CGI::Application> parameters (i.e. via C<$self-E<gt>param()>.

You can also dispatch by HTTP method but not by MIME media type.  The HTTP
method is determined by looking at the C<HTTP_REQUEST_METHOD> environment
variable only.  Methods called C<auto_rest()> and C<auto_rest_lc()> append the
the HTTP method (all upper case and all lower case respectively) to a run mode
that is determined by a dispatch rule which provides a limited version of
L<C::A::P::REST|CGI::Application::Plugin::REST>'s L<rest_resource|rest_resource()> function.

=head2 L<C::A::P::ActionDispatch|CGI::Application::Plugin::ActionDispatch>

This module adds an attribute handler to run modes of your choice which enable
parsing of the path info with regular expressions and dispatch to the run mode
matched. Capturing parentheses in the regex can be accessed via the
C<action_args()> method.

Dispatch based on HTTP method or MIME media type is not supported.

=head2 L<C::A::P::Routes|CGI::Application::Plugin::Routes>

This module installs a prerun hook that matches path info segments with support
for capturing variable with the : ? and * tokens.  They are retrievable in run
modes as L<CGI|CGI> parameters (i.e. via C<$self-E<gt>query-E<gt>param()>

Dispatch based on HTTP method or MIME media type is not supported.

=head1 DIAGNOSTICS

During the dispatch process, errors can occur in certain circumstances. If an
error occurs the appropriate HTTP status is set and execution passes to the
run mode set by L<rest_error_mode|rest_error_mode()>.  Here is a list of status codes and
messages.

=over 4

=item * 404 No Route Found

None of the specified routes matched the request URI.

=item * 405 Method '$method' Not Allowed

The route you specified with L<rest_route|rest_route()> does not allow this HTTP
request method.  An HTTP C<Allow> header is added to the response specifying
which methods can be used.

=item * 415 Unsupported Media Type

None of the MIME media types requested by the client can be returned by this
route and there is no handler for C<*/*>.

=item * 500 No Dispatch Table

This error can occur if L<rest_route|rest_route()> was not called.

=item * 500 Application Error

The function that was called for this run_mode C<die>'d somewhere.

=item * 501 Function '$function_name' Doesn't Exist

The function that you wanted to call from L<rest_route|rest_route()> for this run_mode
doesn't exist in your application.

=back

=head1 BUGS AND LIMITATIONS

There are no known problems with this module.

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-rest at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-REST>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

=over 4

=item * L<CGI::Application|CGI::Application>:

The application framework this module plugs into.

=item * L<REST::Utils|REST::Utils>:

L<C::A::P::REST|CGI::Application::Plugin::REST> uses my L<REST::Utils|REST::Utils> module behind the
scenes.

=item * L<REST::Application|REST::Application>:

This module by Matthew O'Connor gave me some good ideas.

=item * L<http://www.ics.uci.edu/~fielding/pubs/dissertation/top.htm>:

Roy Fieldings' doctoral thesis in which the term REST was first defined.

=item * L<http://www.xml.com/pub/at/34>

"The Restful Web" columns by Joe Gregorio have been very useful to me in
understanding the ins and outs of REST.

=back

=head1 THANKS

Much of the code in this module is based on L<C::A::P::Routes|CGI::Application::Plugin:Routes>
by JuliE<aacute>n Porta who in turn credits Michael Peter's L<CGI::Application::Dispatch|CGI::Application::Dispatch>.

=head1 AUTHOR

Jaldhar H. Vyas, C<< <jaldhar at braincells.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Consolidated Braincells Inc., all rights reserved.

This distribution is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version, or

b) the Artistic License version 2.0.

The full text of the license can be found in the LICENSE file included
with this distribution.

=cut

1;    # End of CGI::Application::Plugin::REST

__END__
