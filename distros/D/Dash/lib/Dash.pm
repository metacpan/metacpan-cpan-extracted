package Dash;

use Moo;
use strictures 2;
use 5.020;

our $VERSION = '0.11';    # VERSION

# ABSTRACT: Analytical Web Apps in Perl (Port of Plotly's Dash to Perl)

# TODO Enable signatures?

use JSON;
use Scalar::Util;
use Browser::Open;
use Path::Tiny;
use Dash::Renderer;
use Dash::Config;
use Dash::Exceptions::NoLayoutException;
use Dash::Exceptions::PreventUpdate;
use Dash::Backend::Mojolicious::App;
use namespace::clean;

# TODO Add ci badges

has app_name => ( is      => 'ro',
                  default => __PACKAGE__ );

has port => ( is      => 'ro',
              default => 8080 );

has external_stylesheets => ( is      => 'rw',
                              default => sub { [] } );

has _layout => ( is      => 'rw',
                 default => sub { {} } );

has _callbacks => ( is      => 'rw',
                    default => sub { {} } );

has _rendered_scripts => ( is      => 'rw',
                           default => "" );

has _rendered_external_stylesheets => ( is      => 'rw',
                                        default => "" );

has backend => ( is      => 'rw',
                 default => sub { Dash::Backend::Mojolicious::App->new( dash_app => shift ) } );

has config => ( is      => 'rw',
                default => sub { Dash::Config->new() } );

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
    my %callback = $self->_process_callback_arguments(@_);

    # TODO check_callback
    # TODO Callback map
    my $output      = $callback{Output};
    my $callback_id = $self->_create_callback_id($output);
    my $callbacks   = $self->_callbacks;
    $callbacks->{$callback_id} = \%callback;
    return $self;
}

my $no_update;
my $internal_no_update = bless( \$no_update, 'Dash::Internal::NoUpdate' );

sub no_update {
    return $internal_no_update;
}

sub _process_callback_arguments {
    my $self = shift;

    my %callback;

    # 1. all refs: 1 blessed, 1 array, 1 code or 2 array, 1 code
    #    Hash with keys Output, Inputs, callback
    # 2.     Values content:  hashref or arrayref[hashref], arrayref[hashref], coderef
    # 3.     Values content:  blessed output or arrayref[blessed], arrayref[blessed], coderef

    if ( scalar @_ < 5 ) {    # Unamed arguments, put names
        my ( $output_index, $input_index, $state_index, $callback_index );

        my $index = 0;
        for my $argument (@_) {
            my $type = ref $argument;
            if ( $type eq 'CODE' ) {
                $callback_index = $index;
            } elsif ( Scalar::Util::blessed $argument) {
                if ( $argument->isa('Dash::Dependencies::Output') ) {
                    $output_index = $index;
                }
            } elsif ( $type eq 'ARRAY' ) {
                if ( scalar @$argument > 0 ) {
                    my $first_element = $argument->[0];
                    if ( Scalar::Util::blessed $first_element) {
                        if ( $first_element->isa('Dash::Dependencies::Output') ) {
                            $output_index = $index;
                        } elsif ( $first_element->isa('Dash::Dependencies::Input') ) {
                            $input_index = $index;
                        } elsif ( $first_element->isa('Dash::Dependencies::State') ) {
                            $state_index = $index;
                        }
                    }
                } else {
                    die "Can't use empty arrayrefs as arguments";
                }
            } elsif ( $type eq 'SCALAR' ) {
                die
                  "Can't mix scalarref arguments with objects when not using named paremeters. Please use named parameters for all arguments or classes for all arguments";
            } elsif ( $type eq 'HASH' ) {
                die
                  "Can't mix hashref arguments with objects when not using named parameters. Please use named parameters for all arguments or classes for all arguments";
            } elsif ( $type eq '' ) {
                die
                  "Can't mix scalar arguments with objects when not using named parameters. Please use named parameters for all arguments or classes for all arguments";
            }
            $index++;
        }
        if ( !defined $output_index ) {
            die "Can't find callback output";
        }
        if ( !defined $input_index ) {
            die "Can't find callback inputs";
        }
        if ( !defined $callback_index ) {
            die "Can't find callback function";
        }

        $callback{Output}   = $_[$output_index];
        $callback{Inputs}   = $_[$input_index];
        $callback{callback} = $_[$callback_index];
        if ( defined $state_index ) {
            $callback{State} = $_[$state_index];
        }
    } else {    # Named arguments
                # TODO check keys ¿Params::Validate or similar?
        %callback = @_;
    }

    # Convert Output & input to hashrefs
    for my $key ( keys %callback ) {
        my $value = $callback{$key};

        if ( ref $value eq 'ARRAY' ) {
            my @hashes;
            for my $dependency (@$value) {
                if ( Scalar::Util::blessed $dependency) {
                    my %dependency_hash = %$dependency;
                    push @hashes, \%dependency_hash;
                } else {
                    push @hashes, $dependency;
                }
            }
            $callback{$key} = \@hashes;
        } elsif ( Scalar::Util::blessed $value) {
            my %dependency_hash = %$value;
            $callback{$key} = \%dependency_hash;
        }
    }

    return %callback;
}

sub _create_callback_id {
    my $self   = shift;
    my $output = shift;

    if ( ref $output eq 'ARRAY' ) {
        return ".." . join( "...", map { $_->{component_id} . "." . $_->{component_property} } @$output ) . "..";
    }

    return $output->{component_id} . "." . $output->{component_property};
}

sub run_server {
    my $self = shift;

    $self->_render_and_cache_scripts();
    $self->_render_and_cache_external_stylesheets();

    # Opening the browser before starting the daemon works because
    #  open_browser returns inmediately
    # TODO Open browser optional
    if ( not caller(1) ) {
        Browser::Open::open_browser( 'http://127.0.0.1:' . $self->port );
        $self->backend->start( 'daemon', '-l', 'http://*:' . $self->port );
    }
    return $self->backend;
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
            my $callback_context   = {};
            for my $callback_input ( @{ $callback->{Inputs} } ) {
                my ( $component_id, $component_property ) = @{$callback_input}{qw(component_id component_property)};
                for my $change_input ( @{ $request->{inputs} } ) {
                    my ( $id, $property, $value ) = @{$change_input}{qw(id property value)};
                    if ( $component_id eq $id && $component_property eq $property ) {
                        push @callback_arguments, $value;
                        $callback_context->{inputs}{ $id . "." . $property } = $value;
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
                        $callback_context->{states}{ $id . "." . $property } = $value;
                        last;
                    }
                }
            }

            $callback_context->{triggered} = [];
            for my $triggered_input ( @{ $request->{changedPropIds} } ) {
                push @{ $callback_context->{triggered} },
                  { prop_id => $triggered_input,
                    value   => $callback_context->{inputs}{$triggered_input}
                  };
            }
            push @callback_arguments, $callback_context;

            my $output_type = ref $callback->{Output};
            if ( $output_type eq 'ARRAY' ) {
                my @return_value  = $callback->{callback}(@callback_arguments);
                my $props_updated = {};
                my $index_output  = 0;
                my $some_updated  = 0;
                for my $output ( @{ $callback->{'Output'} } ) {
                    my $output_value = $return_value[ $index_output++ ];
                    if ( !( Scalar::Util::blessed($output_value) && $output_value->isa('Dash::Internal::NoUpdate') ) ) {
                        $props_updated->{ $output->{component_id} } =
                          { $output->{component_property} => $output_value };
                        $some_updated = 1;
                    }
                }
                if ($some_updated) {
                    return { response => $props_updated, multi => JSON::true };
                } else {
                    Dash::Exceptions::PreventUpdate->throw;
                }
            } elsif ( $output_type eq 'HASH' ) {
                my $updated_value = $callback->{callback}(@callback_arguments);
                if ( Scalar::Util::blessed($updated_value) && $updated_value->isa('Dash::Internal::NoUpdate') ) {
                    Dash::Exceptions::PreventUpdate->throw;
                }
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
    my $self = shift;
    my $json = JSON->new->utf8->allow_blessed->convert_blessed;
    return '<script id="_dash-config" type="application/json">' . $json->encode( $self->config ) . '</script>';
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
    my $dev_bundles   = $params{dev_bundles}   // 0;
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Dash - Analytical Web Apps in Perl (Port of Plotly's Dash to Perl)

=head1 VERSION

version 0.11

=head1 SYNOPSIS

 use Dash;
 use aliased 'Dash::Html::Components' => 'html';
 use aliased 'Dash::Core::Components' => 'dcc';
 use aliased 'Dash::Dependencies' => 'deps';
 
 my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];
 
 my $app = Dash->new(
     app_name             => 'Basic Callbacks',
     external_stylesheets => $external_stylesheets
 );
 
 $app->layout(
     html->Div([
         dcc->Input(id => 'my-id', value => 'initial value', type => 'text'),
         html->Div(id => 'my-div')
     ])
 );
 
 $app->callback(
     deps->Output('my-div', 'children'),
     [deps->Input('my-id', 'value')],
     sub {
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

This package is a port of L<Plotly's Dash|https://dash.plot.ly/> to Perl.

Dash makes building analytical web applications very easy. No JavaScript required.

It's a great way to put a nice interactive web interface to your data analysis application 
without having to make a javascript interface and without having to setup servers or web frameworks.
The typical use case is you just have new data to your ML/AI model and you want to explore
diferent ways of training or just visualize the results of different parameter configurations.

=head1 Basics

The main parts of a Dash App are:

=over 4

=item Layout

Declarative part of the app where you specify the view. This layout is composed of components arranged in a hierarchy, just like html. 
This components are available as component suites (for example: L<Dash::Html::Components>, L<Dash::Core::Components>, ...) 
and they can be simple html elements (for example L<Dash::Html::Components::H1>) or as complex as you want like
L<Dash::Core::Components::Graph> that is a charting component based on L<Plotly.js|https://plot.ly/javascript/>.
Most of the time you'll be using Dash Components already built and ready to use.

=item Callbacks

This is the Perl code that gets executed when some component changes 
and the result of this execution another component (or components) gets updated.
Every callback declares a set of inputs, a set of outputs and optionally a set of "state" inputs. 
All inputs, outputs and "state" inputs are known as callback dependencies. Every dependency is related to 
some property of some component, so the inputs determine that if a property of a component declared as input
in a callback will trigger that callback, and the output returned by the callback will update the property of
the component declared as output.

=back

So to make a Dash app you just need to setup the layout and the callbacks. The basic skeleton will be:

    my $app = Dash->new(app_name => 'My Perl Dash App'); 
    $app->layout(...);
    $app->callback(...);
    $app->run_server();

In the SYNOPSIS you can get a taste of how this works and also in L<the examples folder of the distribution|https://metacpan.org/release/Dash>

=head1 Layout

The layout is the declarative part of the app and its the DOM of our app. The root element can be any component,
and after the root element is done the rest are "children" of this root component, that is they are the value of
the children property of the parent component and children can be one "thing" (text, component, whatever as long as can be converted to JSON)
or an arrayref of "things". So the components can be composed as much as you want. For example:

    $app->layout(html->Div(children => [
            html->H1(children => 'Making Perl Dash Apps'),
            html->Img(src => 'https://raw.githubusercontent.com/kraih/perl-raptor/master/example.png' )
        ]));

=head2 Components

This package ships the following component suites and are ready to use:

=over 4

=item * L<Dash Core Components|https://dash.plot.ly/dash-core-components> as Dash::Core::Components. Main components for interactive analytical web apps: forms and charting

=item * L<Dash Html Components|https://dash.plot.ly/dash-html-components> as Dash::Html::Components. Basically the html elements.

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

Every component suite has a factory method for every component. And using this factory methods children keyword is optional as long as the children is the first element.
For example L<Dash::Html::Components> has the factory method Div to load and build a L<Dash::Html::Components::Div> component:

    use Dash::Html::Components;
    ...
    $app->layout(Dash::Html::Components->Div(id => 'my-div', children => 'This is a simple div'));
    # same as
    $app->layout(Dash::Html::Components->Div('This is a simple div', id => 'my-div');

But this factory methods are meant to be aliased so this gets less verbose:

    use aliased 'Dash::Html::Components' => 'html';
    ...
    $app->layout(html->Div(id => 'my-div', children => 'This is a simple div'));
    # same as
    $app->layout(html->Div('This is a simple div', id => 'my-div'));

=head4 Functions

Many modules use the L<Exporter> & friends to reduce typing. If you like that way every component suite gets a Functions package to import all this functions
to your namespace. Using this functions also allows for ommiting the children keyword if the children is the first element.

So for example for L<Dash::Html::Components> there is a package L<Dash::Html::ComponentsFunctions> with one factory function to load and build the component with the same name:

    use Dash::Html::ComponentsFunctions;
    ...
    $app->layout(Div(id => 'my-div', children => 'This is a simple div'));
    # same as
    $app->layout(Div('This is a simple div', id => 'my-div'));

=head1 Callbacks

Callbacks are the reactive part of the web app. They listen to changes in properties of components and get fired by those changes.
The output of the callbacks can update properties for other componentes (or different properties for the same components) and
potentially firing other callbacks. So your app is "reacting" to changes. These properties that fire changes and the properties 
that get updated are dependencies of the callback, they are the "links" between components and callbacks.

Every component that is expected to fire a callback must have a unique id property.

To define a callback is necessary at least:

=over 4

=item Inputs

The component property (or components properties) which fire the callback on every change. The values of this properties are inputs for the callbacks

=item Output

The component (or components) whose property (or properties) get updated

=item callback

The code that gets executed

=back

A minimun callback will be:

    $app->callback(
        Output => {component_id => 'my-div', component_property => 'children'},
        Inputs => [{component_id=>'my-id', component_property=> 'value'}],
        callback => sub {
            my $input_value = shift;
            return "You've entered '$input_value'";
        }
    );

=head2 Dependencies

Dependencies "link" components and callbacks. Every callback dependency has the following attributes:

=over 4

=item component_id

Value of the id property for the component

=item component_property

Name of the property

=back

=head3 Inputs

A callback can have one or more inputs and for every input declared for a callback the value
of the property will be a parameter for the callback in the same order as the input dependencies are declared.

=head3 Outputs

A callback can have one or more output dependencies. When there is only one
output the value returned by the callback updates the value of the property of the component.
In the second case the output of the callback has to be a list
in the list returned will be mapped one by one to the outputs in the same order as the output dependencies are declared.

=head3 State

Apart from Inputs, a callback could need the value of other properties of other components but without 
firing the callback. State dependencies are for this case. So for every state dependency declared for a callback
the value os the property will be a parameter for the callback in the same order the state dependencies are declared
but after all inputs. 

=head3 Dependencies using objects

Dependencies can be declared using just a hash reference but the preferred way is using the classes and factory methods and functions as with the components.

Using objects:

    use Dash::Dependencies::Input;
    use Dash::Dependencies::Output;
    ...
    $app->callback(
        Output => Dash::Dependencies::Output->new(component_id => 'my-div', component_property => 'children'),
        Inputs => [Dash::Dependencies::Input->new(component_id=>'my-id', component_property=> 'value')],
        callback => sub {
            my $input_value = shift;
            return "You've entered '$input_value'";
        }
    );

Using objects allows to omit the keyword arguments in the callback method:

    use Dash::Dependencies::Input;
    use Dash::Dependencies::Output;
    ...
    $app->callback(
        Dash::Dependencies::Output->new(component_id => 'my-div', component_property => 'children'),
        [Dash::Dependencies::Input->new(component_id=>'my-id', component_property=> 'value')],
        sub {
            my $input_value = shift;
            return "You've entered '$input_value'";
        }
    );

There are also factory methods to use this dependencies, which allows to omit the keyword arguments for the dependencies:

    use Dash::Dependencies;
    ...
    $app->callback(
        Dash::Dependencies->Output('my-div', 'children'),
        [Dash::Dependencies->Input(component_id=>'my-id', component_property=> 'value')],
        sub {
            my $input_value = shift;
            return "You've entered '$input_value'";
        }
    );

This can be aliased

    use aliased 'Dash::Dependencies' => 'deps';
    ...
    $app->callback(
        deps->Output(component_id => 'my-div', component_property => 'children'),
        [deps->Input('my-id', 'value')],
        sub {
            my $input_value = shift;
            return "You've entered '$input_value'";
        }
    );

But if you prefer using just functions in your namespace:

    use Dash::DependenciesFunctions;
    ...
    $app->callback(
        Output('my-div', 'children'),
        [Input(component_id=>'my-id', component_property=> 'value')],
        sub {
            my $input_value = shift;
            return "You've entered '$input_value'";
        }
    );

=head1 Running App

The last step is running the app. Just call: 

    $app->run_server();

And it will start a server on port 8080 and open a browser to start using your app!

=head1 Making new components

There are L<a lot of components... for Python|https://github.com/ucg8j/awesome-dash#component-libraries>. So if you want to contribute I'll be glad to help.

Meanwhile you can build your own component. I'll make a better guide and an automated builder but right now you should use L<https://github.com/plotly/dash-component-boilerplate> for all the javascript part (It's L<React|https://github.com/facebook/react> based) and after that the Perl part is very easy (the components are mostly javascript, or typescript):

=over 4

=item * For every component must be a Perl class inheriting from L<Dash::BaseComponent>, overloading the hash dereferencing %{} with the props that the React component has (check L<Dash::BaseComponent> TO_JSON method), and with this methods:

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

Then you just have to publish the component suite as a Perl package. For new component suites you could use whatever package name you like, but if you want to use Dash:: namespace please use Dash::Components:: to avoid future collisions with further development. Besides this will make easier to find more components.

As mentioned early, I'll make an automated builder but contributions are more than welcome!! In the meantime please check L<CONTRIBUTING.md|https://github.com/pablrod/perl-Dash/blob/master/CONTRIBUTING.md>

Making a component for Dash that is not React based is a little bit difficult so please first get the javascript part React based and after that, integrating it with Perl, R or Python will be easy.

=head1 STATUS

At this moment this library is experimental and still under active
development and the API is going to change!

The ultimate goal of course is to support everything that the Python and R versions supports.

The use will follow the Python version of Dash, as close as possible, so the Python doc can be used with
minor changes:

=over 4

=item * Use of -> (arrow operator) instead of .

=item * Main package and class for apps is Dash

=item * Component suites will use Perl package convention, I mean: dash_html_components will be Dash::Html::Components

=item * Instead of decorators we'll use plain old callbacks

=item * Callback context is available as the last parameter of the callback but without the response part

=item * Instead of Flask we'll be using L<Mojolicious> (Maybe in the future L<Dancer2>)

=back

In the SYNOPSIS you can get a taste of how this works and also in L<the examples folder of the distribution|https://metacpan.org/release/Dash> or directly in L<repository|https://github.com/pablrod/perl-Dash/tree/master/examples>. The full Dash tutorial is ported to Perl in those examples folder.

=head2 Missing parts

Right now there are a lot of parts missing:

=over 4

=item * Prefix mount

=item * Debug mode & hot reloading

=item * Dash configuration (supporting environment variables)

=item * Callback dependency checking

=item * Clientside functions

=item * Support for component properties data-* and aria-*

=item * Dynamic layout generation

=back

And many more, but you could use it right now to make great apps! (If you need some inspiration... just check L<https://dash-gallery.plotly.host/Portal/>)

=head2 Security

B<Warning>: this module is not tested for security so test yourself if you are going to run the app server in a public facing server.

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

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
