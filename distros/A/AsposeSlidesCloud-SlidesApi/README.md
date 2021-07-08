![](https://img.shields.io/badge/api-v3.0-lightgrey) [![GitHub license](https://img.shields.io/github/license/aspose-slides-cloud/aspose-slides-cloud-perl)](https://github.com/aspose-slides-cloud/aspose-slides-cloud-perl/blob/master/LICENSE)

# Perl REST API to Process Presentation in Cloud
This repository contains Aspose.Slides Cloud SDK for Perl source code. This SDK allows you to [process & manipulate PPT, PPTX, ODP, OTP](https://products.aspose.cloud/slides/perl) using Aspose.slides Cloud REST APIs in your Perl applications.

## Presentation Processing Features

- Fetch presentation images in any of the supported file formats.
- Copy the layout side or clone the master slide from the source presentation.
- Process slides shapes, slides notes, placeholders, colors & font theme info.
- Programmatically create a presentation from HTML & export it to various formats.
- Merge multiple presentations or split the single presentation into multiple ones.
- Extract and replace text from a specific slide or an entire presentation.

## Read & Write Presentation Formats

**Microsoft PowerPoint:** PPT, PPTX, PPS, PPSX, PPTM, PPSM, POTX, POTM
**OpenOffice:** ODP, OTP, FODP

## Save Presentation As

**Fixed Layout:** PDF, PDF/A, XPS
**Images:** JPEG, PNG, BMP, TIFF, SVG
**Web:** HTML
**Other:** SWF (export whole presentations)

## Enhancements in Version 21.6
* New **CreateComment**, **CreateCommentOnline**, **DeleteComments**, **DeleteCommentsOnline**, **DeleteSlideComments** and **DeleteSlideCommentsOnline** methods to add or delete comments in presentations.

## Enhancements in Version 21.4
* New **CreateWatermark**, **CreateWatermarkOnline**, **CreateImageWatermark**, **CreateImageWatermarkOnline**, **DeleteWatermark** and **DeleteWatermarkOnline** methods to add or delete and remove watermark in presentations.
* New **SetProtection**, **DeleteProtection**, **SetProtectionOnline** and **DeleteProtectionOnline** methods to set or clear presentation protection properties like read/write password, readonly flag.

## Enhancements in Version 21.3
* New **MergeOnline** and **MergeAndSaveOnline** methods to merge presentations from multipart request body.
* New **SplitOnline** and **SplitAndSaveOnline** methods to split presentation from request body.
* New **DownloadSlideOnline**, **DownloadShapeOnline**, **DownloadImageDefaultFormatOnline**, **DownloadImageOnline**, **SaveSlideOnline** and **SaveShapeOnline** methods to convert slides, shapes and images to spefified format using presentation from request body.
* New **DownloadImagesDefaultFormat**, **DownloadImages**, **DownloadImagesDefaultFormatOnline** and **DownloadImagesDefaultFormatOnline** methods to download all images from presentation as a ZIP archive.
* New **ReplacePresentationTextOnline** and **ReplaceSlideTextOnline** methods to replace text in presentation from request body.
* New **AlignShapes** method to align shapes in a slide.
* Simplified method declarations. See the [Release notes](https://docs.aspose.cloud/slides/aspose-slides-cloud-21-3-release-notes/) for details. Old method declarations are deprecated and will be deleted in 21.6 release.

## Enhancements in Version 21.2
* New **Map** value of **ChartTypeEnum** type to manage map charts.
* New **SketchFromat** property of **LineFormat** class.

## Enhancements in Version 21.1
* New **PostSlidesDocumentFromPdf** method allows creating presentations or adding slides to it using a PDF file as a source.
* New **GetSlidesSlideProperties**, **GetSlidesProtectionProperties**, **PutSlidesSlideProperties**, **PutSlidesProtectionProperties** allow to get/set presentaion properties like slide size, orientaion, read-only etc.
* **PutSlidesDocumentFromHtml** method is deprecated and will be deleted in 21.4 release. Use **PostSlidesDocumentFromHtml** method instead.
* **PutSlidesSlideSize** method is deprecated and will be deleted in 21.4 release. Use **PutSlidesProtectionProperties** method instead.


## Licensing
All Aspose.Slides Cloud SDKs are licensed under MIT License.

## How to use the SDK?
The complete source code is available in this repository folder. You can either directly use it in your project via source code or get [CPAN module](https://metacpan.org/release/AsposeSlidesCloud-SlidesApi) (recommended).

## Prerequisites
To use Aspose Slides Cloud SDK for Perl you need to register an account with [Aspose Cloud](https://www.aspose.cloud/) and lookup/create App Key and SID at [Cloud Dashboard](https://dashboard.aspose.cloud/#/apps). There is free quota available. For more details, see [Aspose Cloud Pricing](https://purchase.aspose.cloud/pricing).

### Installation

```sh
cpan ASPOSE/AsposeSlidesCloud-SlidesApi-21.06.tar.gz
```

### Sample usage

The example code below converts a PowerPoint document to PDF format using aspose_slides_cloud library:
```perl
	use File::Slurp;

	use AsposeSlidesCloud::Configuration;
	use AsposeSlidesCloud::SlidesApi;

	my $config = AsposeSlidesCloud::Configuration->new();
	$config->{app_sid} = "MyClientId";
	$config->{app_key} = "MyClientSecret";
	my $api = AsposeSlidesCloud::SlidesApi->new(config => $config);
	my $file = read_file("MyPresentation.pptx", { binmode => ':raw' });
	my %params = ('format' => 'pdf', 'document' => $file);
	my $result = $api->post_slides_convert(%params);
	my $pdf = "MyPresentation.pdf";
	open my $fh, '>>', $pdf;
	binmode $fh;
	print $fh $result;
	close $fh;
```

## Aspose.Slides Cloud SDKs in Popular Languages

| .NET | Java | PHP | Python | Ruby | Node.js | Android | Swift|Perl|Go|
|---|---|---|---|---|---|---|--|--|--|
| [GitHub](https://github.com/aspose-slides-cloud/aspose-slides-cloud-dotnet) | [GitHub](https://github.com/aspose-slides-cloud/aspose-slides-cloud-java) | [GitHub](https://github.com/aspose-slides-cloud/aspose-slides-cloud-php) | [GitHub](https://github.com/aspose-slides-cloud/aspose-slides-cloud-python) | [GitHub](https://github.com/aspose-slides-cloud/aspose-slides-cloud-ruby)  | [GitHub](https://github.com/aspose-slides-cloud/aspose-slides-cloud-nodejs) | [GitHub](https://github.com/aspose-slides-cloud/aspose-slides-cloud-android) | [GitHub](https://github.com/aspose-slides-cloud/aspose-slides-cloud-swift)|[GitHub](https://github.com/aspose-slides-cloud/aspose-slides-cloud-perl) |[GitHub](https://github.com/aspose-slides-cloud/aspose-slides-cloud-go) |
| [NuGet](https://www.nuget.org/packages/Aspose.slides-Cloud/) | [Maven](https://repository.aspose.cloud/webapp/#/artifacts/browse/tree/General/repo/com/aspose/aspose-slides-cloud) | [Composer](https://packagist.org/packages/aspose/slides-sdk-php) | [PIP](https://pypi.org/project/asposeslidescloud/) | [GEM](https://rubygems.org/gems/aspose_slides_cloud)  | [NPM](https://www.npmjs.com/package/asposeslidescloud) | [Maven](https://repository.aspose.cloud/webapp/#/artifacts/browse/tree/General/repo/com/aspose/aspose-slides-cloud) | [Cocoapods](https://cocoapods.org/pods/AsposeslidesCloud)|[Meta Cpan](https://metacpan.org/release/AsposeSlidesCloud-SlidesApi) | [Go.Dev](https://pkg.go.dev/github.com/aspose-slides-cloud/aspose-slides-cloud-go/) |

[Product Page](https://products.aspose.cloud/slides/perl) | [Documentation](https://docs.aspose.cloud/display/slidescloud/Home) | [API Reference](https://apireference.aspose.cloud/slides/) | [Code Samples](https://github.com/aspose-slides-cloud/aspose-slides-cloud-perl) | [Blog](https://blog.aspose.cloud/category/slides/) | [Free Support](https://forum.aspose.cloud/c/slides) | [Free Trial](https://dashboard.aspose.cloud/#/apps)
