# TODO: add responses
# TODO: add examples
# TODO: then add the template for different responses values
# TODO: override send_error ? 
# TODO: add 'validate_schema'
# TODO: add 'strict_schema'
# TODO: make /swagger.json configurable

package Dancer2::Plugin::OpenAPI;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: create OpenAPI documentation of your application
$Dancer2::Plugin::OpenAPI::VERSION = '1.0.1';
use strict;
use warnings;

use Dancer2::Plugin;
use PerlX::Maybe;
use Scalar::Util qw/ blessed /;

use Dancer2::Plugin::OpenAPI::Path;

use MooseX::MungeHas 'is_ro';

use Path::Tiny;
use File::ShareDir::Tarball;

has doc => (
    is => 'ro',
    lazy => 1,
    default => sub { 
        my $self = shift;

        my $doc = {
            openapi => '3.1.0',
            paths => {},
        };

        $doc->{info}{$_} = '' for qw/ title description version /; 

        $doc->{info}{title} = $self->main_api_module if $self->main_api_module;

        if( my( $desc) = $self->main_api_module_content =~ /
                ^(?:\s* \# \s* ABSTRACT: \s* |=head1 \s+ NAME \s+ (?:\w+) \s+ - \s+  ) ([^\n]+) 
                /xm
        ) {
            $doc->{info}{description} = $desc;
        }

        $doc->{info}{version} = eval {
            $self->main_api_module->VERSION
        } // '0.0.0';

        $doc;
        
    },
);

our $FIRST_LOADED = caller(1);

has main_api_module => (
    is => 'ro',
    lazy => 1,
    from_config => 1,
    default => sub { 
        return if $] lt '5.036000';

        $Dancer2::Plugin::OpenAPI::FIRST_LOADED //= caller;
    },
);

has main_api_module_content => (
    is => 'ro',
    lazy => 1,
    default => sub { 
        my $mod = $_[0]->main_api_module or return '';

        $mod =~ s#::#/#g;
        $mod .= '.pm';
        my $path = $INC{$mod} or return '';

        return Path::Tiny::path($path)->slurp;
    }
);

has show_ui => (
    is => 'ro',
    lazy => 1,
    from_config => sub { 1 },
);

has ui_url => (
    is => 'ro',
    lazy => 1,
    from_config => sub { '/doc' },
);

has ui_dir => (
    is => 'ro',
    lazy => 1,
    from_config => sub { 
        Path::Tiny::path(
            File::ShareDir::Tarball::dist_dir('Dancer2-Plugin-OpenAPI')
        )
    },
);

has auto_discover_skip => (
    is => 'ro',
    lazy => 1,
    default => sub { [
            map { /^qr/ ? eval $_ : $_ }
        @{ $_[0]->config->{auto_discover_skip} || [
            '/openapi.json', ( 'qr!' . $_[0]->ui_url . '!' ) x $_[0]->show_ui
        ] }
    ];
    },
);

has validate_response => ( from_config => 1 );
has strict_validation => ( from_config => 1 );


sub BUILD {
    my $self = shift;

    # TODO make the doc url configurable
    $self->app->add_route(
        method => 'get',
        regexp => '/openapi.json',
        code => sub { $self->doc },
    );

    if ( $self->show_ui ) {
        my $base_url = $self->ui_url;

        $self->app->add_route(
            method => 'get',
            regexp => $base_url,
            code => sub {
                $self->app->redirect( $base_url . '/?url=/openapi.json' );
            },
        );

        $self->app->add_route(
            method => 'get',
            regexp => $base_url . '/',
            code => sub {
                my $file = $self->ui_dir->child('index.html');

                $self->app->send_error( "file not found", 404 ) unless -f $file;

                return $file->slurp;
            }
        );

        $self->app->add_route(
            method => 'get',
            regexp => $base_url . '/**',
            code => sub {
                my $file = $self->ui_dir->child( @{ ($self->app->request->splat())[0] } );

                $self->app->send_error( "file not found", 404 ) unless -f $file;

                $self->app->send_file( $file, system_path => 1);
            }
        );
    }
    
}

sub openapi_auto_discover :PluginKeyword {
    my( $plugin, %args ) = @_;

    $args{skip} ||= $plugin->auto_discover_skip;

    my $routes = Dancer2::App->current->registry->routes;

    # my $doc = $plugin->doc->{paths};

    for my $method ( qw/ get post put delete / ) {
        for my $r ( @{ $routes->{$method} } ) {
            my $pattern = $r->pattern;

            next if ref $pattern eq 'Regexp';

            next if grep { ref $_ ? $pattern =~ $_ : $pattern eq $_ } @{ $args{skip} };

            my $path = Dancer2::Plugin::OpenAPI::Path->new( 
                plugin => $plugin,
                route => $r );

            $path->add_to_doc($plugin->doc);
        }
    }
};

sub openapi_path :PluginKeyword {
    my $plugin = shift;

    $DB::single = 1;
    my @routes;
    push @routes, pop @_ while eval { $_[-1]->isa('Dancer2::Core::Route') };

    # we don't process HEAD
    @routes = grep { $_->method ne 'head' } @routes;


    my $description;
    if( @_ and not ref $_[0] ) {
        $description = shift;
        $description =~ s/^\s*\n//;
        
        $description =~ s/^$1//mg
            if $description =~ /^(\s+)/;
    }

    my $arg = shift @_ || {}; 

    $arg->{description} = $description if $description;

    # groom the parameters
    if ( my $p = $arg->{parameters} ) {
        if( ref $p eq 'HASH' ) {
            $_ = { description => $_ } for grep { ! ref } values %$p;
            $p = [ map { +{ name => $_, %{$p->{$_}} } } sort keys %$p ];
        }

        # deal with named parameters
        my @p;
        while( my $k = shift @$p ) {
            unless( ref $k ) { 
                my $value = shift @$p;
                $value = { description => $value } unless ref $value;
                $value->{name} = $k;
                $k = $value;
            }
            push @p, $k;
        }
        $p = \@p;

        # set defaults
        $p = [ map { +{ in => 'query', type => 'string', %$_ } } @$p ];
        
        $arg->{parameters} = $p;
    }


    for my $route ( @routes ) {
        my $path = Dancer2::Plugin::OpenAPI::Path->new(%$arg, route => $route, plugin => $plugin );

        $path->add_to_doc( $plugin->doc );

        my $code = $route->{code};
        # TODO change this so I don't play in D2's guts directly
        $route->{code} = sub {
            local $Dancer2::Plugin::OpenAPI::THIS_ACTION = $path;
            $code->();
        };
    }
};

sub openapi_template :PluginKeyword {
    my $plugin = shift;

    my $vars = pop;
    my $status = shift || $Dancer2::Core::Route::RESPONSE->status( @_ );

    my $template = $Dancer2::Plugin::OpenAPI::THIS_ACTION->{responses}{$status}{template};

    $Dancer2::Core::Route::RESPONSE->status( $status ) if $status =~ /^\d{3}$/;

    return $plugin->openapi_response( $status, $template ? $template->($vars) : $vars );
};

sub openapi_response :PluginKeyword {
    my $plugin = shift;

    my $data = pop;

    my $status = $Dancer2::Core::Route::RESPONSE->status(@_);
#    $Dancer2::Plugin::OpenAPI::THIS_ACTION->validate_response( 
            my $path = Dancer2::Plugin::OpenAPI::Path->new(plugin=>$plugin);
$path->validate_response(
        $status => $data, $plugin->strict_validation 
    ) if $plugin->validate_response;

    $data;
}

sub openapi_definition :PluginKeyword {
    my $plugin = shift;

    my( $name, $def ) = @_;

    $plugin->doc->{definitions} ||= {};

    $plugin->doc->{definitions}{$name} = $def;

    return { '$ref', => '#/definitions/'.$name };

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::OpenAPI - create OpenAPI documentation of your application

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

    package MyApp;

    use Dancer;
    use Dancer2::Plugin::OpenAPI;

    our $VERSION = "0.1";

    get '/choreograph/:name' => sub { ... };

    1;

=head1 DESCRIPTION

This plugin provides tools to create and access a L<OpenApi|https://spec.openapis.org> specification file for a
Dancer REST web service. Originally was L<Dancer::Plugin::Swagger>.

Overview of C<Dancer2::Plugin::OpenAPI>'s features:

=over

=item Can create a F</openapi.json> REST specification file.

=item Can auto-discover routes and add them to the OpenAPI file.

=item Can provide a OpenAPI UI version of the OpenAPI documentation.

=back

=head1 CONFIGURATION

    plugins:
        OpenApi
           main_api_module: MyApp
           show_ui: 1
           ui_url: /doc
           ui_dir: /path/to/files
           auto_discover_skip:
            - /openapi.json
            - qr#^/doc/#

=head2 main_api_module

If not provided explicitly, the OpenApi document's title and version will be set
to the abstract and version of this module. 

For Perl >= 5.36.0, defaults to the first module to import L<Dancer2::Plugin::OpenAPI>.

=head2 show_ui

If C<true>, a route will be created for the Swagger UI (see L<http://swagger.io/swagger-ui/>).

Defaults to C<true>.

=head2 ui_url

Path of the swagger ui route. Will also be the prefix for all the CSS/JS dependencies of the page.

Defaults to C</doc>.

=head2 ui_dir

Filesystem path to the directory holding the assets for the Swagger UI page.

Defaults to a copy of the Swagger UI code bundled with the L<Dancer2::Plugin::OpenAPI> distribution.

=head2 auto_discover_skip

List of urls that should not be added to the OpenApi document by C<openapi_auto_discover>.
If an url begins with C<qr>, it will be compiled as a regular expression.

Defauls to C</openapi.json> and, if C<show_ui> is C<true>, all the urls under C<ui_url>.

=head2 validate_response 

If set to C<true>, calls to C<openapi_response> will verify if a schema is defined 
for the response, and if so validate against it. L<JSON::Schema::AsType> is used for the
validation (and this required if this option is used).

Defaults to C<false>.

=head2 strict_validation

If set to C<true>, dies if a call to C<openapi_response> doesn't find a schema for its response.

Defaults to C<false>.

=head1 PLUGIN KEYWORDS

=head2 openapi_path $description, \%args, $route

    openapi_path {
        description => 'Returns info about a judge',
    },
    get '/judge/:judge_name' => sub {
        ...;
    };

Registers a route as a OpenAPI path item in the OpenAPI document.

C<%args> is optional.

The C<$description> is optional as well, and can also be defined as part of the 
C<%args>.

    # equivalent to the main example
    openapi_path 'Returns info about a judge',
    get '/judge/:judge_name' => sub {
        ...;
    };

If the C<$description> spans many lines, it will be left-trimmed.

    openapi_path q{ 
        Returns info about a judge.

        Some more documentation can go here.

            And this will be seen as a performatted block
            by OpenAPI.
    }, 
    get '/judge/:judge_name' => sub {
        ...;
    };

=head3 Supported arguments

=over

=item method

The HTTP method (GET, POST, etc) for the path item.

Defaults to the route's method.

=item path

The url for the path item.

Defaults to the route's path.

=item description

The path item's description.

=item tags

Optional arrayref of tags assigned to the path.

=item parameters

List of parameters for the path item. Must be an arrayref or a hashref.

Route parameters are automatically populated. E.g., 

    openapi_path
    get '/judge/:judge_name' => { ... };

is equivalent to

    openapi_path {
        parameters => [
            { name => 'judge_name', in => 'path', required => 1, type => 'string' },
        ] 
    },
    get '/judge/:judge_name' => { ... };

If the parameters are passed as a hashref, the keys are the names of the parameters, and they will
appear in the OpenAPI document following their alphabetical order.

If the parameters are passed as an arrayref, they will appear in the document in the order
in which they are passed. Additionally, each parameter can be given as a hashref, or can be a 
C<< name => arguments >> pair. 

In both format, for the key/value pairs, a string value is considered to be the 
C<description> of the parameter.

Finally, if not specified explicitly, the C<in> argument of a parameter defaults to C<query>,
and its type to C<string>.

    parameters => [
        { name => 'bar', in => 'path', required => 1, type => 'string' },
        { name => 'foo', in => 'query', type => 'string', description => 'yadah' },
    ],

    # equivalent arrayref with mixed pairs/non-pairs

    parameters => [
        { name => 'bar', in => 'path', required => 1, type => 'string' },
        foo => { in => 'query', type => 'string', description => 'yadah' },
    ],

    # equivalent hashref format 
    
    parameters => {
        bar => { in => 'path', required => 1, type => 'string' },
        foo => { in => 'query', type => 'string', description => 'yadah' },
    },

    # equivalent, using defaults
    parameters => {
        bar => { in => 'path', required => 1 },
        foo => 'yadah',
    },

=item responses

Possible responses from the path. Must be a hashref.

    openapi_path {
        responses => {
            default => { description => 'The judge information' }
        },
    },
    get '/judge/:judge_name' => { ... };

If the key C<example> is given (instead of C<examples> as defined by the OpenAPI specs), 

and the serializer used by the application is L<Dancer2::Serializer::JSON> or L<Dancer2::Serializer::YAML>,
the example will be expanded to have the right content-type key.

    openapi_path {
        responses => {
            default => { example => { fullname => 'Mary Ann Murphy' } }
        },
    },
    get '/judge/:judge_name' => { ... };

    # equivalent to

    openapi_path {
        responses => {
            default => { examples => { 'application/json' => { fullname => 'Mary Ann Murphy' } } }
        },
    },
    get '/judge/:judge_name' => { ... };

The special key C<template> will not appear in the OpenAPI doc, but will be
used by the C<openapi_template> plugin keyword.

=back

=head2 openapi_template $code, $args

    openapi_path {
        responses => {
            404 => { template => sub { +{ error => "judge '$_[0]' not found" } }  
        },
    },
    get '/judge/:judge_name' => {  
        my $name = param('judge_name');
        return openapi_template 404, $name unless in_db($name);
        ...;
    };

Calls the template for the C<$code> response, passing it C<$args>. If C<$code> is numerical, also set
the response's status to that value. 

=head2 openapi_auto_discover skip => \@list

Populates the OpenAPI document with information of all
the routes of the application.

Accepts an optional C<skip> parameter that takes an arrayref of
routes that shouldn't be added to the OpenAPI document. The routes
can be specified as-is, or via regular expressions. If no skip list is given, defaults to 
the c<auto_discover_skip> configuration value.

    openapi_auto_discover skip => [ '/openapi.json', qr#^/doc/# ];

The information of a route won't be altered if it's 
already present in the document.

If a route has path parameters, they will be automatically
added as such in the C<parameters> section.

Routes defined as regexes are skipped, as there is no clean way
to automatically make them look nice.

        # will be picked up
    get '/user' => ...;

        # ditto, as '/user/{user_id}'
    get '/user/:user_id => ...;

        # won't be picked up
    get qr#/user/(\d+)# => ...;

Note that routes defined after C<openapi_auto_discover> has been called won't 
be added to the OpenAPI document. Typically, you'll want C<openapi_auto_discover>
to be called at the very end of your module. Alternatively, C<openapi_auto_discover>
can be called more than once safely -- which can be useful if an application creates
routes dynamically.

=head2 openapi_definition $name => $definition, ...

Adds a schema (or more) to the definition section of the OpenAPI document.

    openapi_definition 'Judge' => {
        type => 'object',
        required => [ 'fullname' ],
        properties => {
            fullname => { type => 'string' },
            seasons => { type => 'array', items => { type => 'integer' } },
        }
    };

The function returns the reference to the definition that can be then used where
schemas are used.

    my $Judge = openapi_definition 'Judge' => { ... };
    # $Judge is now the hashref '{ '$ref' => '#/definitions/Judge' }'
    
    # later on...
    openapi_path {
        responses => {
            default => { schema => $Judge },
        },
    },
    get '/judge/:name' => sub { ... };

=head1 EXAMPLES

See the F<examples/> directory of the distribution for a working example.

=head1 SEE ALSO

=over

=item L<http://swagger.io/|Swagger>

=item L<Dancer2::Plugin::OpenAPI>

The original plugin, for Dancer1.

=back

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
