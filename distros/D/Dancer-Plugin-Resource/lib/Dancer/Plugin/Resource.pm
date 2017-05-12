#
# This file is part of Dancer-Plugin-Resource
#
# This software is copyright (c) 2013 by Matthew Phillips.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Dancer::Plugin::Resource;
# ABSTRACT: A plugin for writing declarative RESTful apps with Dancer
BEGIN {
our $VERSION = '1.131120'; # VERSION
}

use strict;
use warnings;

use Carp 'croak';
use Dancer ':syntax';
use Dancer::Plugin;
use Lingua::EN::Inflect::Number;

our $RESOURCE_DEBUG = 0;

my $content_types = {
    json => 'application/json',
    yml  => 'text/x-yaml',
    xml  => 'application/xml',
};

my %routes;

# thanks leont
sub _function_exists {
    no strict 'refs';
    my $funcname = shift;
    return \&{$funcname} if defined &{$funcname};
    return;
}

sub prepare_serializer_for_format {
    my $conf        = plugin_setting;
    my $serializers = (
        ($conf && exists $conf->{serializers})
        ? $conf->{serializers}
        : { 'json' => 'JSON',
            'yml'  => 'YAML',
            'xml'  => 'XML',
            'dump' => 'Dumper',
        }
    );

    hook 'before' => sub {
        my $format = params->{'format'};
        if (not defined $format) {
            set serializer => 'Mutable';
            return;
        }

        return unless defined $format;

        my $serializer = $serializers->{$format};
        unless (defined $serializer) {
            return halt(
                Dancer::Error->new(
                    code    => 404,
                    message => "unsupported format requested: " . $format
                )
            );
        }

        set serializer => $serializer;
        my $ct = $content_types->{$format} || setting('content_type');
        content_type $ct;
    };
}
register prepare_serializer_for_format => \&prepare_serializer_for_format;

register resource => sub {
    my ($resource, %options) = @_;

    my $params = ':id';
    my ($old_prefix, $parent_prefix);

    unless ($options{skip_prepare_serializer} || ((caller)[1] =~ /^(?:t|xt)/)) {
        prepare_serializer_for_format;
    }

    # if this resource is a nested child resource, manage the prefix
    $old_prefix = Dancer::App->current->prefix || '';
    $parent_prefix = '';

    if ($options{parent} and $routes{$options{parent}}) {
        prefix $parent_prefix = $routes{$options{parent}};
    }
    else {
        $parent_prefix = $old_prefix;
    }

    # create a default for the load funcs
    $options{$_} ||= sub { undef } for (qw/load load_all/);

    # if member => 'foo' is passed, turn it into an array
    for my $type (qw/member collection/) {
        if ($options{$type} && ref $options{$type} eq '') {
            $options{$type} = [$options{$type}];
        }
    }

    # by default take the singular resource as the param name (ie :user for users)
    my ($singular_resource, $plural_resource) = (Lingua::EN::Inflect::Number::to_S($resource), $resource);

    # or if the user wants to override to take multiple params, ie /user/:foo/:bar/:baz
    # allow it. This could be useful for composite key schemas
    if ( my $p = $options{params} ) {
        $p = ref $p ? $p : [$p];
        $params = join '/', map ":${_}", @{$p};
    }
    else {
        $params = ":${singular_resource}_id";
    }

    my ($package) = caller;

    # main resource endpoints
    # CRUD
    _post(
        _endpoint(
            path     => $plural_resource,
            params   => '',
            verbs    => [qw/POST create/],
            function => $singular_resource
        )
    );

    _get(
        _endpoint(
            path     => $plural_resource,
            params   => $params,
            verbs    => [qw/GET get read/],
            loader   => $options{load},
            function => $singular_resource
        )
    );

    _put(
        _endpoint(
            path     => $plural_resource,
            params   => $params,
            verbs    => [qw/PUT update/],
            loader   => $options{load},
            function => $singular_resource
        )
    );

    _del(
        _endpoint(
            path     => $plural_resource,
            params   => $params,
            verbs    => [qw/DELETE delete/],
            loader   => $options{load},
            function => $singular_resource
        )
    );

    _get(
        _endpoint(
            path     => $plural_resource,
            params   => '',
            verbs    => [qw/INDEX index/],
            loader   => $options{load_all},
            function => $singular_resource
        )
    );

    # member routes are actions on the given id. ie /users/:user_id/foo
    for my $member (@{$options{member}}) {
        my $path = "${plural_resource}/$params/${member}";
        my $member_param = "";

        _post(
            _endpoint(
                path     => $path,
                params   => '',
                verbs    => [qw/POST create/],
                loader   => $options{load},
                function => "${singular_resource}_${member}"
            )
        );

        _get(
            _endpoint(
                path     => $path,
                params   => $member_param,
                verbs    => [qw/GET get read/],
                loader   => $options{load},
                function => "${singular_resource}_${member}"

            )
        );

        _put(
            _endpoint(
                path     => $path,
                params   => $member_param,
                verbs    => [qw/PUT update/],
                loader   => $options{load},
                function => "${singular_resource}_${member}"

            )
        );

        _del(
            _endpoint(
                path     => $path,
                params   => $member_param,
                verbs    => [qw/DELETE delete/],
                loader   => $options{load},
                function => "${singular_resource}_${member}"

            )
        );
    }

    # collection routes are actions on the collection. ie /users/foo
    for my $collection (@{$options{collection}}) {
        my $path = "${plural_resource}/${collection}";

        _post(
            _endpoint(
                path     => $path,
                params   => '',
                verbs    => [qw/POST create/],
                loader   => $options{load_all},
                function => "${plural_resource}_${collection}"
            )
        );

        _get(
            _endpoint(
                path     => $path,
                params   => '',
                verbs    => [qw/GET get read/],
                loader   => $options{load_all},
                function => "${plural_resource}_${collection}"
            )
        );

        _put(
            _endpoint(
                path     => $path,
                params   => '',
                verbs    => [qw/PUT update/],
                loader   => $options{load_all},
                function => "${plural_resource}_${collection}"
            )
        );

        _del(
            _endpoint(
                path     => $path,
                params   => '',
                verbs    => [qw/DELETE delete/],
                loader   => $options{load_all},
                function => "${plural_resource}_${collection}"
            )
        );
    }

    # save every defined resource if it is referred as a parent in a nested child resource
    $routes{$resource} = "${parent_prefix}/${plural_resource}/${params}";

    # restore existing prefix if saved
    prefix $old_prefix if $old_prefix;
};

sub _debug { $RESOURCE_DEBUG and print @_ }

sub _post {
    my ($route, $sub) = @_;
    for ($route . '.:format', $route) {
        _debug("=> POST " .(Dancer::App->current->prefix||'').$_."\n");
        post($_ => $sub);
    }
}

sub _get {
    my ($route, $sub) = @_;
    for ($route . '.:format', $route) {
        _debug("=> GET " .(Dancer::App->current->prefix||'').$_."\n");
        get($_ => $sub);
    }
}

sub _put {
    my ($route, $sub) = @_;
    for ($route . '.:format', $route) {
        _debug("=> PUT " .(Dancer::App->current->prefix||'').$_."\n");
        put($_ => $sub);
    }
}

sub _del {
    my ($route, $sub) = @_;
    for ($route . '.:format', $route) {
        _debug("=> DEL " .(Dancer::App->current->prefix||'').$_."\n");
        del($_ => $sub);
    }
}

sub _endpoint {
    my %opts = @_;
    my ($function, $word, $params, $verbs, $load_func) = @opts{qw/function path params verbs loader/};

    my $package = caller(1);

    my $wrapped;
    for my $verb (@$verbs) {
        # allow both foo_GET and GET_foo
        my $func = _function_exists("${package}::${verb}_${function}") ||
                   _function_exists("${package}::${function}_${verb}");

        if ($func) {
            _debug("${package}::${verb}_${function} ");
            $wrapped = sub { $func->($load_func ? $load_func->() : (), @_) };

            last; # we only want to attach to the first successful verb
        }
    }

    if (not $wrapped) {
        _debug("undef ");

        # if we've gotten this far, no route exists. use a default
        $wrapped = sub { status_method_not_allowed('Method not allowed.'); };
    }

    my $route
        = $params ? "/${word}/${params}"
        :           "/${word}";

    return ($route, $wrapped);
}

register send_entity => sub {
    my ($entity, $http_code) = @_;

    $http_code ||= 200;

    status($http_code);
    $entity;
};

my %http_codes = (

    # 1xx
    100 => 'Continue',
    101 => 'Switching Protocols',
    102 => 'Processing',

    # 2xx
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    207 => 'Multi-Status',
    210 => 'Content Different',

    # 3xx
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    307 => 'Temporary Redirect',
    310 => 'Too many Redirect',

    # 4xx
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Time-out',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Long',
    415 => 'Unsupported Media Type',
    416 => 'Requested range unsatisfiable',
    417 => 'Expectation failed',
    418 => 'Teapot',
    422 => 'Unprocessable entity',
    423 => 'Locked',
    424 => 'Method failure',
    425 => 'Unordered Collection',
    426 => 'Upgrade Required',
    449 => 'Retry With',
    450 => 'Parental Controls',

    # 5xx
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Time-out',
    505 => 'HTTP Version not supported',
    507 => 'Insufficient storage',
    509 => 'Bandwidth Limit Exceeded',
);

for my $code (keys %http_codes) {
    my $helper_name = lc($http_codes{$code});
    $helper_name =~ s/[^\w]+/_/gms;
    $helper_name = "status_${helper_name}";

    register $helper_name => sub {
        if ($code >= 400 && ref $_[0] eq '') {
            send_entity({error => $_[0]}, $code);
        }
        else {
            send_entity($_[0], $code);
        }
    };
}

register_plugin;
1;


__END__
=pod

=head1 NAME

Dancer::Plugin::Resource - A plugin for writing declarative RESTful apps with Dancer

=head1 VERSION

version 1.131120

=head1 SYNOPSIS

    package MyWebService;

    use Dancer;
    use Dancer::Plugin::Resource;

    prepare_serializer_for_format;

    resource 'users';

    # generates '/users/:user_id' and '/users/:user_id.:format'
    sub user_GET {
        User->find(params->{user_id});
        ...
    }

    # curl http://mywebservice/user/42.json
    { "id": 42, "name": "John Foo", email: "john.foo@example.com"}

    # curl http://mywebservice/user/42.yml
    --
    id: 42
    name: "John Foo"
    email: "john.foo@example.com"

=head1 DESCRIPTION

Dancer::Plugin::Resource is a dancer plugin aimed at simplifying and aiding in
writing RESTful web services and applications in Dancer. It borrows ideas from
both Ruby on Rails and Catalyst::Action::REST, while adding some new ones to
boot. At its core it is used to combine two things:

=item 1

generate routes automatically for a 'resource' and map them to easily named functions.

=item 2

handle automatic serialization based off of what the user requests.

=head1 KEYWORDS

=head2 resource

This keyword is the meat of Dancer::Plugin::Resource. It lets you declare
a resource your application will handle.

By default, you can pass in a mapping of CRUD actions to subrefs that will
align to auto-generated routes: At its simplest, you can call it with no
arguments. This will create the following routes, and try to map them to
functions in the namespace you called it from.

    resource 'users';

    # this defines the following routes:

    # POST /user
    # POST /user.:format
    sub user_POST { ... }

    # GET /user/:id
    # GET /user/:id.:format
    sub user_GET { ... }

    # PUT /user/:id
    # PUT /user/:id.:format
    sub user_PUT { ... }

    # DELETE /user/:id
    # DELETE /user/:id.:format
    sub user_DELETE { ... }

    # GET /user
    # GET /user.:format
    sub user_INDEX { ... }

The optional :format param is used by the prepare_serializer_for_format 'after'
hook, which is described in more detail below. In short, it allows '.xml' or
'.json' suffixes to control the format of data returned by the route.

An example of more complicated usage:

    use Dancer::Plugin::Resource;

    resource 'users',
        member => [qw/posts/],
        collection => [qw/log/],
        load => sub { schema->User->find(param 'user_id'); },
        load_all => sub { schema->User->all; };

    resource 'accounts',
        parent => 'user',
        params => [qw/composite key/];

    # HTTP $resource_VERB is mapped automatically for actions on the resource

    # GET /users
    sub users_INDEX {
        my ($users) = @_;   # returnval of load_all is passed in
    }

    # HTTP $VERB_$SINGULAR is mapped automatically for actions on elements of the resource

    # POST /users
    sub user_POST {
        # ...
    }

    # GET /users/:user_id
    sub user_GET {
        my ($user) = @_;    # returnval of load is passed in
        # ...
    }

    # param id is inflected from the plural resource
    # PUT /users/:user_id
    sub user_PUT { my ($user) = @_; }

    # DELETE /users/:user_id
    sub user_DELETE { my ($user) = @_; }

    # The member collection is attached to the members of the resource
    # All CRUD verbs are automatically mapped
    # GET /users/:user_id/posts
    sub user_posts_GET { }

    # likewise for collection methods
    # POST /users/logs
    sub users_logs_POST { }

    # The accounts resource nests underneath user with the parent keyword
    # the params keyword overrides the default params set by the route
    # POST /users/:user_id/accounts
    sub account_CREATE { }

    # GET /users/:user_id/accounts/:composite/:key
    sub account_GET { }

Mapping CRUD methods to routes is done automatically by inspecting the symbol table.

A full list of keywords that can be passed to resource is listed below. All are
optional.

=head3 params

Defines the list of params that the given resource takes in its part of the
path. Takes scalar or arrayref for 1 or multiple params.

    resource 'users', params => [qw/foo bar/]; # /users/:foo/:bar

=head3 load/load_all

Takes a coderef. Methods called on element of the resource (read/update/delete)
will receive load returnval in @_.  Methods on the resource itself (index) will
receive load_all in @_. Create does not receive any arguments. An alternative
to @_ would be to use Dancers's 'vars' functionality for scope outside of the
given route.

=head3 member

Declares additional methods attached to the given resource. Takes either a
scalar or an arrayref.

    resource 'users', member => 'posts';
    sub read_users_posts { } # GET /users/:user_id/posts

=head3 collection

Like member methods, but attached to the root resource, and not the instance.

    resource 'users', collection => [qw/posts/];
    sub create_users_posts { } # POST /users/posts

=head3 parent

Each time a resource is declared its prefix and route is stored internally. If
you declare a resource as a child of an already defined resource, the parents
resource will be set as a prefix automatically, and the old prefix will be
restored when done.

    resource 'users';
    resource 'posts', parent => 'users';
    resource 'comments', parent => 'posts';

    # /users/:user_id
    # /users/:user_id/posts/:post_id
    # /users/:user_id/posts/:post_id/comments/:comment_id

=head2 helpers

Some helpers are available. This helper will set an appropriate HTTP status for you.

=head3 status_ok

    status_ok({users => {...}});

Set the HTTP status to 200

=head3 status_created

    status_created({users => {...}});

Set the HTTP status to 201

=head3 status_accepted

    status_accepted({users => {...}});

Set the HTTP status to 202

=head3 status_bad_request

    status_bad_request("user foo can't be found");

Set the HTTP status to 400. This function as for argument a scalar that will be
used under the key B<error>.

=head3 status_not_found

    status_not_found("users doesn't exists");

Set the HTTP status to 404. This function as for argument a scalar that will be
used under the key B<error>.

=head2 prepare_serializer_for_format

When this pragma is used, a before filter is set by the plugin to automatically
change the serializer when a format is detected in the URI.

That means that each route you define with a B<:format> token will trigger
a serializer definition, if the format is known.

This lets you define all the REST actions you like as regular Dancer route
handlers, without explicitly handling the outgoing data format.

=head1 LICENCE

This module is released under the same terms as Perl itself.
This module is a fork of Dancer::Plugin::REST written by Alexis Sukrieh C<< <sukria@sukria.net> >> and Franck Cuny.

=head1 SEE ALSO

L<Dancer> L<Dancer::Plugin::REST> L<http://en.wikipedia.org/wiki/Representational_State_Transfer>

=head1 AUTHOR

Matthew Phillips <mattp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Matthew Phillips.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

