package Activiti::Rest::Client;
use Activiti::Sane;
use Carp qw(confess);
use Moo;
use Data::Util qw(:check :validate);
use JSON qw(decode_json encode_json);
use URI::Escape qw(uri_escape);
use Activiti::Rest::Response;

our $VERSION = "0.1254";

#see: http://www.activiti.org/userguide

=head1 NAME

Activiti::Rest::Client - Low level client for the Activiti Rest API

=head1 AUTHORS

Nicolas Franck C<< <nicolas.franck at ugent.be> >>

=head1 NOTE

This is a work in progress. More documentation will be added in time

=head1 PROJECT

see http://www.activiti.org/userguide

=head1 SYNOPSIS

  my $client = Activiti::Rest::Client->new(
    url => 'http://kermit:kermit@localhost:8080/activiti-rest/service'
  );

  my $res = $client->process_definitions;

  die("no parsed content") unless $res->has_parsed_content;

  my $pdefs = $res->parsed_content;

  my @ids = map { $_->{id} } @{ $pdefs->{data} };
  for my $id(@ids){
    print Dumper($client->process_definition(processDefinitionId => $id)->parsed_content);
  }

=head1 CONSTRUCTOR parameters

=head2 url

  base url of the activiti rest api
  activiti-rest uses basic http authentication, so username and password should be included in the url

  e.g.

  http://kermit:kermit@localhost:8080/activiti-rest/service

=cut

has url => (
  is => 'ro',
  isa => sub { $_[0] =~ /^https?:\/\//o or die("url must be a valid web url\n"); },
  required => 1
);

=head2 timeout

  timeout in seconds when connecting to the activiti rest api

  default value is 180

=cut

has timeout => (
  is => 'ro',
  isa => sub { is_integer($_[0]) && $_[0] >= 0 || die("timeout should be natural number"); },
  lazy => 1,
  default => sub { 180; }
);
has ua => (
  is => 'ro',
  lazy => 1,
  builder => '_build_ua'
);
sub _build_ua {
  require Activiti::Rest::UserAgent::LWP;
  Activiti::Rest::UserAgent::LWP->new(
    url => $_[0]->url(),
    timeout => $_[0]->timeout()
  );
}

=head1 METHODS

=head2 deployments

  Retrieve list of Deployments

  parameters: see user guide (http://www.activiti.org/userguide/index.html#N13293)

  equal to rest call:

    GET repository/deployments

=cut
sub deployments {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/repository/deployments",
    params => \%args,
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 deployment

  Get a deployment

  parameters:
    deploymentId

  other parameters: see user guide (http://www.activiti.org/userguide/index.html#N1332E)

  equal to rest call:

    GET repository/deployments/:deploymentId

=cut

sub deployment {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/repository/deployments/".uri_escape($args{deploymentId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 deployment_resources

  List resources in a deployment

  parameters:

    deploymentId

  other parameters: see user guide (http://www.activiti.org/userguide/index.html#N133F1)

  equal to rest call:

    GET repository/deployments/:deploymentId/resources

=cut

sub deployment_resources {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/repository/deployments/".uri_escape($args{deploymentId})."/resources",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}

=head2 deployment_resource

  Get a deployment resource

  parameters:

    deploymentId
    resourceId

  other parameters: see user guide (http://www.activiti.org/userguide/index.html#N1345B)

  equal to rest call:

    GET repository/deployments/:deploymentId/resources/:resourceId

=cut

sub deployment_resource {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/repository/deployments/".uri_escape($args{deploymentId})."/resources/".uri_escape($args{resourceId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 process_definitions

  List of process definitions

  parameters: see user guide (http://www.activiti.org/userguide/index.html#N13520)

  equal to rest call:

    GET repository/process-definitions

=cut

sub process_definitions {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/repository/process-definitions",
    params => \%args,
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 process_definition

  Get a process definition

  parameters:

    processDefinitionId

  other parameters: see user guide (http://www.activiti.org/userguide/index.html#N13605)

  equal to rest call:

    GET repository/process-definitions/:processDefinitionId

=cut

sub process_definition {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/repository/process-definitions/".uri_escape($args{processDefinitionId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 process_definition_resource_data

  Get a process definition resource content

  parameters:

    processDefinitionId

  equal to rest call:

    GET repository/process-definitions/:processDefinitionId/resourcedata

=cut

sub process_definition_resource_data {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/repository/process-definitions/".uri_escape($args{processDefinitionId})."/resourcedata",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}

=head2 process_definition_model

  Get a process definition BPMN model

  parameters:

    processDefinitionId

  equal to rest call:

    GET repository/process-definitions/:processDefinitionId/model

=cut

sub process_definition_model {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/repository/process-definitions/".uri_escape($args{processDefinitionId})."/model",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 process_definition_identity_links

  Get all candidate starters for a process-definition

  parameters:

    processDefinitionId

  equal to rest call:

    GET repository/process-definitions/:processDefinitionId/identitylinks

=cut
sub process_definition_identity_links {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/repository/process-definitions/".uri_escape($args{processDefinitionId})."/identitylinks",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 process_definition_identity_link

  Get a candidate starter from a process definition

  parameters: (see http://www.activiti.org/userguide/index.html#N138A9)

    processDefinitionId
    family
    identityId

  equal to rest call:

    GET repository/process-definitions/:processDefinitionId/identitylinks/:family/:identityId

=cut
sub process_definition_identity_link {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/repository/process-definitions/".uri_escape($args{processDefinitionId})."/identitylinks/".uri_escape($args{family})."/".uri_escape($args{identityId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 models

  Get a list of models

  Parameters: see user guide (http://www.activiti.org/userguide/index.html#N1390A)

  equal to rest call:

    GET repository/models

=cut
sub models {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/repository/models",
    params => \%args,
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 models

  Get a model

  Parameters:

    modelId

  equal to rest call:

    GET repository/models/:modelId

=cut

sub model {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/repository/models/".uri_escape($args{modelId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 process_instances

  List of process instances

  Parameters: see user guide (http://www.activiti.org/userguide/index.html#restProcessInstancesGet)

  equal to rest call:

    GET runtime/process-instances

=cut

sub process_instances {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/process-instances",
    params => \%args,
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 process_instance

  Get a process instance

  Parameters:

    processInstanceId

  equal to rest call:

    GET runtime/process-instances/:processInstanceId

=cut

sub process_instance {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/process-instances/".uri_escape($args{processInstanceId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub delete_process_instance {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/process-instances/".uri_escape($args{processInstanceId}),
    params => { deleteReason => $args{deleteReason} },
    method => "DELETE"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub suspend_process_instance {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/process-instances/".uri_escape($args{processInstanceId}),
    params => {},
    headers => {
      'Content-Type' => "application/json",
      Content => encode_json({ action => "suspend" })
    },
    method => "PUT"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub activate_process_instance {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/process-instances/".uri_escape($args{processInstanceId}),
    params => {},
    headers => {
      'Content-Type' => "application/json",
      Content => encode_json({ action => "activate" })
    },
    method => "PUT"
  );
  Activiti::Rest::Response->from_http_response($res);
}

=head2 query_process_instances

  Query process instances

  Parameters: see user guide (http://www.activiti.org/userguide/index.html#N13E2A)

  equal to rest call:

    POST runtime/process-instances

=cut

sub query_process_instances {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/query/process-instances",
    params => {},
    method => "POST",
    headers => {
      'Content-Type' => "application/json",
      Content => encode_json($args{content})
    }
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 start_process_instance

  Start a process instance

  Parameters: see user guide (http://www.activiti.org/userguide/index.html#N13CE6)

  equal to rest call:

    POST runtime/process-instances

=cut

sub start_process_instance {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/process-instances",
    params => {},
    method => "POST",
    headers => {
      'Content-Type' => "application/json",
      Content => encode_json($args{content})
    }
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 process_instance_identitylinks

  Get involved people for process instance

  Parameters:

    processInstanceId

  equal to rest call:

    GET runtime/process-instances/:processInstanceId/identitylinks

=cut

sub process_instance_identitylinks {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/process-instances/".uri_escape($args{processInstanceId})."/identitylinks",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 process_instance_variables

  List of variables for a process instance

  Parameters:

    processInstanceId

  equal to rest call:

    GET runtime/process-instances/:processInstanceId/variables

=cut

sub process_instance_variables {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/process-instances/".uri_escape($args{processInstanceId})."/variables",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 process_instance_variable

  Get a variable for a process instance

  Parameters:

    processInstanceId
    variableName

  equal to rest call:

    GET runtime/process-instances/:processInstanceId/variables/:variableName

=cut

sub process_instance_variable {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/process-instances/".uri_escape($args{processInstanceId})."/variables/".uri_escape($args{variableName}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub update_process_instance_variable {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/process-instances/".uri_escape($args{processInstanceId})."/variables/".uri_escape($args{variableName}),
    params => {},
    method => "PUT",
    headers => {
      'Content-Type' => "application/json",
      Content => encode_json($args{content})
    }
  );
  Activiti::Rest::Response->from_http_response($res);
}
#DEPRECATED!
sub signal_process_instance {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/process-instance/".uri_escape($args{processInstanceId})."/signal",
    params => {},
    method => "POST",
    headers => {
      'Content-Type' => "application/json",
      Content => encode_json($args{content})
    }
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 process_instance_diagram

  Get a diagram for a process instance

  Parameters:

    processInstanceId

  equal to rest call:

    GET runtime/process-instances/:processInstanceId/diagram

  when successfull the "content_type" of the response is "image/png" and "content" is equal to the image data

=cut

#return: png image data
sub process_instance_diagram {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/process-instances/".uri_escape($args{processInstanceId})."/diagram",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 executions

  List of executions

  Parameters: see user guide (http://www.activiti.org/userguide/index.html#restExecutionsGet)

  equal to rest call:

    GET repository/executions

=cut

sub executions {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/executions",
    params => \%args,
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub query_executions {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/query/executions",
    params => {},
    method => "POST",
    headers => {
      'Content-Type' => "application/json",
      Content => encode_json($args{content})
    }
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 query_executions

    Query executions

    Parameters in request body (i.e. 'content' hash)

    equal to rest call:

        POST query/executions
=cut
sub signal_execution {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/executions/".uri_escape($args{executionId}),
    params => {},
    method => "PUT",
    headers => {
      'Content-Type' => "application/json",
      Content => encode_json($args{content})
    }
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 signal_execution

    send signal to execution

    equal to rest call:

        PUT runtime/executions/{executionId}
=cut

=head2 execution

  Get an execution

  Parameters:

    executionId

  equal to rest call:

    GET repository/executions/:executionId

=cut

sub execution {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/executions/".uri_escape($args{executionId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 execution_activities

  Get active activities in an execution

  Parameters:

    executionId

  equal to rest call:

    GET repository/executions/:executionId/activities

=cut

sub execution_activities {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/executions/".uri_escape($args{executionId})."/activities",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 execution_variables

  List of variables for an execution

  Parameters:

    executionId

  equal to rest call:

    GET repository/executions/:executionId/variables

=cut

sub execution_variables {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/executions/".uri_escape($args{executionId})."/variables",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 tasks

  List of tasks

  Parameters: see user guide (http://www.activiti.org/userguide/index.html#restTasksGet)

  equal to rest call:

    GET runtime/tasks

=cut

sub tasks {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/tasks",
    params => \%args,
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 query_tasks

  Query for tasks

  Parameters: see user guide (http://www.activiti.org/userguide/index.html#N148B7)

  equal to rest call:

    POST query/tasks

=cut

sub query_tasks {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/query/tasks",
    params => {},
    method => "POST",
    headers => {
      'Content-Type' => "application/json",
      Content => encode_json($args{content})
    }
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub query_historic_task_instances {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/query/historic-task-instances",
    params => {},
    method => "POST",
    headers => {
      'Content-Type' => "application/json",
      Content => encode_json($args{content})
    }
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 task

  Get a task

  Parameters:

    taskId

  equal to rest call:

    GET runtime/tasks/:taskId

=cut

sub task {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/tasks/".uri_escape($args{taskId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 update_task

  Update a task

  Parameters:

    taskId

  Body parameters: see user guide (http://www.activiti.org/userguide/index.html#N148FA)

  equal to rest call:

    PUT runtime/tasks/:taskId

=cut

sub update_task {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/tasks/".uri_escape($args{taskId}),
    params => {},
    method => "PUT",
    headers => {
      'Content-Type' => "application/json",
      Content => encode_json($args{content})
    }
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 task_variables

  Get all variables for a task

  Parameters:

    taskId
    scope (global|local)

  equal to rest call:

    GET runtime/tasks/:taskId/variables?scope=:scope

=cut

sub task_variables {
  my($self,%args)=@_;
  my $taskId = delete $args{taskId};
  my $scope = delete $args{scope};
  my $params = {};
  $params->{scope} = $scope if is_string($scope);
  my $res = $self->ua->request(
    path => "/runtime/tasks/".uri_escape($taskId)."/variables",
    params => $params,
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 task_variable

  Get one variable for a task

  Parameters:

    taskId
    scope (global|local)

  equal to rest call:

    GET runtime/tasks/:taskId/variables/:variableName?scope=:scope

=cut

sub task_variable {
  my($self,%args)=@_;
  my $taskId = delete $args{taskId};
  my $variableName = delete $args{variableName};
  my $scope = delete $args{scope};
  my $params = {};
  $params->{scope} = $scope if is_string($scope);
  my $res = $self->ua->request(
    path => "/runtime/tasks/".uri_escape($taskId)."/variables/$variableName",
    params => $params,
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}

=head2 task_identity_links

  Get all identity links for a task

  Parameters:

    taskId

  equal to rest call:

    GET runtime/tasks/:taskId/identitylinks

=cut

sub task_identity_links {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/tasks/".uri_escape($args{taskId})."/identitylinks",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 task_identity_links_users

=head2 task_identity_links_groups

  Get all identity links for a task for either groups or users

  Parameters:

    taskId

  equal to rest call:

    GET runtime/tasks/:taskId/identitylinks/(users|groups)

=cut

sub task_identity_links_users {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/tasks/".uri_escape($args{taskId})."/identitylinks/users",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub task_identity_links_groups {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/tasks/".uri_escape($args{taskId})."/identitylinks/groups",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub task_identity_link {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/tasks/".uri_escape($args{taskId})."/identitylinks/".uri_escape($args{family})."/".uri_escape($args{identityId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 task_comments

  Get all comments on a task

  Parameters:

    taskId

  equal to rest call:

    GET runtime/tasks/:taskId/comments

=cut

sub task_comments {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/tasks/".uri_escape($args{taskId})."/comments",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 task_comment

  Get a comments on a task

  Parameters:

    taskId
    commentId

  equal to rest call:

    GET runtime/tasks/:taskId/comments/:commentId

=cut

sub task_comment {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/tasks/".uri_escape($args{taskId})."/comments/".uri_escape($args{commentId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 task_events

  Get all events for a task

  Parameters:

    taskId

  equal to rest call:

    GET runtime/tasks/:taskId/events

=cut

sub task_events {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/tasks/".uri_escape($args{taskId})."/events",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 task_event

  Get an event for a task

  Parameters:

    taskId
    eventId

  equal to rest call:

    GET runtime/tasks/:taskId/events/:eventId

=cut

sub task_event {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/tasks/".uri_escape($args{taskId})."/events/".uri_escape($args{eventId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 task_attachments

  Get all attachments on a task

  Parameters:

    taskId

  equal to rest call:

    GET runtime/tasks/:taskId/attachments

=cut

sub task_attachments {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/tasks/".uri_escape($args{taskId})."/attachments",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 task_attachment

  Get an attachment on a task

  Parameters:

    taskId
    attachmentId

  equal to rest call:

    GET runtime/tasks/:taskId/comments/:attachmentId

=cut

sub task_attachment {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/tasks/".uri_escape($args{taskId})."/attachments/".uri_escape($args{attachmentId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 task_attachment_content

  Get the content for an attachment on a task

  Parameters:

    taskId
    attachmentId

  equal to rest call:

    GET runtime/tasks/:taskId/attachments/:attachmentId/content

=cut

sub task_attachment_content {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/runtime/tasks/".uri_escape($args{taskId})."/attachments/".uri_escape($args{attachmentId})."/content",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 historic_process_instances

  List of historic process instances

  Parameters: see user guide (http://www.activiti.org/userguide/index.html#restHistoricProcessInstancesGet)

  equal to rest call:

    GET history/historic-process-instances

=cut

sub historic_process_instances {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/history/historic-process-instances",
    params => \%args,
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 query_historic_process_instances

  Query for historic process instances

  Parameters: see user guide (http://www.activiti.org/userguide/index.html#N153C2)

  equal to rest call:

    POST history/historic-process-instances

=cut
sub query_historic_process_instances {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/query/historic-process-instances",
    params => {},
    method => "POST",
    headers => {
      'Content-Type' => "application/json",
      Content => encode_json($args{content})
    }
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 historic_process_instance

  Get a historic process instance

  Parameters:

    processInstanceId

  equal to rest call:

    GET history/historic-process-instances/:processInstanceId

=cut

sub historic_process_instance {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/history/historic-process-instances/".uri_escape($args{processInstanceId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 delete_historic_process_instance

  Delete a historic process instance

  Parameters:

    processInstanceId

  equal to rest call:

    DELETE history/historic-process-instances/:processInstanceId

=cut

sub delete_historic_process_instance {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/history/historic-process-instances/".uri_escape($args{processInstanceId}),
    params => {},
    method => "DELETE"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 historic_process_instance_comments

  Get all comments on a historic process instance

  Parameters:

    processInstanceId

  equal to rest call:

    GET history/historic-process-instances/:processInstanceId/comments

=cut

sub historic_process_instance_comments {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/history/historic-process-instances/".uri_escape($args{processInstanceId})."/comments",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 historic_process_instance_comment

  Get a comment on a historic process instance

  Parameters:

    processInstanceId
    commentId

  equal to rest call:

    GET history/historic-process-instances/:processInstanceId/comments/:commentId

=cut

sub historic_process_instance_comment {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/history/historic-process-instances/".uri_escape($args{processInstanceId})."/comments/".uri_escape($args{commentId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 historic_task_instances

  Get historic task instances

  Parameters: see user guide (http://www.activiti.org/userguide/index.html#restHistoricTaskInstancesGet)

  equal to rest call:

    GET history/historic-task-instances

=cut

sub historic_task_instances {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/history/historic-task-instances",
    params => \%args,
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 historic_variable_instances

  Get historic variable instances, either from tasks or process instances

  Parameters: see user guide (http://www.activiti.org/userguide/index.html#restHistoricVariableInstancesGet)

  equal to rest call:

    GET history/historic-variable-instances

=cut

sub historic_variable_instances {
    my($self,%args) = @_;
    my $res = $self->ua->request(
        path => "/history/historic-variable-instances",
        params => \%args,
        method => "GET"
    );
    Activiti::Rest::Response->from_http_response($res);
}
=head2 query_historic_variable_instances

  Query historic variable instances, either from tasks or process instances

  Parameters: see user guide (http://www.activiti.org/userguide/index.html#N15B00)

  equal to rest call:

    POST query/historic-variable-instances

=cut

sub query_historic_variable_instances {
    my($self,%args)=@_;
    my $res = $self->ua->request(
        path => "/query/historic-variable-instances",
        params => {},
        method => "POST",
        headers => {
            'Content-Type' => "application/json",
            Content => encode_json($args{content})
        }
    );
    Activiti::Rest::Response->from_http_response($res);
}
=head2 historic_task_instance

  Get a historic task instance

  Parameters:

    taskId

  equal to rest call:

    GET history/historic-task-instances/:taskId

=cut

sub historic_task_instance {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/history/historic-task-instances/".uri_escape($args{taskInstanceId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
=head2 historic_task_instance_identity_links

  Get the identity links of a historic task instance

  Parameters:

    taskId

  equal to rest call:

    GET history/historic-task-instances/:taskId/identitylinks

=cut

sub historic_task_instance_identity_links {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/history/historic-task-instances/".uri_escape($args{taskInstanceId})."/identitylinks",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub historic_activity_instances {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/history/historic-activity-instances",
    params => \%args,
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub historic_activity_instance {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/history/historic-activity-instances/".uri_escape($args{activityInstanceId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub historic_detail {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/history/historic-detail",
    params => \%args,
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub query_historic_detail {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/query/historic-detail",
    params => {},
    method => "POST",
    headers => {
      'Content-Type' => "application/json",
      Content => encode_json($args{content})
    }
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub users {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/identity/users",
    params => \%args,
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub user {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/identity/users/".uri_escape($args{userId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub user_info {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/identity/users/".uri_escape($args{userId})."/info",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}

sub groups {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/identity/groups",
    params => \%args,
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub group {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/identity/groups/".uri_escape($args{groupId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}

#forms
sub form {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/form/form-data",
    params => \%args,
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub update_form {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/form/form-data",
    params => \%args,
    method => "POST",
    headers => {
      'Content-Type' => "application/json",
      Content => encode_json($args{content})
    }
  );
  Activiti::Rest::Response->from_http_response($res);
}

sub jobs {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/management/jobs",
    params => \%args,
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub job {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/management/jobs/".uri_escape($args{jobId}),
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub job_exception_stacktrace {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/management/jobs/".uri_escape($args{jobId})."/exception-stacktrace",
    params => {},
    method => "GET"
  );
  Activiti::Rest::Response->from_http_response($res);
}

sub delete_job {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/management/jobs/".uri_escape($args{jobId}),
    params => {},
    method => "DELETE"
  );
  Activiti::Rest::Response->from_http_response($res);
}
sub execute_job {
  my($self,%args)=@_;
  my $res = $self->ua->request(
    path => "/management/jobs/".uri_escape($args{jobId}),
    params => {},
    method => "POST",
    headers => {
      'Content-Type' => "application/json",
      Content => encode_json({ action => "execute" })
    }
  );
  Activiti::Rest::Response->from_http_response($res);
}

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
