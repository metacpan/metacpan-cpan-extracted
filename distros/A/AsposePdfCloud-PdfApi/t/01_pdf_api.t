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

use AsposePdfCloud::PdfApi;
use AsposePdfCloud::ApiClient;
use AsposePdfCloud::Configuration;

use AsposePdfCloud::Object::TiffExportOptions;
use AsposePdfCloud::Object::AppendDocument;
use AsposePdfCloud::Object::DocumentProperty;
use AsposePdfCloud::Object::Rectangle;
use AsposePdfCloud::Object::Field;
use AsposePdfCloud::Object::Fields;
use AsposePdfCloud::Object::TextReplace;
use AsposePdfCloud::Object::Stamp;
use AsposePdfCloud::Object::Signature;
use AsposePdfCloud::Object::MergeDocuments;
use AsposePdfCloud::Object::TextReplaceListRequest;

use_ok('AsposePdfCloud::Configuration');
use_ok('AsposePdfCloud::ApiClient');
use_ok('AsposePdfCloud::PdfApi');

$AsposePdfCloud::Configuration::app_sid = 'XXX';
$AsposePdfCloud::Configuration::api_key = 'XXX';

$AsposePdfCloud::Configuration::debug = 1;

if(not defined $AsposePdfCloud::Configuration::app_sid or $AsposePdfCloud::Configuration::app_sid =~ /^XXX/i){
		done_testing();
    	exit;
  }else{
  	$AsposeStorageCloud::Configuration::app_sid = $AsposePdfCloud::Configuration::app_sid;
  }
    
if (not defined $AsposePdfCloud::Configuration::api_key or $AsposePdfCloud::Configuration::api_key =~ /^XXX/i){
	done_testing();
    exit;
}else{
	$AsposeStorageCloud::Configuration::api_key = $AsposePdfCloud::Configuration::api_key;
}

my $data_path = './data/';

if (not -d $data_path){
	done_testing();
    exit;
}

if($AsposePdfCloud::Configuration::debug){
	$AsposeStorageCloud::Configuration::debug = $AsposePdfCloud::Configuration::debug;
}

my $storageApi = AsposeStorageCloud::StorageApi->new();
my $pdfApi = AsposePdfCloud::PdfApi->new();


subtest 'testPutConvertDocument' => sub {
	my $filename = 'Sample';
	my $name = $filename . '.pdf';
	my $format = "TIFF";
 	my $response = $pdfApi->PutConvertDocument(format=>$format, file=> $data_path.$name);
 	is($response->{'Status'}, "OK"); 
};

subtest 'testGetDocument' => sub {
	my $name = 'Sample.pdf';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 
 	$response = $pdfApi->GetDocument(name=>$name);
 	is($response->{'Status'}, "OK"); 
 	isa_ok($response, 'AsposePdfCloud::Object::DocumentResponse');
 	
};


subtest 'testPutCreateDocument' => sub {
	my $name = 'Sample_';
	for (0..4) { $name .= chr( int(rand(25) + 65) ); }
	$name = $name.'.pdf';
	my $response = $pdfApi->PutCreateDocument(name=>$name);
 	is($response->{'Status'}, "OK"); 
 	isa_ok($response, 'AsposePdfCloud::Object::DocumentResponse');
 	
};

subtest 'testGetDocumentWithFormat' => sub {
	my $filename = 'Sample';
	my $name = $filename . '.pdf';
	my $format = "DOC";
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 
 	$response = $pdfApi->GetDocumentWithFormat(name=>$name, format=> $format);
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPutDocumentSaveAsTiff' => sub {
	my $name =  'Sample.pdf';
	my @tiffExportOptions = AsposePdfCloud::Object::TiffExportOptions->new('ResultFile' => 'Sample.tiff');
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 
 	$response = $pdfApi->PutDocumentSaveAsTiff(name=>$name, body=> @tiffExportOptions);
 	is($response->{'Status'}, "OK"); 
};

subtest 'testPostAppendDocument' => sub {
	my $name =  'Sample.pdf';
	my $startPage = 2;
	my $endPage = 3;
	my $appendFileName = 'sample-input.pdf';	
	my @appendDocumentBody = AsposePdfCloud::Object::AppendDocument->new('Document' => $appendFileName, 'StartPage'=>$startPage, 'EndPage'=>$endPage );
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $storageApi->PutCreate(Path => $appendFileName, file => $data_path.$appendFileName);
 	is($response->{'Status'}, "OK"); 
 	$response = $pdfApi->PostAppendDocument(name=>$name, appendFileName=>$appendFileName, body=>@appendDocumentBody);
 	is($response->{'Status'}, "OK"); 
 	isa_ok($response, 'AsposePdfCloud::Object::DocumentResponse');
};

subtest 'testGetDocumentAttachments' => sub {
	my $name =  'SampleAttachment.pdf';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetDocumentAttachments(name=>$name);
 	is($response->{'Status'}, "OK"); 
 	isa_ok($response, 'AsposePdfCloud::Object::AttachmentsResponse');
};

subtest 'testGetDocumentAttachmentByIndex' => sub {
	my $name =  'SampleAttachment.pdf';
	my $attachmentIndex = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetDocumentAttachmentByIndex(name=>$name, attachmentIndex=>$attachmentIndex);
 	is($response->{'Status'}, "OK"); 
 	isa_ok($response, 'AsposePdfCloud::Object::AttachmentResponse');
};

subtest 'testGetDownloadDocumentAttachmentByIndex' => sub {
	my $name =  'SampleAttachment.pdf';
	my $attachmentIndex = 1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetDownloadDocumentAttachmentByIndex(name=>$name, attachmentIndex=>$attachmentIndex);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetDocumentBookmarks' => sub {
	my $name =  'Sample-Bookmark.pdf';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetDocumentBookmarks(name=>$name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::BookmarksResponse');
};

subtest 'testGetDocumentBookmarksChildren' => sub {
	my $name =  'Sample-Bookmark.pdf';
	my $bookmarkPath = '1';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetDocumentBookmarksChildren(name=>$name, bookmarkPath=>$bookmarkPath);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::BookmarkResponse');
};

subtest 'testGetDocumentProperties' => sub {
	my $name =  'Sample-Annotation.pdf';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetDocumentProperties(name=>$name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::DocumentPropertiesResponse');
};


subtest 'testDeleteProperties' => sub {
	my $name =  'Sample-Annotation.pdf';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetDocumentProperties(name=>$name);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetDocumentProperty' => sub {
	my $name =  'Sample-Annotation.pdf';
	my $propertyName = 'author';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetDocumentProperty(name=>$name,propertyName=>$propertyName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::DocumentPropertyResponse');
};

subtest 'testPutSetProperty' => sub {
	my $name =  'Sample-Annotation.pdf';
	my $propertyName = 'AsposeDev';
	my @documentPropertyBody = AsposePdfCloud::Object::DocumentProperty->new('Name' => 'AsposeDev', 'Value'=>'Farooq Sheikh', 'BuiltIn'=>'False' );
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->PutSetProperty(name=>$name,propertyName=>$propertyName, body=>@documentPropertyBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::DocumentPropertyResponse');
};

subtest 'testDeleteProperty' => sub {
	my $name =  'Sample-Annotation-Property.pdf';
	my $propertyName = 'AsposeDev';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->DeleteProperty(name=>$name,propertyName=>$propertyName);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostCreateField' => sub {
	my $name =  'sample-field.pdf';
	my $page = 1;
	my @rect = AsposePdfCloud::Object::Rectangle->new('X' => 100, 'Y' => 100, 'Height' => 100, 'Width' => 200);
	my @fieldbody = AsposePdfCloud::Object::Field->new('Name' => 'checkBoxField2', 'Values'=>['1'], 'Type'=>'Boolean', 'Rect' => @rect);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->PostCreateField(name=>$name,page=>$page, body=>@fieldbody);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetFields' => sub {
	my $name =  'sample-field.pdf';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetFields(name=>$name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::FieldsResponse');
};

subtest 'testPutUpdateFields' => sub {
	my $name =  'sample-field.pdf';
	my $page = 1;
	my @field = AsposePdfCloud::Object::Field->new('Name' => 'textbox1', 'Values'=>['Aspose']);
	my @fieldsbody = AsposePdfCloud::Object::Fields->new('List' => [@field]);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->PutUpdateFields(name=>$name, body=>@fieldsbody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::FieldsResponse');
};

subtest 'testGetField' => sub {
	my $name =  'sample-field.pdf';
	my $fieldName = 'textbox1';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetField(name=>$name, fieldName=>$fieldName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::FieldResponse');
};

subtest 'testPutUpdateField' => sub {
	my $name =  'sample-field.pdf';
	my $fieldName = 'textbox1';
	my @fieldbody = AsposePdfCloud::Object::Field->new('Name' => 'textbox1', 'Values'=>['Aspose']);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->PutUpdateField(name=>$name, fieldName=>$fieldName, body=>@fieldbody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::FieldResponse');
};


subtest 'testPutMergeDocuments' => sub {
	my $name =  'sample-merged.pdf';
	my $mergefilename1 = 'Sample.pdf';
	my $mergefilename2 = 'sample-input.pdf';
	
	my @mergeDocumentsBody = AsposePdfCloud::Object::MergeDocuments->new('List' => [$mergefilename1,$mergefilename2 ]);
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $storageApi->PutCreate(Path => $mergefilename1, file => $data_path.$mergefilename1);
 	is($response->{'Status'}, "OK");
 	
 	$response = $storageApi->PutCreate(Path => $mergefilename2, file => $data_path.$mergefilename2);
 	is($response->{'Status'}, "OK");
 	
 	$response = $pdfApi->PutMergeDocuments(name=>$name,body=>@mergeDocumentsBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::DocumentResponse');
};

subtest 'testGetPages' => sub {
	my $name =  'Sample-Annotation.pdf';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetPages(name=>$name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::DocumentPagesResponse');
};

subtest 'testPutAddNewPage' => sub {
	my $name =  'Sample-Annotation.pdf';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->PutAddNewPage(name=>$name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::DocumentPagesResponse');
};

subtest 'testGetWordsPerPage' => sub {
	my $name =  'Sample-Annotation.pdf';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetWordsPerPage(name=>$name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::WordCountResponse');
};

subtest 'testGetPage' => sub {
	my $name =  'Sample-Annotation.pdf';
	my $pageNumber =  1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetPage(name=>$name, pageNumber=>$pageNumber);
 	is($response->{'Status'}, "OK");
};


subtest 'testDeletePage' => sub {
	my $name =  'Sample-Annotation.pdf';
	my $pageNumber =  1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->DeletePage(name=>$name, pageNumber=>$pageNumber);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetPageWithFormat' => sub {
	my $name =  'Sample-Annotation.pdf';
	my $pageNumber =  1;
	my $format = 'png';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetPageWithFormat(name=>$name, pageNumber=>$pageNumber , format=>$format);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetPageAnnotations' => sub {
	my $name =  'Sample-Annotation.pdf';
	my $pageNumber =  1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetPageAnnotations(name=>$name, pageNumber=>$pageNumber);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::AnnotationsResponse');
};


subtest 'testGetPageAnnotation' => sub {
	my $name =  'Sample-Annotation.pdf';
	my $pageNumber =  1;
	my $annotationNumber =  1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetPageAnnotation(name=>$name, pageNumber=>$pageNumber, annotationNumber=>$annotationNumber);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::AnnotationResponse');
};


subtest 'testGetFragments' => sub {
	my $name =  'sample-input.pdf';
	my $pageNumber =  1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetFragments(name=>$name, pageNumber=>$pageNumber);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::TextItemsResponse');
};

subtest 'testGetFragment' => sub {
	my $name =  'sample-input.pdf';
	my $pageNumber =  1;
	my $fragmentNumber =  1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetFragment(name=>$name, pageNumber=>$pageNumber, fragmentNumber=>$fragmentNumber);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::TextItemsResponse');
};


subtest 'testGetSegments' => sub {
	my $name =  'Sample-Annotation.pdf';
	my $pageNumber =  1;
	my $fragmentNumber =  1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetSegments(name=>$name, pageNumber=>$pageNumber, fragmentNumber=>$fragmentNumber);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::TextItemsResponse');
};


subtest 'testGetSegment' => sub {
	my $name = 'sample-input.pdf';
	my $pageNumber =  1;
	my $fragmentNumber =  1;
	my $segmentNumber =  1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetSegment(name=>$name, pageNumber=>$pageNumber, fragmentNumber=>$fragmentNumber, segmentNumber=>$segmentNumber);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::TextItemResponse');
};


subtest 'testGetSegmentTextFormat' => sub {
	my $name =  'sample-input.pdf';
	my $pageNumber =  1;
	my $fragmentNumber =  1;
	my $segmentNumber =  1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetSegmentTextFormat(name=>$name, pageNumber=>$pageNumber, fragmentNumber=>$fragmentNumber, segmentNumber=>$segmentNumber);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::TextFormatResponse');
};

subtest 'testGetFragmentTextFormat' => sub {
	my $name =  'sample-input.pdf';
	my $pageNumber =  1;
	my $fragmentNumber =  1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetFragmentTextFormat(name=>$name, pageNumber=>$pageNumber, fragmentNumber=>$fragmentNumber);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::TextFormatResponse');
};

subtest 'testGetImages' => sub {
	my $name =  'SampleImage.pdf';
	my $pageNumber =  1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetImages(name=>$name, pageNumber=>$pageNumber);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::ImagesResponse');
};


subtest 'testPostReplaceImage' => sub {
	my $name =  'SampleImage.pdf';
	my $pageNumber =  1;
	my $imageNumber =  1;
	my $imageFile =  'aspose-cloud.png';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->PostReplaceImage(name=>$name, pageNumber=>$pageNumber, imageNumber=>$imageNumber, file => $data_path.$imageFile);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::ImageResponse');
};

subtest 'testGetImage' => sub {
	my $name =  'SampleImage.pdf';
	my $pageNumber =  1;
	my $imageNumber =  1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetImage(name=>$name, pageNumber=>$pageNumber, imageNumber=>$imageNumber);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetImageWithFormat' => sub {
	my $name =  'SampleImage.pdf';
	my $pageNumber =  1;
	my $imageNumber =  1;
	my $format ='jpeg';	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetImageWithFormat(name=>$name, pageNumber=>$pageNumber, imageNumber=>$imageNumber, format=>$format);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetExtractBarcodes' => sub {
	my $name =  'SampleBarCodeImage.pdf';
	my $pageNumber =  1;
	my $imageNumber =  1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetExtractBarcodes(name=>$name, pageNumber=>$pageNumber, imageNumber=>$imageNumber);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::BarcodeResponseList');
 	
};

subtest 'testGetPageLinkAnnotations' => sub {
	my $name =  'Sample-Bookmark.pdf';
	my $pageNumber =  1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetPageLinkAnnotations(name=>$name, pageNumber=>$pageNumber);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::LinkAnnotationsResponse');
 	
};

subtest 'testGetPageLinkAnnotationByIndex' => sub {
	my $name =  'Sample-Bookmark.pdf';
	my $pageNumber =  1;
	my $linkIndex =  1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->GetPageLinkAnnotationByIndex(name=>$name, pageNumber=>$pageNumber, linkIndex=>$linkIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::LinkAnnotationResponse');
 	
};


subtest 'testPostMovePage' => sub {
	my $name =  'Sample-Bookmark.pdf';
	my $pageNumber =  1;
	my $newIndex =  1;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->PostMovePage(name=>$name, pageNumber=>$pageNumber, newIndex=>$newIndex);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testPostPageReplaceText' => sub {
	my $name =  'sample-input.pdf';
	my $pageNumber =  1;
	my @mergeDocumentsBody = AsposePdfCloud::Object::TextReplace->new('OldValue' => 'Sample PDF', 'NewValue' => 'Sample Aspose PDF');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->PostPageReplaceText(name=>$name, pageNumber=>$pageNumber, body=>@mergeDocumentsBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::PageTextReplaceResponse');
 	
};

subtest 'testPostPageReplaceTextList' => sub {
	my $name =  'sample-input.pdf';
	my $pageNumber =  1;
	my @tr1 = AsposePdfCloud::Object::TextReplace->new('OldValue' => 'Sample PDF', 'NewValue' => 'Sample Aspose PDF');
	my @tr2 = AsposePdfCloud::Object::TextReplace->new('OldValue' => 'Sample PDF', 'NewValue' => 'Sample Aspose PDF');
	my @textReplaceListRequestBody = AsposePdfCloud::Object::TextReplaceListRequest->new('TextReplaces' => [@tr1, @tr2]);	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $pdfApi->PostPageReplaceTextList(name=>$name, pageNumber=>$pageNumber, body=>@textReplaceListRequestBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::PageTextReplaceResponse');
 	
};

subtest 'testPutPageAddStamp' => sub {
	my $name =  'sample-input.pdf';
	my $pageNumber =  1;
	my @stampBody = AsposePdfCloud::Object::Stamp->new('Value' => 'Aspose', 'Background' => 'True','Type' => 'Text');
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $pdfApi->PutPageAddStamp(name=>$name, pageNumber=>$pageNumber, body=>@stampBody);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetPageTextItems' => sub {
	my $name =  'Sample-Annotation.pdf';
	my $pageNumber =  1;	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 	
 	$response = $pdfApi->GetPageTextItems(name=>$name, pageNumber=>$pageNumber);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::TextItemsResponse');
 	
};

subtest 'testPostDocumentReplaceText' => sub {
	my $name =  'sample-input.pdf';
	my @textReplaceBody = AsposePdfCloud::Object::TextReplace->new('OldValue' => 'Sample PDF', 'NewValue' => 'Sample Aspose PDF');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 	
 	$response = $pdfApi->PostDocumentReplaceText(name=>$name, body=>@textReplaceBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::DocumentTextReplaceResponse');
 	
};


subtest 'testPostDocumentReplaceTextList' => sub {
	my $name =  'sample-input.pdf';
	my @tr1 = AsposePdfCloud::Object::TextReplace->new('OldValue' => 'Sample', 'NewValue' => 'Sample Aspose');
	my @tr2 = AsposePdfCloud::Object::TextReplace->new('OldValue' => 'PDF', 'NewValue' => 'Aspose PDF');
	my @textReplaceListRequestBody = AsposePdfCloud::Object::TextReplaceListRequest->new('TextReplaces' => [@tr1, @tr2]);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 	
 	$response = $pdfApi->PostDocumentReplaceTextList(name=>$name, body=>@textReplaceListRequestBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::DocumentTextReplaceResponse');
 	
};

subtest 'testPostSplitDocument' => sub {
	my $name =  'sample-input.pdf';
	my $format =  'pdf';
	my $from =  1;
	my $to =  2;
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 	
 	$response = $pdfApi->PostSplitDocument(name=>$name, format=>$format, from=>$from, to=>$to);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::SplitResultResponse');
 	
};

subtest 'testGetTextItems' => sub {
	my $name =  'Sample-Annotation.pdf';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 	
 	$response = $pdfApi->GetTextItems(name=>$name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposePdfCloud::Object::TextItemsResponse');
 	
};

subtest 'testPostSignPage' => sub {
	my $name =  'sample-input.pdf';
	my $pageNumber =  1;
	my $signatureFileName = 'pkc7-sample.pfx';
	my @rect = AsposePdfCloud::Object::Rectangle->new('X' => 100, 'Y' => 100, 'Height' => 100, 'Width' => 200);
	my @signatureBody = AsposePdfCloud::Object::Signature->new(
			'Authority' => 'Farooq Sheikh',
			'Location' => 'Rawalpindi',
			'Contact' => 'farooq.sheikh@aspose.com',
			'Date' => '05/09/2016 2:00:00.000 AM',
			'FormFieldName' =>  'Signature1',
			'Password' => 'aspose',
			'SignaturePath' => $signatureFileName,
			'SignatureType' => 'PKCS7',
			'Visible' => 'True',
			'Rectangle' => @rect
	);
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $storageApi->PutCreate(Path => $signatureFileName, file => $data_path.$signatureFileName);
 	is($response->{'Status'}, "OK");
 	
 	$response = $pdfApi->PostSignPage(name=>$name, pageNumber=>$pageNumber, body=>@signatureBody);
 	is($response->{'Status'}, "OK");
};


subtest 'testPostSignDocument' => sub {
	my $name =  'sample-input-2.pdf';
	my $signatureFileName = 'pkc7-sample.pfx';
	my @rect = AsposePdfCloud::Object::Rectangle->new('X' => 100, 'Y' => 100, 'Height' => 100, 'Width' => 200);
	my @textReplaceListRequestBody = AsposePdfCloud::Object::Signature->new(
			'Authority' => 'Farooq Sheikh',
			'Location' => 'Rawalpindi',
			'Contact' => 'farooq.sheikh@aspose.com',
			'Date' => '05/09/2016 2:00:00.000 AM',
			'FormFieldName' =>  'Signature1',
			'Password' => 'aspose',
			'SignaturePath' => $signatureFileName,
			'SignatureType' => 'PKCS7',
			'Visible' => 'True',
			'Rectangle' => @rect
	);
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $storageApi->PutCreate(Path => $signatureFileName, file => $data_path.$signatureFileName);
 	is($response->{'Status'}, "OK");
 	
 	$response = $pdfApi->PostSignDocument(name=>$name, body=>@textReplaceListRequestBody);
 	is($response->{'Status'}, "OK");
};

done_testing();