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

use AsposeCellsCloud::CellsApi;
use AsposeCellsCloud::ApiClient;
use AsposeCellsCloud::Configuration;

use AsposeCellsCloud::Object::SaveOptions;
use AsposeCellsCloud::Object::AutoFitterOptions;
use AsposeCellsCloud::Object::StyleResponse;
use AsposeCellsCloud::Object::CellsDocumentPropertyResponse;
use AsposeCellsCloud::Object::CellsDocumentProperty;
use AsposeCellsCloud::Object::WorkbookEncryptionRequest;
use AsposeCellsCloud::Object::ImportOption;
use AsposeCellsCloud::Object::WorkbookProtectionRequest;
use AsposeCellsCloud::Object::ContentMessage;
use AsposeCellsCloud::Object::Worksheet;
use  AsposeCellsCloud::Object::Style;
use AsposeCellsCloud::Object::Font;
use AsposeCellsCloud::Object::Legend;
use AsposeCellsCloud::Object::Title;
use AsposeCellsCloud::Object::Comment;
use AsposeCellsCloud::Object::Hyperlink;
use  AsposeCellsCloud::Object::OleObject;
use AsposeCellsCloud::Object::Picture;
use AsposeCellsCloud::Object::CreatePivotTableRequest;
use AsposeCellsCloud::Object::PivotTableFieldRequest;
use AsposeCellsCloud::Object::WorksheetMovingRequest;
use AsposeCellsCloud::Object::ProtectSheetParameter;
use AsposeCellsCloud::Object::SortKey;
use AsposeCellsCloud::Object::DataSorter;
use AsposeCellsCloud::Object::PasswordRequest;
use AsposeCellsCloud::Object::WorkbookSettings;

use_ok('AsposeCellsCloud::Configuration');
use_ok('AsposeCellsCloud::ApiClient');
use_ok('AsposeCellsCloud::CellsApi');

$AsposeCellsCloud::Configuration::app_sid = 'XXX';
$AsposeCellsCloud::Configuration::api_key = 'XXX';

$AsposeCellsCloud::Configuration::debug = 1;

if(not defined $AsposeCellsCloud::Configuration::app_sid or $AsposeCellsCloud::Configuration::app_sid =~ /^XXX/i){
		done_testing();
    	exit;
  }else{
  	$AsposeStorageCloud::Configuration::app_sid = $AsposeCellsCloud::Configuration::app_sid
  }
    
if (not defined $AsposeCellsCloud::Configuration::api_key or $AsposeCellsCloud::Configuration::api_key =~ /^XXX/i){
	done_testing();
    exit;
}else{
	$AsposeStorageCloud::Configuration::api_key = $AsposeCellsCloud::Configuration::api_key;
}

my $data_path = './data/';

if (not -d $data_path){
	done_testing();
    exit;
}

if($AsposeCellsCloud::Configuration::debug){
	$AsposeStorageCloud::Configuration::debug = $AsposeCellsCloud::Configuration::debug;
}

my $storageApi = AsposeStorageCloud::StorageApi->new();
my $cellsApi = AsposeCellsCloud::CellsApi->new();

subtest 'testPutConvertDocument' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $format = "pdf";
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 
 	$response = $cellsApi->PutConvertWorkBook(format=>$format, file=> $data_path.$name);
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetWorkBook' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 
 	$response = $cellsApi->GetWorkBook(name=> $name); 	
 	isa_ok($response, 'AsposeCellsCloud::Object::WorkbookResponse');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPutWorkbookCreate' => sub {
	my $name = 'Sample_Test_Book_';
	for (0..4) { $name .= chr( int(rand(25) + 65) ); }
	$name = $name.'.xls';
	my $response = $cellsApi->PutWorkbookCreate(name=> $name); 	
 	isa_ok($response, 'AsposeCellsCloud::Object::WorkbookResponse');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetWorkBookWithFormat' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $format = "pdf";
	my $response = $cellsApi->GetWorkBookWithFormat(name=> $name, format=>$format); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostDocumentSaveAs' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $newfilename = 'Sample_Test_Book.xls';
	my @saveOptionsBody = AsposeCellsCloud::Object::SaveOptions->new();
	my $format = "pdf";
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");	
	$response = $cellsApi->PostDocumentSaveAs(name=> $name, newfilename=>$newfilename, format=>$format, body=>@saveOptionsBody); 	
 	is($response->{'Status'}, "OK"); 
 	isa_ok($response, 'AsposeCellsCloud::Object::SaveResponse');
};

subtest 'testPostAutofitWorkbookRows' => sub {
	my $name = 'Sample_Test_Book.xls';
	my @autoFitterOptionsBody = AsposeCellsCloud::Object::AutoFitterOptions->new('IgnoreHidden' => 'True');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");	
	$response = $cellsApi->PostAutofitWorkbookRows(name=> $name, body=>@autoFitterOptionsBody); 	
 	is($response->{'Status'}, "OK");
};

subtest 'testPostWorkbookCalculateFormula' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");	
	$response = $cellsApi->PostWorkbookCalculateFormula(name=> $name); 	
 	is($response->{'Status'}, "OK");
};

subtest 'testGetWorkBookDefaultStyle' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");	
	$response = $cellsApi->GetWorkBookDefaultStyle(name=> $name); 	
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::StyleResponse');
};

subtest 'testGetDocumentProperties' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");	
	$response = $cellsApi->GetDocumentProperties(name=> $name); 	
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::CellsDocumentPropertiesResponse');
};

subtest 'testDeleteDocumentProperties' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");	
	$response = $cellsApi->DeleteDocumentProperties(name=> $name); 	
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::CellsDocumentPropertiesResponse');
};

subtest 'testGetDocumentProperty' => sub {
	my $name = 'Sample_Book1.xlsx';
	my $propertyName = 'AsposeAuthor';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");	
	$response = $cellsApi->GetDocumentProperty(name=> $name, propertyName=>$propertyName); 	
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::CellsDocumentPropertyResponse');
};

subtest 'testPutDocumentProperty' => sub {
	my $name = 'Sample_Book1.xlsx';
	my $propertyName = 'AsposeAuthor';
	my @cellsDocumentPropertyBody = AsposeCellsCloud::Object::CellsDocumentProperty->new('Name' => 'AsposeAuthor', 'Value' => 'Aspose Plugin Developer', 'BuiltIn'=> 'False');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");	
	$response = $cellsApi->PutDocumentProperty(name=> $name, propertyName=>$propertyName, body=>@cellsDocumentPropertyBody);
 	isa_ok($response, 'AsposeCellsCloud::Object::CellsDocumentPropertyResponse');
};

subtest 'testDeleteDocumentProperty' => sub {
	my $name = 'Sample_Book1.xlsx';
	my $propertyName = 'AsposeAuthor';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");	
	$response = $cellsApi->DeleteDocumentProperty(name=> $name, propertyName=>$propertyName);
 	isa_ok($response, 'AsposeCellsCloud::Object::CellsDocumentPropertiesResponse');
};

subtest 'testPostEncryptDocument' => sub {
	my $name = 'Sample_Test_Book.xls';
	my @workbookEncryptionRequest = AsposeCellsCloud::Object::WorkbookEncryptionRequest->new('EncryptionType' => 'XOR', 'Password' => 'aspose', 'KeyLength'=> '128');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");	
	$response = $cellsApi->PostEncryptDocument(name=> $name, body=>@workbookEncryptionRequest);
 	is($response->{'Status'}, "OK");	
};

subtest 'testDeleteDecryptDocument' => sub {
	my $name = 'encrypted_Sample_Test_Book.xls';
	my @workbookEncryptionRequest = AsposeCellsCloud::Object::WorkbookEncryptionRequest->new('EncryptionType' => 'XOR', 'Password' => 'aspose', 'KeyLength'=> '128');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");	
	$response = $cellsApi->DeleteDecryptDocument(name=> $name, body=>@workbookEncryptionRequest);
 	is($response->{'Status'}, "OK");	
};

subtest 'testPostWorkbooksTextSearch' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $text = 'aspose.xls';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");	
	$response = $cellsApi->PostWorkbooksTextSearch(name=> $name, text=>$text);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::TextItemsResponse');	
};

subtest 'testPostWorkbooksMerge' => sub {
	my $name = 'Sample_Book1.xlsx';
	my $mergeWith = 'Sample_Book2.xls';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $storageApi->PutCreate(Path => $mergeWith, file => $data_path.$mergeWith);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostWorkbooksMerge(name=> $name, mergeWith=>$mergeWith);
 	isa_ok($response, 'AsposeCellsCloud::Object::WorkbookResponse');	
};

subtest 'testPostImportData' => sub {
	my $name = 'Sample_Test_Book.xls';
	my @importOptionBody = AsposeCellsCloud::Object::ImportOption->new('IsInsert' => 'true');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostImportData(name=> $name, body=>@importOptionBody);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetWorkBookNames' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorkBookNames(name=> $name);
 	isa_ok($response, 'AsposeCellsCloud::Object::NamesResponse');
};

subtest 'testGetWorkBookName' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $nameName = 'TestRange';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorkBookName(name=> $name, nameName=>$nameName);
 	isa_ok($response, 'AsposeCellsCloud::Object::NameResponse');
};

subtest 'testPostProtectDocument' => sub {
	my $name = 'Sample_Test_Book.xls';
	my @workbookProtectionRequest = AsposeCellsCloud::Object::WorkbookProtectionRequest->new('Password' => 'aspose', 'ProtectionType'=> 'All');	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostProtectDocument(name=> $name, body=>@workbookProtectionRequest);
 	is($response->{'Status'}, "OK");
};

subtest 'testDeleteUnProtectDocument' => sub {
	my $name = 'Sample_Protected_Test_Book.xls';
	my @workbookProtectionRequest = AsposeCellsCloud::Object::WorkbookProtectionRequest->new('Password' => 'aspose', 'ProtectionType'=> 'None');	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->DeleteUnProtectDocument(name=> $name, body=>@workbookProtectionRequest);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostWorkbooksTextReplace' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $oldValue = 'aspose';
	my $newValue = 'aspose.com';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostWorkbooksTextReplace(name=> $name, oldValue=>$oldValue, newValue=>$newValue);
 	isa_ok($response, 'AsposeCellsCloud::Object::WorkbookReplaceResponse');
};

subtest 'testPostWorkbookGetSmartMarkerResult' => sub {
	my $name = 'Sample_SmartMarker.xlsx';
	my $datafile = 'Sample_SmartMarker_Data.xml';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostWorkbookGetSmartMarkerResult(name=> $name, file => $data_path.$datafile);
 	isa_ok($response, 'AsposeCellsCloud::Object::ContentMessage');
};

subtest 'testPostWorkbookSplit' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $from = 1;
	my $to = 1;
	my $format = 'png';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostWorkbookSplit(name=> $name, format => $format, from=>$from, to=>$to);
 	isa_ok($response, 'AsposeCellsCloud::Object::SplitResultResponse');
};

subtest 'testGetWorkBookTextItems' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorkBookTextItems(name=> $name);
 	isa_ok($response, 'AsposeCellsCloud::Object::TextItemsResponse');
};

subtest 'testGetWorkSheets' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorkSheets(name=> $name);
 	isa_ok($response, 'AsposeCellsCloud::Object::WorksheetsResponse');
};

subtest 'testPostUpdateWorksheetProperty' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my @worksheetBody = AsposeCellsCloud::Object::Worksheet->new('Type' => 'Worksheet', 'Name'=> 'Sheet1', 'IsGridlinesVisible', 'True');
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostUpdateWorksheetProperty(name=> $name, sheetName=>$sheetName, body=>@worksheetBody);
 	isa_ok($response, 'AsposeCellsCloud::Object::WorksheetResponse');
};

subtest 'testPutAddNewWorksheet' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1-new';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PutAddNewWorksheet(name=> $name, sheetName=>$sheetName);
 	isa_ok($response, 'AsposeCellsCloud::Object::WorksheetsResponse');
};

subtest 'testDeleteWorksheet' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet3';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->DeleteWorksheet(name=> $name, sheetName=>$sheetName);
 	isa_ok($response, 'AsposeCellsCloud::Object::WorksheetsResponse');
};

subtest 'testGetWorkSheetWithFormat' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet3';
	my $format = 'png';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorkSheetWithFormat(name=> $name, sheetName=>$sheetName, format=>$format);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetWorkSheet' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorkSheet(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::WorksheetResponse');
};

subtest 'testPostAutofitWorksheetRows' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my @autoFitterOptionsBody = AsposeCellsCloud::Object::AutoFitterOptions->new('IgnoreHidden' => 'True');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostAutofitWorksheetRows(name=> $name, sheetName=>$sheetName, body=>@autoFitterOptionsBody);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetWorksheetAutoshapes' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet4';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorksheetAutoshapes(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::AutoShapesResponse');
 	
};

subtest 'testGetWorksheetAutoshape' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet4';
	my $autoshapeNumber = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorksheetAutoshape(name=> $name, sheetName=>$sheetName, autoshapeNumber=>$autoshapeNumber);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::AutoShapeResponse');
 	
};

subtest 'testGetWorksheetAutoshapeWithFormat' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet4';
	my $autoshapeNumber = 1;
	my $format = 'png';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorksheetAutoshapeWithFormat(name=> $name, sheetName=>$sheetName, autoshapeNumber=>$autoshapeNumber, format=>$format);
 	is($response->{'Status'}, "OK");
};

subtest 'testPutWorkSheetBackground' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet4';
	my $bgfile = 'aspose-cloud.png';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PutWorkSheetBackground(name=> $name, sheetName=>$sheetName, file => $data_path.$bgfile);
 	is($response->{'Status'}, "OK");
};

subtest 'testDeleteWorkSheetBackground' => sub {
	my $name = 'WorkSheetBackground_Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->DeleteWorkSheetBackground(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetWorksheetCells' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorksheetCells(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::CellsResponse');
};

subtest 'testPostSetCellRangeValue' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $cellarea = 'A10:B20';
	my $value = '1234';
	my $type = 'int';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostSetCellRangeValue(name=> $name, sheetName=>$sheetName, cellarea=>$cellarea, value=>$value, type=>$type);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testPostClearContents' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $startRow = 1;
	my $startColumn = 1;
	my $endRow = 2;
	my $endColumn = 2;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostClearContents(name=> $name, sheetName=>$sheetName, startRow=>$startRow, startColumn=>$startColumn, endRow=>$endRow, endColumn=>$endColumn);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testPostClearFormats' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';
	my $startRow = 1;
	my $startColumn = 1;
	my $endRow = 2;
	my $endColumn = 2;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostClearFormats(name=> $name, sheetName=>$sheetName, startRow=>$startRow, startColumn=>$startColumn, endRow=>$endRow, endColumn=>$endColumn);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testGetWorksheetColumns' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorksheetColumns(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::ColumnsResponse');
 	
};

subtest 'testPostCopyWorksheetColumns' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';
	my $sourceColumnIndex = 2;
	my $destinationColumnIndex = 2;
	my $columnNumber = 2;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostCopyWorksheetColumns(name=> $name, sheetName=>$sheetName, sourceColumnIndex=>$sourceColumnIndex, destinationColumnIndex=>$destinationColumnIndex, columnNumber=>$columnNumber);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testPostGroupWorksheetColumns' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $firstIndex = 2;
	my $lastIndex = 3;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostGroupWorksheetColumns(name=> $name, sheetName=>$sheetName,  firstIndex=>$firstIndex, lastIndex=>$lastIndex);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testPostHideWorksheetColumns' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $startColumn = 1;
	my $totalColumns = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostHideWorksheetColumns(name=> $name, sheetName=>$sheetName,  startColumn=>$startColumn, totalColumns=>$totalColumns);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testPostUngroupWorksheetColumns' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $firstIndex = 1;
	my $lastIndex = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostUngroupWorksheetColumns(name=> $name, sheetName=>$sheetName,  firstIndex=>$firstIndex, lastIndex=>$lastIndex);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testPostUnhideWorksheetColumns' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $startcolumn = 1;
	my $totalColumns = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostUnhideWorksheetColumns(name=> $name, sheetName=>$sheetName,  startcolumn=>$startcolumn, totalColumns=>$totalColumns);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testGetWorksheetColumn' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $columnIndex = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorksheetColumn(name=> $name, sheetName=>$sheetName,  columnIndex=>$columnIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::ColumnResponse');
 	
};

subtest 'testPutInsertWorksheetColumns' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $columnIndex = 1;
	my $columns = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PutInsertWorksheetColumns(name=> $name, sheetName=>$sheetName,  columnIndex=>$columnIndex, columns=>$columns);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::ColumnsResponse');
 	
};

subtest 'testDeleteWorksheetColumns' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $columnIndex = 1;
	my $columns = 1;
	my $updateReference = 'True';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->DeleteWorksheetColumns(name=> $name, sheetName=>$sheetName,  columnIndex=>$columnIndex, columns=>$columns, updateReference=>$updateReference);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::ColumnsResponse');
 	
};

subtest 'testPostSetWorksheetColumnWidth' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $columnIndex = 1;
	my $width = 20;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostSetWorksheetColumnWidth(name=> $name, sheetName=>$sheetName,  columnIndex=>$columnIndex, width=>$width);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::ColumnResponse');
 	
};

subtest 'testPostColumnStyle' => sub {
	#TODO
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $columnIndex = 0;
	my @font = AsposeCellsCloud::Object::Font->new('Name' => 'Calibri', 'Size'=> 40);
	my @styleBody = AsposeCellsCloud::Object::Style->new('Name' => 'TestStyle', 'Font'=> @font);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostColumnStyle(name=> $name, sheetName=>$sheetName,  columnIndex=>$columnIndex, body=>@styleBody);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testPostWorksheetMerge' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';
	my $startRow = 1;
	my $startColumn = 1;
	my $totalRows = 1;
	my $totalColumns = 5;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostWorksheetMerge(name=> $name, sheetName=>$sheetName,  startRow=>$startRow, startColumn=>$startColumn, totalRows=>$totalRows, totalColumns=>$totalColumns);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testGetWorksheetRows' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorksheetRows(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::RowsResponse');
 	
};

subtest 'testPutInsertWorksheetRows' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $startrow = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PutInsertWorksheetRows(name=> $name, sheetName=>$sheetName, startrow=>$startrow);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testDeleteWorksheetRows' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $startrow = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->DeleteWorksheetRows(name=> $name, sheetName=>$sheetName, startrow=>$startrow);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testPostCopyWorksheetRows' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $sourceRowIndex = 2;
	my $destinationRowIndex = 2;
	my $rowNumber = 2;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostCopyWorksheetRows(name=> $name, sheetName=>$sheetName, sourceRowIndex=>$sourceRowIndex, destinationRowIndex=>$destinationRowIndex, rowNumber=>$rowNumber);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testPostHideWorksheetRows' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $startrow = 1;
	my $totalRows = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostHideWorksheetRows(name=> $name, sheetName=>$sheetName, startrow=>$startrow, totalRows=>$totalRows);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testPostUngroupWorksheetRows' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $firstIndex = 1;
	my $lastIndex = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostUngroupWorksheetRows(name=> $name, sheetName=>$sheetName, firstIndex=>$firstIndex, lastIndex=>$lastIndex);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testPostUnhideWorksheetRows' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $startrow = 1;
	my $totalRows = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostUnhideWorksheetRows(name=> $name, sheetName=>$sheetName, startrow=>$startrow, totalRows=>$totalRows);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testPostUpdateWorksheetRow' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $rowIndex = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostUpdateWorksheetRow(name=> $name, sheetName=>$sheetName, rowIndex=>$rowIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::RowResponse');
 	
};

subtest 'testGetWorksheetRow' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $rowIndex = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorksheetRow(name=> $name, sheetName=>$sheetName, rowIndex=>$rowIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::RowResponse');
 	
};

subtest 'testPutInsertWorksheetRow' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $rowIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PutInsertWorksheetRow(name=> $name, sheetName=>$sheetName, rowIndex=>$rowIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::RowResponse');
 	
};

subtest 'testDeleteWorksheetRow' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $rowIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->DeleteWorksheetRow(name=> $name, sheetName=>$sheetName, rowIndex=>$rowIndex);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostRowStyle' => sub {
	#TODO
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $rowIndex = 1;
	my @font = AsposeCellsCloud::Object::Font->new('Name' => 'Arial', 'Size'=> 10);
	my @styleBody = AsposeCellsCloud::Object::Style->new('Font'=> @font);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostRowStyle(name=> $name, sheetName=>$sheetName, rowIndex=>$rowIndex, body=>@styleBody);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostUpdateWorksheetRangeStyle' => sub {
	#TODO
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $range = 'A2';
	my @font = AsposeCellsCloud::Object::Font->new('Name' => 'Arial', 'Size'=> 10);
	my @styleBody = AsposeCellsCloud::Object::Style->new('Font'=> @font);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostUpdateWorksheetRangeStyle(name=> $name, sheetName=>$sheetName, range=>$range, body=>@styleBody);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostWorksheetUnmerge' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';
	my $startRow = 1;
	my $startColumn = 1;
	my $totalRows = 1;
	my $totalColumns = 5;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostWorksheetUnmerge(name=> $name, sheetName=>$sheetName, startRow=>$startRow, startColumn=>$startColumn, totalRows=>$totalRows, totalColumns=>$totalColumns);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostWorksheetCellSetValue' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';
	my $cellName = "A1";
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostWorksheetCellSetValue(name=> $name, sheetName=>$sheetName, cellName=>$cellName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::CellResponse');
};

subtest 'testPostSetCellHtmlString' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';
	my $cellName = 'A1';
	my $filename = 'testfile.txt';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostSetCellHtmlString(name=> $name, sheetName=>$sheetName, cellName=>$cellName, file=>$data_path.$filename);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::CellResponse');
};

subtest 'testGetWorksheetCellStyle' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';
	my $cellName = 'A1';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorksheetCellStyle(name=> $name, sheetName=>$sheetName, cellName=>$cellName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::StyleResponse');
};

subtest 'testPostUpdateWorksheetCellStyle' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';
	my $cellName = 'A1';
	my @font = AsposeCellsCloud::Object::Font->new('Name' => 'Arial', 'Size'=> 10);
	my @styleBody = AsposeCellsCloud::Object::Style->new('Font'=> @font);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostUpdateWorksheetCellStyle(name=> $name, sheetName=>$sheetName, cellName=>$cellName, body=>@styleBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::StyleResponse');
 		
};

subtest 'testGetWorksheetCell' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $cellOrMethodName = "a1";
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorksheetCell(name=> $name, sheetName=>$sheetName, cellOrMethodName=>$cellOrMethodName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::CellResponse');
 		
};

subtest 'testPostCopyCellIntoCell' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $worksheet =  "Sheet2";
	my $destCellName = "a1";
	my $row = 2;
	my $column = 2;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostCopyCellIntoCell(name=> $name, sheetName=>$sheetName, worksheet=>$worksheet, destCellName=>$destCellName,row=>$row, column=>$column);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetWorksheetCharts' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet5';	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorksheetCharts(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::ChartsResponse');
};

subtest 'testDeleteWorksheetClearCharts' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet5';	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->DeleteWorksheetClearCharts(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
};

subtest 'testPutWorksheetAddChart' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet5';	
	my $chartType = 'bar';
	my $upperLeftRow = 12;
	my $upperLeftColumn = 12;
	my $lowerRightRow = 20;
	my $lowerRightColumn = 20;
	my $area = 'A1:A3';
	my $isVertical = 'False';	
	my $isAutoGetSerialName = 'True';
	my $title = 'SalesState';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PutWorksheetAddChart(name=> $name, sheetName=>$sheetName, chartType=>$chartType, upperLeftRow=>$upperLeftRow, 
				upperLeftColumn=>$upperLeftColumn, lowerRightRow=>$lowerRightRow, lowerRightColumn=>$lowerRightColumn, area=>$area, 
				isVertical=>$isVertical, isAutoGetSerialName=>$isAutoGetSerialName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::ChartsResponse');
};

subtest 'testDeleteWorksheetDeleteChart' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet5';	
	my $chartIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->DeleteWorksheetDeleteChart(name=> $name, sheetName=>$sheetName, chartIndex=>$chartIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::ChartsResponse');
};

subtest 'testGetChartArea' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet5';	
	my $chartIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetChartArea(name=> $name, sheetName=>$sheetName, chartIndex=>$chartIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::ChartAreaResponse');
};

subtest 'testGetChartAreaBorder' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet5';	
	my $chartIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetChartAreaBorder(name=> $name, sheetName=>$sheetName, chartIndex=>$chartIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::LineResponse');
};

subtest 'testGetChartAreaFillFormat' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet5';	
	my $chartIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetChartAreaFillFormat(name=> $name, sheetName=>$sheetName, chartIndex=>$chartIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::FillFormatResponse');
};

subtest 'testGetWorksheetChartLegend' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet5';	
	my $chartIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorksheetChartLegend(name=> $name, sheetName=>$sheetName, chartIndex=>$chartIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::LegendResponse');
};

subtest 'testPutWorksheetChartLegend' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet5';	
	my $chartIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PutWorksheetChartLegend(name=> $name, sheetName=>$sheetName, chartIndex=>$chartIndex);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostWorksheetChartLegend' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet5';	
	my $chartIndex = 0;
	my @legendBody = AsposeCellsCloud::Object::Legend->new('Height' => 200);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostWorksheetChartLegend(name=> $name, sheetName=>$sheetName, chartIndex=>$chartIndex, body=>@legendBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::LegendResponse');
};

subtest 'testDeleteWorksheetChartLegend' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet5';	
	my $chartIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->DeleteWorksheetChartLegend(name=> $name, sheetName=>$sheetName, chartIndex=>$chartIndex);
 	is($response->{'Status'}, "OK");
};

subtest 'testPutWorksheetChartTitle' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet5';	
	my $chartIndex = 0;
	my @titleBody = AsposeCellsCloud::Object::Title->new('Height' => 200);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PutWorksheetChartTitle(name=> $name, sheetName=>$sheetName, chartIndex=>$chartIndex, body=>@titleBody);
 	is($response->{'Status'}, "OK");
 	 	isa_ok($response, 'AsposeCellsCloud::Object::TitleResponse');
};

subtest 'testPostWorksheetChartTitle' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet5';	
	my $chartIndex = 0;
	my @titleBody = AsposeCellsCloud::Object::Title->new('Height' => 200);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostWorksheetChartTitle(name=> $name, sheetName=>$sheetName, chartIndex=>$chartIndex, body=>@titleBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::TitleResponse');
};

subtest 'testDeleteWorksheetChartTitle' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet5';	
	my $chartIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->DeleteWorksheetChartTitle(name=> $name, sheetName=>$sheetName, chartIndex=>$chartIndex);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetWorksheetChart' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet5';	
	my $chartNumber = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorksheetChart(name=> $name, sheetName=>$sheetName, chartNumber=>$chartNumber);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::ChartResponse');
};

subtest 'testGetWorksheetChartWithFormat' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet5';	
	my $chartNumber = 0;
	my $format = 'png';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorksheetChartWithFormat(name=> $name, sheetName=>$sheetName, chartNumber=>$chartNumber, format=>$format);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetWorkSheetComments' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorkSheetComments(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::CommentsResponse');
};

subtest 'testGetWorkSheetComment' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';	
	my $cellName = 'A4'; 
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorkSheetComment(name=> $name, sheetName=>$sheetName, cellName=>$cellName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::CommentResponse');
};

subtest 'testPutWorkSheetComment' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';	
	my $cellName = 'A4'; 
	my @commentBody = AsposeCellsCloud::Object::Comment->new('AutoSize' => 'True','Note' => 'Aspose');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PutWorkSheetComment(name=> $name, sheetName=>$sheetName, cellName=>$cellName, body=>@commentBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::CommentResponse');
};

subtest 'testPostWorkSheetComment' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';	
	my $cellName = 'A4'; 
	my @commentBody = AsposeCellsCloud::Object::Comment->new('AutoSize' => 'True','Note' => 'Aspose');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostWorkSheetComment(name=> $name, sheetName=>$sheetName, cellName=>$cellName, body=>@commentBody);
 	is($response->{'Status'}, "OK");
};

subtest 'testDeleteWorkSheetComment' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';	
	my $cellName = 'A4'; 
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->DeleteWorkSheetComment(name=> $name, sheetName=>$sheetName, cellName=>$cellName);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostCopyWorksheet' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet7';	
	my $sourceSheet = 'Sheet1'; 
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostCopyWorksheet(name=> $name, sheetName=>$sheetName, sourceSheet=>$sourceSheet);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostWorkSheetTextSearch' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';	
	my $text = 'aspose'; 
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostWorkSheetTextSearch(name=> $name, sheetName=>$sheetName, text=>$text);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::TextItemsResponse');
};

subtest 'testGetWorkSheetCalculateFormula' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';	
	my $formula = 'SUM(A5:A10)'; 
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorkSheetCalculateFormula(name=> $name, sheetName=>$sheetName, formula=>$formula);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::SingleValueResponse');
};

subtest 'testPutWorksheetFreezePanes' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';	
	my $row = 0;
	my $column = 1;
	my $freezedRows = 1;
	my $freezedColumns = 2; 
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PutWorksheetFreezePanes(name=> $name, sheetName=>$sheetName, row=>$row, , column=>$column, freezedColumns=>$freezedColumns, freezedRows=>$freezedRows );
 	is($response->{'Status'}, "OK");
};

subtest 'testDeleteWorksheetFreezePanes' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';	
	my $row = 1;
	my $column = 1;
	my $freezedRows = 1;
	my $freezedColumns = 1; 
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->DeleteWorksheetFreezePanes(name=> $name, sheetName=>$sheetName, row=>$row, , column=>$column, freezedColumns=>$freezedColumns, freezedRows=>$freezedRows );
 	is($response->{'Status'}, "OK");
};

subtest 'testPutWorkSheetHyperlink' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';	
	my $firstRow = 2;
	my $firstColumn = 2;
	my $totalRows = 2;
	my $totalColumns = 2;
	my $address = 'http://www.aspose.com/cloud/total-api.aspx'; 
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PutWorkSheetHyperlink(name=> $name, sheetName=>$sheetName, firstRow=>$firstRow, , firstColumn=>$firstColumn, 
						totalRows=>$totalRows, totalColumns=>$totalColumns, address=>$address );
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::HyperlinkResponse');
};

subtest 'testGetWorkSheetHyperlinks' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorkSheetHyperlinks(name=> $name, sheetName=>$sheetName );
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::HyperlinksResponse');
};

subtest 'testGetWorkSheetHyperlinks' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->DeleteWorkSheetHyperlinks(name=> $name, sheetName=>$sheetName );
 	is($response->{'Status'}, "OK");
};

subtest 'testGetWorkSheetHyperlink' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';	
	my $hyperlinkIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorkSheetHyperlink(name=> $name, sheetName=>$sheetName, hyperlinkIndex=>$hyperlinkIndex );
 	is($response->{'Status'}, "OK");
 		isa_ok($response, 'AsposeCellsCloud::Object::HyperlinkResponse');
};

subtest 'testPostWorkSheetHyperlink' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';	
	my $hyperlinkIndex = 0;
	my @hyperlinkBody = AsposeCellsCloud::Object::Hyperlink->new('Address' => 'http://www.aspose.com/cloud/total-api.aspx', 'TextToDisplay' => 'Aspose Cloud APIs');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostWorkSheetHyperlink(name=> $name, sheetName=>$sheetName, hyperlinkIndex=>$hyperlinkIndex, body=>@hyperlinkBody );
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::HyperlinkResponse');
};

subtest 'testDeleteWorkSheetHyperlink' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet2';	
	my $hyperlinkIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->DeleteWorkSheetHyperlink(name=> $name, sheetName=>$sheetName, hyperlinkIndex=>$hyperlinkIndex);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetWorkSheetMergedCells' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorkSheetMergedCells(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::MergedCellsResponse');
};

subtest 'testGetWorkSheetMergedCell' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';	
	my $mergedCellIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorkSheetMergedCell(name=> $name, sheetName=>$sheetName, mergedCellIndex=>$mergedCellIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::MergedCellResponse');
};

subtest 'testGetWorksheetOleObjects' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorksheetOleObjects(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::OleObjectsResponse');
};

subtest 'testDeleteWorksheetOleObjects' => sub {
	my $name = 'Embeded_OleObject_Sample_Book1.xlsx';
	my $sheetName = 'Sheet1';	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->DeleteWorksheetOleObjects(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
};

subtest 'testPutWorksheetOleObject' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $sourceFileName = 'Sample_Book2.xls';
	my $imageFileName = 'aspose-logo.png';
	my @oleObjectBody = AsposeCellsCloud::Object::OleObject->new(
				'SourceFullName' => $sourceFileName,		
		        'ImageSourceFullName' => $imageFileName,
		        'UpperLeftRow' => 15,
		        'UpperLeftColumn' => 5,
		        'Top' => 10,
		        'Bottom' => 10,
		        'Left' => 10,
		        'Height' => 400,
		        'Width' => 400,
		        'IsAutoSize' => 'True'
		        );	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $storageApi->PutCreate(Path => $sourceFileName, file => $data_path.$sourceFileName);
 	is($response->{'Status'}, "OK");
 	$response = $storageApi->PutCreate(Path => $imageFileName, file => $data_path.$imageFileName);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PutWorksheetOleObject(name=> $name, sheetName=>$sheetName, body=>@oleObjectBody);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetWorksheetOleObject' => sub {
	my $name = 'Embeded_OleObject_Sample_Book1.xlsx';
	my $sheetName = 'Sheet1';
	my $objectNumber = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorksheetOleObject(name=> $name, sheetName=>$sheetName, objectNumber=>$objectNumber);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::OleObjectResponse');
};

subtest 'testGetWorksheetOleObjectWithFormat' => sub {
	my $name = 'Embeded_OleObject_Sample_Book1.xlsx';
	my $sheetName = 'Sheet1';
	my $objectNumber = 0;
	my $format = 'png';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->GetWorksheetOleObject(name=> $name, sheetName=>$sheetName, objectNumber=>$objectNumber, format=>$format);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostUpdateWorksheetOleObject' => sub {
	my $name = 'Embeded_OleObject_Sample_Book1.xlsx';
	my $sheetName = 'Sheet1';
	my $oleObjectIndex = 0;
	my $sourceFileName = 'Sample_Book2.xls';
	my $imageFileName = 'aspose-logo.png';
	my @oleObjectBody = AsposeCellsCloud::Object::OleObject->new(
				'SourceFullName' => $sourceFileName,		
		        'ImageSourceFullName' => $imageFileName,
		        'UpperLeftRow' => 15,
		        'UpperLeftColumn' => 5,
		        'Top' => 10,
		        'Bottom' => 10,
		        'Left' => 10,
		        'Height' => 400,
		        'Width' => 400,
		        'IsAutoSize' => 'True'
		        );	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $storageApi->PutCreate(Path => $sourceFileName, file => $data_path.$sourceFileName);
 	is($response->{'Status'}, "OK");
 	$response = $storageApi->PutCreate(Path => $imageFileName, file => $data_path.$imageFileName);
 	is($response->{'Status'}, "OK");
	$response = $cellsApi->PostUpdateWorksheetOleObject(name=> $name, sheetName=>$sheetName, oleObjectIndex=>$oleObjectIndex, body=>@oleObjectBody);
 	is($response->{'Status'}, "OK");
};

subtest 'testDeleteWorksheetOleObject' => sub {
	my $name = 'Embeded_OleObject_Sample_Book1.xlsx';
	my $sheetName = 'Sheet1';
	my $oleObjectIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->DeleteWorksheetOleObject(name=> $name, sheetName=>$sheetName, oleObjectIndex=>$oleObjectIndex);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetWorksheetPictures' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet6';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->GetWorksheetPictures(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::PicturesResponse');
};

subtest 'testDeleteWorkSheetPictures' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet6';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->DeleteWorkSheetPictures(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
};

subtest 'testPutWorksheetAddPicture' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet6';
	my $upperLeftRow = 5;
	my $upperLeftColumn = 5;
	my $lowerRightRow = 10;
	my $lowerRightColumn = 10;
	my $picturePath = "aspose-cloud.png";
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $storageApi->PutCreate(Path => $picturePath, file => $data_path.$picturePath);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PutWorksheetAddPicture(name=> $name, sheetName=>$sheetName, upperLeftRow=>$upperLeftRow, 
 					upperLeftColumn=>$upperLeftColumn, lowerRightRow=>$lowerRightRow, lowerRightColumn=>$lowerRightColumn, picturePath=>$picturePath);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::PicturesResponse');
};

subtest 'testPostWorkSheetPicture' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet6';
	my $pictureIndex = 0;
    my $picName = "aspose-cloud-logo";
    my $pictureBody =  AsposeCellsCloud::Object::Picture->new(
    		'Name' =>  $picName,
    		'RotationAngle' => 90
    		);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PostWorkSheetPicture(name=> $name, sheetName=>$sheetName, pictureIndex=>$pictureIndex, body=> $pictureBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::PictureResponse');
};

subtest 'testDeleteWorksheetPicture' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet6';
	my $pictureIndex = 0;
    my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->DeleteWorksheetPicture(name=> $name, sheetName=>$sheetName, pictureIndex=>$pictureIndex);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetWorksheetPicture' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet6';
	my $pictureNumber = 0;
    my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->GetWorksheetPicture(name=> $name, sheetName=>$sheetName, pictureNumber=>$pictureNumber);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetWorksheetPictureWithFormat' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet6';
	my $pictureNumber = 0;
	my $format = 'png';
    my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->GetWorksheetPictureWithFormat(name=> $name, sheetName=>$sheetName, pictureNumber=>$pictureNumber, format=>$format);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetExtractBarcodes' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet6';
	my $pictureNumber = 0;
    my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->GetExtractBarcodes(name=> $name, sheetName=>$sheetName, pictureNumber=>$pictureNumber);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::BarcodeResponseList');
};

subtest 'testGetWorksheetPivotTables' => sub {
	my $name = 'Sample_Pivot_Table_Example.xls';
	my $sheetName = 'Sheet2';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->GetWorksheetPivotTables(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::PivotTablesResponse');
};

subtest 'testDeleteWorksheetPivotTables' => sub {
	my $name = 'Sample_Pivot_Table_Example.xls';
	my $sheetName = 'Sheet2';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->DeleteWorksheetPivotTables(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
};

subtest 'testPutWorksheetPivotTable' => sub {
	my $name = 'Sample_Pivot_Table_Example.xls';
	my $sheetName = 'Sheet1';
	my $createPivotTableRequestBody = AsposeCellsCloud::Object::CreatePivotTableRequest->new(
			'Name' => 'MyPivot',
	        'SourceData' => 'A5:E10',
	        'DestCellName' => 'H20',
	        'UseSameSource' => 'True',
	        'PivotFieldRows' => [1],
	        'PivotFieldColumns' => [1],
	        'PivotFieldData' => [1]
	);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PutWorksheetPivotTable(name=> $name, sheetName=>$sheetName, body=>$createPivotTableRequestBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::PivotTableResponse');
};

subtest 'testDeleteWorksheetPivotTable' => sub {
	my $name = 'Sample_Pivot_Table_Example.xls';
	my $sheetName = 'Sheet2';
	my $pivotTableIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->DeleteWorksheetPivotTable(name=> $name, sheetName=>$sheetName, pivotTableIndex=>$pivotTableIndex);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostPivotTableCellStyle' => sub {
	my $name = 'Sample_Pivot_Table_Example.xls';
	my $sheetName = 'Sheet2';
	my $pivotTableIndex = 0;
	my $column = 1;
	my $row = 1;
	my @font = AsposeCellsCloud::Object::Font->new('Name' => 'Arial', 'Size'=> 10);
	my @styleBody = AsposeCellsCloud::Object::Style->new('Font'=> @font);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PostPivotTableCellStyle(name=> $name, sheetName=>$sheetName, pivotTableIndex=>$pivotTableIndex,
 													column=>$column,row=>$row, body=>@styleBody);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostPivotTableStyle' => sub {
	my $name = 'Sample_Pivot_Table_Example.xls';
	my $sheetName = 'Sheet2';
	my $pivotTableIndex = 0;
	my @font = AsposeCellsCloud::Object::Font->new('Name' => 'Arial', 'Size'=> 10);
	my @styleBody = AsposeCellsCloud::Object::Style->new('Font'=> @font);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PostPivotTableStyle(name=> $name, sheetName=>$sheetName, pivotTableIndex=>$pivotTableIndex, body=>@styleBody);
 	is($response->{'Status'}, "OK");
};

subtest 'testPutPivotTableField' => sub {
	my $name = 'Sample_Pivot_Table_Example.xls';
	my $sheetName = 'Sheet2';
	my $pivotTableIndex = 0;
	my $pivotFieldType = "Row";
	my @pivotTableFieldRequest = AsposeCellsCloud::Object::PivotTableFieldRequest->new( 'Data' => [1,2]);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PostPivotTableStyle(name=> $name, sheetName=>$sheetName, pivotTableIndex=>$pivotTableIndex, pivotFieldType=>$pivotFieldType, body=>@pivotTableFieldRequest);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetWorksheetPivotTable' => sub {
	my $name = 'Sample_Pivot_Table_Example.xls';
	my $sheetName = 'Sheet2';
	my $pivottableIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->GetWorksheetPivotTable(name=> $name, sheetName=>$sheetName, pivottableIndex=>$pivottableIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::PivotTableResponse');
};

subtest 'testPostMoveWorksheet' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my @worksheetMovingRequest = AsposeCellsCloud::Object::WorksheetMovingRequest->new( 'DestinationWorksheet' => 'Sheet5', 'Position' => 'after');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PostMoveWorksheet(name=> $name, sheetName=>$sheetName, body=>@worksheetMovingRequest);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::WorksheetsResponse');
};

subtest 'testPutProtectWorksheet' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my @protectSheetParameter = AsposeCellsCloud::Object::ProtectSheetParameter->new( 'ProtectionType' => 'None');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PutProtectWorksheet(name=> $name, sheetName=>$sheetName, body=>@protectSheetParameter);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::WorksheetResponse');
};

subtest 'testDeleteUnprotectWorksheet' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my @protectSheetParameter = AsposeCellsCloud::Object::ProtectSheetParameter->new( 'ProtectionType' => 'None');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->DeleteUnprotectWorksheet(name=> $name, sheetName=>$sheetName, body=>@protectSheetParameter);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::WorksheetResponse');
};

subtest 'testPostRenameWorksheet' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $newname = "newSheet";
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PostRenameWorksheet(name=> $name, sheetName=>$sheetName, newname=>$newname);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostWorsheetTextReplace' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $oldValue = "aspose";
	my $newValue = "aspose.com";
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PostWorsheetTextReplace(name=> $name, sheetName=>$sheetName, oldValue=>$oldValue, newValue=>$newValue);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::WorksheetReplaceResponse');
};

subtest 'testPostWorksheetRangeSort' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $cellArea = 'A5:A10';
	my @sortKey = AsposeCellsCloud::Object::SortKey->new( 'Key' => 0, 'SortOrder' => 'descending');
	my @dataSorter = AsposeCellsCloud::Object::DataSorter->new( 'CaseSensitive' => 'False',
    		'HasHeaders' => 'False','SortLeftToRight' => 'False', 'KeyList' => [@sortKey]);
    		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PostWorksheetRangeSort(name=> $name, sheetName=>$sheetName, cellArea=>$cellArea, body=>@dataSorter);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetWorkSheetTextItems' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->GetWorkSheetTextItems(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::TextItemsResponse');
};

subtest 'testPutWorkSheetValidation' => sub {
	#TODO
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PutWorkSheetValidation(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::TextItemsResponse');
};

subtest 'testPostWorkSheetValidation' => sub {
	#TODO
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PostWorkSheetValidation(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::TextItemsResponse');
};

subtest 'testGetWorkSheetValidations' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet3';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->GetWorkSheetValidations(name=> $name, sheetName=>$sheetName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::ValidationsResponse');
};

subtest 'testGetWorkSheetValidation' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet3';
	my $validationIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->GetWorkSheetValidation(name=> $name, sheetName=>$sheetName, validationIndex=>$validationIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::ValidationResponse');
};

subtest 'testDeleteWorkSheetValidation' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet3';
	my $validationIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->DeleteWorkSheetValidation(name=> $name, sheetName=>$sheetName, validationIndex=>$validationIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::ValidationResponse');
};

subtest 'testPutChangeVisibilityWorksheet' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $isVisible = 'False';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PutChangeVisibilityWorksheet(name=> $name, sheetName=>$sheetName, isVisible=>$isVisible);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::WorksheetResponse');
};

subtest 'testPutDocumentProtectFromChanges' => sub {
	my $name = 'Sample_Test_Book.xls';
	my @passwordRequest= AsposeCellsCloud::Object::PasswordRequest->new('Password' => 'aspose');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PutDocumentProtectFromChanges(name=> $name, body=>@passwordRequest);
 	is($response->{'Status'}, "OK");
};

subtest 'testDeleteDocumentUnProtectFromChanges' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->DeleteDocumentUnProtectFromChanges(name=> $name);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetWorkbookSettings' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->GetWorkbookSettings(name=> $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::WorkbookSettingsResponse');
};

subtest 'testPostWorkbookSettings' => sub {
	my $name = 'Sample_Test_Book.xls';
	my @settingsBody= AsposeCellsCloud::Object::WorkbookSettings->new('LanguageCode' => 'USA');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PostWorkbookSettings(name=> $name, body=>@settingsBody);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostWorksheetPivotTableCalculate' => sub {
	my $name = 'Sample_Pivot_Table_Example.xls';
	my $sheetName = "Sheet2";
	my $pivotTableIndex = 0;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PostWorksheetPivotTableCalculate(name=> $name, sheetName=>$sheetName, pivotTableIndex=>$pivotTableIndex);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetPivotTableField' => sub {
	my $name = 'Sample_Pivot_Table_Example.xls';
	my $sheetName = "Sheet2";
	my $pivotTableIndex = 0;
	my $pivotFieldIndex = 0;
	my $pivotFieldType = "Row";
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->GetPivotTableField(name=> $name, sheetName=>$sheetName, pivotTableIndex=>$pivotTableIndex, pivotFieldIndex=>$pivotFieldIndex, pivotFieldType=>$pivotFieldType);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeCellsCloud::Object::PivotFieldResponse');
};

subtest 'testDeletePivotTableField' => sub {
	my $name = 'Sample_Pivot_Table_Example.xls';
	my $sheetName = 'Sheet2';
	my $pivotTableIndex = 0;
	my $pivotFieldType = "Row";
	my @pivotTableFieldRequest = AsposeCellsCloud::Object::PivotTableFieldRequest->new( 'Data' => [1,2]);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->DeletePivotTableField(name=> $name, sheetName=>$sheetName, pivotTableIndex=>$pivotTableIndex, pivotFieldType=>$pivotFieldType, body=>@pivotTableFieldRequest);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostGroupWorksheetRows' => sub {
	my $name = 'Sample_Test_Book.xls';
	my $sheetName = 'Sheet1';
	my $firstIndex = 0;
	my $lastIndex = 3;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $cellsApi->PostGroupWorksheetRows(name=> $name, sheetName=>$sheetName, firstIndex=>$firstIndex, lastIndex=>$lastIndex);
 	is($response->{'Status'}, "OK");
};

done_testing();