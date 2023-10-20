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

package AsposeCellsCloud::Object::Name;

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
                                  class => 'Name',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'comment' => {
     	datatype => 'string',
     	base_name => 'Comment',
     	description => 'Gets and sets the comment of the name.                        Only applies for Excel 2007.',
     	format => '',
     	read_only => '',
     		},
     'worksheet_index' => {
     	datatype => 'int',
     	base_name => 'WorksheetIndex',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_referred' => {
     	datatype => 'boolean',
     	base_name => 'IsReferred',
     	description => 'Indicates whether this name is referred by other formulas.',
     	format => '',
     	read_only => '',
     		},
     'is_visible' => {
     	datatype => 'boolean',
     	base_name => 'IsVisible',
     	description => 'Indicates whether the name is visible.',
     	format => '',
     	read_only => '',
     		},
     'r1_c1_refers_to' => {
     	datatype => 'string',
     	base_name => 'R1C1RefersTo',
     	description => 'Gets or sets a R1C1 reference of the .',
     	format => '',
     	read_only => '',
     		},
     'refers_to' => {
     	datatype => 'string',
     	base_name => 'RefersTo',
     	description => 'Returns or sets the formula that the name is defined to refer to, beginning with an equal sign.',
     	format => '',
     	read_only => '',
     		},
     'text' => {
     	datatype => 'string',
     	base_name => 'Text',
     	description => 'Gets the name text of the object.',
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
    'comment' => 'string',
    'worksheet_index' => 'int',
    'is_referred' => 'boolean',
    'is_visible' => 'boolean',
    'r1_c1_refers_to' => 'string',
    'refers_to' => 'string',
    'text' => 'string',
    'link' => 'Link' 
} );

__PACKAGE__->attribute_map( {
    'comment' => 'Comment',
    'worksheet_index' => 'WorksheetIndex',
    'is_referred' => 'IsReferred',
    'is_visible' => 'IsVisible',
    'r1_c1_refers_to' => 'R1C1RefersTo',
    'refers_to' => 'RefersTo',
    'text' => 'Text',
    'link' => 'link' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;