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

package AsposeCellsCloud::Object::CalculationOptions;

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
use AsposeCellsCloud::Object::AbstractCalculationEngine;
use AsposeCellsCloud::Object::AbstractCalculationMonitor;
use AsposeCellsCloud::Object::Workbook; 


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


__PACKAGE__->class_documentation({description => '           Represents options for calculation.           ',
                                  class => 'CalculationOptions',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'calc_stack_size' => {
     	datatype => 'int',
     	base_name => 'CalcStackSize',
     	description => 'Specifies the stack size for calculating cells recursively. ',
     	format => '',
     	read_only => '',
     		},
     'ignore_error' => {
     	datatype => 'boolean',
     	base_name => 'IgnoreError',
     	description => 'Indicates whether errors encountered while calculating formulas should be ignored.            The error may be unsupported function, external links, etc.            The default value is true. ',
     	format => '',
     	read_only => '',
     		},
     'precision_strategy' => {
     	datatype => 'string',
     	base_name => 'PrecisionStrategy',
     	description => 'Specifies the strategy for processing precision of calculation. ',
     	format => '',
     	read_only => '',
     		},
     'recursive' => {
     	datatype => 'boolean',
     	base_name => 'Recursive',
     	description => 'Indicates whether calculate the dependent cells recursively when calculating one cell and it depends on other cells.            The default value is true. ',
     	format => '',
     	read_only => '',
     		},
     'custom_engine' => {
     	datatype => 'AbstractCalculationEngine',
     	base_name => 'CustomEngine',
     	description => 'The custom formula calculation engine to extend the default calculation engine of Aspose.Cells. ',
     	format => '',
     	read_only => '',
     		},
     'calculation_monitor' => {
     	datatype => 'AbstractCalculationMonitor',
     	base_name => 'CalculationMonitor',
     	description => 'The monitor for user to track the progress of formula calculation. ',
     	format => '',
     	read_only => '',
     		},
     'linked_data_sources' => {
     	datatype => 'ARRAY[Workbook]',
     	base_name => 'LinkedDataSources',
     	description => 'Specifies the data sources for external links used in formulas. ',
     	format => '',
     	read_only => '',
     		},    
});

__PACKAGE__->swagger_types( {
    'calc_stack_size' => 'int',
    'ignore_error' => 'boolean',
    'precision_strategy' => 'string',
    'recursive' => 'boolean',
    'custom_engine' => 'AbstractCalculationEngine',
    'calculation_monitor' => 'AbstractCalculationMonitor',
    'linked_data_sources' => 'ARRAY[Workbook]' 
} );

__PACKAGE__->attribute_map( {
    'calc_stack_size' => 'CalcStackSize',
    'ignore_error' => 'IgnoreError',
    'precision_strategy' => 'PrecisionStrategy',
    'recursive' => 'Recursive',
    'custom_engine' => 'CustomEngine',
    'calculation_monitor' => 'CalculationMonitor',
    'linked_data_sources' => 'LinkedDataSources' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;