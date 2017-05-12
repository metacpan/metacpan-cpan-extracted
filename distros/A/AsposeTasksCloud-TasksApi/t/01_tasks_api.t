use lib '../lib';
use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON;
use File::Slurp; # From CPAN

use AsposeStorageCloud::StorageApi;
use AsposeStorageCloud::ApiClient;
use AsposeStorageCloud::Configuration;

use AsposeTasksCloud::TasksApi;
use AsposeTasksCloud::ApiClient;
use AsposeTasksCloud::Configuration;

use AsposeTasksCloud::Object::Calendar;
use AsposeTasksCloud::Object::DocumentProperty;
use AsposeTasksCloud::Object::TaskLink;
use AsposeTasksCloud::Object::Task;
use AsposeTasksCloud::Object::ResourceAssignment;

use_ok('AsposeTasksCloud::Configuration');
use_ok('AsposeTasksCloud::ApiClient');
use_ok('AsposeTasksCloud::TasksApi');


$AsposeTasksCloud::Configuration::app_sid = 'XXX';
$AsposeTasksCloud::Configuration::api_key = 'XXX';

$AsposeTasksCloud::Configuration::debug = 1;

if(not defined $AsposeTasksCloud::Configuration::app_sid or $AsposeTasksCloud::Configuration::app_sid =~ /^XXX/i){
		done_testing();
    	exit;
  }else{
  	$AsposeStorageCloud::Configuration::app_sid = $AsposeTasksCloud::Configuration::app_sid
  }
    
if (not defined $AsposeTasksCloud::Configuration::api_key or $AsposeTasksCloud::Configuration::api_key =~ /^XXX/i){
	done_testing();
    exit;
}else{
	$AsposeStorageCloud::Configuration::api_key = $AsposeTasksCloud::Configuration::api_key;
}

my $data_path = './data/';

if (not -d $data_path){
	done_testing();
    exit;
}

if($AsposeTasksCloud::Configuration::debug){
	$AsposeStorageCloud::Configuration::debug = $AsposeTasksCloud::Configuration::debug;
}

my $storageApi = AsposeStorageCloud::StorageApi->new();
my $tasksApi = AsposeTasksCloud::TasksApi->new();

subtest 'testDeleteProjectAssignment' => sub {
	my $name = 'sample-project-2.mpp';
	my $assignmentUid = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->DeleteProjectAssignment(name => $name, assignmentUid => $assignmentUid);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetTaskDocument' => sub {
	my $name = 'sample-project-2.mpp';
	my $assignmentUid = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->GetTaskDocument(name => $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::DocumentResponse');
};


subtest 'testGetTaskDocumentWithFormat' => sub {
	my $name = 'sample-project-2.mpp';
	my $format = 'pdf';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->GetTaskDocumentWithFormat(name => $name, format => $format);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetProjectAssignments' => sub {
	my $name = 'sample-project-2.mpp';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->GetProjectAssignments(name => $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::AssignmentItemsResponse');
};

subtest 'testPostProjectAssignment' => sub {
	my $name = 'sample-project-2.mpp';
	my $taskUid = 1;
	my $resourceUid = 1;	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->PostProjectAssignment(name => $name, taskUid => $taskUid, resourceUid => $resourceUid);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::AssignmentItemResponse');
};

subtest 'testGetProjectAssignment' => sub {
	my $name = 'sample-project-2.mpp';
	my $assignmentUid = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->GetProjectAssignment(name => $name, assignmentUid => $assignmentUid);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::AssignmentResponse');
};

subtest 'testPostProjectCalendar' => sub {
	my $name = 'sample-project.mpp';
	my @calBody = AsposeTasksCloud::Object::Calendar->new('Name' => 'TestCalender', 'Uid' => 0);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->PostProjectCalendar(name => $name, body => @calBody);
 	is($response->{'Status'}, "Created");
 	isa_ok($response, 'AsposeTasksCloud::Object::CalendarItemResponse');
};

subtest 'testGetProjectCalendars' => sub {
	my $name = 'sample-project-2.mpp';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->GetProjectCalendars(name => $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::CalendarItemsResponse');
};

subtest 'testGetProjectCalendar' => sub {
	my $name = 'sample-project-2.mpp';
	my $calendarUid = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->GetProjectCalendar(name => $name, calendarUid => $calendarUid);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::CalendarResponse');
};

subtest 'testDeleteProjectCalendar' => sub {
	my $name = 'sample-project.mpp';
	my $calendarUid = 2;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->DeleteProjectCalendar(name => $name, calendarUid => $calendarUid);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostCalendarExceptions' => sub {
	my $name = 'sample-project.mpp';
	my $calendarUid = 2;
	my @calBody = AsposeTasksCloud::Object::Calendar->new('Name' => 'Test', 'FromDate' => '2016-05-26', 'ToDate' => '2016-05-28');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->PostCalendarExceptions(name => $name, calendarUid => $calendarUid, body =>@calBody);
 	is($response->{'Status'}, "Created");
};

subtest 'testPutCalendarException' => sub {
	my $name = 'sample-project.mpp';
	my $calendarUid = 1;
	my $index = 1;
	my @calBody = AsposeTasksCloud::Object::Calendar->new('Name' => 'Test', 'FromDate' => '2016-05-26', 'ToDate' => '2016-05-28');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->PutCalendarException(name => $name, calendarUid => $calendarUid, index => $index, body =>@calBody);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetCalendarExceptions' => sub {
	my $name = 'sample-project.mpp';
	my $calendarUid = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->GetCalendarExceptions(name => $name, calendarUid => $calendarUid);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::CalendarExceptionsResponse');
};

subtest 'testDeleteCalendarException' => sub {
	my $name = 'sample-project.mpp';
	my $calendarUid = 1;
	my $index = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->DeleteCalendarException(name => $name, calendarUid => $calendarUid, index => $index);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetCriticalPath' => sub {
	my $name = 'sample-project.mpp';
	my $assignmentUid = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->GetCriticalPath(name => $name, assignmentUid => $assignmentUid);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::TaskItemsResponse');
};

subtest 'testGetDocumentProperties' => sub {
	my $name = 'sample-project.mpp';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->GetDocumentProperties(name => $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::DocumentPropertiesResponse');
};

subtest 'testGetDocumentProperty' => sub {
	my $name = 'sample-project.mpp';
	my $propertyName = 'Title';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->GetDocumentProperty(name => $name, propertyName => $propertyName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::DocumentPropertyResponse');
};

subtest 'testPutDocumentProperty' => sub {
	my $name = 'sample-project.mpp';
	my $propertyName = 'Title';
	my @docpropBody = AsposeTasksCloud::Object::DocumentProperty->new('Name' => 'Title', 'Value' => 'New Title');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->PutDocumentProperty(name => $name, propertyName => $propertyName, body=>@docpropBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::DocumentPropertyResponse');
};

subtest 'testPostDocumentProperty' => sub {
	my $name = 'sample-project.mpp';
	my $propertyName = 'Title';
	my @docpropBody = AsposeTasksCloud::Object::DocumentProperty->new('Name' => 'Title', 'Value' => 'New Title');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");;
 	$response = $tasksApi->PostDocumentProperty(name => $name, propertyName => $propertyName, body=>@docpropBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::DocumentPropertyResponse');
};

subtest 'testGetExtendedAttributes' => sub {
	my $name = 'ExtendedAttribute.mpp';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->GetExtendedAttributes(name => $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::ExtendedAttributeItemsResponse');
};

subtest 'testGetExtendedAttributeByIndex' => sub {
	my $name = 'ExtendedAttribute.mpp';
	my $index = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->GetExtendedAttributeByIndex(name => $name, index=>$index);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::ExtendedAttributeResponse');
};

subtest 'testDeleteExtendedAttributeByIndex' => sub {
	my $name = 'ExtendedAttribute.mpp';
	my $index = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->DeleteExtendedAttributeByIndex(name => $name, index=>$index);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetOutlineCodes' => sub {
	my $name = 'Outlinecode.mpp';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->GetOutlineCodes(name => $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::OutlineCodeItemsResponse');
};

subtest 'testGetOutlineCodeByIndex' => sub {
	my $name = 'Outlinecode.mpp';
	my $index = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->GetOutlineCodeByIndex(name => $name, index=>$index);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::OutlineCodeResponse');
};

subtest 'testDeleteOutlineCodeByIndex' => sub {
	my $name = 'Outlinecode.mpp';
	my $index = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->DeleteOutlineCodeByIndex(name => $name, index=>$index);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetReportPdf' => sub {
	my $name = 'sample-project.mpp';
	my $type = 'WorkOverview';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->GetReportPdf(name => $name, type=>$type);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostProjectResource' => sub {
	my $name = 'sample-project.mpp';
	my $resourceName = 'Resource6';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->PostProjectResource(name => $name, resourceName=>$resourceName);
 	is($response->{'Status'}, "Created");
 	isa_ok($response, 'AsposeTasksCloud::Object::ResourceItemResponse');
};

subtest 'testGetProjectResources' => sub {
	my $name = 'sample-project.mpp';
	my $assignmentUid = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->GetProjectResources(name => $name, assignmentUid=>$assignmentUid);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::ResourceItemsResponse');
};

subtest 'testGetProjectResource' => sub {
	my $name = 'sample-project.mpp';
	my $resourceUid = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->GetProjectResources(name => $name, resourceUid=>$resourceUid);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::ResourceItemsResponse');
};

subtest 'testDeleteProjectResource' => sub {
	my $name = 'sample-project.mpp';
	my $resourceUid = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->DeleteProjectResource(name => $name, resourceUid=>$resourceUid);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetResourceAssignments' => sub {
	my $name = 'sample-project-2.mpp';
	my $resourceUid = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->GetResourceAssignments(name => $name, resourceUid=>$resourceUid);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::AssignmentsResponse');
};

subtest 'testGetRiskAnalysisReport' => sub {
	my $name = 'sample-project-2.mpp';
	my $taskUid = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->GetRiskAnalysisReport(name => $name, taskUid=>$taskUid);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetTaskLinks' => sub {
	my $name = 'sample-project-2.mpp';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->GetTaskLinks(name => $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::TaskLinksResponse'); 	
};

subtest 'testPostTaskLink' => sub {
	my $name = 'sample-project-2.mpp';
	my @taskBody = AsposeTasksCloud::Object::TaskLink->new('Index' => 2, 'PredecessorUid' => 1, 'SuccessorUid' => 2);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->PostTaskLink(name => $name, body=>@taskBody);
 	is($response->{'Status'}, "OK");
};

subtest 'testPutTaskLink' => sub {
	my $name = 'sample-project.mpp';
	my $index = 1;
	my @taskBody = AsposeTasksCloud::Object::TaskLink->new('Index' => 1, 'PredecessorUid' => 0, 'SuccessorUid' => 1);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->PutTaskLink(name => $name, index => $index, body=>@taskBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::TaskLinkResponse'); 
};

subtest 'testDeleteTaskLink' => sub {
	my $name = 'sample-project.mpp';
	my $index = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->DeleteTaskLink(name => $name, index => $index);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetProjectTasks' => sub {
	my $name = 'sample-project-2.mpp';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->GetProjectTasks(name => $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::TaskItemsResponse'); 
};

subtest 'testGetProjectTask' => sub {
	my $name = 'sample-project-2.mpp';
	my $taskUid = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->GetProjectTasks(name => $name, taskUid => $taskUid);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::TaskItemsResponse'); 
};

subtest 'testDeleteProjectTask' => sub {
	my $name = 'sample-project-2.mpp';
	my $taskUid = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->DeleteProjectTask(name => $name, taskUid => $taskUid);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetTaskAssignments' => sub {
	my $name = 'sample-project-2.mpp';
	my $taskUid = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->GetTaskAssignments(name => $name, taskUid => $taskUid);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::AssignmentsResponse'); 
};

subtest 'testPutMoveTask' => sub {
	my $name = 'sample-project.mpp';
	my $taskUid = 1;
	my $parentTaskUid = 2;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->PutMoveTask(name => $name, taskUid => $taskUid, parentTaskUid => $parentTaskUid);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetTaskRecurringInfo' => sub {
	my $name = 'sample-project-2.mpp';
	my $taskUid = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->GetTaskRecurringInfo(name => $name, taskUid => $taskUid);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::RecurringInfoResponse'); 
};

subtest 'testGetProjectWbsDefinition' => sub {
	my $name = 'sample-project.mpp';
	my $taskUid = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->GetProjectWbsDefinition(name => $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::WBSDefinitionResponse'); 
};

subtest 'testPostProjectTask' => sub {
	my $name = 'sample-project.mpp';
	my $taskName = 'NewTask';
	my $beforeTaskId = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->PostProjectTask(name => $name, taskName => $taskName, beforeTaskId => $beforeTaskId);
 	is($response->{'Status'}, "Created");
 	isa_ok($response, 'AsposeTasksCloud::Object::TaskItemResponse'); 
};

subtest 'testPutProjectTask' => sub {
	my $name = 'sample-project-2.mpp';
	my $taskUid = 0;
	my @taskBody = AsposeTasksCloud::Object::Task->new('Uid' => 0, 'Id' => 0, 'Name' => 'test');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->PutProjectTask(name => $name, taskUid => $taskUid, body => @taskBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::TaskResponse'); 
};

subtest 'testPutProjectAssignment' => sub {
	my $name = 'Outlinecode.mpp';
	my $assignmentUid = 1;
	my @resBody = AsposeTasksCloud::Object::ResourceAssignment->new('TaskUid' => 1, 'ResourceUid' => -1, 'Uid' => 1);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->PutProjectAssignment(name => $name, assignmentUid => $assignmentUid, body => @resBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeTasksCloud::Object::AssignmentResponse'); 
};

subtest 'testPutRecalculateProject' => sub {
	my $name = 'sample-project-2.mpp';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $tasksApi->PutRecalculateProject(name => $name);
 	is($response->{'Status'}, "OK");
};

done_testing();