![](https://img.shields.io/badge/api-v3.0-lightgrey) [![GitHub license](https://img.shields.io/github/license/aspose-slides-cloud/aspose-slides-cloud-perl)](https://github.com/aspose-slides-cloud/aspose-slides-cloud-perl/blob/master/LICENSE)

# Perl REST API to Process Presentation in Cloud
This repository contains Aspose.Slides Cloud SDK for Perl source code. This SDK allows you to [process & manipulate PPT, PPTX, ODP, OTP](https://products.aspose.cloud/slides/perl) using Aspose.slides Cloud REST APIs in your Perl applications.

You may want to check out Aspose free [PPT to PDF](https://products.aspose.app/slides/conversion), [PPT to Word](https://products.aspose.app/slides/conversion/ppt-to-word), and [PPT to JPG](https://products.aspose.app/slides/conversion/ppt-to-jpg) converters because they are live implementations of popular conversion processes.

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
**Other**: PDF, PDF/A

## Save Presentation As

**Fixed Layout:** XPS
**Images:** JPEG, PNG, BMP, TIFF, GIF, SVG
**Web:** HTML/HTML5
**Other:** MPEG4, SWF (export whole presentations)

## Enhancements in Version 22.6
* Added ned **GetSubshapeParagraphEffective**, **GetParagraphEffective** and **GetSubshapePortionEffective**, **GetPortionEffective** methods to retrieve actual format values for paragraphs and portions, whether they are inherited from parent entities or not.
* Password parameter is now optional for **GetProtectionProperties** method. So, you don't need to specify the password to check whether a presentation has a password.
* Added new **ChartSeriesGroup** class and **SeriesGroups** property to **Chart** class to enable managing chart series groups. Added new **UpdateChartSeriesGroup** method.
* Added **HasRoundedCorners** property to **Chart** class.
* Added **InvertIfNegative** property to **OneValueChartDataPoint** class.
* Changed **FormatScheme** class to return actual format values instead of resource links.

## Enhancements in Version 22.5
* Added **Paragraphs** property to **SmartArtNode** class to enable getting and setting text for SmartArt nodes.
* Added **ImageTransformList** property to **PictureFill** class to enable setting image transform effects. Added **ImageTransformEffect** class and subclasses for different kind of of effects.
* Added **PictureFillFormat** property to **VideoFrame** class to enable setting poster image for video frames.
* Added **SlideIndex** and **ShapeIndex** properties to **ResourceUri** class to simplify retrieveing slide & shape indexes for resources.
* Removed redundant **BoxAndWhiskersSeries**, **WaterfallSeries** and **WaterfallChartDataPoint** classes.

## Enhancements in Version 22.4
* Added **TransitionType** and **SlidesTransitionDuration** properties to **VideoExportOptions** class to enable creation videos with transitions.
* Added **DefaultPortionFormat** property to **Paragraph** class. Added new **PortionFormat** class.
* Added **EmbeddedFileBase64Data** and a number of other properties to **OleObjectFrame** class to enable creation of OLE Object frames.
* Added **AccessPermissions** class to support access permissions for PDF export.
* Added **PictureFillformat** property to **AudioFrame** class.
* Added **RowIndex** and **ColumnIndex** properties to **TableCell** class.
* Moved **Width** and **Height** properties from **ExportOptions** base class to the new **ImageExportOptionsBase class**. This is a superclass for **ImageExportOptions**, **GifExportOptions** and **TiffExportOptions** classes.
* Removed redundant **Shapes** property from **ShapeBase** class. It is only left for **GroupShape** class.

## Enhancements in Version 22.3
* Added **ModernSlideComment** class to support modern comments. Also added **SlideCommentBase** as base class for comments.
* Added optional **shapeIndex** parameter to **CreateComment** and **CreateCommentOnline** methods.
* Added **GetParagraphRectangle**, **GetPortionRectangle** method and new **TextBounds** class to get paragraph or portion bounds.
* Added optional **shapeType** parameter for **GetShapes** method. You can now get list of shapes of a particular type (e.g. charts or tables).
* Added **FontFallbackRules** class and **FontFallbackRules** property to **ExportOptions** class.
* Added **LatinFont**, **EastAsianFont** and **ComplexScriptFont** properties to **Portion** class to enable getting and seting portion font name.
* Added **ChartLinesFormat** class; added **MajorGridLinesFormat** and **MinorGridLinesFormat** properties to Axis class.
* Added **HideLegend** boolean property to **Legend** class.

## Enhancements in Version 22.2
* Added **Mpeg4** to the list of allowed values for **ExportFormat** type. You can now convert presentations to video.
* New **HighlightShapeText** and **HighlightShapeRegex** methods.
* New **DeleteUnusedLayoutSlides** and **DeleteUnusedLayoutSlides** methods.
* New **ZoomFrame** and **ZoomObject** classes with a number of subclasses.
* Added **TextFrameFormat** property to **Shape** class to support WordArt.
* Added **XYSeries** class as a supercalss for **ScatterSeries** and **BubbleSeries** methods.
* Added **None** to the list of allowed values for **TimeUnitType** enum type.
* **Level** property of **Category** class is deprecated and will be removed after v22.4.

## Enhancements in Version 22.1
* New **MathParagraph** property of **Portion** class allows to get and set math formulas. A set of **MathElement** subclasses allows to specify complex mathematical expressions.
* New **DownloadPortionAsMathMl** and **SavePortionAsMathMl** methods allow to export math formulas to MathML format.
* New **HyperlinkClick** and **HyperlinkMouseOver** methods of **ShapeBase** and **Portion** classes enable creation and manipulating hyperlinks for shapes and portions.
* New methods **GetShapeGeometryPath** and **SetShapeGeometryPath** can be used to get or set geometry paths for shapes. You can use lines, arcs and curves to specify custom shape boundaries.
* New **AlignSubshapes** method enables aligning shapes within a shape group.
* New **PlayAcrossSlides** and **RewindAudio** properties are added to **AudioFrame** class.
* Added **InClickSequence** to the list of allowable values for **AudioPlayModePreset** and **AudioPlayModePreset** enum types.

## Licensing
All Aspose.Slides Cloud SDKs are licensed under MIT License.

## How to use the SDK?
The complete source code is available in this repository folder. You can either directly use it in your project via source code or get [CPAN module](https://metacpan.org/release/AsposeSlidesCloud-SlidesApi) (recommended).

## Prerequisites
To use Aspose Slides Cloud SDK for Perl you need to register an account with [Aspose Cloud](https://www.aspose.cloud/) and lookup/create App Key and SID at [Cloud Dashboard](https://dashboard.aspose.cloud/#/apps). There is free quota available. For more details, see [Aspose Cloud Pricing](https://purchase.aspose.cloud/pricing).

### Installation

```sh
cpan ASPOSE/AsposeSlidesCloud-SlidesApi-22.06.tar.gz
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
	my $result = $api->convert(%params);
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
