=begin comment

Copyright (c) 2025 Aspose.Cells Cloud
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

package AsposeCellsCloud::Object::XpsSaveOptions;

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
use AsposeCellsCloud::Object::PaginatedSaveOptions; 


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


__PACKAGE__->class_documentation({description => '',
                                  class => 'XpsSaveOptions',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'default_font' => {
     	datatype => 'string',
     	base_name => 'DefaultFont',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'check_workbook_default_font' => {
     	datatype => 'boolean',
     	base_name => 'CheckWorkbookDefaultFont',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'check_font_compatibility' => {
     	datatype => 'boolean',
     	base_name => 'CheckFontCompatibility',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_font_substitution_char_granularity' => {
     	datatype => 'boolean',
     	base_name => 'IsFontSubstitutionCharGranularity',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'one_page_per_sheet' => {
     	datatype => 'boolean',
     	base_name => 'OnePagePerSheet',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'all_columns_in_one_page_per_sheet' => {
     	datatype => 'boolean',
     	base_name => 'AllColumnsInOnePagePerSheet',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'ignore_error' => {
     	datatype => 'boolean',
     	base_name => 'IgnoreError',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'output_blank_page_when_nothing_to_print' => {
     	datatype => 'boolean',
     	base_name => 'OutputBlankPageWhenNothingToPrint',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'page_index' => {
     	datatype => 'int',
     	base_name => 'PageIndex',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'page_count' => {
     	datatype => 'int',
     	base_name => 'PageCount',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'printing_page_type' => {
     	datatype => 'string',
     	base_name => 'PrintingPageType',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'gridline_type' => {
     	datatype => 'string',
     	base_name => 'GridlineType',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'text_cross_type' => {
     	datatype => 'string',
     	base_name => 'TextCrossType',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'default_edit_language' => {
     	datatype => 'string',
     	base_name => 'DefaultEditLanguage',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'emf_render_setting' => {
     	datatype => 'string',
     	base_name => 'EmfRenderSetting',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'merge_areas' => {
     	datatype => 'boolean',
     	base_name => 'MergeAreas',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'sort_external_names' => {
     	datatype => 'boolean',
     	base_name => 'SortExternalNames',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'update_smart_art' => {
     	datatype => 'boolean',
     	base_name => 'UpdateSmartArt',
     	description => '',
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
     'check_excel_restriction' => {
     	datatype => 'boolean',
     	base_name => 'CheckExcelRestriction',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'encrypt_document_properties' => {
     	datatype => 'boolean',
     	base_name => 'EncryptDocumentProperties',
     	description => '',
     	format => '',
     	read_only => '',
     		},    
});

__PACKAGE__->swagger_types( {
    'default_font' => 'string',
    'check_workbook_default_font' => 'boolean',
    'check_font_compatibility' => 'boolean',
    'is_font_substitution_char_granularity' => 'boolean',
    'one_page_per_sheet' => 'boolean',
    'all_columns_in_one_page_per_sheet' => 'boolean',
    'ignore_error' => 'boolean',
    'output_blank_page_when_nothing_to_print' => 'boolean',
    'page_index' => 'int',
    'page_count' => 'int',
    'printing_page_type' => 'string',
    'gridline_type' => 'string',
    'text_cross_type' => 'string',
    'default_edit_language' => 'string',
    'emf_render_setting' => 'string',
    'merge_areas' => 'boolean',
    'sort_external_names' => 'boolean',
    'update_smart_art' => 'boolean',
    'save_format' => 'string',
    'cached_file_folder' => 'string',
    'clear_data' => 'boolean',
    'create_directory' => 'boolean',
    'enable_http_compression' => 'boolean',
    'refresh_chart_cache' => 'boolean',
    'sort_names' => 'boolean',
    'validate_merged_areas' => 'boolean',
    'check_excel_restriction' => 'boolean',
    'encrypt_document_properties' => 'boolean' 
} );

__PACKAGE__->attribute_map( {
    'default_font' => 'DefaultFont',
    'check_workbook_default_font' => 'CheckWorkbookDefaultFont',
    'check_font_compatibility' => 'CheckFontCompatibility',
    'is_font_substitution_char_granularity' => 'IsFontSubstitutionCharGranularity',
    'one_page_per_sheet' => 'OnePagePerSheet',
    'all_columns_in_one_page_per_sheet' => 'AllColumnsInOnePagePerSheet',
    'ignore_error' => 'IgnoreError',
    'output_blank_page_when_nothing_to_print' => 'OutputBlankPageWhenNothingToPrint',
    'page_index' => 'PageIndex',
    'page_count' => 'PageCount',
    'printing_page_type' => 'PrintingPageType',
    'gridline_type' => 'GridlineType',
    'text_cross_type' => 'TextCrossType',
    'default_edit_language' => 'DefaultEditLanguage',
    'emf_render_setting' => 'EmfRenderSetting',
    'merge_areas' => 'MergeAreas',
    'sort_external_names' => 'SortExternalNames',
    'update_smart_art' => 'UpdateSmartArt',
    'save_format' => 'SaveFormat',
    'cached_file_folder' => 'CachedFileFolder',
    'clear_data' => 'ClearData',
    'create_directory' => 'CreateDirectory',
    'enable_http_compression' => 'EnableHTTPCompression',
    'refresh_chart_cache' => 'RefreshChartCache',
    'sort_names' => 'SortNames',
    'validate_merged_areas' => 'ValidateMergedAreas',
    'check_excel_restriction' => 'CheckExcelRestriction',
    'encrypt_document_properties' => 'EncryptDocumentProperties' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;