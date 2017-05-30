package Catalyst::Model::Data::MuForm;

use Moo;
use Module::Pluggable::Object;
use Template::Tiny;

our $VERSION = '0.001';

extends 'Catalyst::Model';

has _application => (is => 'ro', required=>1);

has 'form_namespace' => (
  is=>'ro',
  required=>1,
  lazy=>1, 
  builder=>'_build_form_namespace');
 
  sub _default_form_namespace_part { return 'Form' }
 
  sub _build_form_namespace {
    return $_[0]->_application .'::'. $_[0]->_default_form_namespace_part;
  }
 
has 'form_packages' => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_form_packages');
 
  sub _build_form_packages {
    my $self = shift;
    my @forms = Module::Pluggable::Object->new(
      require => 1,
      search_path => [ $self->form_namespace ],
    )->plugins;
    return \@forms;
  }

has 'template_string' => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_template_string');

  sub _build_template_string { local $/; return <DATA> }

has 'template_processor' => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_template_processor');

  sub _build_template_processor { return Template::Tiny->new(TRIM => 1) }

around 'BUILDARGS' => sub {
  my ($orig, $self, $app, @args) = @_;
  my $args = $self->$orig($app, @args);
  $args->{_application} = $app;
  return $args;
};

sub expand_modules {
  my ($self, $config) = @_;
  my @model_packages;
  foreach my $form_package (@{$self->form_packages}) {
    my $model_package = $self->construct_model_package($form_package);
    my $model_name = $self->construct_model_name($form_package);
    $self->build_model_adaptor($model_package, $form_package, $model_name);
    push @model_packages, $model_package;
  }
  return @model_packages;
}

sub construct_model_package {
  my ($self, $form_package) = @_;
  return $self->_application .'::Model'. ($form_package=~m/${\$self->_application}(::.+$)/)[0];
}
 
sub construct_model_name {
  my ($self, $form_package) = @_;
  return ($form_package=~m/${\$self->_application}::(.+$)/)[0];
}
 
sub build_model_adaptor {
  my ($self, $model_package, $form_package, $model_name) = @_;
  my $input = $self->template_string;
  my $output = '';
  $self->template_processor->process(
    \$input,
    +{
      model_package=>$model_package,
      form_package=>$form_package,
    },
    \$output );

  eval $output;
  die $@ if $@;
}

1;

=head1 NAME
 
Catalyst::Model::Data::MuForm - Proxy a directory of Data::MuFormr forms
 
=head1 SYNOPSIS
 
    package MyApp::Model::Form;
 
    use Moo; # Or Moose, etc.
    extends 'Catalyst::Model::Data::MuForm';
 
    __PACKAGE__->config( form_namespace=>'MyApp::Form' ); # This is the default BTW
 
And then using it in a controller:
 
    my $form = $c->model("Form::Email");  # Maps to MyApp::Email via MyApp:Model::Email
 
    # If the request is a POST, we process parameters automatically
    if($form->validated) {
      ...
    } else {
      ...
    }
 
=head1 DESCRIPTION
 
Assuming a project namespace 'MyApp::Form' with L<HTML::Formhandler> forms. like
the following example:
 
  package MyApp::Form::Email;
 
  use HTML::FormHandler::Moose;
 
  extends 'HTML::FormHandler';

  has 'invalid_domains' => (is=>'ro', required=>1);
  
  has_field 'email' => (
    type=>'Email',
    size => 96,
    required => 1);
 
You create a single L<Catalyst> model like this:
 
    package MyApp::Model::Form;
 
    use Moo; # Or Moose, etc.
    extends 'Catalyst::Model::Data::MuForm';
 
    __PACKAGE__->config( form_namespace=>'MyApp::Form' );
 
(Setting 'form_namespace' is optional, it defaults to the application
namespace plus "::Form" (in this example case that would be "MyApp::Form").
 
When you start your application it will register one model for each form
in the declared namespace.  So in the above example you should see a model
'MyApp::Model::Form::Email'.
 
You can set model configuration in the normal way, in your application general
configuration:
 
    package MyApp;
    use Catalyst;
 
    MyApp->config(
      'Model::Form::Email' => {
        invalid_domains => [qw(foo.com wack.org)],
      },
    );
     
    MyApp->setup;
 
And you can pass additional args to the 'process' call of the form when you request
the form model:
 
    my $email_form = $c->model('Form::Email',
      model => $user_model,
      params => $c->req->body_parameters);
 
Basically you can pass anything you'd pass to 'process' in L<Data::MuForm>.
 
The generated proxy will also add the ctx argument based on the current value of
$c, although using this may not be a good way to build well, decoupled applications.
 
By default if the request is a POST, we will process the request arguments and
return a form object that you can test for validity.  So you don't need to set
the 'params' if the parameters are just the existing L<Catalyst> body_parameters.
If you don't want this behavior you can disable it by passing 'no_auto_process'.
For example:
 
    my $form = $c->model("Form::XXX", no_auto_process=>1);
 
=head1 ATTRIBUTES
 
This class defines the following attributes you may set via
standard L<Catalyst> configuration.
 
=head2 form_namespace
 
This is the target namespace that L<Module::Pluggable> uses to look for forms.
It defaults to 'MyApp::Form' (where 'MyApp' is you application namespace).
  
=head2 body_method
 
This is the name of the method called on L<Catalyst::Request> used to access any
POSTed data.  Required field, the options are 'body_data' and 'body_parameters.
The default is 'body_data'.
 
=head2 no_auto_process
 
By default when createing the perrequest form if the request is a POST we
just go ahead and process those args.  Setting this to true will disable
this behavior globally if you prefer more control.
 
=head1 SPECIAL ARGUMENTS
 
You may pass the following special arguments to $c->model("Form::XXX") to
influence how the form object is setup.
 
=head2 no_auto_process
 
Turns off the call to ->process when the request is a POST.
 
=head1 AUTHOR
  
John Napiorkowski L<email:jjnapiork@cpan.org>
   
=head1 SEE ALSO
  
L<Catalyst>, L<Catalyst::Model>, L<Data::MuForm>
 
=head1 COPYRIGHT & LICENSE
  
Copyright 2017, John Napiorkowski L<email:jjnapiork@cpan.org>
  
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
 
=cut

__DATA__
package [% model_package %];

use Moo;
use Module::Runtime;
extends 'Catalyst::Model';

has _args => (
  is=>'ro',
  required=>1);

has body_method => (
  is=>'ro',
  required=>1,
  default=>'body_data');

has auto_process => (is=>'ro', required=>1, default=>1);

has form => (
  is=>'ro',
  required=>1);

sub COMPONENT {
  my ($class, $app, $args) = @_;
  my $merged_args = $class->merge_config_hashes($class->config, $args);
  my $form = Module::Runtime::use_module("[% form_package %]")->new($merged_args);
  return $class->new(_args=>$merged_args, form=>$form);
}

# If its a POST we grab params automagically
my $prepare_post_params = sub {
  my ($self, $c, %process_args) = @_;
  if(
    ($c->req->method=~m/post/i)
    and (not exists($process_args{params}))
    and (not $process_args{no_auto_process})
    and ($self->auto_process)
  ) {
    my $body_method = $self->body_method;
    $process_args{params} = $c->req->$body_method;
    $process_args{submitted} = 1 unless exists($process_args{submitted});
  }
  return %process_args;
};

# If there are odd args, that means the first one is either the
# model object or model_id
my $normalize_process_args = sub {
  my ($self, $c, %process_args) = (shift, shift, ());
  if(scalar(@_) % 2) {
    my $item_proto = shift;
    %process_args = @_;
    if(ref $item_proto) { # assume its blessed
      $process_args{model} = $item_proto;
    } else {
      $process_args{model_id} = $item_proto;
    }
  } else {
    %process_args = @_;
  }
  return $self->$prepare_post_params($c, %process_args);
};


sub ACCEPT_CONTEXT {
  my ($self, $c, @process_args) = @_;
  my %process_args = $self->$normalize_process_args($c, @process_args);  
  local $_; #WHY?
  $self->form->process(%process_args, ctx=>$c);
  return $self->form;
}

1;
