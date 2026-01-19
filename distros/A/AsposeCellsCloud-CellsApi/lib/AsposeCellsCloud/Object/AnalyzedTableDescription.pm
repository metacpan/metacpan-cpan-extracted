=begin comment

Copyright (c) 2026 Aspose.Cells Cloud
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

package AsposeCellsCloud::Object::AnalyzedTableDescription;

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
use AsposeCellsCloud::Object::AnalyzedColumnDescription;
use AsposeCellsCloud::Object::DiscoverChart;
use AsposeCellsCloud::Object::DiscoverPivotTable; 


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


__PACKAGE__->class_documentation({description => 'Represents analyzed table description.',
                                  class => 'AnalyzedTableDescription',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'name' => {
     	datatype => 'string',
     	base_name => 'Name',
     	description => 'Represents table name.',
     	format => '',
     	read_only => '',
     		},
     'sheet_name' => {
     	datatype => 'string',
     	base_name => 'SheetName',
     	description => 'Represents worksheet name which is where the table is located.',
     	format => '',
     	read_only => '',
     		},
     'columns' => {
     	datatype => 'ARRAY[AnalyzedColumnDescription]',
     	base_name => 'Columns',
     	description => 'Represents analyzed description about table columns.',
     	format => '',
     	read_only => '',
     		},
     'date_columns' => {
     	datatype => 'ARRAY[int?]',
     	base_name => 'DateColumns',
     	description => 'Represents date columns list.',
     	format => '',
     	read_only => '',
     		},
     'number_columns' => {
     	datatype => 'ARRAY[int?]',
     	base_name => 'NumberColumns',
     	description => 'Represents number columns list.',
     	format => '',
     	read_only => '',
     		},
     'text_columns' => {
     	datatype => 'ARRAY[int?]',
     	base_name => 'TextColumns',
     	description => 'Represents string columns list.',
     	format => '',
     	read_only => '',
     		},
     'exception_columns' => {
     	datatype => 'ARRAY[int?]',
     	base_name => 'ExceptionColumns',
     	description => 'Represents exception columns list.',
     	format => '',
     	read_only => '',
     		},
     'has_table_header_row' => {
     	datatype => 'boolean',
     	base_name => 'HasTableHeaderRow',
     	description => 'Represents there is a table header in the table.',
     	format => '',
     	read_only => '',
     		},
     'has_table_total_row' => {
     	datatype => 'boolean',
     	base_name => 'HasTableTotalRow',
     	description => 'Represents there is a total row in the table.',
     	format => '',
     	read_only => '',
     		},
     'start_data_column_index' => {
     	datatype => 'int',
     	base_name => 'StartDataColumnIndex',
     	description => 'Represents the column index as the start data column.',
     	format => '',
     	read_only => '',
     		},
     'end_data_column_index' => {
     	datatype => 'int',
     	base_name => 'EndDataColumnIndex',
     	description => 'Represents the column index as the end data column.',
     	format => '',
     	read_only => '',
     		},
     'start_data_row_index' => {
     	datatype => 'int',
     	base_name => 'StartDataRowIndex',
     	description => 'Represents the row index as the start data row.',
     	format => '',
     	read_only => '',
     		},
     'end_data_row_index' => {
     	datatype => 'int',
     	base_name => 'EndDataRowIndex',
     	description => 'Represents the row index as the end data row.',
     	format => '',
     	read_only => '',
     		},
     'thumbnail' => {
     	datatype => 'string',
     	base_name => 'Thumbnail',
     	description => 'Represents table thumbnail. Base64String',
     	format => '',
     	read_only => '',
     		},
     'discover_charts' => {
     	datatype => 'ARRAY[DiscoverChart]',
     	base_name => 'DiscoverCharts',
     	description => 'Represents a collection of charts, which is a collection of charts created based on data analysis of a table.',
     	format => '',
     	read_only => '',
     		},
     'discover_pivot_tables' => {
     	datatype => 'ARRAY[DiscoverPivotTable]',
     	base_name => 'DiscoverPivotTables',
     	description => 'Represents a collection of pivot tables, which is a collection of pivot tables created based on data analysis of a table.',
     	format => '',
     	read_only => '',
     		},    
});

__PACKAGE__->swagger_types( {
    'name' => 'string',
    'sheet_name' => 'string',
    'columns' => 'ARRAY[AnalyzedColumnDescription]',
    'date_columns' => 'ARRAY[int?]',
    'number_columns' => 'ARRAY[int?]',
    'text_columns' => 'ARRAY[int?]',
    'exception_columns' => 'ARRAY[int?]',
    'has_table_header_row' => 'boolean',
    'has_table_total_row' => 'boolean',
    'start_data_column_index' => 'int',
    'end_data_column_index' => 'int',
    'start_data_row_index' => 'int',
    'end_data_row_index' => 'int',
    'thumbnail' => 'string',
    'discover_charts' => 'ARRAY[DiscoverChart]',
    'discover_pivot_tables' => 'ARRAY[DiscoverPivotTable]' 
} );

__PACKAGE__->attribute_map( {
    'name' => 'Name',
    'sheet_name' => 'SheetName',
    'columns' => 'Columns',
    'date_columns' => 'DateColumns',
    'number_columns' => 'NumberColumns',
    'text_columns' => 'TextColumns',
    'exception_columns' => 'ExceptionColumns',
    'has_table_header_row' => 'HasTableHeaderRow',
    'has_table_total_row' => 'HasTableTotalRow',
    'start_data_column_index' => 'StartDataColumnIndex',
    'end_data_column_index' => 'EndDataColumnIndex',
    'start_data_row_index' => 'StartDataRowIndex',
    'end_data_row_index' => 'EndDataRowIndex',
    'thumbnail' => 'Thumbnail',
    'discover_charts' => 'DiscoverCharts',
    'discover_pivot_tables' => 'DiscoverPivotTables' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;