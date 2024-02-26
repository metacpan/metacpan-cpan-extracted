=begin comment

Copyright (c) 2024 Aspose.Cells Cloud
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

package AsposeCellsCloud::Object::PdfSaveOptions;

require 5.6.0;
use strict;
use warnings;
use utf8;
use JSON qw(decode_json);
use Data::Dumper;
use Module::Runtime qw(use_module);
use Log::Any qw($log);
use Date::Parse;
use DateTime;
use AsposeCellsCloud::Object::PdfSecurityOptions;
use AsposeCellsCloud::Object::RenderingWatermark;
use AsposeCellsCloud::Object::SaveOptions; 


use base ("Class::Accessor", "Class::Data::Inheritable");



__PACKAGE__->mk_classdata('attribute_map' => {});
__PACKAGE__->mk_classdata('swagger_types' => {});
__PACKAGE__->mk_classdata('method_documentation' => {}); 
__PACKAGE__->mk_classdata('class_documentation' => {});

# new object
sub new { 
    my ($class, %args) = @_; 

	my $self = bless {}, $class;

	foreach my $attribute (keys %{$class->attribute_map}) {
		my $args_key = $class->attribute_map->{$attribute};
		$self->$attribute( $args{ $args_key } );
	}

	return $self;
}  

# return perl hash
sub to_hash {
    return decode_json(JSON->new->convert_blessed->encode( shift ));
}

# used by JSON for serialization
sub TO_JSON { 
    my $self = shift;
    my $_data = {};
    foreach my $_key (keys %{$self->attribute_map}) {
        if (defined $self->{$_key}) {
            $_data->{$self->attribute_map->{$_key}} = $self->{$_key};
        }
    }
    return $_data;
}

# from Perl hashref
sub from_hash {
    my ($self, $hash) = @_;

    # loop through attributes and use swagger_types to deserialize the data
    while ( my ($_key, $_type) = each %{$self->swagger_types} ) {
    	my $_json_attribute = $self->attribute_map->{$_key}; 
        if ($_type =~ /^array\[/i) { # array
            my $_subclass = substr($_type, 6, -1);
            my @_array = ();
            foreach my $_element (@{$hash->{$_json_attribute}}) {
                push @_array, $self->_deserialize($_subclass, $_element);
            }
            $self->{$_key} = \@_array;
        } elsif (exists $hash->{$_json_attribute}) { #hash(model), primitive, datetime
            $self->{$_key} = $self->_deserialize($_type, $hash->{$_json_attribute});
        } else {
        	$log->debugf("Warning: %s (%s) does not exist in input hash\n", $_key, $_json_attribute);
        }
    }

    return $self;
}

# deserialize non-array data
sub _deserialize {
    my ($self, $type, $data) = @_;
    $log->debugf("deserializing %s with %s",Dumper($data), $type);

    if ($type eq 'DateTime') {
        return DateTime->from_epoch(epoch => str2time($data));
    } elsif ( grep( /^$type$/, ('int', 'double', 'string', 'boolean'))) {
        return $data;
    } else { # hash(model)
        my $_instance = eval "AsposeCellsCloud::Object::$type->new()";
        return $_instance->from_hash($data);
    }
}


__PACKAGE__->class_documentation({description => 'Represents options of saving pdf file.',
                                  class => 'PdfSaveOptions',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'display_doc_title' => {
     	datatype => 'boolean',
     	base_name => 'DisplayDocTitle',
     	description => 'Indicates whether the window`s title bar should display the document title.',
     	format => '',
     	read_only => '',
     		},
     'export_document_structure' => {
     	datatype => 'boolean',
     	base_name => 'ExportDocumentStructure',
     	description => 'Indicates whether to export document structure.',
     	format => '',
     	read_only => '',
     		},
     'emf_render_setting' => {
     	datatype => 'string',
     	base_name => 'EmfRenderSetting',
     	description => 'Setting for rendering Emf metafile.',
     	format => '',
     	read_only => '',
     		},
     'custom_properties_export' => {
     	datatype => 'string',
     	base_name => 'CustomPropertiesExport',
     	description => 'Specifies the way CustomDocumentPropertyCollection are exported to PDF file.',
     	format => '',
     	read_only => '',
     		},
     'optimization_type' => {
     	datatype => 'string',
     	base_name => 'OptimizationType',
     	description => 'Gets and sets pdf optimization type.',
     	format => '',
     	read_only => '',
     		},
     'producer' => {
     	datatype => 'string',
     	base_name => 'Producer',
     	description => 'Gets and sets producer of generated pdf document.',
     	format => '',
     	read_only => '',
     		},
     'pdf_compression' => {
     	datatype => 'string',
     	base_name => 'PdfCompression',
     	description => 'Indicate the compression algorithm.',
     	format => '',
     	read_only => '',
     		},
     'font_encoding' => {
     	datatype => 'string',
     	base_name => 'FontEncoding',
     	description => 'Gets or sets embedded font encoding in pdf.',
     	format => '',
     	read_only => '',
     		},
     'watermark' => {
     	datatype => 'RenderingWatermark',
     	base_name => 'Watermark',
     	description => 'Gets or sets watermark to output.',
     	format => '',
     	read_only => '',
     		},
     'calculate_formula' => {
     	datatype => 'boolean',
     	base_name => 'CalculateFormula',
     	description => 'Indicates whether calculate formulas before saving pdf file.The default value is false.',
     	format => '',
     	read_only => '',
     		},
     'check_font_compatibility' => {
     	datatype => 'boolean',
     	base_name => 'CheckFontCompatibility',
     	description => 'Indicates whether check font compatibility for every character in text.                The default value is true.  Disable this property may give better performance.                 But when the default or specified font of text/character cannot be used                to render it, unreadable characters(such as block) maybe occur in the generated                pdf.  For such situation user should keep this property as true so that alternative                font can be searched and used to render the text instead;',
     	format => '',
     	read_only => '',
     		},
     'compliance' => {
     	datatype => 'string',
     	base_name => 'Compliance',
     	description => 'Workbook converts to pdf will according to PdfCompliance in this property.',
     	format => '',
     	read_only => '',
     		},
     'default_font' => {
     	datatype => 'string',
     	base_name => 'DefaultFont',
     	description => 'When characters in the Excel are unicode and not be set with correct font in cell style,              They may appear as block in pdf,image.  Set the DefaultFont such as MingLiu or MS Gothic to show these characters.               If this property is not set, Aspose.Cells will use system default font to show these unicode characters.',
     	format => '',
     	read_only => '',
     		},
     'one_page_per_sheet' => {
     	datatype => 'boolean',
     	base_name => 'OnePagePerSheet',
     	description => 'If OnePagePerSheet is true , all content of one sheet will output to only            one page in result. The paper size of pagesetup will be invalid, and the               other settings of pagesetup will still take effect.',
     	format => '',
     	read_only => '',
     		},
     'printing_page_type' => {
     	datatype => 'string',
     	base_name => 'PrintingPageType',
     	description => 'Indicates which pages will not be printed.',
     	format => '',
     	read_only => '',
     		},
     'security_options' => {
     	datatype => 'PdfSecurityOptions',
     	base_name => 'SecurityOptions',
     	description => 'Set this options, when security is need in xls2pdf result.',
     	format => '',
     	read_only => '',
     		},
     'desired_ppi' => {
     	datatype => 'int',
     	base_name => 'desiredPPI',
     	description => 'Set desired PPI(pixels per inch) of resample images and jpeg quality  All images will be converted to JPEG with the specified quality setting, and images that are greater than the specified PPI (pixels per inch) will be resampled.              Desired pixels per inch. 220 high quality. 150 screen quality. 96 email quality.',
     	format => '',
     	read_only => '',
     		},
     'jpeg_quality' => {
     	datatype => 'int',
     	base_name => 'jpegQuality',
     	description => 'Set desired PPI(pixels per inch) of resample images and jpeg quality  All images will be converted to JPEG with the specified quality setting, and images that are greater than the specified PPI (pixels per inch) will be resampled.              0 - 100% JPEG quality.',
     	format => '',
     	read_only => '',
     		},
     'image_type' => {
     	datatype => 'string',
     	base_name => 'ImageType',
     	description => 'Represents the image type when converting the chart and shape .',
     	format => '',
     	read_only => '',
     		},
     'save_format' => {
     	datatype => 'string',
     	base_name => 'SaveFormat',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'cached_file_folder' => {
     	datatype => 'string',
     	base_name => 'CachedFileFolder',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'clear_data' => {
     	datatype => 'boolean',
     	base_name => 'ClearData',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'create_directory' => {
     	datatype => 'boolean',
     	base_name => 'CreateDirectory',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'enable_http_compression' => {
     	datatype => 'boolean',
     	base_name => 'EnableHTTPCompression',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'refresh_chart_cache' => {
     	datatype => 'boolean',
     	base_name => 'RefreshChartCache',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'sort_names' => {
     	datatype => 'boolean',
     	base_name => 'SortNames',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'validate_merged_areas' => {
     	datatype => 'boolean',
     	base_name => 'ValidateMergedAreas',
     	description => '',
     	format => '',
     	read_only => '',
     		},    
});

__PACKAGE__->swagger_types( {
    'display_doc_title' => 'boolean',
    'export_document_structure' => 'boolean',
    'emf_render_setting' => 'string',
    'custom_properties_export' => 'string',
    'optimization_type' => 'string',
    'producer' => 'string',
    'pdf_compression' => 'string',
    'font_encoding' => 'string',
    'watermark' => 'RenderingWatermark',
    'calculate_formula' => 'boolean',
    'check_font_compatibility' => 'boolean',
    'compliance' => 'string',
    'default_font' => 'string',
    'one_page_per_sheet' => 'boolean',
    'printing_page_type' => 'string',
    'security_options' => 'PdfSecurityOptions',
    'desired_ppi' => 'int',
    'jpeg_quality' => 'int',
    'image_type' => 'string',
    'save_format' => 'string',
    'cached_file_folder' => 'string',
    'clear_data' => 'boolean',
    'create_directory' => 'boolean',
    'enable_http_compression' => 'boolean',
    'refresh_chart_cache' => 'boolean',
    'sort_names' => 'boolean',
    'validate_merged_areas' => 'boolean' 
} );

__PACKAGE__->attribute_map( {
    'display_doc_title' => 'DisplayDocTitle',
    'export_document_structure' => 'ExportDocumentStructure',
    'emf_render_setting' => 'EmfRenderSetting',
    'custom_properties_export' => 'CustomPropertiesExport',
    'optimization_type' => 'OptimizationType',
    'producer' => 'Producer',
    'pdf_compression' => 'PdfCompression',
    'font_encoding' => 'FontEncoding',
    'watermark' => 'Watermark',
    'calculate_formula' => 'CalculateFormula',
    'check_font_compatibility' => 'CheckFontCompatibility',
    'compliance' => 'Compliance',
    'default_font' => 'DefaultFont',
    'one_page_per_sheet' => 'OnePagePerSheet',
    'printing_page_type' => 'PrintingPageType',
    'security_options' => 'SecurityOptions',
    'desired_ppi' => 'desiredPPI',
    'jpeg_quality' => 'jpegQuality',
    'image_type' => 'ImageType',
    'save_format' => 'SaveFormat',
    'cached_file_folder' => 'CachedFileFolder',
    'clear_data' => 'ClearData',
    'create_directory' => 'CreateDirectory',
    'enable_http_compression' => 'EnableHTTPCompression',
    'refresh_chart_cache' => 'RefreshChartCache',
    'sort_names' => 'SortNames',
    'validate_merged_areas' => 'ValidateMergedAreas' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;