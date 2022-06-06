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
    'BarElement' => 'MathElement',
    'Base64InputFile' => 'InputFile',
    'BiLevelEffect' => 'ImageTransformEffect',
    'BlockElement' => 'MathElement',
    'BlurImageEffect' => 'ImageTransformEffect',
    'BorderBoxElement' => 'MathElement',
    'BoxElement' => 'MathElement',
    'ClosePathSegment' => 'PathSegment',
    'ColorChangeEffect' => 'ImageTransformEffect',
    'ColorReplaceEffect' => 'ImageTransformEffect',
    'ColorScheme' => 'ResourceBase',
    'CubicBezierToPathSegment' => 'PathSegment',
    'DelimiterElement' => 'MathElement',
    'Document' => 'ResourceBase',
    'DocumentProperties' => 'ResourceBase',
    'DocumentProperty' => 'ResourceBase',
    'DuotoneEffect' => 'ImageTransformEffect',
    'FileVersion' => 'StorageFile',
    'FillOverlayImageEffect' => 'ImageTransformEffect',
    'FontScheme' => 'ResourceBase',
    'FormatScheme' => 'ResourceBase',
    'FractionElement' => 'MathElement',
    'FunctionElement' => 'MathElement',
    'GradientFill' => 'FillFormat',
    'GrayScaleEffect' => 'ImageTransformEffect',
    'GroupingCharacterElement' => 'MathElement',
    'HeaderFooter' => 'ResourceBase',
    'HslEffect' => 'ImageTransformEffect',
    'Html5ExportOptions' => 'ExportOptions',
    'HtmlExportOptions' => 'ExportOptions',
    'Image' => 'ResourceBase',
    'ImageExportOptionsBase' => 'ExportOptions',
    'Images' => 'ResourceBase',
    'LayoutSlide' => 'ResourceBase',
    'LayoutSlides' => 'ResourceBase',
    'LeftSubSuperscriptElement' => 'MathElement',
    'LimitElement' => 'MathElement',
    'LineToPathSegment' => 'PathSegment',
    'LuminanceEffect' => 'ImageTransformEffect',
    'MasterSlide' => 'ResourceBase',
    'MasterSlides' => 'ResourceBase',
    'MatrixElement' => 'MathElement',
    'Merge' => 'Task',
    'MoveToPathSegment' => 'PathSegment',
    'NaryOperatorElement' => 'MathElement',
    'NoFill' => 'FillFormat',
    'NotesSlide' => 'ResourceBase',
    'NotesSlideHeaderFooter' => 'ResourceBase',
    'OneValueChartDataPoint' => 'DataPoint',
    'OneValueSeries' => 'Series',
    'Paragraph' => 'ResourceBase',
    'Paragraphs' => 'ResourceBase',
    'PathInputFile' => 'InputFile',
    'PathOutputFile' => 'OutputFile',
    'PatternFill' => 'FillFormat',
    'PdfExportOptions' => 'ExportOptions',
    'PictureFill' => 'FillFormat',
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
    'Section' => 'ResourceBase',
    'Sections' => 'ResourceBase',
    'ShapeBase' => 'ResourceBase',
    'Shapes' => 'ResourceBase',
    'Slide' => 'ResourceBase',
    'SlideAnimation' => 'ResourceBase',
    'SlideBackground' => 'ResourceBase',
    'SlideComment' => 'SlideCommentBase',
    'SlideComments' => 'ResourceBase',
    'SlideModernComment' => 'SlideCommentBase',
    'SlideProperties' => 'ResourceBase',
    'Slides' => 'ResourceBase',
    'SolidFill' => 'FillFormat',
    'SplitDocumentResult' => 'ResourceBase',
    'SubscriptElement' => 'MathElement',
    'SuperscriptElement' => 'MathElement',
    'SvgExportOptions' => 'ExportOptions',
    'SwfExportOptions' => 'ExportOptions',
    'TextElement' => 'MathElement',
    'TextItems' => 'ResourceBase',
    'Theme' => 'ResourceBase',
    'TintEffect' => 'ImageTransformEffect',
    'UpdateBackground' => 'Task',
    'UpdateShape' => 'Task',
    'VideoExportOptions' => 'ExportOptions',
    'ViewProperties' => 'ResourceBase',
    'XYSeries' => 'Series',
    'XamlExportOptions' => 'ExportOptions',
    'XpsExportOptions' => 'ExportOptions',
    'BubbleChartDataPoint' => 'ScatterChartDataPoint',
    'BubbleSeries' => 'XYSeries',
    'Chart' => 'ShapeBase',
    'DocumentReplaceResult' => 'Document',
    'GeometryShape' => 'ShapeBase',
    'GifExportOptions' => 'ImageExportOptionsBase',
    'GraphicalObject' => 'ShapeBase',
    'GroupShape' => 'ShapeBase',
    'ImageExportOptions' => 'ImageExportOptionsBase',
    'OleObjectFrame' => 'ShapeBase',
    'ScatterSeries' => 'XYSeries',
    'SlideReplaceResult' => 'Slide',
    'SmartArt' => 'ShapeBase',
    'SummaryZoomFrame' => 'ShapeBase',
    'Table' => 'ShapeBase',
    'TiffExportOptions' => 'ImageExportOptionsBase',
    'ZoomObject' => 'ShapeBase',
    'AudioFrame' => 'GeometryShape',
    'Connector' => 'GeometryShape',
    'PictureFrame' => 'GeometryShape',
    'SectionZoomFrame' => 'ZoomObject',
    'Shape' => 'GeometryShape',
    'SmartArtShape' => 'GeometryShape',
    'VideoFrame' => 'GeometryShape',
    'ZoomFrame' => 'ZoomObject',
    'SummaryZoomSection' => 'SectionZoomFrame',
    
);

my %determiners = (
    'AccessPermissions' => {  },
    'ApiInfo' => {  },
    'ArrowHeadProperties' => {  },
    'Axes' => {  },
    'Axis' => {  },
    'BlurEffect' => {  },
    'Camera' => {  },
    'ChartCategory' => {  },
    'ChartLinesFormat' => {  },
    'ChartTitle' => {  },
    'ChartWall' => {  },
    'CommonSlideViewProperties' => {  },
    'CustomDashPattern' => {  },
    'DataPoint' => {  },
    'DiscUsage' => {  },
    'Effect' => {  },
    'EffectFormat' => {  },
    'EntityExists' => {  },
    'Error' => {  },
    'ErrorDetails' => {  },
    'ExportFormat' => {  },
    'ExportOptions' => {  },
    'FileVersions' => {  },
    'FilesList' => {  },
    'FilesUploadResult' => {  },
    'FillFormat' => {  },
    'FillOverlayEffect' => {  },
    'FontFallbackRule' => {  },
    'FontSet' => {  },
    'GeometryPath' => {  },
    'GeometryPaths' => {  },
    'GlowEffect' => {  },
    'GradientFillStop' => {  },
    'Hyperlink' => {  },
    'IShapeExportOptions' => {  },
    'ImageExportFormat' => {  },
    'ImageTransformEffect' => {  },
    'InnerShadowEffect' => {  },
    'Input' => {  },
    'InputFile' => {  },
    'InteractiveSequence' => {  },
    'Legend' => {  },
    'LightRig' => {  },
    'LineFormat' => {  },
    'MathElement' => {  },
    'MathParagraph' => {  },
    'MergingSource' => {  },
    'NormalViewRestoredProperties' => {  },
    'NotesSlideExportFormat' => {  },
    'ObjectExist' => {  },
    'OrderedMergeRequest' => {  },
    'OuterShadowEffect' => {  },
    'OutputFile' => {  },
    'PathSegment' => {  },
    'Pipeline' => {  },
    'PlotArea' => {  },
    'PortionFormat' => {  },
    'PresentationToMerge' => {  },
    'PresentationsMergeRequest' => {  },
    'PresetShadowEffect' => {  },
    'ReflectionEffect' => {  },
    'ResourceBase' => {  },
    'ResourceUri' => {  },
    'Series' => {  },
    'SeriesMarker' => {  },
    'ShapeBevel' => {  },
    'ShapeExportFormat' => {  },
    'ShapeImageExportOptions' => {  },
    'ShapeThumbnailBounds' => {  },
    'ShapeType' => {  },
    'ShapesAlignmentType' => {  },
    'SlideCommentBase' => {  },
    'SlideExportFormat' => {  },
    'SmartArtNode' => {  },
    'SoftEdgeEffect' => {  },
    'SpecialSlideType' => {  },
    'StorageExist' => {  },
    'StorageFile' => {  },
    'TableCell' => {  },
    'TableColumn' => {  },
    'TableRow' => {  },
    'Task' => {  },
    'TextBounds' => {  },
    'TextFrameFormat' => {  },
    'TextItem' => {  },
    'ThreeDFormat' => {  },
    'AccentElement' => { 'Type' => 'Accent', },
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
    'ArcToPathSegment' => { 'Type' => 'ArcTo', },
    'ArrayElement' => { 'Type' => 'Array', },
    'BarElement' => { 'Type' => 'Bar', },
    'Base64InputFile' => { 'Type' => 'Base64', },
    'BiLevelEffect' => { 'Type' => 'BiLevel', },
    'BlockElement' => { 'Type' => 'Block', },
    'BlurImageEffect' => { 'Type' => 'Blur', },
    'BorderBoxElement' => { 'Type' => 'BorderBox', },
    'BoxElement' => { 'Type' => 'Box', },
    'ClosePathSegment' => { 'Type' => 'Close', },
    'ColorChangeEffect' => { 'Type' => 'ColorChange', },
    'ColorReplaceEffect' => { 'Type' => 'ColorReplace', },
    'ColorScheme' => {  },
    'CubicBezierToPathSegment' => { 'Type' => 'CubicBezierTo', },
    'DelimiterElement' => { 'Type' => 'Delimiter', },
    'Document' => {  },
    'DocumentProperties' => {  },
    'DocumentProperty' => {  },
    'DuotoneEffect' => { 'Type' => 'Duotone', },
    'FileVersion' => {  },
    'FillOverlayImageEffect' => { 'Type' => 'FillOverlay', },
    'FontScheme' => {  },
    'FormatScheme' => {  },
    'FractionElement' => { 'Type' => 'Fraction', },
    'FunctionElement' => { 'Type' => 'Function', },
    'GradientFill' => { 'Type' => 'Gradient', },
    'GrayScaleEffect' => { 'Type' => 'GrayScale', },
    'GroupingCharacterElement' => { 'Type' => 'GroupingCharacter', },
    'HeaderFooter' => {  },
    'HslEffect' => { 'Type' => 'Hsl', },
    'Html5ExportOptions' => { 'Format' => 'html5', },
    'HtmlExportOptions' => { 'Format' => 'html', },
    'Image' => {  },
    'ImageExportOptionsBase' => {  },
    'Images' => {  },
    'LayoutSlide' => {  },
    'LayoutSlides' => {  },
    'LeftSubSuperscriptElement' => { 'Type' => 'LeftSubSuperscriptElement', },
    'LimitElement' => { 'Type' => 'Limit', },
    'LineToPathSegment' => { 'Type' => 'LineTo', },
    'LuminanceEffect' => { 'Type' => 'Luminance', },
    'MasterSlide' => {  },
    'MasterSlides' => {  },
    'MatrixElement' => { 'Type' => 'Matrix', },
    'Merge' => { 'Type' => 'Merge', },
    'MoveToPathSegment' => { 'Type' => 'MoveTo', },
    'NaryOperatorElement' => { 'Type' => 'NaryOperator', },
    'NoFill' => { 'Type' => 'NoFill', },
    'NotesSlide' => {  },
    'NotesSlideHeaderFooter' => {  },
    'OneValueChartDataPoint' => {  },
    'OneValueSeries' => { 'DataPointType' => 'OneValue', },
    'Paragraph' => {  },
    'Paragraphs' => {  },
    'PathInputFile' => { 'Type' => 'Path', },
    'PathOutputFile' => { 'Type' => 'Path', },
    'PatternFill' => { 'Type' => 'Pattern', },
    'PdfExportOptions' => { 'Format' => 'pdf', },
    'PictureFill' => { 'Type' => 'Picture', },
    'Placeholder' => {  },
    'Placeholders' => {  },
    'Portion' => {  },
    'Portions' => {  },
    'PptxExportOptions' => { 'Format' => 'pptx', },
    'ProtectionProperties' => {  },
    'QuadraticBezierToPathSegment' => { 'Type' => 'QuadBezierTo', },
    'RadicalElement' => { 'Type' => 'Radical', },
    'RemoveShape' => { 'Type' => 'RemoveShape', },
    'RemoveSlide' => { 'Type' => 'RemoveSlide', },
    'ReorderSlide' => { 'Type' => 'ReoderSlide', },
    'ReplaceText' => { 'Type' => 'ReplaceText', },
    'RequestInputFile' => { 'Type' => 'Request', },
    'ResetSlide' => { 'Type' => 'ResetSlide', },
    'ResponseOutputFile' => { 'Type' => 'Response', },
    'RightSubSuperscriptElement' => { 'Type' => 'RightSubSuperscriptElement', },
    'Save' => { 'Type' => 'Save', },
    'SaveShape' => { 'Type' => 'SaveShape', },
    'SaveSlide' => { 'Type' => 'SaveSlide', },
    'ScatterChartDataPoint' => {  },
    'Section' => {  },
    'Sections' => {  },
    'ShapeBase' => {  },
    'Shapes' => {  },
    'Slide' => {  },
    'SlideAnimation' => {  },
    'SlideBackground' => {  },
    'SlideComment' => { 'Type' => 'Regular', },
    'SlideComments' => {  },
    'SlideModernComment' => { 'Type' => 'Modern', },
    'SlideProperties' => {  },
    'Slides' => {  },
    'SolidFill' => { 'Type' => 'Solid', },
    'SplitDocumentResult' => {  },
    'SubscriptElement' => { 'Type' => 'SubscriptElement', },
    'SuperscriptElement' => { 'Type' => 'SuperscriptElement', },
    'SvgExportOptions' => { 'Format' => 'svg', },
    'SwfExportOptions' => { 'Format' => 'swf', },
    'TextElement' => { 'Type' => 'Text', },
    'TextItems' => {  },
    'Theme' => {  },
    'TintEffect' => { 'Type' => 'Tint', },
    'UpdateBackground' => { 'Type' => 'UpdateBackground', },
    'UpdateShape' => { 'Type' => 'UpdateShape', },
    'VideoExportOptions' => { 'Format' => 'mpeg4', },
    'ViewProperties' => {  },
    'XYSeries' => {  },
    'XamlExportOptions' => { 'Format' => 'xaml', },
    'XpsExportOptions' => { 'Format' => 'xps', },
    'BubbleChartDataPoint' => {  },
    'BubbleSeries' => { 'DataPointType' => 'Bubble', },
    'Chart' => { 'Type' => 'Chart', },
    'DocumentReplaceResult' => {  },
    'GeometryShape' => {  },
    'GifExportOptions' => { 'Format' => 'gif', },
    'GraphicalObject' => { 'Type' => 'GraphicalObject', },
    'GroupShape' => { 'Type' => 'GroupShape', },
    'ImageExportOptions' => { 'Format' => 'image', },
    'OleObjectFrame' => { 'Type' => 'OleObjectFrame', },
    'ScatterSeries' => { 'DataPointType' => 'Scatter', },
    'SlideReplaceResult' => {  },
    'SmartArt' => { 'Type' => 'SmartArt', },
    'SummaryZoomFrame' => { 'Type' => 'SummaryZoomFrame', },
    'Table' => { 'Type' => 'Table', },
    'TiffExportOptions' => { 'Format' => 'tiff', },
    'ZoomObject' => {  },
    'AudioFrame' => { 'Type' => 'AudioFrame', },
    'Connector' => { 'Type' => 'Connector', },
    'PictureFrame' => { 'Type' => 'PictureFrame', },
    'SectionZoomFrame' => { 'Type' => 'SectionZoomFrame', },
    'Shape' => { 'Type' => 'Shape', },
    'SmartArtShape' => { 'Type' => 'SmartArtShape', },
    'VideoFrame' => { 'Type' => 'VideoFrame', },
    'ZoomFrame' => { 'Type' => 'ZoomFrame', },
    'SummaryZoomSection' => { 'Type' => 'SummaryZoomSection', },
);

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
