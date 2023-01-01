package Catalyst::ActionRole::RequestModel;

our $VERSION = '0.001';

use Moose::Role;
use Catalyst::Utils;
use CatalystX::RequestModel::Utils::InvalidContentType;

requires 'attributes', 'execute';

around 'execute', sub {
  my ($orig, $self, $controller, $ctx, @args) = @_;
  my @req_models = $self->_get_request_model($controller, $ctx);
  push @args, @req_models if @req_models;

  return $self->$orig($controller, $ctx, @args);
};

sub _get_request_model {
  my ($self, $controller, $ctx) = @_;
  return unless exists $self->attributes->{RequestModel} || exists $self->attributes->{QueryModel};

  my @models = map { $_=~s/^\s+|\s+$//g; $_ } # Allow RequestModel( Model ) and RequestModel (Model, Model2)
     map {split ',', $_ }  # Allow RequestModel(Model1,Model2)
    @{$self->attributes->{RequestModel} || []};

  my $request_content_type = $ctx->req->content_type;

  # Allow GET to hijack form encoded
  $request_content_type = "application/x-www-form-urlencoded"
    if (($ctx->req->method eq 'GET') && !$request_content_type);

  my (@matching_models) = grep {
    (lc($_->content_type) eq lc($request_content_type)) || ($_->get_content_in eq 'query')
  } map {
    $self->_build_request_model_instance($controller, $ctx, $_)
  } @models;

  if(exists $self->attributes->{RequestModel}) {
    return CatalystX::RequestModel::Utils::InvalidContentType->throw(ct=>$ctx->req->content_type) unless @matching_models;
  }

  ## Query
  my @qmodels = map { $_=~s/^\s+|\s+$//g; $_ } # Allow RequestModel( Model ) and RequestModel (Model, Model2)
    map {split ',', $_ }  # Allow RequestModel(Model1,Model2)
    @{$self->attributes->{QueryModel} || []};

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
    || die "Request Model '$request_model_class' doesn't exist";
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

      sub update :POST Chained('root') PathPart('') Args(0) Does(RequestModel) RequestModel(AccountRequest) {
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

    sub update :POST Chained('root') PathPart('') Args(0) Does(RequestModel) RequestModel(AccountRequest) {
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

=head1 METHOD ATTRIBUTES

This action role defines the following method attributes

=head2 RequestModel

Should be the name of a L<Catalyst::Model> subclass that does <CatalystX::RequestModel::DoesRequestModel>.  You may 
supply more than one value to handle different request content types (the code will match the incoming
content type to an available request model and throw an L<CatalystX::RequestModel::Utils::InvalidContentType>
exception if none of the available models match.

Example of an action with more than one request model, which will be matched based on request content type.

    sub update :POST Chained('root') PathPart('') Args(0) Does(RequestModel) RequestModel(AccountRequestForm) RequestModel(AccountRequestJSON) {
      my ($self, $c, $request_model) = @_;
      ## Do something with the $request_model
    }

Also, if more than one model matches, you'll get an instance of each matching model.

=head2 QueryModel

Should be the name of a L<Catalyst::Model> subclass that does L<CatalystX::QueryModel::DoesQueryModel>.  You may 
supply more than one value to handle different request content types (the code will match the incoming
content type to an available query model and throw an L<CatalystX::RequestModel::Utils::InvalidContentType>
exception if none of the available models match.

    sub root :Chained(/root) PathPart('users') CaptureArgs(0)  { }

      sub list :GET Chained('root') PathPart('') Args(0) Does(RequestModel) QueryModel(PagingModel) {
        my ($self, $c, $paging_model) = @_;
      }

B<NOTE>: In the situation where you have QueryModel and Request model for the same action, the request models
will be added first to the action argument list, followed by the query models, no matter what order they appear
in the action method declaration.  This is due to a limitation in how Catalyst collects the subroutine attributes
(we can't know the order of dissimilar attributes since this information is stored in a hash, not an array, and
L<Catalyst> allows a controller to inherit attributes from a base class, or from a role or even from configutation).
However the order of QueryModels and RequestModels independently are preserved.

=head1 AUTHOR

See L<CatalystX::RequestModel>.
 
=head1 COPYRIGHT
 
See L<CatalystX::RequestModel>.

=head1 LICENSE
 
See L<CatalystX::RequestModel>.
 
=cut
