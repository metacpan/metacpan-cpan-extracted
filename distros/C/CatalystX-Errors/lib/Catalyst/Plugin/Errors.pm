package Catalyst::Plugin::Errors;

use Moose;
use MRO::Compat;
use CatalystX::Utils::ContentNegotiation;
use Catalyst::Utils;

our %DEFAULT_ERROR_VIEWS = (
  'text/html'   => 'Errors::HTML',
  'text/plain'  => 'Errors::Text',
  'application/json' => 'Errors::JSON',
);

my %views = %DEFAULT_ERROR_VIEWS;
my @accepted = ();
my $default_media_type = 'text/plain';

my $normalize_args = sub {
  my $c = shift;
  my %args = (ref($_[0])||'') eq 'HASH' ? %{$_[0]} : @_;
  return %args;
};

sub finalize_error_args {
  my ($c, $code, %args) = @_;
  return (
    code => $code,
    template => $code,
    uri => "@{[ $c->req->uri ]}",
    %args );
}
 
sub setup {
  my $app = shift;
  my $ret = $app->maybe::next::method(@_);
  my $config = $app->config->{'Plugin::Error'};

  %views = %{$config->{views}} if $config->{views};
  $default_media_type = $config->{default_media_type} if $config->{views};
  @accepted = keys %views;

  return $ret;
}

sub setup_components {
  my ($app, @args) = @_;
  my $ret = $app->maybe::next::method(@_);

  my $namespace = "${app}::View::Errors";
  my %views_we_have = map { Catalyst::Utils::class2classsuffix($_) => 1 }
    grep { m/$namespace/ }
    keys %{ $app->components };

  foreach my $view_needed (values %views) {
    next if $views_we_have{$view_needed};
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

  my %args = $c->finalize_error_args($code, $c->$normalize_args(@args));
  my $chosen_media_type = CatalystX::Utils::ContentNegotiation::content_negotiator
    ->choose_media_type(\@accepted, $c->request->header('Accept'))
    ||  $default_media_type;

  $c->log->info("Error dispatch to mediatype: $chosen_media_type");

  my $chosen_view = $views{$chosen_media_type};
  my $view_obj = $c->view($chosen_view);

  $c->stash(%args);

  if(my $sub = $view_obj->can("http_${code}")) {
    $view_obj->sub($c, %args);
  } elsif($view_obj->can('http_default')) {
    $view_obj->http_default($c, $code, %args);
  } else {
    $c->forward($view_obj, \%args);
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

=head2 dispatch_error ($code, ?%args)

Dispatches to an error view based on content negotiation and the provided code.  Any additional
C<%args> will be passed to the view handler, down to the template so if you have a custom view
template you can use this to provide custom template parameters.

When dispatching to a C<$view> we use the following rules in order:

First if the View has a method C<http_${code}> (where C<$code> is the HTTP status code you are 
using for the error) we call that method with args C<$c, %args> and expect that method to setup
a valid error response.

Second, when call the method C<http_default> with args C<$c, $code, %args> if that exists.

If neither method exists we call C<$c->forward($view)> and C<%args> are added to the stash, along
with a stash field 'template' which is set to the error $code.   This should work with most
standard L<Catalyst> views that look at the stash field 'template' to find a template name.

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
        'text/html'   => 'Errors::HTML',
        'text/plain'  => 'Errors::Text',
        'application/json' => 'Errors::JSON',
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
