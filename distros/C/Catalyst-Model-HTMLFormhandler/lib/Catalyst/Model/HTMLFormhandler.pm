package Catalyst::Model::HTMLFormhandler;

use Moose;
use Module::Pluggable::Object;
use Moose::Util::TypeConstraints ();
use Catalyst::Utils;

extends 'Catalyst::Model';
with 'Catalyst::Component::ApplicationAttribute';

our $VERSION = '0.009';

has 'roles' => (
  is=>'ro',
  isa=>'ArrayRef',
  predicate=>'has_roles');

has 'body_method' => (
  is=>'ro',
  isa=> Moose::Util::TypeConstraints::enum([qw/body_data body_parameters/]),
  required=>1,
  default=>'body_data');

has 'schema_model_name' => (is=>'ro',
  isa=>'Str',
  predicate=>'has_schema_model_name');

has 'form_namespace' => (
  is=>'ro',
  required=>1,
  lazy=>1, 
  builder=>'_build_form_namespace');

  sub _default_form_namespace_part { 'Form' }

  sub _build_form_namespace {
    my $self = shift;
    return $self->_application .'::'. $self->_default_form_namespace_part;
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

has 'no_auto_process' => (is=>'ro', isa=>'Bool', required=>1, default=>0);

sub build_model_adaptor {
  my ($self, $model_package, $form_package, $model_name) = @_;
  my $roles = join( ',', map { "'$_'"} @{$self->roles||[]}) if $self->has_roles;

  my $schema_args = $self->has_schema_model_name ?
    '$args{schema} = $c->model("'.$self->schema_model_name.'");' : '';

  my $package = "package $model_package;\n" . q(
  
  use Moose;
  use Moose::Util;
  use ). $form_package . q! ;
  extends 'Catalyst::Model';

  sub COMPONENT {
    my ($class, $app, @args) = @_;
    # Don't call new, we don't want to merge config now since this is a per-request
    # model, that way we call for new configuration each time we bless (that way we
    # can use models that are context sensitive.)

    return bless +{}, $class;
  }

  sub ACCEPT_CONTEXT {
    my ($self, $c, @args) = @_;
    my $id = '__'. ref $self;

    # If there are odd args, that means the first one is either the item object
    # or item_id (assuming someone is using the DBIC model trait.
    my %args = ();
    if(scalar(@args) % 2) {
      # args are odd, so shift off the first one and figure it out.
      my $item_proto = shift @args;
      %args = @args;
      if(ref $item_proto eq 'HASH') {
        $args{params} = $item_proto;
      } elsif(ref $item_proto) {
        $args{item} = $item_proto;
      } else {
        $args{item_id} = $item_proto;
      }
    } else {
      %args = @args;
    }
    
    #If an action arg is passed and its a Catalyst::Action, make it a URL
    if(my $action = delete $args{action_from}) {
      my @action = ref $action eq 'ARRAY' ? @$action : ($action);
      $args{action} = ref $action ? $c->uri_for(@action) : $c->uri_for_action(@action);
    }

    if(my $form = $c->stash->{$id}) {
      $form->process( %args ) if keys(%args);
      return $form;
    }
    my $set = 0;
    unless($args{action}) {
      foreach my $action ($c->controller->get_action_methods) {
        my @attrs =  map {($_ =~m/^FormModelTarget\((.+)\)$/)[0]} @{$action->attributes||[]};
        foreach my $attr(@attrs) {
          my @parts = (@{$c->req->captures}, @{$c->req->args});
          $set=$c->uri_for($c->controller->action_for($action), (scalar @parts ? \@parts : ())) if ref($self) =~/$attr$/;
        }
      }
    }
    $args{action} = $set if $set;

    #If there is a schema model name use it
    !. $schema_args .q!

    # If its a POST, set the request params (you can always override 
    # later.
    if($c->req->method=~m/post/i) {
      $args{params} = $c->req->! .$self->body_method. q! unless exists $args{params};
      $args{posted} = 1 unless $args{posts};
    }

    my $no_auto_process = exists $args{no_auto_process} ?
    delete($args{no_auto_process}) : ! .$self->no_auto_process. q!;

    $c->stash->{$id} ||= do {
      %args = %{$self->merge_config_hashes($c->config_for($self->catalyst_component_name), \%args)};
      my $form = $self->_build_per_request_form(%args, ctx=>$c);
      $form->process() if
        $c->req->method=~m/post/i && \!$no_auto_process;
      $form;
    };

    return $c->stash->{$id};
  }

  sub _build_per_request_form {
    my ($self, %args) = @_;
    my $composed = Moose::Util::with_traits( '! .$form_package. q!' , (! .($roles||'').q!));
    my $form = $composed->new(%args);
  }

  __PACKAGE__->meta->make_immutable;

  package ! .$model_package. q!::IsValid;
  
  use Moose;
  extends 'Catalyst::Model';

  sub ACCEPT_CONTEXT {
    my ($self, $c, @args) = @_;
    my $form = $c->model('! .$model_name. q!', @args);
    return $form->is_valid ? $form : undef;
  } 

  __PACKAGE__->meta->make_immutable;

  !;

  eval $package or die "Trouble creating model: \n\n$@\n\n$package";
}

sub construct_model_package {
  my ($self, $form_package) = @_;
  return $self->_application .'::Model'. ($form_package=~m/${\$self->_application}(::.+$)/)[0];
}

sub construct_model_name {
  my ($self, $form_package) = @_;
  return ($form_package=~m/${\$self->_application}::(.+$)/)[0];
}

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

__PACKAGE__->meta->make_immutable;

=head1 NAME

Catalyst::Model::HTMLFormhandler - Proxy a directory of HTML::Formhandler forms

=head1 SYNOPSIS

    package MyApp::Model::Form;

    use Moose;
    extends 'Catalyst::Model::HTMLFormhandler';

    __PACKAGE__->config( form_namespace=>'MyApp::Form' );

And then using it in a controller:

    my $form = $c->model("Form::Email");  # Maps to MyApp::Email via MyApp:Model::Email

    # If the request is a POST, we process parameters automatically
    if($form->is_valid) {
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

  has aaa => (is=>'ro', required=>1);
  has bbb => (is=>'ro', required=>1);

  has_field 'email' => (
    type=>'Email',
    size => 96,
    required => 1);

You create a single L<Catalyst> model like this:

    package MyApp::Model::Form;

    use Moose;
    extends 'Catalyst::Model::HTMLFormhandler';

    __PACKAGE__->config( form_namespace=>'MyApp::Form' );

(Setting 'form_namespace' is optional, it defaults to the application
namespace plus "::Form" (in this example case that would be "MyApp::Form").

When you start your application it will register one model for each form
in the declared namespace.  So in the above example you should see a model
'MyApp::Model::Form::Email'.  This is a 'PerRequest' model since it does
ACCEPT_CONTEXT, it will generate a new instance of the form object once
per request scope.

It will also create one model with the ::IsValid suffix, which is a shortcut
to return a form only if its valid and undef otherwise.

You can set model configuration in the normal way, in your application general
configuration:

    package MyApp;
    use Catalyst;

    MyApp->config(
      'Model::Form::Email' => { aaa => 1000 }
    );
    
    MyApp->setup;

And you can pass additional args to the 'new' call of the form when you request
the form model:

     my $email = $c->model('Form::Email', bbb=>2000);

Additional args should be in the form of a hash, as in the above example OR you can
pass a single argument which is either an object, hashref or id followed by a hash
of remaining arguements.  These first argument gets set to the item or item_id
since its common to need:

    my $email = $c->model('Form::Email', $dbic_email_row, %args);

Or if its a HashRef, these are set to the params for processing.

The generated proxy will also add the ctx argument based on the current value of
$c, although using this may not be a good way to build well, decoupled applications.
It also will add the schema argument if you set a schema_model_name.

We offer two additional bit of useful suger:

If you pass argument 'action_from' with a value of an action object or an action 
private name that will set the form action value.  If 'action_from' is an arrayref
we dereference it when building the url.

By default if the request is a POST, we will process the request arguments and
return a form object that you can test for validity.  If you don't want this
behavior you can disable it by passing 'no_auto_process'.  For example:

    my $form = $c->model("Form::XXX", no_auto_process=>1)

=head1 ATTRIBUTES

This class defines the following attributes you may set via
standard L<Catalyst> configuration.

=head2 form_namespace

This is the target namespace that L<Module::Pluggable> uses to look for forms.
It defaults to 'MyApp::Form' (where 'MyApp' is you application namespace).

=head2 schema_model_name

The name of your DBIC Schema model (if you have one).  If you set this, we will
automatically instantiate your form classes with as schema => $model argument.
Useful if you are using L<HTML::FormHandler::Model::DBIC>.

=head2 roles

A list of L<Moose::Role>s that get applied automatically to each form model.

=head2 post_method

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

=head2 action_from

Shortcut to create the action value of the form.  If an object, we set 'action'
from $c->uri_for($object).  If its an arrayref from $c->uri_for( @$action_from).

=head1 ACTION ATTRIBUTES.

=head2 FormModelTarget( $model)

When used on an action, sets that action as the target of the form action.  This
is a bit experimental.  We get any needed captures and arguments from the current
request, this this only works if the target action has the same number of needed
args and captures.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Catalyst>, L<Catalyst::Model>, L<HTML::Formhandler>, L<Module::Pluggable>

=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
