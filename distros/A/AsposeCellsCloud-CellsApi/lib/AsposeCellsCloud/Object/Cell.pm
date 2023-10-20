=begin comment

Copyright (c) 2023 Aspose.Cells Cloud
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

package AsposeCellsCloud::Object::Cell;

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


__PACKAGE__->class_documentation({description => '',
                                  class => 'Cell',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'name' => {
     	datatype => 'string',
     	base_name => 'Name',
     	description => 'Gets the name of the cell.',
     	format => '',
     	read_only => '',
     		},
     'row' => {
     	datatype => 'int',
     	base_name => 'Row',
     	description => 'Gets row number (zero based) of the cell.',
     	format => '',
     	read_only => '',
     		},
     'column' => {
     	datatype => 'int',
     	base_name => 'Column',
     	description => 'Gets column number (zero based) of the cell.',
     	format => '',
     	read_only => '',
     		},
     'value' => {
     	datatype => 'string',
     	base_name => 'Value',
     	description => 'Gets the value contained in this cell.',
     	format => '',
     	read_only => '',
     		},
     'type' => {
     	datatype => 'string',
     	base_name => 'Type',
     	description => 'Represents cell value type.',
     	format => '',
     	read_only => '',
     		},
     'formula' => {
     	datatype => 'string',
     	base_name => 'Formula',
     	description => 'Gets or sets a formula of the .',
     	format => '',
     	read_only => '',
     		},
     'is_formula' => {
     	datatype => 'boolean',
     	base_name => 'IsFormula',
     	description => 'Represents if the specified cell contains formula.',
     	format => '',
     	read_only => '',
     		},
     'is_merged' => {
     	datatype => 'boolean',
     	base_name => 'IsMerged',
     	description => 'Checks if a cell is part of a merged range or not.',
     	format => '',
     	read_only => '',
     		},
     'is_array_header' => {
     	datatype => 'boolean',
     	base_name => 'IsArrayHeader',
     	description => 'Indicates the cell`s formula is and array formula                         and it is the first cell of the array.',
     	format => '',
     	read_only => '',
     		},
     'is_in_array' => {
     	datatype => 'boolean',
     	base_name => 'IsInArray',
     	description => 'Indicates whether the cell formula is an array formula.',
     	format => '',
     	read_only => '',
     		},
     'is_error_value' => {
     	datatype => 'boolean',
     	base_name => 'IsErrorValue',
     	description => 'Checks if the value of this cell is an error.',
     	format => '',
     	read_only => '',
     		},
     'is_in_table' => {
     	datatype => 'boolean',
     	base_name => 'IsInTable',
     	description => 'Indicates whether this cell is part of table formula.',
     	format => '',
     	read_only => '',
     		},
     'is_style_set' => {
     	datatype => 'boolean',
     	base_name => 'IsStyleSet',
     	description => 'Indicates if the cell`s style is set. If return false, it means this cell has a default cell format.',
     	format => '',
     	read_only => '',
     		},
     'html_string' => {
     	datatype => 'string',
     	base_name => 'HtmlString',
     	description => 'Gets and sets the html string which contains data and some formats in this cell.',
     	format => '',
     	read_only => '',
     		},
     'style' => {
     	datatype => 'LinkElement',
     	base_name => 'Style',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'worksheet' => {
     	datatype => 'string',
     	base_name => 'Worksheet',
     	description => 'Gets the parent worksheet.',
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
    'name' => 'string',
    'row' => 'int',
    'column' => 'int',
    'value' => 'string',
    'type' => 'string',
    'formula' => 'string',
    'is_formula' => 'boolean',
    'is_merged' => 'boolean',
    'is_array_header' => 'boolean',
    'is_in_array' => 'boolean',
    'is_error_value' => 'boolean',
    'is_in_table' => 'boolean',
    'is_style_set' => 'boolean',
    'html_string' => 'string',
    'style' => 'LinkElement',
    'worksheet' => 'string',
    'link' => 'Link' 
} );

__PACKAGE__->attribute_map( {
    'name' => 'Name',
    'row' => 'Row',
    'column' => 'Column',
    'value' => 'Value',
    'type' => 'Type',
    'formula' => 'Formula',
    'is_formula' => 'IsFormula',
    'is_merged' => 'IsMerged',
    'is_array_header' => 'IsArrayHeader',
    'is_in_array' => 'IsInArray',
    'is_error_value' => 'IsErrorValue',
    'is_in_table' => 'IsInTable',
    'is_style_set' => 'IsStyleSet',
    'html_string' => 'HtmlString',
    'style' => 'Style',
    'worksheet' => 'Worksheet',
    'link' => 'link' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;