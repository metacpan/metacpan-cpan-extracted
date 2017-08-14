package Catalyst::View::Template::Lace;

our $VERSION = '0.008';

use Module::Runtime;
use Catalyst::View::Template::Lace::Renderer;
use Template::Lace::Utils;
use Moo;

extends 'Catalyst::View';

sub COMPONENT {
  my ($class, $app, $args) = @_;
  my $merged_args = $class->merge_config_hashes($class->config, $args);
  my $merged_component_handlers = $class->merge_config_hashes(
    (delete($merged_args->{component_handlers})||+{}),
    $class->view_components($app, $merged_args));

  my $adaptor = delete($merged_args->{factory}) || 'Catalyst::View::Template::Lace::Factory';
  my $model_class = delete($merged_args->{model_class}) || $class;
  my %args = (
    model_class=>$model_class,
    renderer_class=>'Catalyst::View::Template::Lace::Renderer',
    component_handlers=>$merged_component_handlers,
    init_args=>+{ %$merged_args, app=>$app },
  );

  $args{model_constructor} = delete($merged_args->{model_constructor})
    if $merged_args->{model_constructor};

  my $factory = Module::Runtime::use_module($adaptor)->new(%args);
  return $factory;
}

has ctx => (is=>'ro', required=>0);

sub view_components {
  my ($class, $app, $merged_args) = @_;
  return +{
    catalyst => {
      subrequest => Template::Lace::Utils::mk_component {
        require HTTP::Request;
        require HTTP::Message::PSGI;

        my @args = (delete $_{action});
        my $method = ((delete $_{method}) || 'GET');
        push @args, delete($_{parts}) if $_{parts};
        push @args, delete($_{query}) if $_{query};

        my $href = $_{model}->uri_for(@args);
        my $http_request = HTTP::Request->new($method, $href);
        my $psgi_env = HTTP::Message::PSGI::req_to_psgi($http_request);
        my $psgi_response = $_{model}->ctx->psgi_app->($psgi_env);
        my $http_response = HTTP::Message::PSGI::res_from_psgi($psgi_response);
        my $content = $http_response->content;
        if($_{at}) {
          return $_->make_dom($content)->at($_{at});
        }
        return $content;
      }
    },
    view => sub {
      my ($name, $args, %attrs) = @_;
      my $view_name = join '::', map {
        $_=~s/[_-]([a-z])/\u$1/g;
        ucfirst $_; 
      } split '-', $name;
      return $app->view($view_name);
    },
  };
}

1;

=head1 NAME

Catalyst::View::Template::Lace - Catalyst View Adaptor for Template::Lace

=head1 SYNOPSIS

Define a View:

    package  MyApp::View::User;

    use Moo;
    extends 'Catalyst::View::Template::Lace';

    has [qw/age name motto/] => (is=>'ro', required=>1);

    sub template {q[
      <html>
        <head>
          <title>User Info</title>
        </head>
        <body>
          <dl id='user'>
            <dt>Name</dt>
            <dd id='name'>NAME</dd>
            <dt>Age</dt>
            <dd id='age'>AGE</dd>
            <dt>Motto</dt>
            <dd id='motto'>MOTTO</dd>
          </dl>
        </body>
      </html>
    ]}

    sub process_dom {
      my ($self, $dom) = @_;
      $dom->dl('#user', +{
       age=>$self->age,
       name=>$self->name,
       motto=>$self->motto});
    }

    1;

Used in a controller:

    package MyApp::Controller::User;

    use Moose;
    use MooseX::MethodAttributes;
    extends 'Catalyst::Controller';

    sub display :Path('') {
      my ($self, $c) = @_;
      $c->view('User',
        name => 'John',
        age => 42,
        motto => 'Why Not?')
      ->http_ok;
    }

    __PACKAGE__->meta->make_immutable;

A Template may also contain components which are reusable blocks of template
functionality and which refer to other Catalyst Views in your application:

    <view-master title='Homepage'>
      <view-header navbar_section='home'/>
        <section>
          <p>You are doomed to discover you can never recover from the narcolyptic
          country in which you once stood, where the fires alway burning but there's
          never enough wood</p>
        </section>
      <view-footer copyright='$.copy' />
    </view-master>

Such components can wrap your main content or even other component, and they can
accept arguments.  See L<Catalyst::View::Template::Lace::Tutorial> for more details.

=head1 DESCRIPTION

B<NOTE> I consider this an early access release.  Code and API here is subject
to significant change as needed to advance the project.  Please don't use this
in production unless you are willing to cope with that.

L<Catalyst::View::Template::Lace> is a view adaptor for L<Template::Lace> with
some L<Catalyst> specific helpers and features added.  Reviewing documentation
for L<Template::Lace> would useful in furthering your ability to use it in
L<Catalyst>.

In short, this is a template framework for L<Catalyst> that introduces strongly
typed views and view components as design patterns for your web applications.
What this means is that unlike most L<Catalyst> views that you're probably
familiar with (such as the Template::Toolkit view) we define one view per
template instead of one view for all the templates.  Although this might seem
like a lot of views to write the upside is by defining a strong interface for your
view, you eliminate a host of display errors that I commonly see in the wild since
there is no contract beween a view and the controller that is calling it.  Also
since each component in your view has access to the L<Catalyst> context, you can
write smarter views with display logic properly encapsulated near the template
code it will actually be used.  This reduces complexity in your controllers and
makes it easier to solve complex layout logic.

After reviewing these documentation you can advance to L<Catalyst::View::Template::Lace::Tutorial>
and you might find the test cases in the C</t> directory of this distribution
handy as well.

B<NOTE> I consider current documentation to be the 'thin red line' requirement
for CPAN publication but there's tons more to be done.  Critique and contributions
very welcomed!.

=head1 CONFIGURATION

This component defines the following configuration options:

=head2 factory

These specifies which subclass of L<Template::Lace::Factory> will be used to
manage your view lifecycle.  The default is L<Catalyst::View::Template::Lace::Factory>.
You can also specify L<Catalyst::View::Template::Lace::PerContext> or write your
own.  See documentation for the two options for more.

=head2 model_class

=head2 render_class

=head2 init_args

=head2 model_constructor

=head2 component_handlers

All these are pass through configuration to the underlying subclass of
L<Template::Lace::Factory> which you should review.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Template::Lace>, L<Catalyst::View::Template::Pure>

=head1 COPYRIGHT & LICENSE
 
Copyright 2017, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
