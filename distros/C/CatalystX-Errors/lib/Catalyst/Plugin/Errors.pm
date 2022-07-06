package Catalyst::Plugin::Errors;

use Moose;
use MRO::Compat;
use CatalystX::Utils::ContentNegotiation;
use CatalystX::Utils::ErrorMessages;
use Catalyst::Utils;
use Scalar::Util ();

our %DEFAULT_ERROR_VIEWS = (
  'text/html'   => 'Errors::HTML',
  'text/plain'  => 'Errors::Text',
  'application/json' => 'Errors::JSON',
);

my %views = %DEFAULT_ERROR_VIEWS;
my @accepted = ();
my $default_media_type = 'text/plain';
my $default_language = 'en_US';

my $profile = sub {
  my $c = shift;
  $c->stats->profile(@_)
    if $c->debug;
};

my $available_languages = sub {
  my ($c) = @_;
  return my @lang_tags = CatalystX::Utils::ErrorMessages::available_languages;
};

my $get_language = sub {
  my ($c) = @_;
  if(my $lang = $c->request->header('Accept-Language')) {
    return CatalystX::Utils::ContentNegotiation::content_negotiator->choose_language([$c->$available_languages], $lang) || $default_language;
  }
  return $default_language;
};

my $get_message_info = sub {
  my ($c, $lang, $code) = @_;
  return my $message_info_hash = CatalystX::Utils::ErrorMessages::get_message_info($lang, $code);
};

my $finalize_message_info = sub {
  my ($c, $code, $lang, %args) = @_;
  my $message_info = $c->$get_message_info($lang, $code);
  $message_info = $c->$get_message_info('en_US', $code) unless $message_info; # Fallback to US English
  return (
    %$message_info,
    lang => $lang,
    %args,
  );
};

sub generate_error_template_name {
  my ($c, $code, %args) = @_;
  return 'http_error';
}

sub finalize_error_args {
  my ($c, $code, %args) = @_;
  my $lang = $c->$get_language;
  my %message_info = $c->$finalize_message_info($code, $lang, %args);
  return (
    status_code => $code,
    uri => "@{[ $c->req->uri ]}",
    %message_info );
}

sub looks_like_http_error_obj {
  my ($self, $obj) = @_;
  return Scalar::Util::blessed($obj) && $obj->can('as_http_response') ? 1:0;
}

sub setup {
  my $app = shift;
  my $ret = $app->maybe::next::method(@_);
  my $config = $app->config->{'Plugin::Errors'};

  %views = (%views, %{$config->{views}}) if $config->{views};
  $default_media_type = $config->{default_media_type} if exists $config->{default_media_type};
  $default_language = $config->{default_language} if exists $config->{default_language};

  @accepted = keys %views;

  return $ret;
}

sub setup_components {
  my ($app, @args) = @_;
  my $ret = $app->maybe::next::method(@_);

  my $namespace = "${app}::View";
  my %views_we_have = map { Catalyst::Utils::class2classsuffix($_) => 1 }
    grep { m/$namespace/ }
    keys %{ $app->components };

  foreach my $view_needed (values %views) {
    next if $views_we_have{"View::${view_needed}"};
    $app->log->debug("Injecting Catalyst::View::${view_needed}") if $app->debug;
    Catalyst::Utils::ensure_class_loaded("Catalyst::View::${view_needed}");
    Catalyst::Utils::inject_component(
      into => $app,
      component => "Catalyst::View::${view_needed}",
      as => $view_needed );
  }

  return $ret;
}

sub dispatch_error {
  my ($c, $code, @args) = @_;
  my (@additional_headers, %data) = ();

  @additional_headers = @{shift(@args)} if (ref($args[0])||'') eq 'ARRAY';
  while(@additional_headers) {
    $c->response->headers->header(shift(@additional_headers), shift(@additional_headers));
  }

  %data = %{shift(@args)} if (ref($args[0])||'') eq 'HASH';
  %data = $c->finalize_error_args($code, %data);

  my $chosen_media_type = CatalystX::Utils::ContentNegotiation::content_negotiator
    ->choose_media_type(\@accepted, $c->request->header('Accept'))
    ||  $default_media_type;

  $c->log->debug("Error dispatched to mediatype '$chosen_media_type' using view '$views{$chosen_media_type}'") if $c->debug;
  $c->log->error($data{error}) if exists($data{error});

  my $chosen_view = $views{$chosen_media_type};
  my $view_class = ref($c) . "::View::${chosen_view}";
  my $view_obj = $view_class->can('ACCEPT_CONTEXT') ?
    $c->view($chosen_view, %data) :
      $c->view($chosen_view);

  if(my $sub = $view_obj->can("http_${code}")) {
    $c->$profile(begin => "=> View::${chosen_view}");
    $view_obj->$sub($c, %data);
    $c->$profile(end => "=> View::${chosen_view}");
  } elsif($view_obj->can('http_default')) {
    $c->$profile(begin => "=> View::${chosen_view}");
    $view_obj->http_default($c, $code, %data);
    $c->$profile(end => "=> View::${chosen_view}");
  } else {
    my $template = $c->generate_error_template_name($code, %data);
    $c->stash(template=>$template, %data);
    $c->forward($view_obj);
  }
}

sub detach_error {
  my $c = shift;
  $c->dispatch_error(@_);
  $c->detach;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Catalyst::Plugin::Errors - Standard error responses with content negotiation

=head1 SYNOPSIS

Use in your application class

    package Example;

    use Catalyst;

    __PACKAGE__->setup_plugins([qw/Errors/]);
    __PACKAGE__->setup();
    __PACKAGE__->meta->make_immutable();

And then you can use it in a controller (or anyplace where you have C<$c> context).

    package Example::Controller::Root;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub root :Chained(/) PathPart('') CaptureArgs(0) {} 

      sub not_found :Chained(root) PathPart('') Args {
        my ($self, $c, @args) = @_;
        $c->detach_error(404);
      }

    __PACKAGE__->config(namespace=>'');
    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

This is a plugin which installs (if needed) View classes to handle HTTP errors (4xx
and 5xx codes) in a regular and content negotiated way.  See <CatalystX::Errors>
for a high level overview.   Documentation here is more API level and the examples
are sparse.

=head1 METHODS

This plugin adds the following methods to your C<$c> context.

=head2 dispatch_error ($code, ?\@additional_headers, ?\%template_args)

Examples:

    $c->detach_error(404);
    $c->detach_error(404, +{error=>'invalid uri request'});
    $c->detach_error(401, ['WWW-Authenticate" => 'Basic realm=myapp, charset="UTF-8"'], +{error=>'unauthorized access attempt'});

Dispatches to an error view based on content negotiation and the provided code. You can also pass
an arrayref of extra HTTP headers (such as www-authenticate for 401 errors) and also optionally
a hashref of fields that will be sent to the view.

When dispatching to a C<$view> we use the following rules in order:

First if the View has a method C<http_${code}> (where C<$code> is the HTTP status code you are 
using for the error) we call that method with args C<$c, %template_args> and expect that method to setup
a valid error response.

Second, call the method C<http_default> with args C<$c, $code, %template_args> if that exists.

If neither method exists we call C<$c->forward($view)> and C<%template_args> are added to the stash, along
with a stash var 'template' which is set to 'http_error'. This should work with most standard L<Catalyst> 
views that look at the stash field 'template' to find a template name.  If you  prefer a different template
name you can override the method 'generate_error_template_name' to make it whatever you wish.

B<NOTE> Using C<dispatch_error> (or C<detach_error>) doesn't add anything to the Catalyst error log
as we consider this control flow more than anything else.   If you want to log a special line you can
add an C<error> field to C<%template_args> and that we go to the error log.

=head2 detach_error

Calls L</dispatch_error> with the provided arguments and then does a C<$c->detach> which
effectively ends processing for the action.

=head1 CONFIGURATION & CUSTOMIZATION

This plugin can be customized with the following configuration options or via
overriding or adapting the following methods

=head2 finalize_error_args

This method provides the actual arguments given to the error view (args which are for
example used in the template for messaging to the end user).  You can override this
to provide your own version.   See the source for how this should work

=head2 Configuration keys

This plugin defines the following configuration by default, which you can override.

    package Example;

    use Catalyst;

    __PACKAGE__->setup_plugins([qw/Errors/]);
    __PACKAGE__->config(
      # This is the configuration which is default.  You don't have to actually type
      # this out.  I'm just putting it here to show you what its doing under the hood.
      'Plugin::Errors' => +{
        default_media_type => 'text/plain',
        default_language => 'en_US',
        views => +{
          'text/html'   => 'Errors::HTML',
          'text/plain'  => 'Errors::Text',
          'application/json' => 'Errors::JSON',
        },
      },
    );

    __PACKAGE__->setup();
    __PACKAGE__->meta->make_immutable();

By default we map the media types C<text/html>, C<text/plain> and C<application/json> to
cooresponding views.  This views are injected automatically if you don't provide subclasses
or your own view locally.   The following views are injected as needed:

L<Catalyst::View::Error::HTML>, L<Catalyst::View::Error::Text>, and L<L<Catalyst::View::Error::JSON>.

You can check the docs for each of the default views for customization options but you can always
make a local subclass inside you application's view directory and tweak as desired (or you can just
use your own view or one of the common ones on CPAN).

You can also add additional media types mappings.

=head1 SEE ALSO
 
L<CatalystX::Errors>.

=head1 AUTHOR
 
L<CatalystX::Errors>.
    
=head1 COPYRIGHT & LICENSE
 
L<CatalystX::Errors>.

=cut
