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

use AsposeSlidesCloud::SlidesApi;
use AsposeSlidesCloud::ApiClient;
use AsposeSlidesCloud::Configuration;

use AsposeSlidesCloud::Object::DocumentProperty;
use AsposeSlidesCloud::Object::DocumentProperties;
use AsposeSlidesCloud::Object::OrderedMergeRequest;
use AsposeSlidesCloud::Object::PresentationsMergeRequest;
use AsposeSlidesCloud::Object::Portion;
use AsposeSlidesCloud::Object::Shape;
use AsposeSlidesCloud::Object::HtmlExportOptions;
use AsposeSlidesCloud::Object::PdfExportOptions;
use AsposeSlidesCloud::Object::TiffExportOptions;

use_ok('AsposeSlidesCloud::Configuration');
use_ok('AsposeSlidesCloud::ApiClient');
use_ok('AsposeSlidesCloud::SlidesApi');


$AsposeSlidesCloud::Configuration::app_sid = 'XXX';
$AsposeSlidesCloud::Configuration::api_key = 'XXX';

$AsposeSlidesCloud::Configuration::debug = 1;

if(not defined $AsposeSlidesCloud::Configuration::app_sid or $AsposeSlidesCloud::Configuration::app_sid =~ /^XXX/i){
		done_testing();
    	exit;
  }else{
  	$AsposeStorageCloud::Configuration::app_sid = $AsposeSlidesCloud::Configuration::app_sid
  }
    
if (not defined $AsposeSlidesCloud::Configuration::api_key or $AsposeSlidesCloud::Configuration::api_key =~ /^XXX/i){
	done_testing();
    exit;
}else{
	$AsposeStorageCloud::Configuration::api_key = $AsposeSlidesCloud::Configuration::api_key;
}

my $data_path = './data/';

if (not -d $data_path){
	done_testing();
    exit;
}

if($AsposeSlidesCloud::Configuration::debug){
	$AsposeStorageCloud::Configuration::debug = $AsposeSlidesCloud::Configuration::debug;
}

my $storageApi = AsposeStorageCloud::StorageApi->new();
my $slidesApi = AsposeSlidesCloud::SlidesApi->new();

subtest 'testPutSlidesConvert' => sub {
	my $name = 'friday_1484.odp';
	my $format = 'pdf';
 	my $response = $slidesApi->PutSlidesConvert(file => $data_path.$name, format => $format);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetSlidesDocument' => sub {
	my $name = 'sample-input.pptx';
 	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK"); 
 	$response = $slidesApi->GetSlidesDocument(name=> $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::DocumentResponse');
};

subtest 'testPutNewPresentation' => sub {
	my $name = 'sample_';
	for (0..7) { $name .= chr( int(rand(25) + 65) ); }
	$name .= '.pptx';
	my $templatePath = 'sample.pptx';
 	my $response = $slidesApi->PutNewPresentation(name => $name, file => $data_path.$templatePath);
 	isa_ok($response, 'AsposeSlidesCloud::Object::DocumentResponse');
};

subtest 'testPostSlidesDocument' => sub {
	my $name = 'sample_';
	for (0..7) { $name .= chr( int(rand(25) + 65) ); }
	$name .= '.pptx';
	my $templatePath = 'sample.pptx';
	my $response = $storageApi->PutCreate(Path => $templatePath, file => $data_path.$templatePath);
 	is($response->{'Status'}, "OK");
 	$response = $slidesApi->PostSlidesDocument(name => $name, templatePath => $templatePath, file => $data_path.'Test.html');
 	isa_ok($response, 'AsposeSlidesCloud::Object::DocumentResponse');
};


subtest 'testPutNewPresentationFromStoredTemplate' => sub {
	my $name = 'sample_';
	for (0..7) { $name .= chr( int(rand(25) + 65) ); }
	$name .= '.pptx';
	my $templatePath = 'sample.pptx';
	my $response = $storageApi->PutCreate(Path => $templatePath, file => $data_path.$templatePath);
 	is($response->{'Status'}, "OK");
 	$response = $slidesApi->PutNewPresentationFromStoredTemplate(name => $name, templatePath => $templatePath);
 	isa_ok($response, 'AsposeSlidesCloud::Object::DocumentResponse');
};

subtest 'testGetSlidesDocumentWithFormat' => sub {
	my $name = 'sample.pptx';
	my $format = 'tiff';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $slidesApi->GetSlidesDocumentWithFormat(name => $name, format => $format);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetSlidesDocumentProperties' => sub {
	my $name = 'sample-input.pptx';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $slidesApi->GetSlidesDocumentProperties(name => $name);
 	isa_ok($response, 'AsposeSlidesCloud::Object::DocumentPropertiesResponse');
};

subtest 'testPostSlidesSetDocumentProperties' => sub {
	my $name = 'sample-input.pptx';
	
	my @docPop = AsposeSlidesCloud::Object::DocumentProperty->new('Name' => 'Author', 'Value' => 'Farooq Sheikh');
	my @docPops = AsposeSlidesCloud::Object::DocumentProperties->new('List' => [@docPop]);
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $slidesApi->PostSlidesSetDocumentProperties(name => $name, body =>@docPops);
 	isa_ok($response, 'AsposeSlidesCloud::Object::DocumentPropertiesResponse');
};

subtest 'testDeleteSlidesDocumentProperties' => sub {
	my $name = 'sample-input.pptx';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $slidesApi->DeleteSlidesDocumentProperties(name => $name);
 	isa_ok($response, 'AsposeSlidesCloud::Object::DocumentPropertiesResponse');
};

subtest 'testPutSlidesSetDocumentProperty' => sub {
	my $name = 'sample-input.pptx';
	my $propertyName = 'Author';
	my @docPop = AsposeSlidesCloud::Object::DocumentProperty->new('Name' => 'Author', 'Value' => 'Farooq Sheikh');
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $slidesApi->PutSlidesSetDocumentProperty(name => $name, propertyName=>$propertyName, body=>@docPop);
 	isa_ok($response, 'AsposeSlidesCloud::Object::DocumentPropertyResponse');
};

subtest 'testDeleteSlidesDocumentProperty' => sub {
	my $name = 'sample-input.pptx';
	my $propertyName = 'Author';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $slidesApi->DeleteSlidesDocumentProperty(name => $name, propertyName=>$propertyName);
 	is($response->{'Status'}, "OK");
};

subtest 'testPutSlidesDocumentFromHtml' => sub {
	my $name = 'sample_';
	for (0..7) { $name .= chr( int(rand(25) + 65) ); }
	$name .= '.pptx';
 	my $response = $slidesApi->PutSlidesDocumentFromHtml(name => $name, file => $data_path.'ReadMe.html');
 	is($response->{'Status'}, "Created");
 	isa_ok($response, 'AsposeSlidesCloud::Object::DocumentResponse');
};

subtest 'testGetSlidesImages' => sub {
	my $name = 'sample-input.pptx';
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	$response = $slidesApi->GetSlidesImages(name => $name, file => $data_path.'ReadMe.html');
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::ImagesResponse');
};

subtest 'testPutPresentationMerge' => sub {
	my $name = 'sample.pptx';
	my $mergeFile1 = 'welcome.pptx';
	my $mergeFile2 = 'demo.pptx';
	my @orderedMergeRequest = AsposeSlidesCloud::Object::OrderedMergeRequest->new('Presentations' => [$mergeFile1, $mergeFile2]);
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $storageApi->PutCreate(Path => $mergeFile1, file => $data_path.$mergeFile1);
 	is($response->{'Status'}, "OK");
 	
 	$response = $storageApi->PutCreate(Path => $mergeFile2, file => $data_path.$mergeFile2);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PutPresentationMerge(name => $name, body => @orderedMergeRequest);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::DocumentResponse');
};

subtest 'testPostPresentationMerge' => sub {
	my $name = 'sample.pptx';
	my $mergeFile1 = 'welcome.pptx';
	my $mergeFile2 = 'demo.pptx';
	my @presentationsMergeRequest = AsposeSlidesCloud::Object::PresentationsMergeRequest->new('PresentationPaths' => [$mergeFile1, $mergeFile2]);
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $storageApi->PutCreate(Path => $mergeFile1, file => $data_path.$mergeFile1);
 	is($response->{'Status'}, "OK");
 	
 	$response = $storageApi->PutCreate(Path => $mergeFile2, file => $data_path.$mergeFile2);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PostPresentationMerge(name => $name, body => @presentationsMergeRequest);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::DocumentResponse');
};

subtest 'testPostSlidesPresentationReplaceText' => sub {
	my $name = 'sample.pptx';
	my $oldValue = 'aspose';
	my $newValue = 'aspose2';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PostSlidesPresentationReplaceText(name => $name, oldValue => $oldValue, newValue=>$newValue);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::PresentationStringReplaceResponse');
};

subtest 'testGetSlidesSlidesList' => sub {
	my $name = 'sample.pptx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlidesSlidesList(name => $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::SlideListResponse');
};

subtest 'testPostAddEmptySlide' => sub {
	my $name = 'sample.pptx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PostAddEmptySlide(name => $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::SlideListResponse');
};

subtest 'testDeleteSlidesCleanSlidesList' => sub {
	my $name = 'sample.pptx';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->DeleteSlidesCleanSlidesList(name => $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::SlideListResponse');
};

subtest 'testPostSlidesReorderPosition' => sub {
	my $name = 'sample-input.pptx';
	my $oldPosition = 1;
	my $newPosition = 2;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PostSlidesReorderPosition(name => $name, oldPosition=>$oldPosition, newPosition=>$newPosition);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::SlideListResponse');
};

subtest 'testPostAddEmptySlideAtPosition' => sub {
	my $name = 'sample-input.pptx';
	my $position = 1;
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PostAddEmptySlideAtPosition(name => $name, position=>$position);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::SlideListResponse');
};

subtest 'testPostClonePresentationSlide' => sub {
	my $name = 'sample.pptx';
	my $position = 1;	
	my $slideToClone = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PostClonePresentationSlide(name => $name, position=>$position, slideToClone=>$slideToClone);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::SlideListResponse');
};

subtest 'testPostAddSlideCopy' => sub {
	my $name = 'sample.pptx';
	my $slideToClone = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PostAddSlideCopy(name => $name, slideToClone=>$slideToClone);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::SlideListResponse');
};

subtest 'testPostCopySlideFromSourcePresentation' => sub {
	my $name = 'sample.pptx';
	my $slideToCopy = 1;
	my $source = 'sample-input.pptx';
	my $position = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PostCopySlideFromSourcePresentation(name => $name, slideToCopy=>$slideToCopy, source=>$source, position=>$position);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::SlideListResponse');
};

subtest 'testGetSlidesSlide' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlidesSlide(name => $name, slideIndex=>$slideIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::SlideListResponse');
};

subtest 'testDeleteSlideByIndex' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->DeleteSlideByIndex(name => $name, slideIndex=>$slideIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::SlideListResponse');
};

subtest 'testGetSlideWithFormat' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
	my $format = 'pdf';
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlideWithFormat(name => $name, slideIndex=>$slideIndex, format=>$format);
 	is($response->{'Status'}, "OK");
 	
};

subtest 'testGetSlidesSlideBackground' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlidesSlideBackground(name => $name, slideIndex=>$slideIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::SlideBackgroundResponse');
 	
};

subtest 'testDeleteSlidesSlideBackground' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->DeleteSlidesSlideBackground(name => $name, slideIndex=>$slideIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::SlideBackgroundResponse');
 	
};

subtest 'testGetSlidesSlideComments' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlidesSlideComments(name => $name, slideIndex=>$slideIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::SlideCommentsResponse');
 	
};

subtest 'testGetSlidesSlideImages' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlidesSlideImages(name => $name, slideIndex=>$slideIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::ImagesResponse');
 	
};

subtest 'testGetSlidesPlaceholders' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlidesPlaceholders(name => $name, slideIndex=>$slideIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::PlaceholdersResponse');
 	
};

subtest 'testGetSlidesPlaceholder' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
	my $placeholderIndex = 0;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlidesPlaceholder(name => $name, slideIndex=>$slideIndex, placeholderIndex=>$placeholderIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::PlaceholderResponse');
 	
};

subtest 'testPostSlidesSlideReplaceText' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
	my $oldValue = 'aspose';
	my $newValue = 'aspose2';
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PostSlidesSlideReplaceText(name => $name, slideIndex=>$slideIndex, oldValue=>$oldValue, newValue=>$newValue);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::SlideStringReplaceResponse');
 	
};

subtest 'testGetSlideShapeParagraphs' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
	my $shapeIndex = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlideShapeParagraphs(name => $name, slideIndex=>$slideIndex, shapeIndex=>$shapeIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::ShapesResponse');
 	
};

subtest 'testGetSlidesSlideShapes' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlidesSlideShapes(name => $name, slideIndex=>$slideIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::ShapesResponse');
 	
};

subtest 'testGetParagraphPortion' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
	my $shapeIndex = 1;
	my $paragraphIndex = 1;
	my $portionIndex = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetParagraphPortion(name => $name, slideIndex=>$slideIndex, shapeIndex=>$shapeIndex, paragraphIndex=>$paragraphIndex, portionIndex=>$portionIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::PortionResponse');
 	
};

subtest 'testPutSetParagraphPortionProperties' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
	my $shapeIndex = 1;
	my $paragraphIndex = 1;
	my $portionIndex = 1;
	my @portionBody = AsposeSlidesCloud::Object::Portion->new('Text' => 'Aspose.Slides for Perl', 'FontColor' => '#FFFF0000');
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PutSetParagraphPortionProperties(name => $name, slideIndex=>$slideIndex, shapeIndex=>$shapeIndex, paragraphIndex=>$paragraphIndex, portionIndex=>$portionIndex, body=>@portionBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::PortionResponse');
};

subtest 'testGetSlidesSlideShapesParent' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
	my $shapePath = '1';
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlidesSlideShapesParent(name => $name, slideIndex=>$slideIndex, shapePath=>$shapePath);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::ShapeResponse');
};

subtest 'testPutSlideShapeInfo' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
	my $shapePath = 1;
	my @shapeBody = AsposeSlidesCloud::Object::Shape->new('AlternativeText' => 'Aspose');
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PutSlideShapeInfo(name => $name, slideIndex=>$slideIndex, shapePath=>$shapePath, body=>@shapeBody);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::ShapeResponse');
};

subtest 'testGetSlidesSlideTextItems' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlidesSlideTextItems(name => $name, slideIndex=>$slideIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::TextItemsResponse');
};

subtest 'testGetSlidesTheme' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlidesTheme(name => $name, slideIndex=>$slideIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::ThemeResponse');
};

subtest 'testGetSlidesThemeColorScheme' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlidesThemeColorScheme(name => $name, slideIndex=>$slideIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::ColorSchemeResponse');
};

subtest 'testGetSlidesThemeFontScheme' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlidesThemeFontScheme(name => $name, slideIndex=>$slideIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::FontSchemeResponse');
};

subtest 'testGetSlidesThemeFormatScheme' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlidesThemeFormatScheme(name => $name, slideIndex=>$slideIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::FormatSchemeResponse');
};

subtest 'testGetSlidesThemeFormatScheme' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlidesThemeFormatScheme(name => $name, slideIndex=>$slideIndex);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::FormatSchemeResponse');
};

subtest 'testPostSlidesSplit' => sub {
	my $name = 'sample-input.pptx';
	my $from = 2;
	my $to = 3;
	my $format = 'png';
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PostSlidesSplit(name => $name, from=>$from, to=>$to, format=>$format);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::SplitDocumentResponse');
};

subtest 'testGetSlidesPresentationTextItems' => sub {
	my $name = 'sample-input.pptx';
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlidesPresentationTextItems(name => $name);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::TextItemsResponse');
};

subtest 'testGetSlidesDocumentProperty' => sub {
	my $name = 'sample-input.pptx';
	my $propertyName = 'Author';
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetSlidesDocumentProperty(name => $name, propertyName=>$propertyName);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::DocumentPropertyResponse');
};

subtest 'testPostSlidesSaveAsHtml' => sub {
	my $name = 'sample.pptx';
	my @htmlExportOptionsBody = AsposeSlidesCloud::Object::HtmlExportOptions->new('SaveAsZip' => 'True');
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PostSlidesSaveAsHtml(name => $name, body=>@htmlExportOptionsBody);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostSlidesSaveAsPdf' => sub {
	my $name = 'sample.pptx';
	my @pdfExportOptionsBody = AsposeSlidesCloud::Object::PdfExportOptions->new('JpegQuality' => 50);
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PostSlidesSaveAsPdf(name => $name, body=>@pdfExportOptionsBody);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostSlidesSaveAsTiff' => sub {
	my $name = 'sample.pptx';
	my @tiffExportOptionsBody = AsposeSlidesCloud::Object::TiffExportOptions->new('ExportFormat' => 'tiff');
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PostSlidesSaveAsTiff(name => $name, body=>@tiffExportOptionsBody);
 	is($response->{'Status'}, "OK");
};

subtest 'testGetShapeWithFormat' => sub {
	my $name = 'sample-input.pptx';
	my $slideIndex = 1;
	my $shapeIndex = 1;
	my $format = 'png';
	
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->GetShapeWithFormat(name => $name, slideIndex=>$slideIndex, shapeIndex=>$shapeIndex, format=>$format);
 	is($response->{'Status'}, "OK");
};

subtest 'testPostAddNewShape' => sub {
	my $name = 'sample-input.pptx';
	my $slideIndex = 1;
	my @shapeBody = AsposeSlidesCloud::Object::Shape->new('Name' => 'Aspose', 'Type' => 'Shape', 'AlternativeText' => 'Aspose', 'ShapeType' => 'Line');
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PostAddNewShape(name => $name, slideIndex=>$slideIndex, body=>@shapeBody);
 	isa_ok($response, 'AsposeSlidesCloud::Object::ShapeResponse');
};

subtest 'testPutSlidesSlideBackground' => sub {
	my $name = 'sample.pptx';
	my $slideIndex = 1;
	my $body = "\"#FFFF0000\"";
		
	my $response = $storageApi->PutCreate(Path => $name, file => $data_path.$name);
 	is($response->{'Status'}, "OK");
 	
 	$response = $slidesApi->PutSlidesSlideBackground(name => $name, slideIndex=>$slideIndex, body=>$body);
 	is($response->{'Status'}, "OK");
 	isa_ok($response, 'AsposeSlidesCloud::Object::SlideBackgroundResponse');
 	
};

done_testing();