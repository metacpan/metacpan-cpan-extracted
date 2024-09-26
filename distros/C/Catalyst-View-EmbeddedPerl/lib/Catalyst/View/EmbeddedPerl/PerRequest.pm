package Catalyst::View::EmbeddedPerl::PerRequest;

use Moose;
use String::CamelCase;
use Template::EmbeddedPerl;

extends 'Catalyst::View::BasePerRequest';

# Args that get passed cleanly to Template::EmbeddedPerl
my @temple_args = qw(
  open_tag close_tag expr_marker line_start  
  template_extension auto_flatten_expr prepend
  use_cache auto_escape);

# methods we proxy from the temple object
my @proxy_methods = qw(
  raw safe safe_concat html_escape url_encode 
  escape_javascript uri_escape trim mtrim);

has _temple => (is=>'ro', required=>1, handles=>\@proxy_methods); # The underlying temple object
has _doc => (is=>'ro', required=>1); # The underlying parsed template object

sub modify_init_args {
  my ($class, $app, $merged_args) = @_;

  # First pull out all the args we are sending to Template::EmbeddedPerl a.k.a. 'Temple'
  my %temple_args = ();
  foreach my $temple_arg (@temple_args) {
    $temple_args{$temple_arg} = delete($merged_args->{$temple_arg})
      if exists($merged_args->{$temple_arg});
  };

  # Next update template args to have the correct namespace, etc.
  %temple_args = $class->modify_temple_args($app, %temple_args);

  # Finally, build the temple object
  my ($temple, $doc) = $class->build_temple($app, %temple_args);
  $merged_args->{_temple} = $temple;
  $merged_args->{_doc} = $doc;

  # Build the helpers hash by merging all the possible sourcess
  my %helpers = $class->build_helpers(delete $merged_args->{helpers} || +{});
  $class->inject_helpers($temple->{sandbox_ns}, %helpers);
  # Return the merged args
  return $merged_args;
}

#   

# This sets defaults to template args that can't really change without breaking everything
sub modify_temple_args {
  my ($class, $app, %temple_args) = @_;
  $temple_args{preamble} ||= 'sub __SELF {  };' . ($temple_args{preamble}||'');
  $temple_args{prepend} = $class->prepare_prepend_arg($app, $temple_args{prepend});
  $temple_args{sandbox_ns} ||= "${class}::EmbeddedPerl::SandBox";
  $temple_args{template_extension} = 'epl' unless $temple_args{template_extension};
  return %temple_args;
}

sub prepare_prepend_arg {
  my ($class, $app, $prepend) = @_;
  return 'my ($self, $c, $content) = @_;' . ($prepend||'');
}

sub build_temple {
  my ($class, $app, %temple_args) = @_;
  my ($data, $path) = $class->find_template($app, $temple_args{template_extension});
  $temple_args{source} = $path;

  my $temple = Template::EmbeddedPerl->new(%temple_args);
  my $compiled = $temple->from_string($data);

  return ($temple, $compiled);
}

sub find_template {
  my ($class, $app, $template_extension) = @_;

  # Ok so first check __DATA__ for the template
  my $data_fh = do { no warnings 'once'; no strict 'refs'; *{"${class}::DATA"}{IO} };
  if (defined $data_fh) {
    my $data = do { local $/; <$data_fh> };
    close($data_fh);
    if($data) {
      my $package_file = $class;
      $package_file =~ s/::/\//g;
      my $path = $INC{"${package_file}.pm"};
      return ($data, "${path}/DATA");
    }
  }

  # ...and if its not there look for a file based on the class name
  return $class->template_from_filesystem($app, $template_extension);
}

sub template_from_filesystem {
  my ($class, $app, $template_extension) = @_;
  my $template_path = $class->get_path_to_template($app, $template_extension);
  open(my $fh, '<', $template_path)
    || die "can't open '$template_path': $@";
  local $/; my $slurped = $fh->getline;
  close($fh);
  return ($slurped, $template_path);
}

sub get_path_to_template {
  my ($class, $app, $template_extension) = @_;
  my @parts = split("::", $class);
  my $filename = (pop @parts);
  $filename = String::CamelCase::decamelize($filename);
  my $path = "$class.pm";
  $path =~s/::/\//g;
  my $inc = $INC{$path};
  my $base = $inc;
  $base =~s/$path$//g;
  my $template_path = File::Spec->catfile($base, @parts, $filename);
  $template_path .= ".$template_extension" if $template_extension;
  $app->log->debug("Looking for template at: $template_path") if $app->debug;
  return $template_path;
}

# helpers

sub build_helpers {
  my ($class, $init_arg_helpers) = @_;

  # Gather helpers from all the places we can
  my %helpers = (
    $class->default_helpers,
    %$init_arg_helpers,
    ($class->can('helpers') ? $class->helpers() : ())
  );
  return %helpers;
}

sub default_helpers {
  my $class = shift;
  return (
    view  => sub { my ($self, $c, @args) = @_; return $self->view(@args); },
    content => sub { my ($self, $c, @args) = @_; return $self->content(@args); },
    content_for => sub { my ($self, $c, @args) = @_; return $self->content_for(@args); },
    content_append => sub { my ($self, $c, @args) = @_; return $self->content_append(@args); },
    content_prepend => sub { my ($self, $c, @args) = @_; return $self->content_prepend(@args); },
    content_replace => sub { my ($self, $c, @args) = @_; return $self->content_replace(@args); },
  );
}

sub inject_helpers {
  my ($class, $sandbox_ns, %helpers) = @_;
  foreach my $helper(keys %helpers) {
    if($sandbox_ns->can($helper)) {
      warn "Skipping injection of helper '$helper'; already exists in namespace $sandbox_ns" 
        if $ENV{DEBUG_TEMPLATE_EMBEDDED_PERL};
      next;
    }
    eval qq[
      package $sandbox_ns;
      sub $helper { \$helpers{'$helper'}->(__SELF, __SELF->ctx, \@_) }
    ]; die "Can't inject helpers: $@" if $@;
  }
}

sub render {
  my ($self, $c, @args) = @_;
  $c->log->debug("Rendering Template: @{[ ref $self ]}") if $c->debug;

  my $rendered = eval {
    $self->render_template($c, @args);
  } || do {
    my $error = $@;
    $c->log->error("Error processing template: $error");
    $c->log->debug($error) if $c->debug;
    return $error;
  };

  $c->log->debug("Template @{[ ref $self ]} successfully rendered") if $c->debug;    

  return $rendered;
}

sub render_template {
  my ($self, $c, @args) = @_;
  my $ns = $self->_temple->{sandbox_ns};

  no strict 'refs';
  no warnings 'redefine';
  local *{"${ns}::__SELF"} = sub { $self };

  return my $page = $self->_doc->render($self, $c, @args);
}

sub read_attribute_for_html {
  my ($self, $attribute) = @_;
  return unless defined $attribute;
  return my $value = $self->$attribute if $self->can($attribute);
  die "No such attribute '$attribute' for view"; 
}

sub attribute_exists_for_html {
  my ($self, $attribute) = @_;
  return unless defined $attribute;
  return 1 if $self->can($attribute);
  return;
}

sub view {
  my ($self, $view, @args) = @_;
  return $self->ctx->view($view, @args)->get_rendered;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Catalyst::View::EmbeddedPerl::PerRequest - Per-request embedded Perl view for Catalyst

=head1 SYNOPSIS

Declare a view in your Catalyst application:

  package Example::View::HelloName;

  use Moose;
  extends 'Catalyst::View::EmbeddedPerl::PerRequest';

  has 'name' => (is => 'ro', isa => 'Str');

  __PACKAGE__->meta->make_immutable;
  __DATA__
  <p>Hello <%= $self->name %></p>

You can also use a standalone text file as a template.  This text file
will be located in the same directory as the view module and will have
a 'snake case' version of the view module name with a '.epl' extension.

  # In hello_name.epl
  <p>Hello <%= $self->name %>!</p>

In your Catalyst controller:

  sub some_action :Path('/some/path') ($self, $c) {
    # Create the view and render it as a 200 OK response
    $c->view('HelloName', name => 'Perl Hacker')->http_ok;
  }

Produces the following output:

  <p>Hello Perl Hacker!</p>

=head1 DESCRIPTION

C<Catalyst::View::EmbeddedPerl::PerRequest> is a per-request view for the L<Catalyst> 
framework that uses L<Template::EmbeddedPerl> to process templates containing embedded 
Perl code. It allows for dynamic content generation with embedded Perl expressions 
within your templates.

Since it uses 'just Perl' for the template language, it is very flexible and powerful
(maybe too much so, if you lack self control...) and has the upside that any Perl
programmer will be able to understand and work with it without learning a new language.
Anyone that's worked with similar systems like L<Mason> or L<Mojo::Template> will with
a bit of reorientation be quickly productive, but I suspect most Perl programmers will
pick up the syntax quickly even if they've never seen it before.  These templates are
not my favorite type of approach but they have the massive upside of not something you
need to learn to use, so a type of least common denominator.  This is great for Perl
only shops, for small projects where you don't want a complex stack and of course for
demo applications and presentations to other Perl programmers.  That's not to say you
can't use it for larger projects, but you should be aware of the tradeoffs here.  By
exposing Perl in the template it's very easy to write code that is hard to maintain
and a bit messy and also its easy to stick too much business logic in the template.
You should exercise self control and have strong code review conventions.

You should read the (short) documentation for L<Template::EmbeddedPerl> to understand
the syntax and features of the template language.  These docs will focus on the how
to use this view in a Catalyst application.

This view is a subclass of L<Catalyst::View::BasePerRequest> and is designed to be
used in a per-request context. You may wish to read the documentation for that class
to get a better understanding of what a 'per-request' view is and how it differs from
views like L<Catalyst::View::TT> or L<Catalyst::View::Mason> which you may already be
familiar with.  The topic will be covered here in brief.

=head1 PER-REQUEST VIEWS

A per-request view is a view that is created and destroyed for each request. This is
in contrast to a 'per-application' view which is created once when the application is
started and shared across all requests.  This means you can have a view that contains
state that is specific to a single request, has access to the C<$c> context for that
request and you can write display logic methods that are specific to that request.  You 
can also gave object attributes that define the view interface.  Unlike other commonly used
view like L<Catalyst::View::TT> you can't use the stash to pass data to the view, you
must pass it as arguments when you create the view.  This creates a strongly typed
view, which has an explicit interface leading to fewer bug and easier to understand
code.  It also means you can't use the stash to pass data to the view, which is a
common pattern in Catalyst applications but is one I have found to be a source of
confusion and bugs in many applications.  When using per request views you will write a
view model for each template, which you might find strange at first, and of course its 
extra work, but over time I think you will have a much more sustainable, maintainable
application.  Review the documentation, test cases and example applications and decide
for yourself.

=head1 HTML ESCAPING

By default the view will escape all output to prevent cross site scripting attacks.
If you want to output raw HTML you can use the C<raw> helper.  For example:

  <%= raw $self->html %>

See L<Template::EmbeddedPerl::SafeString> for more information.

You can disable this feature by setting the C<auto_escape> option to false in the
view configuration.  For example if you are not using this to generate HTML output
you might not want it.

=head1 METHODS

This class provides the following methods for public use:

=head2 render

  $output = $view->render($c, @args);

Renders the currently created template to a string, passing addional arguments if needed

=head2 view

  $output = $self->view($view_name, @args);

Renders another view and returns its content. Useful for including the output of one 
template within another or using another template as a layout or wrapper.

=head1 INHERITED METHODS

This class inherits all methods from L<Catalyst::View::BasePerRequest> but the following
are public and considered useful:

=head2 Content Block Helpers

Used to capture blocks of template.  SEE:

L<Catalyst::View::BasePerRequest/content>, L<Catalyst::View::BasePerRequest/content_for>,
L<Catalyst::View::BasePerRequest/content_append>, L<Catalyst::View::BasePerRequest/content_prepend>,
L<Catalyst::View::BasePerRequest/content_replace>.

=head2 Response Helpers

Used to set up the response object.  SEE: L<Catalyst::View::BasePerRequest/RESPONSE-HELPERS>
Example:

  $c->view('HelloName', name => 'Perl Hacker')->http_ok;

=head2 process
  
  $view->process($c, @args);

Renders a view and sets up the response object. Generally this is called from a
controller via the forward method and not directly:

  $c->forward($view, @args);

See L<Catalyst::View::BasePerRequest/process> for more information.

=head2 respond

  $view->respond($status, $headers, @args);

See L<Catalyst::View::BasePerRequest/respond> for more information.

=head2 detach

See L<Catalyst::View::BasePerRequest/detach> for more information.

=head1 METHODS PROXIED FROM L<Template::EmbeddedPerl>

This class proxies the following methods from L<Template::EmbeddedPerl>:

  raw safe safe_concat html_escape url_encode
  escape_javascript uri_escape trim mtrim

See L<Template::EmbeddedPerl/HELPER-FUNCTIONS> (these are available as template
helpers and as methods on the view object).

=head1 CONFIGURATION

You can configure the view in your Catalyst application by passing options either in your
application configuration or when setting up the view.

Example configuration in your Catalyst application.   

  # In MyApp.pm or myapp.conf
  __PACKAGE__->config(
      'View::EmbeddedPerl' => {
          template_extension => 'epl',
          open_tag           => '<%',
          close_tag          => '%>',
          expr_marker        => '=',
          line_start         => '%',
          auto_flatten_expr  => 1,
          use_cache          => 1,
          helpers            => {
              helper_name => sub { ... },
          },
      },
  );

The following configuration options are passed thru to L<Template::EmbeddedPerl>:

  open_tag close_tag expr_marker line_start  
  template_extension auto_flatten_expr prepend
  use_cache auto_escape

=head1 HELPERS

You can define custom helper functions that are available within your templates. 
Helpers can be defined in the configuration under the C<helpers> key.

Example:

  __PACKAGE__->config(
      'View::EmbeddedPerl' => {
          helpers => {
              format_date => sub {
                  my ($self, $c, $date) = @_;
                  return $date->strftime('%Y-%m-%d');
              },
          },
      },
  );

In your template:

  <%== format_date($data->{date}) %>

You can also define helpers in your view module by defining a C<helpers> method 
that returns a list of helper functions.  You may prefer this option
if you are creating a single base class for all your views, with shared features.

Example:

  sub helpers {
    my ($class) = @_;
    return (
      format_date => sub {
        my ($self, $c, $date) = @_;
        return $date->strftime('%Y-%m-%d');
      },
   );
  }

=head1 DEFAULT HELPERS

The following default helpers are available in all templates, in addition to
helpers that are default in L<Template::EmbeddedPerl> itself (see 
L<Template::EmbeddedPerl/HELPER-FUNCTIONS> for more information):

B<Note:> Just to be clear, you don't have to write a helper for every method you
want to call in your template.  You always get C<$self> and C<$c> in your template
so you can call methods on the view object and the context object directly.  Personally
my choice is to have helpers for things that are in my base view which are shared across
all views and then call $self for things that are specific to the view.  This makes it
easier for people to debug and understand the code IMHO.  

=over 4

=item * C<view($view_name, @args)>

Renders another view and returns its content. Useful for including the output of one

=item * C<content($name, $content)>

Captures a block of content for later use.

=item * C<content_for($name, $content)>

Captures a block of content for later use, appending to any existing content.

=item * C<content_append($name, $content)>

Appends content to a previously captured block.

=item * C<content_prepend($name, $content)>

Prepends content to a previously captured block.

=item * C<content_replace($name, $content)>

Replaces a previously captured block with new content.

=back

=head1 TEMPLATE LOCATIONS

Templates are searched in the following order:

=over 4

=item 1. C<__DATA__> section of the view module.

If your view module has a C<__DATA__> section, the template will be read from there.

=item 2. File system based on the view's class name.

If not found in C<__DATA__>, the template file is looked up in the file system, 
following the view's class name path.  The file will be a 'snake case' version of
the view module name with a '.epl' extension.

=back

=head1 COOKBOOK

Some ideas about how to use this view well

=head2 Avoid complex logic in the view

Instead of putting complex logic in the view, you can define a method on the
view which accepts a callback to render the content.  This way you can keep
the logic in the controller or model where it belongs.

  package MyApp::View::MyView;

  use Moose
  extends 'Catalyst::View::EmbeddedPerl::PerRequest';

  has 'person' => (is => 'ro', required => 1);

  sub person_data {
    my ($self, $content_cb) = @_;
    my $content = $content_cb->($self->person->name, $self->person->age);
    return "....@{[ $self->trim($content_cb->()) ]}....";
  }

  __PACKAGE__->meta->make_immutable;

In your template:

  %# Person info
  <%= $self->person_data(sub($name, $age) {
    <p>Name: <%= $name %></p>
    <p>Age: <%= $age %></p>
  }) %>

=head2 Use a base view class

If you have a lot of views that share common features, you can create a base view
class that contains those features.  This way you can avoid repeating yourself
and keep your code DRY.

  package MyApp::View;

  use Moose;
  extends 'Catalyst::View::EmbeddedPerl::PerRequest';

  sub helpers {
    my ($class) = @_;
    return (
      format_date => sub {
        my ($self, $c, $date) = @_;
        return $date->strftime('%Y-%m-%d');
      },
    );
  }

  # Other shared view features such as methods, attributes, etc.

  __PACKAGE__->meta->make_immutable;

In your view modules:

  package MyApp::View::MyView;

  use Moose;
  extends 'MyApp::View';

  __PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

=over 4

=item * L<Catalyst>

The Catalyst web framework.

=item * L<Catalyst::View::BasePerRequest>

The base class for per-request views in Catalyst.

=item * L<Template::EmbeddedPerl>

Module used for processing embedded Perl templates.

=item * L<Moose>

A postmodern object system for Perl 5.

=back

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
