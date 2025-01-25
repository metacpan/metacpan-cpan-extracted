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

package AsposeCellsCloud::Object::Validation;

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
use AsposeCellsCloud::Object::CellArea;
use AsposeCellsCloud::Object::Link;
use AsposeCellsCloud::Object::LinkElement; 


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


__PACKAGE__->class_documentation({description => 'Represents data validation.settings.',
                                  class => 'Validation',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'alert_style' => {
     	datatype => 'string',
     	base_name => 'AlertStyle',
     	description => 'Represents the validation alert style.',
     	format => '',
     	read_only => '',
     		},
     'area_list' => {
     	datatype => 'ARRAY[CellArea]',
     	base_name => 'AreaList',
     	description => 'Represents a collection of Aspose.Cells.CellArea which contains the data                validation settings.',
     	format => '',
     	read_only => '',
     		},
     'error_message' => {
     	datatype => 'string',
     	base_name => 'ErrorMessage',
     	description => 'Represents the data validation error message.',
     	format => '',
     	read_only => '',
     		},
     'error_title' => {
     	datatype => 'string',
     	base_name => 'ErrorTitle',
     	description => 'Represents the title of the data-validation error dialog box.',
     	format => '',
     	read_only => '',
     		},
     'formula1' => {
     	datatype => 'string',
     	base_name => 'Formula1',
     	description => 'Represents the value or expression associated with the data validation.',
     	format => '',
     	read_only => '',
     		},
     'formula2' => {
     	datatype => 'string',
     	base_name => 'Formula2',
     	description => 'Represents the value or expression associated with the data validation.',
     	format => '',
     	read_only => '',
     		},
     'ignore_blank' => {
     	datatype => 'boolean',
     	base_name => 'IgnoreBlank',
     	description => 'Indicates whether blank values are permitted by the range data validation.',
     	format => '',
     	read_only => '',
     		},
     'in_cell_drop_down' => {
     	datatype => 'boolean',
     	base_name => 'InCellDropDown',
     	description => 'Indicates whether data validation displays a drop-down list that contains acceptable values.',
     	format => '',
     	read_only => '',
     		},
     'input_message' => {
     	datatype => 'string',
     	base_name => 'InputMessage',
     	description => 'Represents the data validation input message.',
     	format => '',
     	read_only => '',
     		},
     'input_title' => {
     	datatype => 'string',
     	base_name => 'InputTitle',
     	description => 'Represents the title of the data-validation input dialog box.',
     	format => '',
     	read_only => '',
     		},
     'operator' => {
     	datatype => 'string',
     	base_name => 'Operator',
     	description => 'Represents the operator for the data validation.',
     	format => '',
     	read_only => '',
     		},
     'show_error' => {
     	datatype => 'boolean',
     	base_name => 'ShowError',
     	description => 'Indicates whether the data validation error message will be displayed whenever the user enters invalid data.',
     	format => '',
     	read_only => '',
     		},
     'show_input' => {
     	datatype => 'boolean',
     	base_name => 'ShowInput',
     	description => 'Indicates whether the data validation input message will be displayed whenever the user selects a cell in the data validation range.',
     	format => '',
     	read_only => '',
     		},
     'type' => {
     	datatype => 'string',
     	base_name => 'Type',
     	description => 'Represents the data validation type.',
     	format => '',
     	read_only => '',
     		},
     'value1' => {
     	datatype => 'string',
     	base_name => 'Value1',
     	description => 'Represents the first value associated with the data validation.',
     	format => '',
     	read_only => '',
     		},
     'value2' => {
     	datatype => 'string',
     	base_name => 'Value2',
     	description => 'Represents the second value associated with the data validation.',
     	format => '',
     	read_only => '',
     		},
     'link' => {
     	datatype => 'Link',
     	base_name => 'link',
     	description => '',
     	format => '',
     	read_only => '',
     		},    
});

__PACKAGE__->swagger_types( {
    'alert_style' => 'string',
    'area_list' => 'ARRAY[CellArea]',
    'error_message' => 'string',
    'error_title' => 'string',
    'formula1' => 'string',
    'formula2' => 'string',
    'ignore_blank' => 'boolean',
    'in_cell_drop_down' => 'boolean',
    'input_message' => 'string',
    'input_title' => 'string',
    'operator' => 'string',
    'show_error' => 'boolean',
    'show_input' => 'boolean',
    'type' => 'string',
    'value1' => 'string',
    'value2' => 'string',
    'link' => 'Link' 
} );

__PACKAGE__->attribute_map( {
    'alert_style' => 'AlertStyle',
    'area_list' => 'AreaList',
    'error_message' => 'ErrorMessage',
    'error_title' => 'ErrorTitle',
    'formula1' => 'Formula1',
    'formula2' => 'Formula2',
    'ignore_blank' => 'IgnoreBlank',
    'in_cell_drop_down' => 'InCellDropDown',
    'input_message' => 'InputMessage',
    'input_title' => 'InputTitle',
    'operator' => 'Operator',
    'show_error' => 'ShowError',
    'show_input' => 'ShowInput',
    'type' => 'Type',
    'value1' => 'Value1',
    'value2' => 'Value2',
    'link' => 'link' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;