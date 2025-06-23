=begin comment

Copyright (c) 2019 Aspose Pty Ltd

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=end comment

=cut
package AsposeSlidesCloud::ClassRegistry;

use strict;
use warnings;
use utf8;

use JSON;
use Scalar::Util;

my %hierarchy = (
    'AccentElement' => 'MathElement',
    'AddLayoutSlide' => 'Task',
    'AddMasterSlide' => 'Task',
    'AddShape' => 'Task',
    'AddSlide' => 'Task',
    'AlphaBiLevelEffect' => 'ImageTransformEffect',
    'AlphaCeilingEffect' => 'ImageTransformEffect',
    'AlphaFloorEffect' => 'ImageTransformEffect',
    'AlphaInverseEffect' => 'ImageTransformEffect',
    'AlphaModulateEffect' => 'ImageTransformEffect',
    'AlphaModulateFixedEffect' => 'ImageTransformEffect',
    'AlphaReplaceEffect' => 'ImageTransformEffect',
    'ArcToPathSegment' => 'PathSegment',
    'ArrayElement' => 'MathElement',
    'AudioFrame' => 'GeometryShape',
    'BarElement' => 'MathElement',
    'Base64InputFile' => 'InputFile',
    'BiLevelEffect' => 'ImageTransformEffect',
    'BlockElement' => 'MathElement',
    'BlurImageEffect' => 'ImageTransformEffect',
    'BorderBoxElement' => 'MathElement',
    'BoxElement' => 'MathElement',
    'BubbleChartDataPoint' => 'ScatterChartDataPoint',
    'BubbleSeries' => 'XYSeries',
    'CaptionTrack' => 'ResourceBase',
    'CaptionTracks' => 'ResourceBase',
    'Chart' => 'ShapeBase',
    'ClosePathSegment' => 'PathSegment',
    'ColorChangeEffect' => 'ImageTransformEffect',
    'ColorReplaceEffect' => 'ImageTransformEffect',
    'ColorScheme' => 'ResourceBase',
    'CommentAuthors' => 'ResourceBase',
    'Connector' => 'GeometryShape',
    'CubicBezierToPathSegment' => 'PathSegment',
    'DelimiterElement' => 'MathElement',
    'Document' => 'ResourceBase',
    'DocumentProperties' => 'ResourceBase',
    'DocumentProperty' => 'ResourceBase',
    'DocumentReplaceResult' => 'Document',
    'DuotoneEffect' => 'ImageTransformEffect',
    'FileVersion' => 'StorageFile',
    'FillOverlayImageEffect' => 'ImageTransformEffect',
    'FontScheme' => 'ResourceBase',
    'FormatScheme' => 'ResourceBase',
    'FractionElement' => 'MathElement',
    'FunctionElement' => 'MathElement',
    'GeometryShape' => 'ShapeBase',
    'GifExportOptions' => 'ImageExportOptionsBase',
    'GradientFill' => 'FillFormat',
    'GraphicalObject' => 'ShapeBase',
    'GrayScaleEffect' => 'ImageTransformEffect',
    'GroupShape' => 'ShapeBase',
    'GroupingCharacterElement' => 'MathElement',
    'HandoutLayoutingOptions' => 'SlidesLayoutOptions',
    'HeaderFooter' => 'ResourceBase',
    'HslEffect' => 'ImageTransformEffect',
    'Html5ExportOptions' => 'ExportOptions',
    'HtmlExportOptions' => 'ExportOptions',
    'Image' => 'ResourceBase',
    'ImageExportOptions' => 'ImageExportOptionsBase',
    'ImageExportOptionsBase' => 'ExportOptions',
    'Images' => 'ResourceBase',
    'LayoutSlide' => 'ResourceBase',
    'LayoutSlides' => 'ResourceBase',
    'LeftSubSuperscriptElement' => 'MathElement',
    'LimitElement' => 'MathElement',
    'LineToPathSegment' => 'PathSegment',
    'Literals' => 'DataSource',
    'LuminanceEffect' => 'ImageTransformEffect',
    'MarkdownExportOptions' => 'ExportOptions',
    'MasterSlide' => 'ResourceBase',
    'MasterSlides' => 'ResourceBase',
    'MatrixElement' => 'MathElement',
    'Merge' => 'Task',
    'MoveToPathSegment' => 'PathSegment',
    'NaryOperatorElement' => 'MathElement',
    'NoFill' => 'FillFormat',
    'NotesCommentsLayoutingOptions' => 'SlidesLayoutOptions',
    'NotesSlide' => 'ResourceBase',
    'NotesSlideHeaderFooter' => 'ResourceBase',
    'OleObjectFrame' => 'ShapeBase',
    'OneValueChartDataPoint' => 'DataPoint',
    'OneValueSeries' => 'Series',
    'Paragraph' => 'ResourceBase',
    'Paragraphs' => 'ResourceBase',
    'PathInputFile' => 'InputFile',
    'PathOutputFile' => 'OutputFile',
    'PatternFill' => 'FillFormat',
    'PdfExportOptions' => 'ExportOptions',
    'PictureFill' => 'FillFormat',
    'PictureFrame' => 'GeometryShape',
    'Placeholder' => 'ResourceBase',
    'Placeholders' => 'ResourceBase',
    'Portion' => 'ResourceBase',
    'Portions' => 'ResourceBase',
    'PptxExportOptions' => 'ExportOptions',
    'ProtectionProperties' => 'ResourceBase',
    'QuadraticBezierToPathSegment' => 'PathSegment',
    'RadicalElement' => 'MathElement',
    'RemoveShape' => 'Task',
    'RemoveSlide' => 'Task',
    'ReorderSlide' => 'Task',
    'ReplaceText' => 'Task',
    'RequestInputFile' => 'InputFile',
    'ResetSlide' => 'Task',
    'ResponseOutputFile' => 'OutputFile',
    'RightSubSuperscriptElement' => 'MathElement',
    'Save' => 'Task',
    'SaveShape' => 'Task',
    'SaveSlide' => 'Task',
    'ScatterChartDataPoint' => 'DataPoint',
    'ScatterSeries' => 'XYSeries',
    'Section' => 'ResourceBase',
    'SectionZoomFrame' => 'ZoomObject',
    'Sections' => 'ResourceBase',
    'Shape' => 'GeometryShape',
    'ShapeBase' => 'ResourceBase',
    'Shapes' => 'ResourceBase',
    'Slide' => 'ResourceBase',
    'SlideAnimation' => 'ResourceBase',
    'SlideBackground' => 'ResourceBase',
    'SlideComment' => 'SlideCommentBase',
    'SlideComments' => 'ResourceBase',
    'SlideModernComment' => 'SlideCommentBase',
    'SlideProperties' => 'ResourceBase',
    'SlideReplaceResult' => 'Slide',
    'SlideShowProperties' => 'ResourceBase',
    'Slides' => 'ResourceBase',
    'SmartArt' => 'ShapeBase',
    'SmartArtShape' => 'GeometryShape',
    'SolidFill' => 'FillFormat',
    'SplitDocumentResult' => 'ResourceBase',
    'SubscriptElement' => 'MathElement',
    'SummaryZoomFrame' => 'ShapeBase',
    'SummaryZoomSection' => 'SectionZoomFrame',
    'SuperscriptElement' => 'MathElement',
    'SvgExportOptions' => 'ExportOptions',
    'SwfExportOptions' => 'ExportOptions',
    'Table' => 'ShapeBase',
    'TextElement' => 'MathElement',
    'TextItems' => 'ResourceBase',
    'Theme' => 'ResourceBase',
    'TiffExportOptions' => 'ImageExportOptionsBase',
    'TintEffect' => 'ImageTransformEffect',
    'UpdateBackground' => 'Task',
    'UpdateShape' => 'Task',
    'VbaModule' => 'ResourceBase',
    'VbaProject' => 'ResourceBase',
    'VideoExportOptions' => 'ExportOptions',
    'VideoFrame' => 'GeometryShape',
    'ViewProperties' => 'ResourceBase',
    'Workbook' => 'DataSource',
    'XYSeries' => 'Series',
    'XamlExportOptions' => 'ExportOptions',
    'XpsExportOptions' => 'ExportOptions',
    'ZoomFrame' => 'ZoomObject',
    'ZoomObject' => 'ShapeBase',
    
);

my %determiners = (
    'AccentElement' => { 'Type' => 'Accent', },
    'AccessPermissions' => {  },
    'AddLayoutSlide' => { 'Type' => 'AddLayoutSlide', },
    'AddMasterSlide' => { 'Type' => 'AddMasterSlide', },
    'AddShape' => { 'Type' => 'AddShape', },
    'AddSlide' => { 'Type' => 'AddSlide', },
    'AlphaBiLevelEffect' => { 'Type' => 'AlphaBiLevel', },
    'AlphaCeilingEffect' => { 'Type' => 'AlphaCeiling', },
    'AlphaFloorEffect' => { 'Type' => 'AlphaFloor', },
    'AlphaInverseEffect' => { 'Type' => 'AlphaInverse', },
    'AlphaModulateEffect' => { 'Type' => 'AlphaModulate', },
    'AlphaModulateFixedEffect' => { 'Type' => 'AlphaModulateFixed', },
    'AlphaReplaceEffect' => { 'Type' => 'AlphaReplace', },
    'ApiInfo' => {  },
    'ArcToPathSegment' => { 'Type' => 'ArcTo', },
    'ArrayElement' => { 'Type' => 'Array', },
    'ArrowHeadProperties' => {  },
    'AudioFrame' => { 'Type' => 'AudioFrame', },
    'Axes' => {  },
    'Axis' => {  },
    'AxisType' => {  },
    'BarElement' => { 'Type' => 'Bar', },
    'Base64InputFile' => { 'Type' => 'Base64', },
    'BiLevelEffect' => { 'Type' => 'BiLevel', },
    'BlockElement' => { 'Type' => 'Block', },
    'BlurEffect' => {  },
    'BlurImageEffect' => { 'Type' => 'Blur', },
    'BorderBoxElement' => { 'Type' => 'BorderBox', },
    'BoxElement' => { 'Type' => 'Box', },
    'BubbleChartDataPoint' => { 'Type' => 'Bubble', },
    'BubbleSeries' => { 'DataPointType' => 'Bubble', },
    'Camera' => {  },
    'CaptionTrack' => {  },
    'CaptionTracks' => {  },
    'Chart' => { 'Type' => 'Chart', },
    'ChartCategory' => {  },
    'ChartLinesFormat' => {  },
    'ChartSeriesGroup' => {  },
    'ChartTitle' => {  },
    'ChartWall' => {  },
    'ChartWallType' => {  },
    'ClosePathSegment' => { 'Type' => 'Close', },
    'ColorChangeEffect' => { 'Type' => 'ColorChange', },
    'ColorReplaceEffect' => { 'Type' => 'ColorReplace', },
    'ColorScheme' => {  },
    'CommentAuthor' => {  },
    'CommentAuthors' => {  },
    'CommonSlideViewProperties' => {  },
    'Connector' => { 'Type' => 'Connector', },
    'CubicBezierToPathSegment' => { 'Type' => 'CubicBezierTo', },
    'CustomDashPattern' => {  },
    'DataPoint' => {  },
    'DataSource' => {  },
    'DelimiterElement' => { 'Type' => 'Delimiter', },
    'DiscUsage' => {  },
    'Document' => {  },
    'DocumentProperties' => {  },
    'DocumentProperty' => {  },
    'DocumentReplaceResult' => {  },
    'DrawingGuide' => {  },
    'DuotoneEffect' => { 'Type' => 'Duotone', },
    'Effect' => {  },
    'EffectFormat' => {  },
    'EntityExists' => {  },
    'Error' => {  },
    'ErrorDetails' => {  },
    'ExportFormat' => {  },
    'ExportOptions' => {  },
    'FileVersion' => {  },
    'FileVersions' => {  },
    'FilesList' => {  },
    'FilesUploadResult' => {  },
    'FillFormat' => {  },
    'FillOverlayEffect' => {  },
    'FillOverlayImageEffect' => { 'Type' => 'FillOverlay', },
    'FontData' => {  },
    'FontFallbackRule' => {  },
    'FontScheme' => {  },
    'FontSet' => {  },
    'FontSubstRule' => {  },
    'FontsData' => {  },
    'FormatScheme' => {  },
    'FractionElement' => { 'Type' => 'Fraction', },
    'FunctionElement' => { 'Type' => 'Function', },
    'GeometryPath' => {  },
    'GeometryPaths' => {  },
    'GeometryShape' => {  },
    'GifExportOptions' => { 'Format' => 'gif', },
    'GlowEffect' => {  },
    'GradientFill' => { 'Type' => 'Gradient', },
    'GradientFillStop' => {  },
    'GraphicalObject' => { 'Type' => 'GraphicalObject', },
    'GrayScaleEffect' => { 'Type' => 'GrayScale', },
    'GroupShape' => { 'Type' => 'GroupShape', },
    'GroupingCharacterElement' => { 'Type' => 'GroupingCharacter', },
    'HandoutLayoutingOptions' => { 'LayoutType' => 'Handout', },
    'HeaderFooter' => {  },
    'HslEffect' => { 'Type' => 'Hsl', },
    'Html5ExportOptions' => { 'Format' => 'html5', },
    'HtmlExportOptions' => { 'Format' => 'html', },
    'Hyperlink' => {  },
    'IShapeExportOptions' => {  },
    'Image' => {  },
    'ImageExportFormat' => {  },
    'ImageExportOptions' => { 'Format' => 'image', },
    'ImageExportOptionsBase' => {  },
    'ImageTransformEffect' => {  },
    'Images' => {  },
    'InnerShadowEffect' => {  },
    'Input' => {  },
    'InputFile' => {  },
    'InteractiveSequence' => {  },
    'LayoutSlide' => {  },
    'LayoutSlides' => {  },
    'LeftSubSuperscriptElement' => { 'Type' => 'LeftSubSuperscriptElement', },
    'Legend' => {  },
    'LightRig' => {  },
    'LimitElement' => { 'Type' => 'Limit', },
    'LineFormat' => {  },
    'LineToPathSegment' => { 'Type' => 'LineTo', },
    'Literals' => { 'Type' => 'Literals', },
    'LuminanceEffect' => { 'Type' => 'Luminance', },
    'MarkdownExportOptions' => { 'Format' => 'md', },
    'MasterSlide' => {  },
    'MasterSlides' => {  },
    'MathElement' => {  },
    'MathFormat' => {  },
    'MathParagraph' => {  },
    'MatrixElement' => { 'Type' => 'Matrix', },
    'Merge' => { 'Type' => 'Merge', },
    'MergingSource' => {  },
    'MoveToPathSegment' => { 'Type' => 'MoveTo', },
    'NaryOperatorElement' => { 'Type' => 'NaryOperator', },
    'NoFill' => { 'Type' => 'NoFill', },
    'NormalViewRestoredProperties' => {  },
    'NotesCommentsLayoutingOptions' => { 'LayoutType' => 'NotesComments', },
    'NotesSlide' => {  },
    'NotesSlideExportFormat' => {  },
    'NotesSlideHeaderFooter' => {  },
    'ObjectExist' => {  },
    'OleObjectFrame' => { 'Type' => 'OleObjectFrame', },
    'OneValueChartDataPoint' => { 'Type' => 'OneValue', },
    'OneValueSeries' => { 'DataPointType' => 'OneValue', },
    'Operation' => {  },
    'OperationError' => {  },
    'OperationProgress' => {  },
    'OrderedMergeRequest' => {  },
    'OuterShadowEffect' => {  },
    'OutputFile' => {  },
    'Paragraph' => {  },
    'ParagraphFormat' => {  },
    'Paragraphs' => {  },
    'PathInputFile' => { 'Type' => 'Path', },
    'PathOutputFile' => { 'Type' => 'Path', },
    'PathSegment' => {  },
    'PatternFill' => { 'Type' => 'Pattern', },
    'PdfExportOptions' => { 'Format' => 'pdf', },
    'PdfImportOptions' => {  },
    'PictureFill' => { 'Type' => 'Picture', },
    'PictureFrame' => { 'Type' => 'PictureFrame', },
    'Pipeline' => {  },
    'Placeholder' => {  },
    'Placeholders' => {  },
    'PlotArea' => {  },
    'Portion' => {  },
    'PortionFormat' => {  },
    'Portions' => {  },
    'PptxExportOptions' => { 'Format' => 'pptx', },
    'PresentationToMerge' => {  },
    'PresentationsMergeRequest' => {  },
    'PresetShadowEffect' => {  },
    'ProtectionProperties' => {  },
    'QuadraticBezierToPathSegment' => { 'Type' => 'QuadBezierTo', },
    'RadicalElement' => { 'Type' => 'Radical', },
    'ReflectionEffect' => {  },
    'RemoveShape' => { 'Type' => 'RemoveShape', },
    'RemoveSlide' => { 'Type' => 'RemoveSlide', },
    'ReorderSlide' => { 'Type' => 'ReoderSlide', },
    'ReplaceText' => { 'Type' => 'ReplaceText', },
    'RequestInputFile' => { 'Type' => 'Request', },
    'ResetSlide' => { 'Type' => 'ResetSlide', },
    'ResourceBase' => {  },
    'ResourceUri' => {  },
    'ResponseOutputFile' => { 'Type' => 'Response', },
    'RightSubSuperscriptElement' => { 'Type' => 'RightSubSuperscriptElement', },
    'Save' => { 'Type' => 'Save', },
    'SaveShape' => { 'Type' => 'SaveShape', },
    'SaveSlide' => { 'Type' => 'SaveSlide', },
    'ScatterChartDataPoint' => { 'Type' => 'Scatter', },
    'ScatterSeries' => { 'DataPointType' => 'Scatter', },
    'Section' => {  },
    'SectionZoomFrame' => { 'Type' => 'SectionZoomFrame', },
    'Sections' => {  },
    'Series' => {  },
    'SeriesMarker' => {  },
    'Shape' => { 'Type' => 'Shape', },
    'ShapeBase' => {  },
    'ShapeBevel' => {  },
    'ShapeExportFormat' => {  },
    'ShapeImageExportOptions' => {  },
    'ShapeThumbnailBounds' => {  },
    'ShapeType' => {  },
    'Shapes' => {  },
    'ShapesAlignmentType' => {  },
    'Slide' => {  },
    'SlideAnimation' => {  },
    'SlideBackground' => {  },
    'SlideComment' => { 'Type' => 'Regular', },
    'SlideCommentBase' => {  },
    'SlideComments' => {  },
    'SlideExportFormat' => {  },
    'SlideModernComment' => { 'Type' => 'Modern', },
    'SlideProperties' => {  },
    'SlideReplaceResult' => {  },
    'SlideShowProperties' => {  },
    'SlideShowTransition' => {  },
    'Slides' => {  },
    'SlidesLayoutOptions' => {  },
    'SmartArt' => { 'Type' => 'SmartArt', },
    'SmartArtNode' => {  },
    'SmartArtShape' => { 'Type' => 'SmartArtShape', },
    'SoftEdgeEffect' => {  },
    'SolidFill' => { 'Type' => 'Solid', },
    'SpecialSlideType' => {  },
    'SplitDocumentResult' => {  },
    'StorageExist' => {  },
    'StorageFile' => {  },
    'SubscriptElement' => { 'Type' => 'SubscriptElement', },
    'SummaryZoomFrame' => { 'Type' => 'SummaryZoomFrame', },
    'SummaryZoomSection' => { 'Type' => 'SummaryZoomSection', },
    'SuperscriptElement' => { 'Type' => 'SuperscriptElement', },
    'SvgExportOptions' => { 'Format' => 'svg', },
    'SwfExportOptions' => { 'Format' => 'swf', },
    'Table' => { 'Type' => 'Table', },
    'TableCell' => {  },
    'TableCellMergeOptions' => {  },
    'TableCellSplitType' => {  },
    'TableColumn' => {  },
    'TableRow' => {  },
    'Task' => {  },
    'TextBounds' => {  },
    'TextElement' => { 'Type' => 'Text', },
    'TextFrameFormat' => {  },
    'TextItem' => {  },
    'TextItems' => {  },
    'Theme' => {  },
    'ThreeDFormat' => {  },
    'TiffExportOptions' => { 'Format' => 'tiff', },
    'TintEffect' => { 'Type' => 'Tint', },
    'UpdateBackground' => { 'Type' => 'UpdateBackground', },
    'UpdateShape' => { 'Type' => 'UpdateShape', },
    'VbaModule' => {  },
    'VbaProject' => {  },
    'VbaReference' => {  },
    'VideoExportOptions' => { 'Format' => 'mpeg4', },
    'VideoFrame' => { 'Type' => 'VideoFrame', },
    'ViewProperties' => {  },
    'Workbook' => { 'Type' => 'Workbook', },
    'XYSeries' => {  },
    'XamlExportOptions' => { 'Format' => 'xaml', },
    'XpsExportOptions' => { 'Format' => 'xps', },
    'ZoomFrame' => { 'Type' => 'ZoomFrame', },
    'ZoomObject' => {  },
);

sub has_class {
    my ($self, $name) = @_;
    return exists $determiners{$name};
}

sub is_subclass {
    my ($self, $subclass, $class) = @_;
    if ($subclass eq $class) {
        return 1;
    }
    for(keys %hierarchy) {
        if ($hierarchy{$_} eq $class && $self->is_subclass($subclass, $_)) {
            return 1;
        }
    }
    return 0;
}

sub get_class_name {
    my ($self, $name, $data) = @_;
    my $descendant = $self->get_subclass_name($name, $data);
    if ($descendant) {
        return $descendant;
    }
    return $name;
}

sub get_subclass_name {
    my ($self, $name, $data) = @_;
    for(keys %hierarchy) {
        if ($hierarchy{$_} eq $name) {
            my $descendant = $self->get_subclass_name($_, $data);
            if ($descendant) {
                return $descendant;
            }
            if ($self->is_instance_of($_, $data)) {
                return $_;
            }
        }
    }
    return "";
}

sub is_instance_of {
    my ($self, $name, $data) = @_;
    if (!exists $determiners{$name} || !keys %{$determiners{$name}}) {
        return 0;
    }
    my $data_decoded = $data;
    if (ref $data ne "HASH") {
        $data_decoded = decode_json($data);
    }
    for(keys %{$determiners{$name}}) {
        if (!$self->value_exists($_, ${$determiners{$name}}{$_}, $data_decoded)) {
            return 0;
        }
    }
    return 1;
}

sub value_exists {
    my ($self, $key, $value, $data) = @_;
    if (%$data{$key} && %$data{$key} eq $value) {
        return 1;
    }
    my $lckey = lcfirst($key);
    if (%$data{$lckey} && %$data{$lckey} eq $value) {
        return 1;
    }
    my $uckey = ucfirst($key);
    if (%$data{$uckey} && %$data{$uckey} eq $value) {
        return 1;
    }
    return 0;
}

1;
