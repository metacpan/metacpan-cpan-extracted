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

package AsposeCellsCloud::Object::DigitalSignature;

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


__PACKAGE__->class_documentation({description => 'Signature in file.            ',
                                  class => 'DigitalSignature',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'comments' => {
     	datatype => 'string',
     	base_name => 'Comments',
     	description => 'The purpose to signature.',
     	format => '',
     	read_only => '',
     		},
     'sign_time' => {
     	datatype => 'string',
     	base_name => 'SignTime',
     	description => 'The time when the document was signed.',
     	format => '',
     	read_only => '',
     		},
     'id' => {
     	datatype => 'string',
     	base_name => 'Id',
     	description => 'Specifies a GUID which can be cross-referenced with the GUID of the signature line stored in the document content. Default value is Empty (all zeroes) Guid.',
     	format => '',
     	read_only => '',
     		},
     'password' => {
     	datatype => 'string',
     	base_name => 'Password',
     	description => 'Specifies the text of actual signature in the digital signature. Default value is Empty.            ',
     	format => '',
     	read_only => '',
     		},
     'image' => {
     	datatype => 'ARRAY[byte?]',
     	base_name => 'Image',
     	description => 'Specifies an image for the digital signature. Default value is null.',
     	format => '',
     	read_only => '',
     		},
     'provider_id' => {
     	datatype => 'string',
     	base_name => 'ProviderId',
     	description => 'Specifies the class ID of the signature provider. Default value is Empty (all zeroes) Guid.            ',
     	format => '',
     	read_only => '',
     		},
     'is_valid' => {
     	datatype => 'boolean',
     	base_name => 'IsValid',
     	description => 'If this digital signature is valid and the document has not been tampered with, this value will be true.',
     	format => '',
     	read_only => '',
     		},
     'x_ad_es_type' => {
     	datatype => 'string',
     	base_name => 'XAdESType',
     	description => 'XAdES type. Default value is None(XAdES is off).',
     	format => '',
     	read_only => '',
     		},    
});

__PACKAGE__->swagger_types( {
    'comments' => 'string',
    'sign_time' => 'string',
    'id' => 'string',
    'password' => 'string',
    'image' => 'ARRAY[byte?]',
    'provider_id' => 'string',
    'is_valid' => 'boolean',
    'x_ad_es_type' => 'string' 
} );

__PACKAGE__->attribute_map( {
    'comments' => 'Comments',
    'sign_time' => 'SignTime',
    'id' => 'Id',
    'password' => 'Password',
    'image' => 'Image',
    'provider_id' => 'ProviderId',
    'is_valid' => 'IsValid',
    'x_ad_es_type' => 'XAdESType' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;