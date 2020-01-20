package Dash;

use strict;
use warnings;
use 5.020;

our $VERSION = '0.06';    # VERSION

# ABSTRACT: Analytical Web Apps in Perl (Port of Plotly's Dash to Perl)

# TODO Enable signatures?

use Mojo::Base 'Mojolicious';
use JSON;
use Scalar::Util;
use Browser::Open;
use File::ShareDir;
use Path::Tiny;
use Try::Tiny;
use Dash::Renderer;
use Dash::Exceptions::NoLayoutException;

# TODO Add ci badges

has app_name => __PACKAGE__;

has external_stylesheets => sub { [] };

has _layout => sub { {} };

has _callbacks => sub { {} };

has '_rendered_scripts' => "";

has '_rendered_external_stylesheets' => "";

sub layout {
    my $self   = shift;
    my $layout = shift;
    if ( defined $layout ) {
        my $type = ref $layout;
        if ( $type eq 'CODE' || ( Scalar::Util::blessed($layout) && $layout->isa('Dash::BaseComponent') ) ) {
            $self->_layout($layout);
        } else {
            Dash::Exceptions::NoLayoutException->throw(
                                         'Layout must be a dash component or a function that returns a dash component');
        }
    } else {
        $layout = $self->_layout;
    }
    return $layout;
}

sub callback {
    my $self     = shift;
    my %callback = @_;

    # TODO check_callback
    # TODO Callback map
    my $output      = $callback{Output};
    my $callback_id = $self->_create_callback_id($output);
    my $callbacks   = $self->_callbacks;
    $callbacks->{$callback_id} = \%callback;
    return $self;
}

sub _create_callback_id {
    my $self   = shift;
    my $output = shift;

    if ( ref $output eq 'ARRAY' ) {
        return ".." . join( "...", map { $_->{component_id} . "." . $_->{component_property} } @$output ) . "..";
    }

    return $output->{component_id} . "." . $output->{component_property};
}

sub startup {
    my $self = shift;

    my $renderer = $self->renderer;
    push @{ $renderer->classes }, __PACKAGE__;

    my $r = $self->routes;
    $r->get(
        '/' => sub {
            my $c = shift;
            $c->stash( stylesheets          => $self->_rendered_stylesheets,
                       external_stylesheets => $self->_rendered_external_stylesheets,
                       scripts              => $self->_rendered_scripts,
                       title                => $self->app_name
            );
            $c->render( template => 'index' );
        }
    );

    my $dist_name = 'Dash';
    $r->get(
        '/_dash-component-suites/:namespace/*asset' => sub {

            # TODO Component registry to find assets file in other dists
            my $c    = shift;
            my $file = $self->_filename_from_file_with_fingerprint( $c->stash('asset') );

            $c->reply->file(
                       File::ShareDir::dist_file( $dist_name,
                                                  Path::Tiny::path( 'assets', $c->stash('namespace'), $file )->canonpath
                       )
            );
        }
    );

    $r->get(
        '/_favicon.ico' => sub {
            my $c = shift;
            $c->reply->file( File::ShareDir::dist_file( $dist_name, 'favicon.ico' ) );
        }
    );

    $r->get(
        '/_dash-layout' => sub {
            my $c = shift;
            $c->render( json => $self->layout() );
        }
    );

    $r->get(
        '/_dash-dependencies' => sub {
            my $c            = shift;
            my $dependencies = $self->_dependencies();
            $c->render( json => $dependencies );
        }
    );

    $r->post(
        '/_dash-update-component' => sub {
            my $c = shift;

            my $request = $c->req->json;
            try {
                my $content = $self->_update_component($request);
                $c->render( json => $content );
            } catch {
                if ( Scalar::Util::blessed $_ && $_->isa('Dash::Exceptions::PreventUpdate') ) {
                    $c->render( status => 204, json => '' );
                } else {
                    die $_;
                }
            };
        }
    );

    return $self;
}

sub run_server {
    my $self = shift;

    $self->_render_and_cache_scripts();
    $self->_render_and_cache_external_stylesheets();

    # Opening the browser before starting the daemon works because
    #  open_browser returns inmediately
    # TODO Open browser optional
    if ( not caller(1) ) {
        Browser::Open::open_browser('http://127.0.0.1:8080');
        $self->start( 'daemon', '-l', 'http://*:8080' );
    }
    return $self;
}

sub _dependencies {
    my $self         = shift;
    my $dependencies = [];
    for my $callback ( values %{ $self->_callbacks } ) {
        my $rendered_callback = { clientside_function => JSON::null };
        my $states            = [];
        for my $state ( @{ $callback->{State} } ) {
            my $rendered_state = { id       => $state->{component_id},
                                   property => $state->{component_property}
            };
            push @$states, $rendered_state;
        }
        $rendered_callback->{state} = $states;
        my $inputs = [];
        for my $input ( @{ $callback->{Inputs} } ) {
            my $rendered_input = { id       => $input->{component_id},
                                   property => $input->{component_property}
            };
            push @$inputs, $rendered_input;
        }
        $rendered_callback->{inputs} = $inputs;
        my $output_type = ref $callback->{Output};
        if ( $output_type eq 'ARRAY' ) {
            $rendered_callback->{'output'} .= '.';
            for my $output ( @{ $callback->{'Output'} } ) {
                $rendered_callback->{'output'} .=
                  '.' . join( '.', $output->{component_id}, $output->{component_property} ) . '..';
            }
        } elsif ( $output_type eq 'HASH' ) {
            $rendered_callback->{'output'} =
              join( '.', $callback->{'Output'}{component_id}, $callback->{'Output'}{component_property} );
        } else {
            die 'Dependecy type for callback not implemented';
        }
        push @$dependencies, $rendered_callback;
    }
    return $dependencies;
}

sub _update_component {
    my $self    = shift;
    my $request = shift;

    if ( scalar( values %{ $self->_callbacks } ) > 0 ) {
        my $callbacks = $self->_search_callback( $request->{'output'} );
        if ( scalar @$callbacks > 1 ) {
            die 'Not implemented multiple callbacks';
        } elsif ( scalar @$callbacks == 1 ) {
            my $callback           = $callbacks->[0];
            my @callback_arguments = ();
            for my $callback_input ( @{ $callback->{Inputs} } ) {
                my ( $component_id, $component_property ) = @{$callback_input}{qw(component_id component_property)};
                for my $change_input ( @{ $request->{inputs} } ) {
                    my ( $id, $property, $value ) = @{$change_input}{qw(id property value)};
                    if ( $component_id eq $id && $component_property eq $property ) {
                        push @callback_arguments, $value;
                        last;
                    }
                }
            }
            for my $callback_input ( @{ $callback->{State} } ) {
                my ( $component_id, $component_property ) = @{$callback_input}{qw(component_id component_property)};
                for my $change_input ( @{ $request->{state} } ) {
                    my ( $id, $property, $value ) = @{$change_input}{qw(id property value)};
                    if ( $component_id eq $id && $component_property eq $property ) {
                        push @callback_arguments, $value;
                        last;
                    }
                }
            }
            my $output_type = ref $callback->{Output};
            if ( $output_type eq 'ARRAY' ) {
                my @return_value  = $callback->{callback}(@callback_arguments);
                my $props_updated = {};
                my $index_output  = 0;
                for my $output ( @{ $callback->{'Output'} } ) {
                    $props_updated->{ $output->{component_id} } =
                      { $output->{component_property} => $return_value[$index_output] };
                    $index_output++;
                }
                return { response => $props_updated, multi => JSON::true };
            } elsif ( $output_type eq 'HASH' ) {
                my $updated_value    = $callback->{callback}(@callback_arguments);
                my $updated_property = ( split( /\./, $request->{output} ) )[-1];
                my $props_updated    = { $updated_property => $updated_value };
                return { response => { props => $props_updated } };
            } else {
                die 'Callback not supported';
            }
        } else {
            return { response => "There is no matching callback" };
        }

    } else {
        return { response => "There is no registered callbacks" };
    }
    return { response => "Internal error" };
}

sub _search_callback {
    my $self   = shift;
    my $output = shift;

    my $callbacks          = $self->_callbacks;
    my @matching_callbacks = ( $callbacks->{$output} );
    return \@matching_callbacks;
}

sub _rendered_stylesheets {
    return '';
}

sub _render_external_stylesheets {
    my $self                          = shift;
    my $stylesheets                   = $self->external_stylesheets;
    my $rendered_external_stylesheets = "";
    for my $stylesheet (@$stylesheets) {
        $rendered_external_stylesheets .= '<link rel="stylesheet" href="' . $stylesheet . '">' . "\n";
    }
    return $rendered_external_stylesheets;
}

sub _render_and_cache_external_stylesheets {
    my $self        = shift;
    my $stylesheets = $self->_render_external_stylesheets();
    $self->_rendered_external_stylesheets($stylesheets);
}

sub _render_and_cache_scripts {
    my $self    = shift;
    my $scripts = $self->_render_scripts();
    $self->_rendered_scripts($scripts);
}

sub _render_dash_config {
    return
      '<script id="_dash-config" type="application/json">{"url_base_pathname": null, "requests_pathname_prefix": "/", "ui": false, "props_check": false, "show_undo_redo": false}</script>';
}

sub _dash_renderer_js_dependencies {
    my $js_dist_dependencies = Dash::Renderer::_js_dist_dependencies();
    my @js_deps              = ();
    for my $deps (@$js_dist_dependencies) {
        my $external_url          = $deps->{external_url};
        my $relative_package_path = $deps->{relative_package_path};
        my $namespace             = $deps->{namespace};
        my $dep_count             = 0;
        for my $dep ( @{ $relative_package_path->{prod} } ) {
            my $js_dep = { namespace             => $namespace,
                           relative_package_path => $dep,
                           dev_package_path      => $relative_package_path->{dev}[$dep_count],
                           external_url          => $external_url->{prod}[$dep_count]
            };
            push @js_deps, $js_dep;
            $dep_count++;
        }
    }
    \@js_deps;
}

sub _dash_renderer_js_deps {
    return Dash::Renderer::_js_dist();
}

sub _render_dash_renderer_script {
    return '<script id="_dash-renderer" type="application/javascript">var renderer = new DashRenderer();</script>';
}

sub _render_scripts {
    my $self = shift;

    # First dash_renderer dependencies
    my $scripts_dependencies = $self->_dash_renderer_js_dependencies;

    # Traverse layout and recover javascript dependencies
    # TODO auto register dependencies on component creation to avoid traversing and filter too much dependencies
    my $layout = $self->layout;

    my $visitor;
    my $stack_depth_limit = 1000;
    $visitor = sub {
        my $node        = shift;
        my $stack_depth = shift;
        if ( $stack_depth++ >= $stack_depth_limit ) {

            # TODO warn user that layout is too deep
            return;
        }
        my $type = ref $node;
        if ( $type eq 'HASH' ) {
            for my $key ( keys %$node ) {
                $visitor->( $node->{$key}, $stack_depth );
            }
        } elsif ( $type eq 'ARRAY' ) {
            for my $element (@$node) {
                $visitor->( $element, $stack_depth );
            }
        } elsif ( $type ne '' ) {
            my $node_dependencies = $node->_js_dist();
            push @$scripts_dependencies, @$node_dependencies if defined $node_dependencies;
            if ( $node->can('children') ) {
                $visitor->( $node->children, $stack_depth );
            }
        }
    };

    $visitor->( $layout, 0 );

    my $rendered_scripts = "";
    $rendered_scripts .= $self->_render_dash_config();
    push @$scripts_dependencies, @{ $self->_dash_renderer_js_deps() };
    my $filtered_resources = $self->_filter_resources($scripts_dependencies);
    my %rendered           = ();
    for my $dep (@$filtered_resources) {
        my $dynamic = $dep->{dynamic} // 0;
        if ( !$dynamic ) {
            my $resource_path_part = join( "/", $dep->{namespace}, $dep->{relative_package_path} );
            if ( !$rendered{$resource_path_part} ) {
                $rendered_scripts .=
                  '<script src="/' . join( "/", '_dash-component-suites', $resource_path_part ) . '"></script>' . "\n";
                $rendered{$resource_path_part} = 1;
            }
        }
    }
    $rendered_scripts .= $self->_render_dash_renderer_script();

    return $rendered_scripts;
}

sub _filter_resources {
    my $self          = shift;
    my $resources     = shift;
    my %params        = @_;
    my $dev_bundles   = $params{dev_bundles} // 0;
    my $eager_loading = $params{eager_loading} // 0;
    my $serve_locally = $params{serve_locally} // 1;

    my $filtered_resources = [];
    for my $resource (@$resources) {
        my $filtered_resource = {};
        my $dynamic           = $resource->{dynamic};
        if ( defined $dynamic ) {
            $filtered_resource->{dynamic} = $dynamic;
        }
        my $async = $resource->{async};
        if ( defined $async ) {
            if ( defined $dynamic ) {
                die "A resource can't have both dynamic and async: " + to_json($resource);
            }
            my $dynamic = 1;
            if ( $async eq 'lazy' ) {
                $dynamic = 1;
            } else {
                if ( $async eq 'eager' && !$eager_loading ) {
                    $dynamic = 1;
                } else {
                    if ( $async && !$eager_loading ) {
                        $dynamic = 1;
                    } else {
                        $dynamic = 0;
                    }
                }
            }
            $filtered_resource->{dynamic} = $dynamic;
        }
        my $namespace = $resource->{namespace};
        if ( defined $namespace ) {
            $filtered_resource->{namespace} = $namespace;
        }
        my $external_url = $resource->{external_url};
        if ( defined $external_url && !$serve_locally ) {
            $filtered_resource->{external_url} = $external_url;
        } else {
            my $dev_package_path = $resource->{dev_package_path};
            if ( defined $dev_package_path && $dev_bundles ) {
                $filtered_resource->{relative_package_path} = $dev_package_path;
            } else {
                my $relative_package_path = $resource->{relative_package_path};
                if ( defined $relative_package_path ) {
                    $filtered_resource->{relative_package_path} = $relative_package_path;
                } else {
                    my $absolute_path = $resource->{absolute_path};
                    if ( defined $absolute_path ) {
                        $filtered_resource->{absolute_path} = $absolute_path;
                    } else {
                        my $asset_path = $resource->{asset_path};
                        if ( defined $asset_path ) {
                            my $stat_info = path( $resource->{filepath} )->stat;
                            $filtered_resource->{asset_path} = $asset_path;
                            $filtered_resource->{ts}         = $stat_info->mtime;
                        } else {
                            if ($serve_locally) {
                                warn
                                  'There is no local version of this resource. Please consider using external_scripts or external_stylesheets : '
                                  + to_json($resource);
                                next;
                            } else {
                                die
                                  'There is no relative_package-path, absolute_path or external_url for this resource : '
                                  + to_json($resource);
                            }
                        }
                    }
                }
            }
        }

        push @$filtered_resources, $filtered_resource;
    }
    return $filtered_resources;
}

sub _filename_from_file_with_fingerprint {
    my $self       = shift;
    my $file       = shift;
    my @path_parts = split( /\//, $file );
    my @name_parts = split( /\./, $path_parts[-1] );

    # Check if the resource has a fingerprint
    if ( ( scalar @name_parts ) > 2 && $name_parts[1] =~ /^v[\w-]+m[0-9a-fA-F]+$/ ) {
        my $original_name = join( ".", $name_parts[0], @name_parts[ 2 .. ( scalar @name_parts - 1 ) ] );
        $file = join( "/", @path_parts[ 0 .. ( scalar @path_parts - 2 ) ], $original_name );
    }

    return $file;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Dash - Analytical Web Apps in Perl (Port of Plotly's Dash to Perl)

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 use Dash;
 use aliased 'Dash::Html::Components' => 'html';
 use aliased 'Dash::Core::Components' => 'dcc';
 
 my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];
 
 my $app = Dash->new(
     app_name             => 'Basic Callbacks',
     external_stylesheets => $external_stylesheets
 );
 
 $app->layout(
     html->Div(children => [
         dcc->Input(id => 'my-id', value => 'initial value', type => 'text'),
         html->Div(id => 'my-div')
     ])
 );
 
 $app->callback(
     Output => {component_id => 'my-div', component_property => 'children'},
     Inputs => [{component_id=>'my-id', component_property=> 'value'}],
     callback => sub {
         my $input_value = shift;
         return "You've entered '$input_value'";
     }
 );
 
 $app->run_server();

 use Dash;
 use aliased 'Dash::Html::Components' => 'html';
 use aliased 'Dash::Core::Components' => 'dcc';
 
 my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];
 
 my $app = Dash->new(
     app_name             => 'Random chart',
     external_stylesheets => $external_stylesheets
 );
 
 my $initial_number_of_values = 20;
 $app->layout(
     html->Div(children => [
         dcc->Input(id => 'my-id', value => $initial_number_of_values, type => 'number'),
         dcc->Graph(id => 'my-graph')
     ])
 );
 
 my $serie = [ map { rand(100) } 1 .. $initial_number_of_values];
 $app->callback(
     Output => {component_id => 'my-graph', component_property => 'figure'},
     Inputs => [{component_id=>'my-id', component_property=> 'value'}],
     callback => sub {
         my $number_of_elements = shift;
         my $size_of_serie = scalar @$serie;
         if ($number_of_elements >= $size_of_serie) {
             push @$serie, map { rand(100) } $size_of_serie .. $number_of_elements;
         } else {
             @$serie = @$serie[0 .. $number_of_elements];
         }
         return { data => [ {
             type => "scatter",
             y => $serie
             }]};
     }
 );
 
 $app->run_server();

=head1 DESCRIPTION

This package is a port of L<Plotly's Dash|https://dash.plot.ly/> to Perl. As
the official Dash doc says: I<Dash is a productive Python framework for building web applications>. 
So this Perl package is a humble atempt to ease the task of building data visualization web apps in Perl.

The ultimate goal of course is to support everything that the Python version supports.

The use will follow, as close as possible, the Python version of Dash so the Python doc can be used with
minor changes:

=over 4

=item * Use of -> (arrow operator) instead of .

=item * Main package and class for apps is Dash

=item * Component suites will use Perl package convention, I mean: dash_html_components will be Dash::Html::Components, although for new component suites you could use whatever package name you like

=item * Instead of decorators we'll use plain old callbacks

=item * Instead of Flask we'll be using L<Mojolicious> (Maybe in the future L<Dancer2>)

=back

In the SYNOPSIS you can get a taste of how this works and also in L<the examples folder of the distribution|https://metacpan.org/release/Dash> or directly in L<repository|https://github.com/pablrod/perl-Dash/tree/master/examples>. The full Dash tutorial is ported to Perl in those examples folder.

=head2 Components

This package ships the following component suites and are ready to use:

=over 4

=item * L<Dash Core Components|https://dash.plot.ly/dash-core-components> as Dash::Core::Components

=item * L<Dash Html Components|https://dash.plot.ly/dash-html-components> as Dash::Html::Components

=item * L<Dash DataTable|https://dash.plot.ly/datatable> as Dash::Table

=back

The plan is to make the packages also for L<Dash-Bio|https://dash.plot.ly/dash-bio>, L<Dash-DAQ|https://dash.plot.ly/dash-daq>, L<Dash-Canvas|https://dash.plot.ly/canvas> and L<Dash-Cytoscape|https://dash.plot.ly/cytoscape>.

=head3 Using the components

Every component has a class of its own. For example dash-html-component Div has the class: L<Dash::Html::Components::Div> and you can use it the perl standard way:

    use Dash::Html::Components::Div;
    ...
    $app->layout(Dash::Html::Components::Div->new(id => 'my-div', children => 'This is a simple div'));

But with every component suite could be a lot of components. So to ease the task of importing them (one by one is a little bit tedious) we could use two ways:

=head4 Factory methods

Every component suite has a factory method for every component. For example L<Dash::Html::Components> has the factory method Div to load and build a L<Dash::Html::Components::Div> component:

    use Dash::Html::Components;
    ...
    $app->layout(Dash::Html::Components->Div(id => 'my-div', children => 'This is a simple div'));

But this factory methods are meant to be aliased so this gets less verbose:

    use aliased 'Dash::Html::Components' => 'html';
    ...
    $app->layout(html->Div(id => 'my-div', children => 'This is a simple div'));

=head4 Functions

Many modules use the L<Exporter> & friends to reduce typing. If you like that way every component suite gets a Functions package to import all this functions
to your namespace.

So for example for L<Dash::Html::Components> there is a package L<Dash::Html::ComponentsFunctions> with one factory function to load and build the component with the same name:

    use Dash::Html::ComponentsFunctions;
    ...
    $app->layout(Div(id => 'my-div', children => 'This is a simple div'));

=head3 I want more components

There are L<a lot of components... for Python|https://github.com/ucg8j/awesome-dash#component-libraries>. So if you want to contribute I'll be glad to help.

Meanwhile you can build your own component. I'll make a better guide and an automated builder but right now you should use L<https://github.com/plotly/dash-component-boilerplate> for all the javascript part (It's L<React|https://github.com/facebook/react> based) and after that the Perl part is very easy (the components are mostly javascript, or typescript):

=over 4

=item * For every component must be a Perl class inheriting from L<Dash::BaseComponent>, overloaded the hash dereferencing %{} with the props that the React component has, and with this methods:

=over 4

=item DashNamespace

Namespace of the component

=item _js_dist

Javascript dependencies for the component

=item _css_dist

Css dependencies for the component

=back

=back

Optionally the component suite will have the Functions package and the factory methods for ease of using.

As mentioned early, I'll make an automated builder but contributions are more than welcome!!

Making a component for Dash that is not React based is a little bit difficult so please first get the javascript part React based and integrating it with Perl, R or Python will be easy.

=head1 Missing parts

Right now there are a lot of parts missing:

=over 4

=item * Callback context

=item * Prefix mount

=item * Debug mode & hot reloading

=item * Dash configuration (supporting environment variables)

=item * Callback dependency checking

=item * Clientside functions

=item * Support for component properties data-* and aria-*

=item * Dynamic layout generation

=back

And many more, but you could use it right now to make great apps! (If you need some inspiration... just check L<https://dash-gallery.plotly.host/Portal/>)

=head1 STATUS

At this moment this library is experimental and still under active
development and the API is going to change!

The intent of this release is to try, test and learn how to improve it.

Security warning: this module is not tested for security so test yourself if you are going to run the app server in a public facing server.

If you want to help, just get in contact! Every contribution is welcome!

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think Dash is a great library and I want to use it with perl.

If you like Dash please consider supporting them purchasing professional services: L<Dash Enterprise|https://plot.ly/dash/>

=head1 SEE ALSO

=over 4

=item L<Dash|https://dash.plot.ly/>

=item L<Dash Repository|https://github.com/plotly/dash>

=item L<Chart::Plotly>

=item L<Chart::GGPlot>

=item L<Alt::Data::Frame::ButMore>

=item L<AI::MXNet>

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Renderer';
<div id="react-entry-point">
    <div class="_dash-loading">
        Loading...
    </div>
</div>

        <footer>
            <%== $scripts %>
        </footer>


@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
      <meta charset="UTF-8">
        <title><%= $title %></title>
        <link rel="icon" type="image/x-icon" href="/_favicon.ico?v=1.7.0">
        <%== $stylesheets %>
        <%== $external_stylesheets %>
    </head>
    <body>
        
  <%= content %>
    </body>
</html>


