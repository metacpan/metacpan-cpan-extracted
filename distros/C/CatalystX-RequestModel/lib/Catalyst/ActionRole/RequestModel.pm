package Catalyst::ActionRole::RequestModel;

use Moose::Role;
use Catalyst::Utils;
use CatalystX::RequestModel::Utils::InvalidContentType;
use String::CamelCase;
use Carp;

requires 'attributes', 'execute';

our $DEFAULT_BODY_POSTFIX = 'Body';
our $DEFAULT_BODY_PREFIX_NAMESPACE = '';
our $DEFAULT_QUERY_POSTFIX = 'Query';
our $DEFAULT_QUERY_PREFIX_NAMESPACE = '';

around 'execute', sub {
  my ($orig, $self, $controller, $ctx, @args) = @_;
  my @req_models = $self->_get_request_model($controller, $ctx);
  push @args, @req_models if @req_models;

  return $self->$orig($controller, $ctx, @args);
};

sub _default_body_postfix {
  my ($self, $controller, $ctx) = @_;
  return $controller->config->{body_model_postfix} if exists $controller->config->{body_model_postfix};
  return $controller->default_body_postfix($self, $ctx) if $controller->can('default_body_postfix');
  return $DEFAULT_BODY_POSTFIX;
}

sub _default_body_prefix_namespace {
  my ($self, $controller, $ctx) = @_;
  return $controller->config->{body_model_prefix_namespace} if exists $controller->config->{body_model_prefix_namespace};
  return $controller->default_body_prefix_namespace($self, $ctx) if $controller->can('default_body_prefix_namespace');
  return $DEFAULT_BODY_PREFIX_NAMESPACE;
}

sub _default_body_model {
  my ($self, $controller, $ctx) = @_;
  return $self->_default_body_model_for_action($controller, $ctx, $self);
}

sub _default_body_model_for_action {
  my ($self, $controller, $ctx, $action) = @_;
  return $controller->default_body_model($self, $ctx) if $controller->can('default_body_model');

  my $prefix = $self->_default_body_prefix_namespace($controller, $ctx);
  $prefix .= '::' if length($prefix) && $prefix !~m/::$/;

  my $action_namepart = String::CamelCase::camelize($action->reverse);
  $action_namepart =~s/\//::/g;
  
  my $postfix = $self->_default_body_postfix($controller, $ctx);
  my $model_component_name = "${prefix}${action_namepart}${postfix}";

  $ctx->log->debug("Initializing RequestModel: $model_component_name") if $ctx->debug;
  return $model_component_name;
}


sub _process_body_model {
  my ($self, $controller, $ctx, $model) = @_;
  return $model unless $model =~m/^~/;

  $model =~s/^~(::)?//;

  my $prefix = $self->_default_body_prefix_namespace($controller, $ctx);
  $prefix .= '::' if length($prefix) && $prefix !~m/::$/;

  my $namepart = String::CamelCase::camelize($controller->action_namespace);
  $namepart =~s/\//::/g;

  my $model_component_name = length("${prefix}${namepart}") ? "${prefix}${namepart}::${model}" : $model;

  $ctx->log->debug("Initializing Body Model: $model_component_name") if $ctx->debug;
  return $model_component_name;
}

sub _default_query_postfix {
  my ($self, $controller, $ctx) = @_;
  return $controller->config->{query_model_postfix} if exists $controller->config->{query_model_postfix};
  return $controller->default_query_postfix($self, $ctx) if $controller->can('default_query_postfix');
  return $DEFAULT_QUERY_POSTFIX;
}

sub _default_query_prefix_namespace {
  my ($self, $controller, $ctx) = @_;
  return $controller->config->{query_model_prefix_namespace} if exists $controller->config->{query_model_prefix_namespace};
  return $controller->default_query_prefix_namespace($self, $ctx) if $controller->can('default_query_prefix_namespace');
  return $DEFAULT_QUERY_PREFIX_NAMESPACE;
}

sub _default_query_model {
  my ($self, $controller, $ctx) = @_;
  return $self->_default_query_model_for_action($controller, $ctx, $self);
}

sub _default_query_model_for_action {
  my ($self, $controller, $ctx, $action) = @_;
  return $controller->default_query_model($self, $ctx) if $controller->can('default_query_model');

  my $prefix = $self->_default_query_prefix_namespace($controller, $ctx);
  $prefix .= '::' if length($prefix) && $prefix !~m/::$/;

  my $action_namepart = String::CamelCase::camelize($action->reverse);
  $action_namepart =~s/\//::/g;
  
  my $postfix = $self->_default_query_postfix($controller, $ctx);
  my $model_component_name = "${prefix}${action_namepart}${postfix}";

  $ctx->log->debug("Initializing Query Model: $model_component_name") if $ctx->debug;
  return $model_component_name;
}


sub _process_query_model {
  my ($self, $controller, $ctx, $model) = @_;
  return $model unless $model =~m/^~/;

  $model =~s/^~(::)?//;

  my $prefix = $self->_default_query_prefix_namespace($controller, $ctx);
  $prefix .= '::' if length($prefix) && $prefix !~m/::$/;

  my $namepart = String::CamelCase::camelize($controller->action_namespace);
  $namepart =~s/\//::/g;

  my $model_component_name = length("${prefix}${namepart}") ? "${prefix}${namepart}::${model}" : $model;

  $ctx->log->debug("Initializing Query Model: $model_component_name") if $ctx->debug;
  return $model_component_name;
}

sub _get_request_model {
  my ($self, $controller, $ctx) = @_;
  return unless exists $self->attributes->{RequestModel} ||
    exists $self->attributes->{QueryModel} || 
    exists $self->attributes->{BodyModel} ||
    exists $self->attributes->{QueryModelFor} ||
    exists $self->attributes->{BodyModelFor};

  my @models = map { $_=~s/^\s+|\s+$//g; $_ } # Allow RequestModel( Model ) and RequestModel (Model, Model2)
     map {split ',', $_||'' }  # Allow RequestModel(Model1,Model2)
    @{$self->attributes->{RequestModel} || []},
    @{$self->attributes->{BodyModel} || []};

  my $request_content_type = $ctx->req->content_type;

  if(exists($self->attributes->{RequestModel}) || exists($self->attributes->{BodyModel})) {
    @models = $self->_default_body_model($controller, $ctx) unless @models;
    @models = map {
      $self->_process_body_model($controller, $ctx, $_);
    } @models;
  }

  if(my ($action_name) = @{$self->attributes->{BodyModelFor}||[]}) {
    my $action = $controller->action_for($action_name) || croak "There is no action for '$action_name'";
    my $model = $self->_default_body_model_for_action($controller, $ctx, $action);
    @models = ($model);
  }

  # Allow GET to hijack form encoded
  $request_content_type = "application/x-www-form-urlencoded"
    if (($ctx->req->method eq 'GET') && !$request_content_type);

  my (@matching_models) = grep {
    my $model = $_;
    my @model_ct = $model->content_type;
    grep { lc($_) eq lc($request_content_type) || ($model->get_content_in eq 'query') } @model_ct;
  } map {
    $self->_build_request_model_instance($controller, $ctx, $_)
  } @models;

  if(exists($self->attributes->{RequestModel}) ||exists($self->attributes->{BodyModelFor}) || exists($self->attributes->{BodyModel})) {
    my ($content_type, @params) = $ctx->req->content_type; # handle "multipart/form-data; boundary=xYzZY"
    $ctx->log->warn("No matching models for content type '$content_type'") unless @matching_models;
    return CatalystX::RequestModel::Utils::InvalidContentType->throw(ct=>$content_type) unless @matching_models;
  }

  ## Query
  my @qmodels = map { $_=~s/^\s+|\s+$//g; $_ } # Allow RequestModel( Model ) and RequestModel (Model, Model2)
    map {split ',', $_||'' }  # Allow RequestModel(Model1,Model2)
    @{$self->attributes->{QueryModel} || []};

  if(exists($self->attributes->{QueryModel})) {
    @qmodels = $self->_default_query_model($controller, $ctx) unless @qmodels;
    @qmodels = map {
      $self->_process_query_model($controller, $ctx, $_);
    } @qmodels;
  }

  if(my ($action_name) = @{$self->attributes->{QueryModelFor}||[]}) {
    my $action = $controller->action_for($action_name) || croak "There is no action for '$action_name'";
    my $qmodel = $self->_default_query_model_for_action($controller, $ctx, $action);
    @qmodels = ($qmodel);
  }

  # Loop over all the found models.  Create each one and then filter by request
  # content type if that is defined.  This allows you to have different query paremters
  # based on the incoming content type.

  push @matching_models, grep {
    $_->has_content_type ? (lc($_->content_type) eq lc($request_content_type)) : 1;
  } map {
    $self->_build_request_model_instance($controller, $ctx, $_)
  } @qmodels;

  return @matching_models;
}

sub _build_request_model_instance {
  my ($self, $controller, $ctx, $request_model_class) = @_;
  my $request_model_instance = $ctx->model($request_model_class)
    || croak "Request Model '$request_model_class' doesn't exist";
  return $request_model_instance;
}

1;

=head1 NAME

Catalyst::ActionRole::RequestModel - Inflate a Request Model

=head1 SYNOPSIS

    package Example::Controller::Account;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub root :Chained(/root) PathPart('account') CaptureArgs(0)  { }

      sub update :POST Chained('root') PathPart('') Args(0) Does(RequestModel) BodyModel(AccountRequest) {
        my ($self, $c, $request_model) = @_;
        ## Do something with the $request_model
      }

      sub list :GET Chained('root') PathPart('') Args(0) Does(RequestModel) QueryModel(PagingModel) {
        my ($self, $c, $paging_model) = @_;
      }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Moves creating the request model into the action class execute phase.  The following two actions are essentially
the same in effect:

    sub update :POST Chained('root') PathPart('') Args(0) Does(RequestModel) BodyModel(AccountRequest) {
      my ($self, $c, $request_model) = @_;
      ## Do something with the $request_model
    }

    sub update :POST Chained('root') PathPart('') Args(0) {
      my ($self, $c) = @_;
      my $request_model = $c->model('AccountRequest');
      ## Do something with the $request_model
    }

The main reason for moving this into the action attributes line is the thought that it allows us
to declare the request model as meta data on the action and in the future we will be able to
introspect that meta data at application setup time to do things like generate an Open API specification.
Also, if you have several request models for the endpoint you can declare all of them on the
attributes line and we will match the incoming request to the best request model, or throw an exception
if none match.  So if you have more than one this saves you writing that boilerplate code to chose and
to handled the no match conditions.

You might also just find the code neater and more clean reading.  Downside is for people unfamiliar with
this system it might increase learning curve time.

=head1 ATTRITBUTE VALUE DEFAULTS

Although you may prefer to be explicit in defining the request model name, we infer default values for
both B<BodyModeL> and B<QueryModel> based on the action name and the controller namespace.  For example,

    package Example::Controller::Account;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub root :Chained(/root) PathPart('account') CaptureArgs(0)  { }

      sub update :POST Chained('root') PathPart('') Args(0) Does(RequestModel) BodyModel() {
        my ($self, $c, $request_model) = @_;
        ## Do something with the $request_model
      }

      sub list :GET Chained('root') PathPart('') Args(0) Does(RequestModel) QueryModel() {
        my ($self, $c, $paging_model) = @_;
      }

For the body model associated with the C<update> action, we will look for a model named
C<Example::Model::Account:UpdateBody> and for the query model associated with the C<list> action
we will look for a model named C<Example::Model::Account:ListQuery>.  You can change the default
'postfix' for both types of models by defining the following methods in your controller class:

    sub default_body_postfix { return 'Body' }
    sub default_query_postfix { return 'Query' }

Or via the controller configuration:

    __PACKAGE__->config(
      default_body_postfix => 'Body',
      default_query_postfix => 'Query',
    );

You can also prepend a namespace affix to either the body or query model name by defining the following
methods in your controller class:

    sub default_body_prefix_namespace { return 'MyApp::Model' }
    sub default_query_prefix_namespace { return 'MyApp::Model' }

Or via the controller configuration:

    __PACKAGE__->config(
      default_body_prefix_namespace => 'MyApp::Model',
      default_query_prefix_namespace => 'MyApp::Model',
    );

By default both namespace prefixes are empty, while the postfixes are 'Body' and 'Query' respectively.
This I think sets a reasonable pattern that you can reuse to help make your code more consistent while
allowing overrides for special cases.

Alternatively you can use the action namespace of the current controller as a namespace prefix for
the model name.  For example, if you have the following controller:

    package Example::Controller::Account;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub root :Chained(/root) PathPart('account') CaptureArgs(0)  { }

      ## You can use either ~ or ~:: to indicate 'under the current namespace'.

      sub update :POST Chained('root') PathPart('') Args(0) Does(RequestModel) BodyModel(~::RequestBody) {
        my ($self, $c, $request_model) = @_;
        ## Do something with the $request_model
      }

      sub list :GET Chained('root') PathPart('') Args(0) Does(RequestModel) QueryModel(~RequestQuery) {
        my ($self, $c, $paging_model) = @_;
      }

    __PACKAGE__->meta->make_immutable;

Then we will look for a model named C<Example::Model::Account::RequestBody>
and C<Example::Model::Account:RequestQuery> in your application namespace.  This approach also can
set a query and body namespace prefix but not the postfix.

=head1 METHOD ATTRIBUTES

This action role defines the following method attributes

=head2 RequestModel

Deprecated; for now this is an alias for BodyModel.  Use BodyModel instead and please convert your code to use.

=head2 BodyModel

Should be the name of a L<Catalyst::Model> subclass that does <CatalystX::RequestModel::DoesRequestModel>.  You may 
supply more than one value to handle different request content types (the code will match the incoming
content type to an available request model and throw an L<CatalystX::RequestModel::Utils::InvalidContentType>
exception if none of the available models match.

Example of an action with more than one request model, which will be matched based on request content type.

    sub update :POST Chained('root') PathPart('') Args(0) Does(RequestModel) BodyModel(AccountRequestForm) RequestModel(AccountRequestJSON) {
      my ($self, $c, $request_model) = @_;
      ## Do something with the $request_model
    }

Also, if more than one model matches, you'll get an instance of each matching model.

You can also leave the C<BodyModel> value empty; if you do so it use a default model based on the action private name.
For example if the private name is C</posts/user_comments> we will look for a model package name C<MyApp::Model::Posts::UserCommentsBody>.
Please see L</ATTRITBUTE VALUE DEFAULTS> for more on configurating and controlling how this works.


=head2 QueryModel

Should be the name of a L<Catalyst::Model> subclass that does L<CatalystX::QueryModel::DoesQueryModel>.  You may 
supply more than one value to handle different request content types (the code will match the incoming
content type to an available query model and throw an L<CatalystX::RequestModel::Utils::InvalidContentType>
exception if none of the available models match.

    sub root :Chained(/root) PathPart('users') CaptureArgs(0)  { }

      sub list :GET Chained('root') PathPart('') Args(0) Does(RequestModel) QueryModel(PagingModel) {
        my ($self, $c, $paging_model) = @_;
      }

B<NOTE>: In the situation where you have QueryModel and BodyModel for the same action, the request models
will be added first to the action argument list, followed by the query models, no matter what order they appear
in the action method declaration.  This is due to a limitation in how Catalyst collects the subroutine attributes
(we can't know the order of dissimilar attributes since this information is stored in a hash, not an array, and
L<Catalyst> allows a controller to inherit attributes from a base class, or from a role or even from configutation).
However the order of QueryModels and RequestModels independently are preserved.

You can also leave the C<QueryModel> value empty; if you do so it use a default model based on the action private name.
For example if the private name is C</posts/user_comments> we will look for a model package name C<MyApp::Model::Posts::UserCommentsQuery>.
Please see L</ATTRITBUTE VALUE DEFAULTS> for more on configurating and controlling how this works.

=head2 BodyModelFor

=head2 QueryModelFor

Use the default models for a different action in the same controller.  Useful for example if you have a lot of
basic CRUD style controllers where the create and update actions need the same parameters.

=head1 AUTHOR

See L<CatalystX::RequestModel>.
 
=head1 COPYRIGHT
 
See L<CatalystX::RequestModel>.

=head1 LICENSE
 
See L<CatalystX::RequestModel>.
 
=cut
