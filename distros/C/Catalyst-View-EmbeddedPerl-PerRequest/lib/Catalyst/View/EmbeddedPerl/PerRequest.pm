package Catalyst::View::EmbeddedPerl::PerRequest;

use Moose;
use String::CamelCase;
use Template::EmbeddedPerl;
use Moose::Util::MetaRole;
use Scalar::Util;
use Catalyst::View::EmbeddedPerl::PerRequest::EachInfo;
use Catalyst::View::EmbeddedPerl::PerRequest::TagUtils;
use MooseX::Attribute::Catalyst::View::EmbeddedPerl::ExportedAttribute;

Moose::Util::MetaRole::apply_metaroles(
  for => __PACKAGE__,
  class_metaroles => {
    attribute  => ['MooseX::Attribute::Catalyst::View::EmbeddedPerl::ExportedAttribute'],
  },
);

extends 'Catalyst::View::BasePerRequest';

our $VERSION = 0.001021;
eval $VERSION;

# Args that get passed cleanly to Template::EmbeddedPerl
my @temple_args = qw(
  open_tag close_tag expr_marker line_start  
  template_extension auto_flatten_expr prepend
  use_cache auto_escape interpolation);

# methods we proxy from the temple object
my @proxy_methods = qw(
  raw safe safe_concat html_escape url_encode 
  escape_javascript uri_escape trim mtrim);

has _temple => (is=>'ro', required=>1, handles=>\@proxy_methods); # The underlying temple object
has _doc => (is=>'ro', required=>1); # The underlying parsed template object
has _parent_views => (is=>'ro', required=>1); # All parent classes that inherit from Catalyst::View::EmbeddedPerl::PerRequest
has _exported_attributes => (is=>'ro', required=>1); # All attributes that are exported to the template
has _tag_utils => (is=>'ro', lazy_build=>1); # Tag utility object

sub _build__tag_utils {
  return Catalyst::View::EmbeddedPerl::PerRequest::TagUtils->new(shift);
}

sub modify_init_args {
  my ($class, $app, $merged_args) = @_;

  ## Get All parent objects that inherit from Catalyst::View::EMbeddedPerl::PerRequest 
  ## except for the current object and Catalyst::View::EmbeddedPerl::PerRequest itself

  my @parent_views = grep {
    $_->isa('Catalyst::View::EmbeddedPerl::PerRequest')
    && $_ ne $class
    && $_ ne 'Catalyst::View::EmbeddedPerl::PerRequest'
  } $class->meta->linearized_isa;

  $merged_args->{_parent_views} = \@parent_views;

  # Find all the attributes that have a 'export' flag via the meta object
  my @exported_attributes =
    map { $_->name  } 
    grep {
      $_->can('exported_to_template') && $_->exported_to_template
    } $class->meta->get_all_attributes;

  $merged_args->{_exported_attributes} = \@exported_attributes;

  # First pull out all the args we are sending to Template::EmbeddedPerl a.k.a. 'Temple'
  my %temple_args = ();
  foreach my $temple_arg (@temple_args) {
    $temple_args{$temple_arg} = delete($merged_args->{$temple_arg})
      if exists($merged_args->{$temple_arg});
  };

  # Next update template args to have the correct namespace, etc.
  %temple_args = $class->modify_temple_args($app, %temple_args);

  foreach my $exported_attr (@exported_attributes) {
    $temple_args{prepend} .= ";my \$$exported_attr = \$self->$exported_attr; ";
  }

  # Finally, build the temple object
  my ($temple, $doc) = $class->build_temple($app, $merged_args->{_parent_views}, %temple_args);
  $merged_args->{_temple} = $temple;
  $merged_args->{_doc} = $doc;

  # Build the helpers hash by merging all the possible sourcess
  my %helpers = $class->build_helpers(delete $merged_args->{helpers} || +{});
  $class->inject_helpers($temple->{sandbox_ns}, %helpers);
  # Return the merged args
  return $merged_args;
} 

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
  my ($class, $app, $parent_views, %temple_args) = @_;
  my ($data, $path) = $class->find_template($app, $temple_args{template_extension});
  $temple_args{source} = $path;

  my $temple = Template::EmbeddedPerl->new(%temple_args);
  my $compiled = $temple->from_string($data);

  my @parent_compiled = ();
  foreach my $parent_class (@$parent_views) {
    my ($parent_template, $ppath) = $parent_class->find_template($app, $temple_args{template_extension});
    my %parent_temple_args = (
      %temple_args,
      source => $ppath,
      preamble => '',
      sandbox_ns => "${parent_class}::EmbeddedPerl::SandBox",
    );
    my $parent_temple = Template::EmbeddedPerl->new(%parent_temple_args);
    my $parent_compiled = $parent_temple->from_string($parent_template);   
    push @parent_compiled, $parent_compiled;
  }
  return ($temple, [$compiled, @parent_compiled]);
}

my %cached_templates = ();
sub find_template {
  my ($class, $app, $template_extension) = @_;

  # Ok so first check __DATA__ for the template
  my $data_fh = do { no warnings 'once'; no strict 'refs'; *{"${class}::DATA"}{IO} };
  if (defined $data_fh) {
    return @{$cached_templates{$class}} if exists $cached_templates{$class};
    my $data = do { local $/; <$data_fh> };
    close($data_fh);
    if($data) {
      my $package_file = $class;
      $package_file =~ s/::/\//g;
      my $path = $INC{"${package_file}.pm"};
      $cached_templates{$class} = [$data, "${path}/DATA"];
      return ($data, "${path}/DATA");
    }
  }

  # ...and if its not there look for a file based on the class name
  my ($template, $path) = $class->template_from_filesystem($app, $template_extension);
  return ($template, $path) if $template;
  return ($class->_default_template, 'default');
}

sub _default_template {
  my ($class) = @_;
  return $class->default_template if $class->can('default_template'); 
  return '<%= $content %>';
}

sub template_from_filesystem {
  my ($class, $app, $template_extension) = @_;
  my $template_path = $class->get_path_to_template($app, $template_extension);
  return unless -e $template_path;
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

  # Using meta, get all the methods with the Helper attribute
  my @helper_methods = grep {
    $_->can('attributes') && (grep { $_ eq 'Helper' } @{$_->attributes})
  } $class->meta->get_all_methods;

  foreach my $helper_method (@helper_methods) {
    my $helper_name = $helper_method->name;
    $helpers{$helper_name} = sub {
      my ($self, $c, @args) = @_;
      return $self->$helper_name(@args);
    };
  }

  return %helpers;
}

sub push_style {
  my ($self, @args) = @_;
  my $cb = pop @args;
  my $name = shift @args; # optional

  if($name) {
    return if $self->ctx->stash->{view_blocks}{'css'}{$name};
    $self->ctx->stash->{view_blocks}{'css'}{$name} = 1;
  }

  if(exists $self->ctx->stash->{view_blocks}{'css'}) {
    $self->content_append('css', $cb);
  } else {
    $self->content_for('css', $cb);
  }
  return;
}

sub get_styles {
  my $self = shift;
  my $css = $self->content('css');
  return '' unless $css;
  return $self->raw("<style>\n$css\n</style>");
}

sub push_script {
  my ($self, @args) = @_;
  my $cb = pop @args;
  my $name = shift @args; # optional

  if($name) {
    return if $self->ctx->stash->{view_blocks}{'js'}{$name};
    $self->ctx->stash->{view_blocks}{'js'}{$name} = 1;
  }

  if(exists $self->ctx->stash->{view_blocks}{'js'}) {
    $self->content_append('js', $cb);
  } else {
    $self->content_for('js', $cb);
  }
  return;
}

sub get_scripts {
  my $self = shift;
  my $js = $self->content('js');
  return '' unless $js;
  return $self->raw("<script>\n$js\n</script>");
}

sub _over_length {
  my ($self, $arg) = @_;
  return $arg->length if $arg->can('length');
  return $arg->size if $arg->can('size');
  return $arg->count if $arg->can('count');
  return undef;
}

sub over {
  my ($self, @args) = @_;
  my $cb = pop @args; # The callback block is always the last argument

  my $iterator;
  my $length;
  if(scalar(@args) == 1) {
    my $arg = $args[0];
    if(ref($arg) eq 'ARRAY') {  # []
      $length = scalar(@$arg);
      $iterator = sub { return shift @{$arg} };
    } elsif(ref($arg) eq 'CODE') {  # \&cb->()
      $iterator = $arg;
    } elsif(Scalar::Util::blessed($arg) && $arg->can('next')) {  # $obj->next
      $iterator = sub { return $arg->next };
      $length = $self->_over_length($arg);
    } elsif((ref(\$arg)||'') eq 'SCALAR') { # A single value (string or number, or undef)
      $iterator = sub { return shift @args };
      $length = 1;
    } elsif((ref($arg)||'') eq 'HASH') { # A single value (hash)
      $iterator = sub { return shift @args };
      $length = 1;
    } elsif(Scalar::Util::blessed($arg)) { # A single value (object)
      $iterator = sub { return shift @args };
      $length = 1;
    } else {
      die "Invalid argument to over";
    }
  } else {
    $iterator = sub { return shift @args }; # each(#arry, sub { ... })
    $length = scalar(@args);
  }


  my $content = $self->raw('');
  my $current_count = 1;
  while(my $item = $iterator->()) {
    my $inf = Catalyst::View::EmbeddedPerl::PerRequest::EachInfo->new($current_count, $length);
    $content = $self->safe_concat($content,$cb->($item, $inf));
    $current_count++;
  }
  return $content;
}

sub attr {
  my ($self, $attribute, $value) = @_;
  return $self->_tag_utils->_tag_options($attribute => $value);
}

sub style {
  my ($self, $style) = @_;
  return $self->attr('style', $style);
}

sub class {
  my ($self, $class) = @_;
  return $self->attr('class', $class);
}

sub checked {
  my ($self, $checked) = @_;
  return $self->attr('checked', 'checked') if $checked;
  return '';
}

sub selected {
  my ($self, $selected) = @_;
  return $self->attr('selected', 'selected') if $selected;
  return '';
}

sub disabled {
  my ($self, $disabled) = @_;
  return $self->attr('disabled', 'disabled') if $disabled;
  return '';
}

sub readonly {
  my ($self, $readonly) = @_;
  return $self->attr('readonly', 'readonly') if $readonly;
  return '';
}

sub required {
  my ($self, $required) = @_;
  return $self->attr('required', 'required') if $required;
  return '';
}

sub href {
  my ($self, @href_parts) = @_;
  my $href = $self->safe_concat(@href_parts);
  return $self->attr('href', $href);
}

sub src {
  my ($self, @src_parts) = @_;
  my $src = $self->safe_concat(@src_parts);
  return $self->attr('src', $src);
}

sub data {
  my ($self, $data) = @_;
  return $self->attr('data', $data);
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
    content_around => sub { my ($self, $c, @args) = @_; return $self->content_around(@args); },
    push_style => sub { my ($self, $c, @args) = @_; return $self->push_style(@args); },
    get_styles => sub { my ($self, $c, @args) = @_; return $self->get_styles(@args); },
    push_script => sub { my ($self, $c, @args) = @_; return $self->push_script(@args); },
    get_scripts => sub { my ($self, $c, @args) = @_; return $self->get_scripts(@args); },
    over => sub { my ($self, $c, @args) = @_; return $self->over(@args); },
    attr => sub { my ($self, $c, @args) = @_; return $self->attr(@args); },
    style => sub { my ($self, $c, @args) = @_; return $self->style(@args); },
    class => sub { my ($self, $c, @args) = @_; return $self->class(@args); },
    checked => sub { my ($self, $c, @args) = @_; return $self->checked(@args); },
    selected => sub { my ($self, $c, @args) = @_; return $self->selected(@args); },
    disabled => sub { my ($self, $c, @args) = @_; return $self->disabled(@args); },
    readonly => sub { my ($self, $c, @args) = @_; return $self->readonly(@args); },
    required => sub { my ($self, $c, @args) = @_; return $self->required(@args); },
    href => sub { my ($self, $c, @args) = @_; return $self->href(@args); },
    src => sub { my ($self, $c, @args) = @_; return $self->src(@args); },
    data => sub { my ($self, $c, @args) = @_; return $self->data(@args); },
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

  my $rendered_template = '';
  my @docs = @{$self->_doc};
  foreach my $doc (@docs) {
    my $ns = $doc->{yat}->{sandbox_ns}; 
    no strict 'refs';
    no warnings 'redefine';
    local *{"${ns}::__SELF"} = sub { $self };

    $rendered_template = $doc->render($self, $c, @args);
    $rendered_template = $self->_temple->{auto_escape}
      ? $self->raw($rendered_template)
      : $rendered_template;

    @args = ($rendered_template);
  }

  return $rendered_template;
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

  # If the $view is a part string like ::Foo, then convert it to a full class name
  # by prepending the namespace of the current view.  For example if the current view
  # is Example::View::Bar::Baz and the $view is ::Foo then the full class name will
  # be Example::View::Bar::Foo.  This is useful for including views that are in the
  # same namespace as the current view.
  if($view =~ m/^::/) {
    my $current_view = ref $self;
    # chop off the last part of the namespace
    $current_view =~ s/::[^:]+$//;
    # chop off everything from the start to 'View::'
    $current_view =~ s/.*View:://;
    $self->ctx->log->debug("Resolving view: $view to ${current_view}${view}") if $self->ctx->debug;
    $view = $current_view . $view;
  }

  my $response = $self->ctx->view($view, @args)->get_rendered;

  ## If temple is auto escape, we need to mark the string as safe
  ## so that embedded views properly escape the content.  This is ok
  ## because the temple object will escape the content when it renders

  $response = $self->_temple->{auto_escape}
    ? $self->raw($response)
    : $response;

  return $response;
}

# Rendered is always a string, never an array so no need to flatten
around 'flatten_rendered' => sub {
  my ($orig, $self, @args) = @_;
  return $args[0] if scalar(@args) == 1;
  return $self->safe_concat(@args);
};

__PACKAGE__->meta->make_immutable;

=head1 NAME

Catalyst::View::EmbeddedPerl::PerRequest - Per-request embedded Perl view for Catalyst

=head1 SYNOPSIS

Declare a view in your Catalyst application:

  package Example::View::HelloName;

  use Moose;
  extends 'Catalyst::View::EmbeddedPerl::PerRequest';

  has 'name' => (is => 'ro', isa => 'Str', export=>1);

  sub title :Helper { 'Hello Title' }

  __PACKAGE__->meta->make_immutable;
  __DATA__
  <title><%= title() %></title>
  <p>Hello <%= $name %></p>

You can also use a standalone text file as a template.  This text file
will be located in the same directory as the view module and will have
a 'snake case' version of the view module name with a '.epl' extension.

  # In hello_name.epl
  <title><%= title() %></title>
  <p>Hello <%= $name %></p>

In your Catalyst controller:

  sub some_action :Path('/some/path') ($self, $c) {
    # Create the view and render it as a 200 OK response
    $c->view('HelloName', name => 'Perl Hacker')->http_ok;
  }

Produces the following output:

  <title>Hello Title</title>
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

By default this view does not automatically escape HTML output.  If you are using this
view to generate HTML output you should be aware of the security implications of this.
You either need to explicitly escape all output or use the C<auto_escape> option to
enable automatic escaping.   The latter is the recommended approach.  Example:

  package Example::View::Escape;

  use Moose;
  extends 'Catalyst::View::EmbeddedPerl::PerRequest';

  __PACKAGE__->config(auto_escape => 1);

If C<auto_escape> is enabled and you want to output raw HTML you can use the
C<raw> helper.  For example:

  <%= raw $self->html %>

See L<Template::EmbeddedPerl::SafeString> for more information.

If for some reason you don't want to use the C<auto_escape> feature you can use the
C<html_escape> helper to escape HTML output.  For example:

  <%= html_escape($self->html) %>

Or use the C<safe> helper to mark a string as safe.  For example:

  <%= safe($self->html) %>

The C<safe> helper is preferred because it won't double escape content that is already
escaped whereas the C<html_escape> helper will.

Unless you are writing text output or javascript that has special encoding needs you
really should use the C<auto_escape> feature.

=head1 METHODS

This class provides the following methods for public use:

=head2 render

  $output = $view->render($c, @args);

Renders the currently created template to a string, passing addional arguments if needed

=head2 view

  $output = $self->view($view_name, @args);

Renders another view and returns its content. Useful for including the output of one 
template within another or using another template as a layout or wrapper.

$view_name is the name of the view to render.  If the view name starts with '::' then
it is assumed to be a relative view name and the namespace of the current view is prepended
to it.  This is useful for including views that are in the same namespace as the current
view.  For example if the current view is Example::View::Foo and you want to include
Example::View::Foo::Bar you can use the relative view name '::Bar'.

=head1 INHERITED METHODS

This class inherits all methods from L<Catalyst::View::BasePerRequest> but the following
are public and considered useful:

=head2 Content Block Helpers

Used to capture blocks of template.  SEE:

L<Catalyst::View::BasePerRequest/content>, L<Catalyst::View::BasePerRequest/content_for>,
L<Catalyst::View::BasePerRequest/content_append>, L<Catalyst::View::BasePerRequest/content_prepend>,
L<Catalyst::View::BasePerRequest/content_replace>, L<Catalyst::View::BasePerRequest/content_around>.

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

Lastly, experimentally you can use the C<Helper> attribute to define helpers in your view
module.  This requires L<MooseX::MethodAttributes>.

Example:

  package MyApp::View::MyView;

  use Moose;
  use MooseX::MethodAttributes;

  extends 'Catalyst::View::EmbeddedPerl::PerRequest';

  sub my_helper :Helper {
    my ($self, $c, $arg) = @_;
    return "Hello $arg";
  }

  __PACKAGE__->meta->make_immutable;

Please note that if you override a helper method in a subclass you currently need
to also add the Helper attribute to the method in the subclass.

=head1 TEMPLATE INHERITANCE

This is an experimental feature that allows you to inherit from other views. When
you inherit from a view, the parent's template automatically becomes the base template
Example:

    package Example::View::Base;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::View::EmbeddedPerl::PerRequest';

    sub title :Helper { 'Missing title' }

    sub styles {
      my ($self, $cb) = @_;
      my $styles = $self->content('css') || return '';
      return $cb->($styles);
    }

    __PACKAGE__->meta->make_immutable;
    __PACKAGE__->config(
      auto_escape => 1,
      content_type => 'text/html',
    );
    
    __DATA__
    <html>
      <head>
        <title><%= title() %></title>
        %= $self->styles(sub {
          <style>
            %= shift
          </style>
        % })
      </head>
      <body>
        <%= $content %>
      </body>
    </html>

And an inheriting view:

    package Example::View::Inherit;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Example::View::Base';

    has 'name' => (is => 'ro', isa => 'Str', export=>1);

    sub title :Helper  { 'Inherited Title' }

    __PACKAGE__->meta->make_immutable;
    __DATA__
    # Style content
    % content_for('css', sub {
          p { color: red; }
    % });
    # Main content
      <p>hello <%= $name %></p>

When called from a controller like this:

    sub inherit :Local  {
      my ($self, $c) = @_;
      return $c->view('Inherit', name=>'joe')->http_ok;
    }

Produced output similar to:

    <html>
      <head>
        <title>Inherited Title</title>
        <style>
          p { color: red; }
        </style>
      </head>
      <body>
        <p>hello joe</p>
      </body>
    </html>

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

=head2 view

  view($view_name, @args)

Renders another view and returns its content. Useful for including the output of one view inside another.

=head2 content

  content($name, $content)

Captures a block of content for later use.

=head2 content_for

  content_for($name, $content)

Captures a block of content for later use, appending to any existing content.

=head2 content_append

  content_append($name, $content)

Appends content to a previously captured block.

=head2 content_prepend

  content_prepend($name, $content)

Prepends content to a previously captured block.

=head2 content_replace

  content_replace($name, $content)

Replaces a previously captured block with new content.

=head2 get_styles

  get_styles()

Returns all the styles that have been pushed to the 'css' block.

=head3 Example

    $self->push_style(sub {
      p { color: red; }
    });

    my $styles = $self->get_styles;

Or in a template:

    <%= get_styles() %>

    %= push_style(sub {
      p { color: red; }
    %})

Produces output like:

    <style>
      p { color: red; }
    </style>

=head2 push_style

  push_style($content)
  push_style($name, $content)

Pushes content to the 'css' block.  If a name is provided, the content will only be
pushed if it has not already been pushed with that name.  Useful for ensuring that
styles are only included once in the output.

=head2 get_scripts

  get_scripts()

Returns all the scripts that have been pushed to the 'js' block.

=head3 Example

    $self->push_script(sub {
      alert('hello');
    });

    my $scripts = $self->get_scripts;

Or in a template:

    <%= get_scripts() %>

    %= push_script(sub {
      alert('hello');
    %})

Produces output like:

    <script>
      alert('hello');
    </script>

=head2 push_script

  push_script($content)
  push_script($name, $content)

Pushes content to the 'js' block.  If a name is provided, the content will only be
pushed if it has not already been pushed with that name.  Useful for ensuring that
scripts are only included once in the output.

=head2 attr

  attr($attribute, $value)

Returns an HTML attribute string.  Example usage:

  <a href="<%= attr('href', $url) %>">Link</a>

=head2 style

  style($style)

Returns a C<style> attribute string.  Example usage:

  <div <%= style('color: red;') %>>Content</div>

=head2 class

  class($class)

Returns a C<class> attribute string.  Example usage:

  <div <%= class('important') %>>Content</div>

=head2 checked 
  
    checked($checked)

Returns a C<checked> attribute string.  Example usage:
  
    <input type="checkbox" <%= checked($checked) %> />

=head2 selected

    selected($selected)

Returns a C<selected> attribute string.  Example usage:

    <select>
      <option value="1" <%= selected($selected) %>>One</option>
      <option value="2" <%= selected($selected) %>>Two</option>
    </select>

=head2 disabled

    disabled($disabled)

Returns a C<disabled> attribute string.  Example usage:

    <input type="text" <%= disabled($disabled) %> />

=head2 readonly

    readonly($readonly)

Returns a C<readonly> attribute string.  Example usage:

    <input type="text" <%= readonly($readonly) %> />

=head2 required

    required($required)

Returns a C<required> attribute string.  Example usage:

    <input type="text" <%= required($required) %> />

=head2 href

    href(@href_parts)

Returns an C<href> attribute string.  Example usage:


    <a <%= href('/path/to/page') %>>Link</a>

=head2 src
  
      src(@src_parts)

Returns a C<src> attribute string.  Example usage:

    <img <%= src('/path/to/image.jpg') %> />

=head2 data

    data($data)

Returns a C<data> attribute string.  Example usage: 
  
      <div <%= data({'id', '123'}) %>>Content</div> 

=head2 over

  my $result = $self->over($iterable, sub {
      my ($item, $info) = @_;
      return "<p>Item: $item, Index: " . $info->current . "</p>";
  });

In a template:

  <%= over($iterable, sub($item, $info) {
      <p>Item: <%= $item %>, Index: <%= $info->current %></p>
  }) %>

(Remember in the template calling helpers via C<$self> is your option)

Executes a callback for each item in an iterable, providing metadata about the iteration 
through a L<Catalyst::View::EmbeddedPerl::PerRequest::EachInfo> object.

Although you can use standard Perl looping constructs in your templates, the C<over>
helper provides the addional metadata about the iteration that can be useful in some
situations related to display logic, such as changing the CSS based on even/odd rows
or tracking the item number.

=head3 Arguments

=over

=item * C<$iterable> - An iterable source. This can be:

=over

=item * An array reference (e.g., C<[1, 2, 3]>).

=item * A coderef that returns the next value when called (e.g., C<sub { ... }>).

=item * An object with a C<next> method and optionally C<length> or C<count> methods.

=item * A scalar value or single item.

=back

=item * C<$cb> - A callback subroutine. The callback will be called for each item in the iterable and receives the following arguments:

=over

=item * C<$item> - The current item in the iterable.

=item * C<$info> - An instance of L<Catalyst::View::EmbeddedPerl::PerRequest::EachInfo> containing metadata about the current iteration.

=back

=back

=head3 Returns

A concatenated string of the results returned by the callback for each item.

=head3 Examples

=head4 Iterating over an array reference

  my $array = [qw(foo bar baz)];
  my $result = $self->over($array, sub {
      my ($item, $info) = @_;
      return "<p>Item: $item, Index: " . $info->current . "</p>";
  });

  # Output:
  # <p>Item: foo, Index: 0</p>
  # <p>Item: bar, Index: 1</p>
  # <p>Item: baz, Index: 2</p>

=head4 Using a coderef as an iterator

  my $iterator = sub {
      state $count = 0;
      return $count < 5 ? ++$count : undef;
  };

  my $result = $self->over($iterator, sub {
      my ($item, $info) = @_;
      return "<p>Item: $item, Is Even: " . $info->is_even . "</p>";
  });

  # Output:
  # <p>Item: 1, Is Even: 0</p>
  # <p>Item: 2, Is Even: 1</p>
  # <p>Item: 3, Is Even: 0</p>
  # <p>Item: 4, Is Even: 1</p>
  # <p>Item: 5, Is Even: 0</p>

=head4 Iterating over an object with C<next> and C<length>

  package MyIterator;
  use Moo;

  has items => (is => 'rw', default => sub { [1, 2, 3] });
  sub next { shift @{ shift->items } }
  sub length { scalar @{ shift->items } }

  my $obj = MyIterator->new(items => [qw(alpha beta gamma)]);
  my $result = $self->over($obj, sub {
      my ($item, $info) = @_;
      return "<p>Item: $item, Total: " . $info->total . "</p>";
  });

  # Output:
  # <p>Item: alpha, Total: 3</p>
  # <p>Item: beta, Total: 3</p>
  # <p>Item: gamma, Total: 3</p>

=head4 Passing a scalar value

  my $result = $self->over("single value", sub {
      my ($item, $info) = @_;
      return "<p>Item: $item, Is First: " . $info->is_first . "</p>";
  });

  # Output:
  # <p>Item: single value, Is First: 1</p>

=head4 Iterating over multiple arguments

  my $result = $self->over(qw(apple banana cherry), sub {
      my ($item, $info) = @_;
      return "<p>Item: $item, Is Last: " . $info->is_last . "</p>";
  });

  # Output:
  # <p>Item: apple, Is Last: 0</p>
  # <p>Item: banana, Is Last: 0</p>
  # <p>Item: cherry, Is Last: 1</p>

=head1 TEMPLATE LOCATIONS

Templates are searched in the following order:

=over 4

=item 1. C<__DATA__> section of the view module.

If your view module has a C<__DATA__> section, the template will be read from there.

=item 2. File system based on the view's class name.

If not found in C<__DATA__>, the template file is looked up in the file system, 
following the view's class name path.  The file will be a 'snake case' version of
the view module name with a '.epl' extension.

=item 3. default_template method

If no template is found, the C<default_template> method is called to get a default
template.  This method should return a string containing the template.

The default template is:

  <%= $content %>

Which is handy for when you are making a base view that others will inherit from.
But you can override this method in your view module to provide a different default.


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
  __PACKAGE__->config(
    prepend => 'use v5.40',
    content_type=>'text/html; charset=UTF-8'
  );

In your view modules:

  package MyApp::View::MyView;

  use Moose;
  extends 'MyApp::View';

  __PACKAGE__->meta->make_immutable;

=head2 Using 'tags' for HTML snippets in helpers

Sometimes you want a helper that can construct safe HTML:

  sub hello_name :Helper ($self, $name) {
    my $t = $self->tags;
    return $t->div({class=>"container"}, sub {
      return $t->h1($self->text("hello ${name}!")),
        $t->hr;
     }),
  }

Used in a template like:

  %= hello_name('John')

Results in:

  <div class='container'>Hello John!<div>

See L<Valiant::HTML::Util::TagBuilder> whose methods are proxied by this class.

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
