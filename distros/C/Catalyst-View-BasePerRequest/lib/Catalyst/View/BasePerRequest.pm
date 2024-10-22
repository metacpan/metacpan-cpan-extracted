package Catalyst::View::BasePerRequest;

our $VERSION = '0.011';
our $DEFAULT_FACTORY = 'Catalyst::View::BasePerRequest::Lifecycle::Request';

use Moose;
use HTTP::Status ();
use Scalar::Util ();
use Module::Runtime ();

extends 'Catalyst::View';

has 'catalyst_component_name' => (is=>'ro');
has 'app' => (is=>'ro', required=>1);
has 'ctx' => (is=>'ro', required=>1);
has 'root' => (is=>'rw', required=>1, default=>sub { shift });
has 'parent' => (is=>'rw', predicate=>'has_parent');
has 'content_type' => (is=>'ro', required=>0, predicate=>'has_content_type');
has 'code' => (is=>'rw', predicate=>'has_code');
has 'status_codes' => (is=>'rw', predicate=>'has_status_codes');
has 'injected_views' => (is=>'rw', predicate=>'has_injected_views');
has 'forwarded_args' => (is=>'rw', predicate=>'has_forwarded_args');

sub application { shift->app }

sub views {
  my ($app, %views) = @_;
  $app->config->{views} = \%views;
}

sub view {
  my ($app, $method, @args) = @_;
  if(scalar(@args) > 1) {
    $app->config->{views}{$method} = \@args;
  } else {
    $app->config->{views}{$method} = $args[0];
  }
}

sub set_content_type {
  my ($app, $ct) = @_;
  $app->config->{content_type} = $ct;
}

sub set_status_codes {
  my $app = shift;
  my $codes = ref($_[0]) ? shift : [shift];
  $app->config->{status_codes} = $codes;
}

sub COMPONENT {
  my ($class, $app, $args) = @_;
  my $merged_args = $class->merge_config_hashes($class->config, $args);

  $merged_args = $class->modify_init_args($app, $merged_args) if $class->can('modify_init_args');
  my %status_codes = $class->inject_http_status_helpers($merged_args);
  $merged_args->{status_codes} = \%status_codes if scalar(keys(%status_codes));
  my @injected_views = $class->inject_view_helpers($merged_args);
  $merged_args->{injected_views} = \@injected_views if scalar @injected_views;

  my $factory_class = Module::Runtime::use_module($class->factory_class($app, $merged_args));
  return my $factory = $class->build_factory($factory_class, $app, $merged_args);
}

sub inject_view_helpers {
  my ($class, $merged_args) = @_;
  if(my $views = $merged_args->{views}) {
    require Sub::Util;
    foreach my $method (keys %$views) {
      my ($view_name, @args_proto) = ();
      my $options_proto = $views->{$method};

      my $global_args_generator;
      if( (ref($options_proto)||'') eq 'ARRAY') {
        ($view_name, @args_proto) = @$options_proto;
        $global_args_generator = (ref($args_proto[0])||'') eq 'CODE' ?
          shift(@args_proto) :
            sub { @args_proto };
      } else {
        $view_name = $options_proto;
      }

      no strict 'refs';
      *{"${class}::${method}"} = Sub::Util::set_subname "${class}::${method}" => sub {
        my ($self, @args) = @_;
        my @global_args = $global_args_generator ? $global_args_generator->($self, $self->ctx, @args) : ();
        my $view = $self->ctx->view($view_name, @global_args, @args);

        $view->root($self->root);
        $view->parent($self);

        return $view;
      }; 
    }
    return keys %$views;
  }
  return ();
}

sub inject_http_status_helpers {
  my ($class, $merged_args) = @_;

  my %status_codes = ();
  if(exists $merged_args->{status_codes}) {
    %status_codes = map { $_=>1 } @{$merged_args->{status_codes}};
  }

  foreach my $helper( grep { $_=~/^http/i} @HTTP::Status::EXPORT_OK) {
    my $subname = lc $helper;
    my $code = HTTP::Status->$helper;
    if(scalar(keys(%status_codes))) {
      next unless $status_codes{$code};
    }
    eval "sub ${\$class}::${\$subname} { return shift->respond(HTTP::Status::$helper,\\\@_) }";
    eval "sub ${\$class}::set_${\$subname} {
      my (\$self, \@headers) = \@_; 
      \$self->ctx->res->status(HTTP::Status::$helper);
      \$self->ctx->res->headers->push_header(\@headers) if \@headers;
      return \$self;
    }";
  }

  return %status_codes;
}

sub factory_class {
  my ($class, $app, $merged_args) = @_;
  if(exists $merged_args->{lifecycle}) {
    my $lifecycle = $merged_args->{lifecycle};
    $lifecycle = "Catalyst::View::BasePerRequest::Lifecycle::${lifecycle}" unless $lifecycle=~/^\+/;
    return $lifecycle;
  }
  return $DEFAULT_FACTORY;
}

sub build {
  my ($class, %args) = @_;
  return $class->new(%args);
}

sub build_factory {
  my ($class, $factory_class, $app, $merged_args) = @_;
  return $factory_class->new(
    class => $class,
    app => $app,
    merged_args => $merged_args
  );
}

sub render {
  my ($self, $ctx, @args) = @_;
  die "You need to write a 'render' method!";
}

sub process {
  my ($self, $c, @args) = @_;
  $self->forwarded_args(\@args);
  return $self->respond();
}

sub respond {
  my ($self, $status, $headers, @args) = @_;
  for my $r ($self->ctx->res) {
    $r->status($status) if $status && $r->status; # != 200; # Catalyst sets 200

    Module::Runtime::use_module('Catalyst::View::BasePerRequest::Exception::InvalidStatusCode')->throw(status_code=>$r->status)
      if $self->has_status_codes && !$self->status_codes->{$r->status};
  
    $r->content_type($self->content_type) if !$r->content_type && $self->has_content_type;
    $r->headers->push_header(@{$headers}) if $headers;
    $r->body($self->get_rendered(@args));
  }
  return $self; # allow chaining
}

sub get_rendered {
  my $self = shift;
  my @rendered = ();

  eval {
    my @args = $self->prepare_render_args(@_);
    @rendered = map {
      Scalar::Util::blessed($_) && $_->can('get_rendered') ? $_->get_rendered : $_;
    } $self->render(@args);
    1;
  } || do { 
    $self->do_handle_render_exception($@);
  };

  return $self->flatten_rendered_for_response_body(@rendered);
}

sub flatten_rendered_for_response_body { return shift->flatten_rendered(@_) }

sub render_error_class { 'Catalyst::View::BasePerRequest::Exception::RenderError' }

sub do_handle_render_exception {
  my ($self, $err) = @_;
  return $err->rethrow if Scalar::Util::blessed($err) && $err->can('rethrow');
  my $class = Module::Runtime::use_module($self->render_error_class);
  $class->throw(render_error=>$err);
}

sub prepare_render_args {
  my ($self, @args) = @_;

  if($self->has_code) {
    my $inner = $self->render_code;
    unshift @args, $inner; # pass any $inner as an argument to ->render()
  }

  return ($self->ctx, @args);
}

sub render_code {
  my $self = shift;
  my @inner = map {
    Scalar::Util::blessed($_) && $_->can('get_rendered') ? $_->get_rendered : $_;
  }  $self->execute_code_callback($self->prepare_render_code_args);

  my $flat = $self->flatten_rendered_for_inner_content(@inner);
  return $flat;
}

sub execute_code_callback {
  my ($self, @args) = @_;
  return $self->code->(@args);
}

sub prepare_render_code_args {
  my ($self) = @_;
  return $self;
}

sub flatten_rendered_for_inner_content { return shift->flatten_rendered(@_) }

sub flatten_rendered {
  my $self = shift;
  return join '', grep { defined($_) } @_;
}

sub content {
  my ($self, $name, $options) = @_;
  my %options = $options ? %$options : ();
  my $default = exists($options{default}) ? $options{default} : '';

  return exists($self->ctx->stash->{view_blocks}{$name}) ? 
    $self->ctx->stash->{view_blocks}{$name} :
      $default;
}

sub render_content_value {
  my $self = shift;
  if((ref($_[0])||'') eq 'CODE') {
    return $self->flatten_rendered_for_content_blocks($_[0]->($_[1]));
  } else {
    return $self->flatten_rendered_for_content_blocks(@_);
  }
}

sub flatten_rendered_for_content_blocks { return shift->flatten_rendered(@_) }

sub content_for {
  my ($self, $name, $value) = @_;
  Module::Runtime::use_module($self->_content_exception_class)
    ->throw(content_name=>$name, content_msg=>'Content block is already defined') if $self->_content_exists($name);
  $self->ctx->stash->{view_blocks}{$name} = $self->render_content_value($value);
  return;
}

sub content_append {
  my ($self, $name, $value) = @_;
  Module::Runtime::use_module($self->_content_exception_class)
    ->throw(content_name=>$name, content_msg=>'Content block doesnt exist for appending') unless $self->_content_exists($name);
  $self->ctx->stash->{view_blocks}{$name} .= $self->render_content_value($value);
  return;
}

sub content_prepend {
  my ($self, $name, $value) = @_;
  Module::Runtime::use_module($self->_content_exception_class)
    ->throw(content_name=>$name, content_msg=>'Content block doesnt exist for prepending') unless $self->_content_exists($name);
  $self->ctx->stash->{view_blocks}{$name} = $self->render_content_value($value) . $self->ctx->stash->{view_blocks}{$name};
  return;
}


sub content_replace {
  my ($self, $name, $value) = @_;
  Module::Runtime::use_module($self->_content_exception_class)
    ->throw(content_name=>$name, content_msg=>'Content block doesnt exist for replacing') unless $self->_content_exists($name);
  $self->ctx->stash->{view_blocks}{$name} = $self->render_content_value($value);
  return;
}

sub content_around {
  my ($self, $name, $value) = @_;
  Module::Runtime::use_module($self->_content_exception_class)
    ->throw(content_name=>$name, content_msg=>'Content block doesnt exist') unless $self->_content_exists($name);
  $self->ctx->stash->{view_blocks}{$name} = $self->render_content_value($value, $self->ctx->stash->{view_blocks}{$name});
  return;
}

sub _content_exception_class { return 'Catalyst::View::BasePerRequest::Exception::ContentBlockError' }

sub _content_exists {
  my ($self, $name) = @_;
  return exists $self->ctx->stash->{view_blocks}{$name} ? 1:0;
}

sub detach { return shift->ctx->detach }

__PACKAGE__->meta->make_immutable;

=head1 NAME
 
Catalyst::View::Template::BasePerRequest - Catalyst base view for per request, strongly typed templates

=head1 SYNOPSIS

    package Example::View::Hello;

    use Moose;

    extends 'Catalyst::View::BasePerRequest';

    has name => (is=>'ro', required=>1);
    has age => (is=>'ro', required=>1);

    sub render {
      my ($self, $c) = @_;
      return "<div>Hello @{[ $self->name] }",
        "I see you are @{[ $self->age]} years old!</div>";
    }

    __PACKAGE__->config(
      content_type=>'text/html',
      status_codes=>[200]
    );

    __PACKAGE__->meta->make_immutable();

One way to use it in a controller:

    package Example::Controller::Root;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub root :Chained(/) PathPart('') CaptureArgs(0) { } 

      sub hello :Chained(root) Args(0) {
        my ($self, $c) = @_;
        return $c->view(Hello =>
          name => 'John',
          age => 53
        )->http_ok;
      }

    __PACKAGE__->config(namespace=>'');
    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

B<NOTE>: This is early access code.  Although it's based on several other internal projects
which I have iterated over this concept for a number of years I still reserve the right
to make breaking changes as needed.

B<NOTE>: You probably won't actually use this directly, it's intended to be a base framework
for building / prototyping strongly typed / per request views in L<Catalyst>. This
documentation serves as an overview of the concept.  In particular please note that
this code does not address any issues around HTML / Javascript injection attacks or
provides any auto escaping. You'll need to bake those features into whatever you
build on top of this.  Because of this the following documentation is light and is mostly
intended to help anyone who is planning to build something on top of this framework
rather than use it directly.

B<NOTE>: This distribution's C</example> directory gives you a toy prototype using L<HTML::Tags>
as the basis to a view as well as some raw examples using this code directly (again,
not recommended for anything other than learning).

In a classic L<Catalyst> application with server side templates, the canonical approach
is to use a 'view' as a sort of handler for an underlying template system (such as 
L<Template::Toolkit> or L<Xslate>) and to send data to this template by populating
the stash.  These views are very lean, and in general don't provide much in the way
of view logic processing; they generally are just a thin proxy for the underlying
templating system.

This approach has the upside of being very simple to understand and in general works
ok with a simple websites.  There are however downsides as your site becomes more
complex. First of all the stash as a means to pass data from the Controller to the
template can be fragile.  For example just making a simple typo in the stash key
can break your templates in ways that might not be easy to figure out.  Also your
template can't enforce its requirements very easily (and it's not easy for someone
working in the controller to know exactly what things need to go into the stash in
order for the template to function as desired.)  The view itself has no way of 
providing view / display oriented logic; generally that logic ends up creeping back up
into the controller in ways that break the notion of MVC's separation of concerns.

Lastly the controller doesn't have a defined API with the view. All it can ask the view
is 'go ahead and process yourself using the current context' and all it gets back from
the view is a string response.  If the controller wishes to introspect this response
or modify it in some way prior to it being sent back to the client, you have few options
apart from using regular expression matching to try and extract the required information
or to modify the response string.

Basically the classic approach works acceptable well for a simple website but starts to
break down as your site becomes more complicated.

An alternative approach, which is explored in this distribution, is to have a defined view for
each desired response and for it to define an explicit API that the controller uses to provide the required
and optional data to the view.  This defined view can further define its own methods
used to generate suitable information for display.   Such an approach is more initial work
as well as learning for the website developers, but in the long term it can provide
an easier path to sustainable development and maintainence with hopefully fewer bugs 
and overall site issues.

=head1 EXAMPLE: Basic

The most minimal thing your view must provide in a C<render> method.   This method gets
the view object and the context (it can also receive additional arguments if this view is
being called from other views as a wrapper or parent view; more on that later).

The C<render> method should return a string or array of strings suitable for the body of
the response> B<NOTE> if you return an array of strings we flatten the array into a single
string since the C<body> method of L<Catalyst::Response> can't take an array.

Here's a minimal example:

    package Example::View::Hello;

    use Moose;

    extends 'Catalyst::View::BasePerRequest';

    sub render {
      my ($self, $c) = @_;
      return "<p>Hello</p>";
    }

    __PACKAGE__->config(content_type=>'text/html');

And here's an example view with attributes:

    package Example::View::HelloPerson;

    use Moose;

    extends 'Catalyst::View::BasePerRequest';

    has name => (is=>'ro', required=>1);

    sub render {
      my ($self, $c) = @_;
      return qq[
        <div>
          Hello  @{[ $self->name ]}
        </div>];
    }

    __PACKAGE__->meta->make_immutable();

One way to invoke this view from the controller using the traditional C<forward> method:

    package Example::Controller::Root;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub root :Chained(/) PathPart('') CaptureArgs(0) { }

      sub hello :Chained(root) Args(0) {
        my ($self, $c) = @_;
        my $view = $c->view(HelloPerson => (name => 'John'));
        return $c->forward($view);
      }

    __PACKAGE__->config(namespace=>'');
    __PACKAGE__->meta->make_immutable;

Alternatively using L</"RESPONSE HELPERS">:

    package Example::Controller::Root;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub root :Chained(/) PathPart('') CaptureArgs(0) { }

      sub hello :Chained(root) Args(0) {
        my ($self, $c) = @_;
        return $c->view(HelloPerson => (name => 'John'))->http_ok;
      }

    __PACKAGE__->config(namespace=>'');
    __PACKAGE__->meta->make_immutable;

=head1 ATTRIBUTES

The following Moose attributes are considered part of this classes public API

=head2 app

The string namespace of your L<Catalyst> application.

=head2 ctx

The current L<Catalyst> context

=head2 root

The root view object (that is the top view that was called first, usually from
the controller).  

=head2 parent

=head2 has_parent

If the view was called from another view, that first view is set as the parent.

=head2 injected_views

=head2 has_injected_views

An arrayref of the method names associated with any injected views.

=head1 METHODS

The following methods are considered part of this classes public API

=head2 process

Renders a view and sets up the response object.  Generally this is called from a
controller via the C<forward> method and not directly:

    $c->forward($view);

=head2 respond

Accepts an HTTP status code and an arrayref of key / values used to set HTTP headers for a
response.  Example:

    $view->respond(201, [ location=>$url ]);

Returns the view object to make it easier to do method chaining

=head2 detach

Just a shortcut to ->detach via the context

=head1 CONTENT BLOCK HELPERS

Content block helpers are an optional feature to make it easy to create and populate content
areas between different views.  Although you can also do this with object attributes you may
wish to separate template / text from data.  Example:

    package Example::View::Layout;

    use Moose;

    extends 'Catalyst::View::BasePerRequest';

    has title => (is=>'ro', required=>1, default=>'Missing Title');

    sub render {
      my ($self, $c, $inner) = @_;
      return "
        <html>
          <head>
            <title>@{[ $self->title ]}</title>
            @{[ $self->content('css') ]}
          </head>
          <body>$inner</body>
        </html>";
    }

    __PACKAGE__->config(content_type=>'text/html');
    __PACKAGE__->meta->make_immutable();

    package Example::View::Hello;

    use Moose;

    extends 'Catalyst::View::BasePerRequest';

    has name => (is=>'ro', required=>1);

    sub render {
      my ($self, $c) = @_;
      return $c->view(Layout => title=>'Hello', sub {
        my $layout = shift;
        $self->content_for('css', "<style>...</style>");
        return "<div>Hello @{[ $self->name ]}!</div>";
      });
    }

    __PACKAGE__->config(content_type=>'text/html', status_codes=>[200]);
    __PACKAGE__->meta->make_immutable();

=head2 content

Examples:

    $self->content($name);
    $self->content($name, +{ default=>'No main content' });

Gets a content block string by '$name'.  If the block has not been defined returns either
a zero length string or whatever you set the default key of the hashref options to.

=head2 content_for

Sets a named content block or throws an exception if the content block already exists.

=head2 content_append

Appends to a named content block or throws an exception if the content block doesn't exist.

=head2 content_replace

Replaces a named content block or throws an exception if the content block doesn't exist.

=head2 content_around

Wraps an existing content with new content.  Throws an exception if the named content block doesn't exist.

    $self->content_around('footer', sub {
      my $footer = shift;
      return "wrapped $footer end wrap";
    });

=head1 VIEW INJECTION

Usually when building a website of more than toy complexity you will find that you will
decompose your site into sub views and view wrappers.  Although you can call the C<view>
method on the context, I think its more in the spirit of the idea of a strong or structured
view to have a view declare upfront what views its calling as sub views.  That lets you
have more central control over view initalization and decouples how you are calling your
views from the actual underlying views.  It can also tidy up some of the code and lastly
makes it easy to immediately know what views are needed for the current one.  This can
help with later refactoring (I've worked on projects where sub views got detached from
actual use but nobody ever cleaned them up.)

To inject a view into the current one, you need to declare it in configuration:

    __PACKAGE__->config(
      content_type=>'text/html', 
      status_codes=>[200,404,400],
      views=>+{
        layout1 => [ Layout => sub { my ($self, $c) = @_; return title=>'Hey!' } ],
        layout2 => [ Layout => (title=>'Yeah!') ],
        layout3 => 'Layout',
      },
    );

Basically this is a hashref under the C<views> key, where each key in the hashref is the name
of the method you are injecting into the current view which is responsible for creating the
sub view and the value is one of three options:

=over

=item A scalar value

    __PACKAGE__->config(
      content_type=>'text/html', 
      status_codes=>[200,404,400],
      views=>+{
        layout => 'Layout',
      },
    );

This is the simplest option, it just injects a method that will call the named view and pass
any arguments from the method but does not add any global arguments.

=item An arrayref

    __PACKAGE__->config(
      content_type=>'text/html', 
      status_codes=>[200,404,400],
      views=>+{
        layout => [ Layout => (title=>'Yeah!') ],
      },
    );

This option allows you to set some argument defaults to the view called.  The first item in the
arrayref must be the real name of the view, followed by arguments which are merged with any provided
to the method.

=item A coderef

    __PACKAGE__->config(
      content_type=>'text/html', 
      status_codes=>[200,404,400],
      views=>+{
        layout => [ Layout => sub { my ($self, $c) = @_; return title=>'Hey!' } ],
      },
    );

The most complex option, you should probably reserve for very special needs.  Basically this coderef
will be called with the current view instance and Catalyst context; it should return arguments which
with then be merged and treated as in the arrayref option.

=back

Now you can call for the sub view via a simple method call on the view, rather than via the context:

    package Example::View::Hello;

    use Moose;

    extends 'Catalyst::View::BasePerRequest';

    has name => (is=>'ro', required=>1);
    has age => (is=>'ro', required=>1);


    sub render {
      my ($self, $c) = @_;

      return $self->layout(title=>'Hello!', sub {
        my $layout = shift;
        return "Hello @{[$self->name]}; you are @{[$self->age]} years old!";  
      });
    }


    __PACKAGE__->config(
      content_type=>'text/html', 
      status_codes=>[200,404,400],
      views=>+{
        layout => 'Layout',
      },
    );

    __PACKAGE__->meta->make_immutable;


=head1 RESPONSE HELPERS

When you create a view instance the actual response is not send to the client until
the L</respond> method is called (either directly, via L</process> or thru the generated
response helpers).

Response helpers are just methods that call L</respond> with the correct status code
and using a more easy to remember name (and possibly a more self documenting one).

For example:

    $c->view('Login')->http_ok;

calls the L</respond> method with the expected http status code.  You can also pass
arguments to the response helper which are send to L</respond> and used to add HTTP
headers to the response.

    $c->view("NewUser")
      ->http_created(location=>$url);

Please note that calling a response helper only sets up the response object, it doesn't
stop any future actions in you controller.   If you really want to stop action processing
you'll need to call L</detach>:

    return $c->view("Error")
      ->http_bad_request
      ->detach;

If you don't want to generate the response yet (perhaps you'll leave that to a global 'end'
action) you can use the 'set_http_$STATUS' helpers instead which wil just set the response
status.

    return $c->view("Error")
      ->set_http_bad_request
      ->detach;

Response helpers are just lowercased names you'll find for the codes listed in L<HTTP::Status>.
Some of the most common ones I find in my code:

    http_ok
    http_created
    http_bad_request
    http_unauthorized
    http_not_found
    http_internal_server_error

By default we create response helpers for all the status codes in L<HTTP::Status>.  However
if you set the C<status_codes> configuration key (see L</status_codes>) you can limit the
generated helpers to specific codes.  This can be useful since most views are only meaningful
with a limited set of response codes.

=head1 APPLICATION CONTEXT

Generally views using this will need to be called in request context (that is with 
a L<Catalyst> context, or C<'$c'>).  However if you call the view in application context
you will get the underlying factory object. Useful if you need access to any complex
constructs built at startup.

If none of this makes sense to you, you don't need to worry about it.  It's advanced
edge case stuff.   Added because I found a use case around view inheritance.

=head1 RUNTIME HOOKS
 
This class defines the following method hooks you may optionally defined in your
view subclass in order to control or otherwise influence how the view works.
 
=head2 $class->modify_init_args($app, $args)
 
Runs when C<COMPONENT> is called during C<setup_components>.  This gets a reference
to the merged arguments from all configuration.  You should return this reference
after modification.

This is for modifying or adding arguments that are application scoped rather than context
scoped.  

=head2 prepare_build_args

This method will be called (if defined) by the factory class during build time.  It can be used
to inject args and modify args.   It gets the context and C<@args> as arguments and should return
all the arguments you want to pass to C<new>.  Example:

    sub prepare_build_args {
      my ($class, $c, @args) = @_;
      # Mess with @args
      return @args;
    }

=head2 build

Receives the initialization hash and should return a new instance of the the view.  By default this
just calls C<new> on the class with the hash of args but if you need to call some other method or
have some complex initialization work that can't be handled with L</prepare_build_args> you can
override.

=head1 CONFIGURATION
 
This Catalyst Component supports the following configuation.
 
=head2 content_type

The HTTP content type of the response.   For example 'text/html'. Required.

=head2 status_codes
 
An ArrayRef of HTTP status codes used to provide response helpers.  This is optional
but it allows you to specify the permitted HTTP response codes that a template can
generate.  for example a NotFound view probably makes no sense to return anything
other than a 404 Not Found code.

=head2 lifecycle

By default your view lifecycle is 'per request' which means we only build it one during the entire
request cycle.  This is handled by the lifecycle module L<Catalyst::View::BasePerRequest::Lifecycle::Request>.
However sometimes you would like your view to be build newly each you you request it.  For example
you might have a view called from inside a loop, passing it different arguments each time.  In that
case you want the 'Factory' lifecycle, which is handled by L<Catalyst::View::BasePerRequest::Lifecycle::Factory>.
In order to do that set this configuration value to 'Factory'.  For example

    __PACKAGE__->config(
      content_type => 'text/html', 
      status_codes => [200,201,400],
      lifecycle => 'Factory',
    );

You can create your own lifecycle classes, but that's very advanced so for now if you
want to do that you should review the source of the existing ones.  F<D-d>or example you might
create a view with a 'session' lifecycle, which returns the same view as long as the user
is logged in.

=head1 ALSO SEE
 
L<Catalyst>

=head1 AUTHORS & COPYRIGHT
 
John Napiorkowski L<email:jjnapiork@cpan.org>
 
=head1 LICENSE
 
Copyright 2023, John Napiorkowski  L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=cut
