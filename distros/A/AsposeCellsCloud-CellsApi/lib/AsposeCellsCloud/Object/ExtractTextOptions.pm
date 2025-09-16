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

package AsposeCellsCloud::Object::ExtractTextOptions;

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
use AsposeCellsCloud::Object::BaseOperateOptions;
use AsposeCellsCloud::Object::DataSource;
use AsposeCellsCloud::Object::FileInfo; 


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


__PACKAGE__->class_documentation({description => 'I`m happy to help! Could you please provide me with the features you would like me to summarize for you?',
                                  class => 'ExtractTextOptions',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'name' => {
     	datatype => 'string',
     	base_name => 'Name',
     	description => 'This class has a public property for storing and retrieving a name value.',
     	format => '',
     	read_only => '',
     		},
     'data_source' => {
     	datatype => 'DataSource',
     	base_name => 'DataSource',
     	description => 'Represents data source.  There are three types of data, they are CloudFileSystem, RequestFiles, HttpUri.',
     	format => '',
     	read_only => '',
     		},
     'file_info' => {
     	datatype => 'FileInfo',
     	base_name => 'FileInfo',
     	description => 'Represents file information. Include of filename, filesize, and file content(base64String).',
     	format => '',
     	read_only => '',
     		},
     'worksheet' => {
     	datatype => 'string',
     	base_name => 'Worksheet',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'range' => {
     	datatype => 'string',
     	base_name => 'Range',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'extract_text_type' => {
     	datatype => 'string',
     	base_name => 'ExtractTextType',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'before_text' => {
     	datatype => 'string',
     	base_name => 'BeforeText',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'after_text' => {
     	datatype => 'string',
     	base_name => 'AfterText',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'before_position' => {
     	datatype => 'int',
     	base_name => 'BeforePosition',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'after_position' => {
     	datatype => 'int',
     	base_name => 'AfterPosition',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'out_position_range' => {
     	datatype => 'string',
     	base_name => 'OutPositionRange',
     	description => '',
     	format => '',
     	read_only => '',
     		},    
});

__PACKAGE__->swagger_types( {
    'name' => 'string',
    'data_source' => 'DataSource',
    'file_info' => 'FileInfo',
    'worksheet' => 'string',
    'range' => 'string',
    'extract_text_type' => 'string',
    'before_text' => 'string',
    'after_text' => 'string',
    'before_position' => 'int',
    'after_position' => 'int',
    'out_position_range' => 'string' 
} );

__PACKAGE__->attribute_map( {
    'name' => 'Name',
    'data_source' => 'DataSource',
    'file_info' => 'FileInfo',
    'worksheet' => 'Worksheet',
    'range' => 'Range',
    'extract_text_type' => 'ExtractTextType',
    'before_text' => 'BeforeText',
    'after_text' => 'AfterText',
    'before_position' => 'BeforePosition',
    'after_position' => 'AfterPosition',
    'out_position_range' => 'OutPositionRange' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;