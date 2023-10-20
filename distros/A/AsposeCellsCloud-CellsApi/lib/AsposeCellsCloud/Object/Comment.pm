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

package AsposeCellsCloud::Object::Comment;

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
                                  class => 'Comment',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'cell_name' => {
     	datatype => 'string',
     	base_name => 'CellName',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'author' => {
     	datatype => 'string',
     	base_name => 'Author',
     	description => 'Gets and sets Name of the original comment author',
     	format => '',
     	read_only => '',
     		},
     'html_note' => {
     	datatype => 'string',
     	base_name => 'HtmlNote',
     	description => 'Gets and sets the html string which contains data and some formats in this comment.',
     	format => '',
     	read_only => '',
     		},
     'note' => {
     	datatype => 'string',
     	base_name => 'Note',
     	description => 'Represents the content of comment.',
     	format => '',
     	read_only => '',
     		},
     'auto_size' => {
     	datatype => 'boolean',
     	base_name => 'AutoSize',
     	description => 'Indicates if size of comment is adjusted automatically according to its content.',
     	format => '',
     	read_only => '',
     		},
     'is_visible' => {
     	datatype => 'boolean',
     	base_name => 'IsVisible',
     	description => 'Represents if the comment is visible or not.',
     	format => '',
     	read_only => '',
     		},
     'width' => {
     	datatype => 'int',
     	base_name => 'Width',
     	description => 'Represents the width of the comment, in unit of pixels.',
     	format => '',
     	read_only => '',
     		},
     'height' => {
     	datatype => 'int',
     	base_name => 'Height',
     	description => 'Represents the Height of the comment, in unit of pixels.',
     	format => '',
     	read_only => '',
     		},
     'text_horizontal_alignment' => {
     	datatype => 'string',
     	base_name => 'TextHorizontalAlignment',
     	description => 'Gets and sets the text horizontal alignment type of the comment.',
     	format => '',
     	read_only => '',
     		},
     'text_orientation_type' => {
     	datatype => 'string',
     	base_name => 'TextOrientationType',
     	description => 'Gets and sets the text orientation type of the comment.',
     	format => '',
     	read_only => '',
     		},
     'text_vertical_alignment' => {
     	datatype => 'string',
     	base_name => 'TextVerticalAlignment',
     	description => 'Gets and sets the text vertical alignment type of the comment.',
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
    'cell_name' => 'string',
    'author' => 'string',
    'html_note' => 'string',
    'note' => 'string',
    'auto_size' => 'boolean',
    'is_visible' => 'boolean',
    'width' => 'int',
    'height' => 'int',
    'text_horizontal_alignment' => 'string',
    'text_orientation_type' => 'string',
    'text_vertical_alignment' => 'string',
    'link' => 'Link' 
} );

__PACKAGE__->attribute_map( {
    'cell_name' => 'CellName',
    'author' => 'Author',
    'html_note' => 'HtmlNote',
    'note' => 'Note',
    'auto_size' => 'AutoSize',
    'is_visible' => 'IsVisible',
    'width' => 'Width',
    'height' => 'Height',
    'text_horizontal_alignment' => 'TextHorizontalAlignment',
    'text_orientation_type' => 'TextOrientationType',
    'text_vertical_alignment' => 'TextVerticalAlignment',
    'link' => 'link' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;