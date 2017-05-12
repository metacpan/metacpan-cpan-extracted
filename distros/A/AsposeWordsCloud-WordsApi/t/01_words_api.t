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

use AsposeWordsCloud::WordsApi;
use AsposeWordsCloud::ApiClient;
use AsposeWordsCloud::Configuration;

use AsposeWordsCloud::Object::BookmarkData;
use AsposeWordsCloud::Object::Bookmark;
use AsposeWordsCloud::Object::BookmarkResponse;
use AsposeWordsCloud::Object::LoadWebDocumentData;
use AsposeWordsCloud::Object::SaveOptionsData;
use AsposeWordsCloud::Object::DocumentEntry;
use AsposeWordsCloud::Object::DocumentEntryList;
use AsposeWordsCloud::Object::DocumentProperty;
use AsposeWordsCloud::Object::SaaSposeResponse;
use AsposeWordsCloud::Object::PageNumber;
use AsposeWordsCloud::Object::WatermarkText;
use AsposeWordsCloud::Object::Font;
use AsposeWordsCloud::Object::ProtectionRequest;
use AsposeWordsCloud::Object::ReplaceTextRequest;
use AsposeWordsCloud::Object::PageSetup;
use AsposeWordsCloud::Object::FormField;
use AsposeWordsCloud::Object::WatermarkText;
use AsposeWordsCloud::Object::FieldDto;
use AsposeWordsCloud::Object::CommentDto;
use AsposeWordsCloud::Object::NodeLink;
use AsposeWordsCloud::Object::DocumentPositionDto;


use_ok('AsposeWordsCloud::Configuration');
use_ok('AsposeWordsCloud::ApiClient');
use_ok('AsposeWordsCloud::WordsApi');

$AsposeWordsCloud::Configuration::app_sid = 'XXX';
$AsposeWordsCloud::Configuration::api_key = 'XXX';

$AsposeWordsCloud::Configuration::debug = 1;

if(not defined $AsposeWordsCloud::Configuration::app_sid or $AsposeWordsCloud::Configuration::app_sid =~ /^XXX/i){
		done_testing();
    	exit;
  }else{
  	$AsposeStorageCloud::Configuration::app_sid = $AsposeWordsCloud::Configuration::app_sid
  }
    
if (not defined $AsposeWordsCloud::Configuration::api_key or $AsposeWordsCloud::Configuration::api_key =~ /^XXX/i){
	done_testing();
    exit;
}else{
	$AsposeStorageCloud::Configuration::api_key = $AsposeWordsCloud::Configuration::api_key;
}

my $data_path = './data/';

if (not -d $data_path){
	done_testing();
    exit;
}

if($AsposeWordsCloud::Configuration::debug){
	$AsposeStorageCloud::Configuration::debug = $AsposeWordsCloud::Configuration::debug;
}

my $storageApi = AsposeStorageCloud::StorageApi->new();
my $wordsApi = AsposeWordsCloud::WordsApi->new();

subtest 'testPostUpdateDocumentBookmark' => sub {
	my $name = 'SampleWordDocument.docx';
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 
 	my $bookmarkDataBody = AsposeWordsCloud::Object::BookmarkData->new( 'Name' => 'aspose', 'Text' => 'Bookmark is very good');
 	$response = $wordsApi->PostUpdateDocumentBookmark(name=> $name, bookmarkName=>'aspose',  body=> $bookmarkDataBody);
 	isa_ok($response, 'AsposeWordsCloud::Object::BookmarkResponse');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPutConvertDocument' => sub {
	my $name = 'SampleWordDocument.docx';
	my $format = 'pdf';
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");  	
 	$response = $wordsApi->PutConvertDocument(format=> $format, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
};	

subtest 'testPostLoadWebDocument' => sub {
	my $name = 'SampleExecuteTemplate.doc';
	
	my $saveOptionsData = AsposeWordsCloud::Object::SaveOptionsData->new('SaveFormat' => 'doc', 'FileName' => 'google.doc');
	my $loadWebDocumentData = AsposeWordsCloud::Object::LoadWebDocumentData->new('LoadingDocumentUrl' => 'http://google.com', 'SaveOptions' => $saveOptionsData); 	 	
 	my $response = $wordsApi->PostLoadWebDocument(body => $loadWebDocumentData);
 	isa_ok($response, 'AsposeWordsCloud::Object::SaveResponse');
 	is($response->{'Status'}, "OK");
};
	
subtest 'testPutDocumentFieldNames' => sub {
	my $response = $storageApi->PutCreate(Path => 'SampleWordDocument.docx', file => $data_path.'SampleWordDocument.docx');
	is($response->{'Status'}, "OK"); 
	$response = $wordsApi->PutDocumentFieldNames(useNonMergeFields => 'False');
 	isa_ok($response, 'AsposeWordsCloud::Object::FieldNamesResponse');
 	is($response->{'Status'}, "OK");
};

subtest 'testGetDocument' => sub {
	my $filename = 'SampleWordDocument';
	my $name = $filename . '.docx';
	
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 	
 	$response = $wordsApi->GetDocument(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::DocumentResponse');
 	is($response->{'Status'}, "OK");
};	

subtest 'testGetDocumentWithFormat' => sub {
	my $filename = 'SampleWordDocument';
	my $name = $filename . '.docx';
	my $format = 'pdf';
	
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 	
 	$response = $wordsApi->GetDocumentWithFormat(name=> $name, format=>$format);
 	is($response->{'Status'}, "OK");
};	

subtest 'testPostDocumentSaveAs' => sub {
	my $filename = 'SampleWordDocument';
	my $name = $filename . '.docx';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK"); 	
	my $saveOptionsData = AsposeWordsCloud::Object::SaveOptionsData->new('SaveFormat' => 'doc', 'FileName' => 'google.doc');
 	$response = $wordsApi->PostDocumentSaveAs(name=> $name, body=>$saveOptionsData); 	
 	isa_ok($response, 'AsposeWordsCloud::Object::SaveResponse');
 	is($response->{'Status'}, "OK");
};	

subtest 'testPutDocumentSaveAsTiff' => sub {
	my $filename = 'SampleWordDocument';
	my $name = $filename . '.docx';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);	
	is($response->{'Status'}, "OK"); 	
	my $saveOptionsData = AsposeWordsCloud::Object::SaveOptionsData->new('SaveFormat' => 'tiff', 'FileName' => 'SampleWordDocument.tiff');
 	$response = $wordsApi->PutDocumentSaveAsTiff(name=> $name, body=>$saveOptionsData); 	
 	isa_ok($response, 'AsposeWordsCloud::Object::SaveResponse');
 	is($response->{'Status'}, "OK");
};

subtest 'testGetDocumentBookmarks' => sub {
	my $name = 'SampleWordDocument.docx';
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 
 	$response = $wordsApi->GetDocumentBookmarks(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::BookmarksResponse');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostUpdateDocumentBookmark' => sub {
	my $name = 'SampleWordDocument.docx';
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 
 	my $bookmarkDataBody = AsposeWordsCloud::Object::BookmarkData->new( 'Name' => 'aspose', 'Text' => 'Bookmark is very good');
 	$response = $wordsApi->PostUpdateDocumentBookmark(name=> $name, bookmarkName=>'aspose',  body=> $bookmarkDataBody);
 	isa_ok($response, 'AsposeWordsCloud::Object::BookmarkResponse');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentBookmarkByName' => sub {
	my $name = 'SampleWordDocument.docx';
	my $bookmarkName = 'aspose';
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 
 	$response = $wordsApi->GetDocumentBookmarkByName(name=> $name, bookmarkName=>$bookmarkName);
 	isa_ok($response, 'AsposeWordsCloud::Object::BookmarkResponse');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentProperties' => sub {
	my $name = 'SampleWordDocument.docx';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK"); 
 	$response = $wordsApi->GetDocumentProperties(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::DocumentPropertiesResponse');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPutUpdateDocumentProperty' => sub {
	my $name = 'SampleWordDocument.docx';
	my $propertyName = 'Author';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK"); 
	my $propertyBody = AsposeWordsCloud::Object::DocumentProperty->new( 'Name' => 'Author', 'Value' => 'Farooq Sheikh');
 	$response = $wordsApi->PutUpdateDocumentProperty(name=> $name, propertyName=>$propertyName, body=>$propertyBody);
 	isa_ok($response, 'AsposeWordsCloud::Object::DocumentPropertyResponse');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testDeleteDocumentProperty' => sub {
	my $name = 'SampleWordDocument.docx';
	my $propertyName = 'AsposeAuthor';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
 	$response = $wordsApi->DeleteDocumentProperty(name=> $name, propertyName=>$propertyName);
 	isa_ok($response, 'AsposeWordsCloud::Object::SaaSposeResponse');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentProperty' => sub {
	my $name = 'SampleWordDocument.docx';
	my $propertyName = 'Author';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
 	$response = $wordsApi->GetDocumentProperty(name=> $name, propertyName=>$propertyName);
 	isa_ok($response, 'AsposeWordsCloud::Object::DocumentPropertyResponse');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentDrawingObjects' => sub {
	my $name = 'SampleWordDocument.docx';	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
 	$response = $wordsApi->GetDocumentDrawingObjects(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::DrawingObjectsResponse');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentDrawingObjectByIndex' => sub {
	my $name = 'SampleWordDocument.docx';	
	my $objectIndex = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
 	$response = $wordsApi->GetDocumentDrawingObjects(name=> $name, objectIndex=>$objectIndex);
 	isa_ok($response, 'AsposeWordsCloud::Object::DrawingObjectsResponse');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentDrawingObjectByIndexWithFormat' => sub {
	my $name = 'SampleWordDocument.docx';	
	my $objectIndex = 1;
	my $format = 'jpg';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
 	$response = $wordsApi->GetDocumentDrawingObjectByIndexWithFormat(name=> $name, objectIndex=>$objectIndex, format=>$format); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentDrawingObjectImageData' => sub {
	my $name = 'SampleWordDocument.docx';	
	my $objectIndex = 1;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
 	$response = $wordsApi->GetDocumentDrawingObjectImageData(name=> $name, objectIndex=>$objectIndex); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentDrawingObjectOleData' => sub {
	my $name = 'sample_EmbeddedOLE.docx';	
	my $objectIndex = 0;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
 	$response = $wordsApi->GetDocumentDrawingObjectOleData(name=> $name, objectIndex=>$objectIndex); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostDocumentExecuteMailMerge' => sub {
	my $name = 'SampleMailMergeTemplateImage.doc';
	my $document1 =  'aspose-cloud.png';	
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $storageApi->PutCreate(Path => $document1, file => $data_path.$document1);
	is($response->{'Status'}, "OK");
	
 	$response = $wordsApi->PostDocumentExecuteMailMerge(name=> $name, file=>$data_path.'SampleMailMergeTemplateImageData.txt', withRegions=>'False');
 	isa_ok($response, 'AsposeWordsCloud::Object::DocumentResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostExecuteTemplate' => sub {
	my $name = 'SampleExecuteTemplate.doc';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->PostExecuteTemplate(name=> $name, file=>$data_path.'SampleExecuteTemplateData.txt');
 	isa_ok($response, 'AsposeWordsCloud::Object::DocumentResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testDeleteDocumentFields' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->DeleteDocumentFields(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::SaaSposeResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testDeleteHeadersFooters' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->DeleteHeadersFooters(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::SaaSposeResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentHyperlinks' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->GetDocumentHyperlinks(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::HyperlinksResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentHyperlinkByIndex' => sub {
	my $name = 'SampleWordDocument.docx';
	my $hyperlinkIndex = 0;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->GetDocumentHyperlinkByIndex(name=> $name, hyperlinkIndex=>$hyperlinkIndex);
 	isa_ok($response, 'AsposeWordsCloud::Object::HyperlinkResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostInsertPageNumbers' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	my $pageNumberBody = AsposeWordsCloud::Object::PageNumber->new('Format' => '{PAGE} of {NUMPAGES}', 'Alignment' => 'center');
	$response = $wordsApi->PostInsertPageNumbers(name=> $name, body=>$pageNumberBody);
 	isa_ok($response, 'AsposeWordsCloud::Object::DocumentResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostInsertWatermarkImage' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->PostInsertWatermarkImage(name=> $name, file => $data_path.'aspose-cloud.png');
 	isa_ok($response, 'AsposeWordsCloud::Object::DocumentResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostInsertWatermarkText' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	my $watermarkText = AsposeWordsCloud::Object::WatermarkText->new('Text' => 'Welcome Aspose', 'RotationAngle' => '45');
	$response = $wordsApi->PostInsertWatermarkText(name=> $name, body=>$watermarkText);
 	isa_ok($response, 'AsposeWordsCloud::Object::DocumentResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testDeleteDocumentMacros' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->DeleteDocumentMacros(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::SaaSposeResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentFieldNames' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->GetDocumentFieldNames(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::FieldNamesResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentParagraphs' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->GetDocumentParagraphs(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::ParagraphLinkCollectionResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentParagraph' => sub {
	my $name = 'SampleWordDocument.docx';
	my $index = 1;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->GetDocumentParagraph(name=> $name, index=>$index);
 	isa_ok($response, 'AsposeWordsCloud::Object::ParagraphResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testDeleteParagraphFields' => sub {
	my $name = 'SampleWordDocument.docx';
	my $index = 0;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->DeleteParagraphFields(name=> $name, index=>$index);
 	isa_ok($response, 'AsposeWordsCloud::Object::SaaSposeResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentParagraphRun' => sub {
	my $name = 'SampleWordDocument.docx';
	my $index = 0;
	my $runIndex = 0;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->GetDocumentParagraphRun(name=> $name, index=>$index, runIndex=>$runIndex);
 	isa_ok($response, 'AsposeWordsCloud::Object::RunResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentParagraphRunFont' => sub {
	my $name = 'SampleWordDocument.docx';
	my $index = 0;
	my $runIndex = 0;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->GetDocumentParagraphRunFont(name=> $name, index=>$index, runIndex=>$runIndex);
 	isa_ok($response, 'AsposeWordsCloud::Object::FontResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostDocumentParagraphRunFont' => sub {
	my $name = 'SampleWordDocument.docx';
	my $index = 0;
	my $runIndex = 0;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	my $font = AsposeWordsCloud::Object::Font->new('Name' => 'Arial', 'Bold' => 'True');

	$response = $wordsApi->PostDocumentParagraphRunFont(name=> $name, index=>$index, runIndex=>$runIndex, body=>$font);
 	isa_ok($response, 'AsposeWordsCloud::Object::FontResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPutProtectDocument' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	my $protectionRequest = AsposeWordsCloud::Object::ProtectionRequest->new('Password' => 'aspose', 'ProtectionType' => 'ReadOnly');

	$response = $wordsApi->PutProtectDocument(name=> $name, body=>$protectionRequest);
 	isa_ok($response, 'AsposeWordsCloud::Object::ProtectionDataResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostChangeDocumentProtection' => sub {
	my $name = 'SampleProtectedBlankWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	my $protectionRequest = AsposeWordsCloud::Object::ProtectionRequest->new('Password' => 'aspose','NewPassword' => '', 'ProtectionType' => 'NoProtection');

	$response = $wordsApi->PostChangeDocumentProtection(name=> $name, body=>$protectionRequest);
 	isa_ok($response, 'AsposeWordsCloud::Object::ProtectionDataResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testDeleteUnprotectDocument' => sub {
	my $name = 'SampleProtectedBlankWordDocument.docx';
	my $destfilename = "updated-" . $name;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	my $protectionRequest = AsposeWordsCloud::Object::ProtectionRequest->new('Password' => 'aspose');

	$response = $wordsApi->DeleteUnprotectDocument(name=> $name, body=>$protectionRequest, filename =>$destfilename);
 	isa_ok($response, 'AsposeWordsCloud::Object::ProtectionDataResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentProtection' => sub {
	my $name = 'SampleProtectedBlankWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->GetDocumentProtection(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::ProtectionDataResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostReplaceText' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	my $replaceTextRequest = AsposeWordsCloud::Object::ReplaceTextRequest->new('OldValue' => 'aspose', 'NewValue' =>  'aspose.com');
	$response = $wordsApi->PostReplaceText(name=> $name, body=>$replaceTextRequest);
 	isa_ok($response, 'AsposeWordsCloud::Object::ReplaceTextResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testAcceptAllRevisions' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->AcceptAllRevisions(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::RevisionsModificationResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testRejectAllRevisions' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->RejectAllRevisions(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::RevisionsModificationResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetSections' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->GetSections(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::SectionLinkCollectionResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetSection' => sub {
	my $name = 'SampleWordDocument.docx';
	my $sectionIndex = 0;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->GetSection(name=> $name, sectionIndex=>$sectionIndex);
 	isa_ok($response, 'AsposeWordsCloud::Object::SectionResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testDeleteSectionFields' => sub {
	my $name = 'SampleWordDocument.docx';
	my $sectionIndex = 0;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->DeleteSectionFields(name=> $name, sectionIndex=>$sectionIndex);
 	isa_ok($response, 'AsposeWordsCloud::Object::SaaSposeResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetSectionPageSetup' => sub {
	my $name = 'SampleWordDocument.docx';
	my $sectionIndex = 0;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->GetSectionPageSetup(name=> $name, sectionIndex=>$sectionIndex);
 	isa_ok($response, 'AsposeWordsCloud::Object::SectionPageSetupResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testUpdateSectionPageSetup' => sub {
	my $name = 'SampleWordDocument.docx';
	my $sectionIndex = 0;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	my $pageSetup = AsposeWordsCloud::Object::PageSetup->new(
															'RtlGutter' => 'True',
															'LeftMargin' => 10.0,
															'Orientation' => 'Landscape',
															'PaperSize' => 'A5'
															);
	
	$response = $wordsApi->UpdateSectionPageSetup(name=> $name, sectionIndex=>$sectionIndex, body=>$pageSetup);
 	isa_ok($response, 'AsposeWordsCloud::Object::SectionPageSetupResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testDeleteSectionParagraphFields' => sub {
	my $name = 'SampleWordDocument.docx';
	my $sectionIndex = 0;
	my $paragraphIndex = 0;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->DeleteSectionParagraphFields(name=> $name, sectionIndex=>$sectionIndex, paragraphIndex=>$paragraphIndex);
 	isa_ok($response, 'AsposeWordsCloud::Object::SaaSposeResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testDeleteFormField' => sub {
	my $name = 'FormFilled.docx';
	my $sectionIndex = 0;
	my $paragraphIndex = 0;
	my $formfieldIndex = 0;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->DeleteFormField(name=> $name, sectionIndex=>$sectionIndex, 
										paragraphIndex=>$paragraphIndex, formfieldIndex=>$formfieldIndex);
 	isa_ok($response, 'AsposeWordsCloud::Object::SaaSposeResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetFormField' => sub {
	my $name = 'FormFilled.docx';
	my $sectionIndex = 0;
	my $paragraphIndex = 0;
	my $formfieldIndex = 0;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->GetFormField(name=> $name, sectionIndex=>$sectionIndex, 
										paragraphIndex=>$paragraphIndex, formfieldIndex=>$formfieldIndex);
 	isa_ok($response, 'AsposeWordsCloud::Object::FormFieldResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostSplitDocument' => sub {
	my $name = 'SampleWordDocument.docx';
	my $format = 'text';
	my $from = 1;
	my $to = 2;
	my $zipOutput = 'False';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->PostSplitDocument(name=> $name, format=>$format, 
										from=>$from, to=>$to, zipOutput=>$zipOutput );
 	isa_ok($response, 'AsposeWordsCloud::Object::SplitDocumentResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentStatistics' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->GetDocumentStatistics(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::StatDataResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocumentTextItems' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->GetDocumentTextItems(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::TextItemsResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostUpdateDocumentFields' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->PostUpdateDocumentFields(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::DocumentResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testDeleteDocumentWatermark' => sub {
	my $name = 'SampleBlankWatermarkDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->DeleteDocumentWatermark(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::DocumentResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostInsertDocumentWatermarkImage' => sub {
	my $name = 'SampleWordDocument.docx';
	my $image = 'aspose-cloud.png';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $storageApi->PutCreate(Path => $image, file => $data_path.$image);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->PostInsertDocumentWatermarkImage(name=> $name, file => $data_path.$image);
 	isa_ok($response, 'AsposeWordsCloud::Object::DocumentResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostInsertDocumentWatermarkText' => sub {
	my $name = 'SampleWordDocument.docx';
	my $image = 'aspose-cloud.png';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	my $watermarkText = AsposeWordsCloud::Object::WatermarkText->new('Text' => 'aspose.com');
	
	$response = $wordsApi->PostInsertDocumentWatermarkText(name=> $name, body => $watermarkText);
 	isa_ok($response, 'AsposeWordsCloud::Object::DocumentResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetComments' => sub {
	my $name = 'SampleWordDocument.docx';

	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->GetComments(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::CommentsResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetComment' => sub {
	my $name = 'SampleWordDocument.docx';
	my $commentIndex = 0;

	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->GetComment(name=> $name, commentIndex=>$commentIndex);
 	isa_ok($response, 'AsposeWordsCloud::Object::CommentResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testDeleteComment' => sub {
	my $name = 'SampleWordDocument.docx';
	my $commentIndex = 0;

	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->DeleteComment(name=> $name, commentIndex=>$commentIndex);
 	isa_ok($response, 'AsposeWordsCloud::Object::SaaSposeResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testSearch' => sub {
	my $name = 'SampleWordDocument.docx';
	my $pattern = 'aspose';

	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->Search(name=> $name, pattern=>$pattern);
 	isa_ok($response, 'AsposeWordsCloud::Object::SearchResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostComment' => sub {
	my $name = 'SampleWordDocument.docx';
	my $commentIndex = 0;

	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	my $rangeStartNode = AsposeWordsCloud::Object::NodeLink->new('Text' => 'Font Formatting', 'NodeId'=> '0.0.1');
	my $rangeStart = AsposeWordsCloud::Object::DocumentPositionDto->new('Node' => $rangeStartNode);
	
	my $rangeEndNode = AsposeWordsCloud::Object::NodeLink->new('Text' => 'Font Formatting', 'NodeId'=> '0.0.1');
	my $rangeEnd = AsposeWordsCloud::Object::DocumentPositionDto->new('Node' => $rangeEndNode);
	my $commentDtoBody = AsposeWordsCloud::Object::CommentDto->new(
    		'RangeStart'=> $rangeStart,
    		    'RangeEnd'=> $rangeEnd,
        		    'Initial' => 'FS',
        		    'Author' => 'Farooq Sheikh',
        		    'Text'=> 'This is a new comment'
        		    );
	$response = $wordsApi->PostComment(name=> $name, commentIndex=> $commentIndex, body=>$commentDtoBody);
 	isa_ok($response, 'AsposeWordsCloud::Object::CommentResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPutComment' => sub {
	my $name = 'SampleWordDocument.docx';
	my $commentIndex = 0;

	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	my $rangeStartNode = AsposeWordsCloud::Object::NodeLink->new('Text' => 'Font Formatting', 'NodeId'=> '0.0.1');
	my $rangeStart = AsposeWordsCloud::Object::DocumentPositionDto->new('Node' => $rangeStartNode);
	
	my $rangeEndNode = AsposeWordsCloud::Object::NodeLink->new('Text' => 'Font Formatting', 'NodeId'=> '0.0.1');
	my $rangeEnd = AsposeWordsCloud::Object::DocumentPositionDto->new('Node' => $rangeEndNode);
	my $commentDtoBody = AsposeWordsCloud::Object::CommentDto->new(
    		'RangeStart'=> $rangeStart,
    		    'RangeEnd'=> $rangeEnd,
        		    'Initial' => 'FS',
        		    'Author' => 'Farooq Sheikh',
        		    'Text'=> 'This is a new comment'
        		    );
	$response = $wordsApi->PutComment(name=> $name, commentIndex=> $commentIndex, body=>$commentDtoBody);
 	isa_ok($response, 'AsposeWordsCloud::Object::CommentResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostFormField' => sub {
	my $name = 'FormFilled.docx';
	my $sectionIndex = 0;
	my $paragraphIndex = 0;
	my $formfieldIndex = 0;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	my $xmlBody = '<FormFieldTextInput>'
            . '<Name>MyName</Name>'
            . '<Enabled>true</Enabled>'
            . '<StatusText />'
            . '<OwnStatus>false</OwnStatus>'
            . '<HelpText />'
            . '<OwnHelp>false</OwnHelp>'
            . '<CalculateOnExit>true</CalculateOnExit>'
            . '<EntryMacro />'
            . '<ExitMacro />'
            . '<TextInputFormat>UPPERCASE</TextInputFormat>'
            . '<TextInputType>Regular</TextInputType>'
            . '<TextInputDefault>Farooq Sheikh</TextInputDefault>'
            . '</FormFieldTextInput>';
            															
	$response = $wordsApi->PostFormField(name=> $name, sectionIndex=>$sectionIndex, 
										paragraphIndex=>$paragraphIndex, formfieldIndex=>$formfieldIndex, body=>$xmlBody);
 	isa_ok($response, 'AsposeWordsCloud::Object::FormFieldResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPutFormField' => sub {
	my $name = 'SampleBlankWordDocument.docx';
	my $sectionIndex = 0;
	my $paragraphIndex = 0;
	my $insertBeforeNode = "";
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	my $xmlBody = '<FormFieldTextInput>'
            . '<Name>MyName</Name>'
            . '<Enabled>true</Enabled>'
            . '<StatusText />'
            . '<OwnStatus>false</OwnStatus>'
            . '<HelpText />'
            . '<OwnHelp>false</OwnHelp>'
            . '<CalculateOnExit>true</CalculateOnExit>'
            . '<EntryMacro />'
            . '<ExitMacro />'
            . '<TextInputFormat>UPPERCASE</TextInputFormat>'
            . '<TextInputType>Regular</TextInputType>'
            . '<TextInputDefault>Farooq Sheikh</TextInputDefault>'
            . '</FormFieldTextInput>';
															
	$response = $wordsApi->PutFormField(name=> $name, sectionIndex=>$sectionIndex, 
										paragraphIndex=>$paragraphIndex, insertBeforeNode=>$insertBeforeNode, body=>$xmlBody);
 	isa_ok($response, 'AsposeWordsCloud::Object::FormFieldResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostAppendDocument' => sub {
	my $name =  'SampleWordDocument.docx';
	my $document1 =  'SampleWordDocument.docx';
	my $document2 =  'SampleWordDocument.docx';

	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK"); 	
	 	
	my @docEntry1 = AsposeWordsCloud::Object::DocumentEntry->new('Href' => $document1, 'ImportFormatMode' => 'KeepSourceFormatting');
	my @docEntry2 = AsposeWordsCloud::Object::DocumentEntry->new('Href' => $document2, 'ImportFormatMode' => 'KeepSourceFormatting');
	my $documentEntryList = AsposeWordsCloud::Object::DocumentEntryList->new('DocumentEntries' => [@docEntry1, @docEntry2]);

 	$response = $wordsApi->PostAppendDocument(name=> $name, body=> $documentEntryList); 	
 	isa_ok($response, 'AsposeWordsCloud::Object::DocumentResponse');
 	is($response->{'Status'}, "OK");
};

subtest 'testPutExecuteMailMergeOnline' => sub {
	my $name = 'SampleMailMergeTemplate.docx';
	my $data = 'SampleMailMergeTemplateData.txt';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	$response = $storageApi->PutCreate(Path => $data, file => $data_path.$data);
	is($response->{'Status'}, "OK");
 	$response = $wordsApi->PutExecuteMailMergeOnline(withRegions => 'False', file => $data_path.$name, data=>$data_path.$data);
 	isa_ok($response, 'AsposeWordsCloud::Object::ResponseMessage');
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPutExecuteTemplateOnline' => sub {
	my $name = 'SampleExecuteTemplate.doc';
	my $data = 'SampleExecuteTemplateData.txt';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	$response = $storageApi->PutCreate(Path => $data, file => $data_path.$data);
	is($response->{'Status'}, "OK");
 	$response = $wordsApi->PutExecuteTemplateOnline(withRegions => 'False', file => $data_path.$name, data=>$data_path.$data);
 	isa_ok($response, 'AsposeWordsCloud::Object::ResponseMessage');
 	is($response->{'Status'}, "OK"); 
};

=pod

subtest 'testPostField' => sub {
	my $name = 'SampleWordDocument.docx';
	my $sectionIndex = 0;
	my $paragraphIndex = 0;
	my $fieldIndex = 0;

	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	my $fieldDto = AsposeWordsCloud::Object::FieldDto->new('Result' => 'John Doe');
	
	$response = $wordsApi->PostField(name=> $name, sectionIndex=>$sectionIndex, paragraphIndex=>$paragraphIndex, fieldIndex=>$fieldIndex, body =>$fieldDto);
 	isa_ok($response, 'AsposeWordsCloud::Object::SearchResponse'); 	
 	is($response->{'Status'}, "OK"); 
};



subtest 'testPutField' => sub {
	my $name = 'SampleWordDocument.docx';
	my $sectionIndex = 0;
	my $paragraphIndex = 0;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	my $fieldDto = AsposeWordsCloud::Object::FieldDto->new('Result' => 'John Doe', 'FieldCode' => '{FORMTEXT }','NodeId' => '0.1');
	
	$response = $wordsApi->PutField(name=> $name, sectionIndex=>$sectionIndex, paragraphIndex=>$paragraphIndex, body =>$fieldDto);
 	isa_ok($response, 'AsposeWordsCloud::Object::SearchResponse'); 	
 	is($response->{'Status'}, "OK"); 
};


subtest 'testPostRunTask' => sub {
	my $name = 'SampleWordDocument.docx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
	is($response->{'Status'}, "OK");
	
	$response = $wordsApi->PostRunTask(name=> $name);
 	isa_ok($response, 'AsposeWordsCloud::Object::SearchResponse'); 	
 	is($response->{'Status'}, "OK"); 
};

=cut
done_testing();