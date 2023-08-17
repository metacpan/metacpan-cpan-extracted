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

package AsposeCellsCloud::Object::IconSet;

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
use AsposeCellsCloud::Object::ConditionalFormattingIcon;
use AsposeCellsCloud::Object::ConditionalFormattingValue; 


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


__PACKAGE__->class_documentation({description => 'Describe the IconSet conditional formatting rule. This conditional formatting    rule applies icons to cells according to their values.',
                                  class => 'IconSet',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'cf_icons' => {
     	datatype => 'ARRAY[ConditionalFormattingIcon]',
     	base_name => 'CfIcons',
     	description => 'Get theAspose.Cells.ConditionalFormattingIcon from the collection',
     	format => '',
     	read_only => '',
     		},
     'cfvos' => {
     	datatype => 'ARRAY[ConditionalFormattingValue]',
     	base_name => 'Cfvos',
     	description => 'Get the CFValueObjects instance.',
     	format => '',
     	read_only => '',
     		},
     'is_custom' => {
     	datatype => 'boolean',
     	base_name => 'IsCustom',
     	description => 'Indicates whether the icon set is custom.  Default value is false.',
     	format => '',
     	read_only => '',
     		},
     'reverse' => {
     	datatype => 'boolean',
     	base_name => 'Reverse',
     	description => 'Get or set the flag indicating whether to reverses the default order of the  icons in this icon set.  Default value is false.            ',
     	format => '',
     	read_only => '',
     		},
     'show_value' => {
     	datatype => 'boolean',
     	base_name => 'ShowValue',
     	description => 'Get or set the flag indicating whether to show the values of the cells on   which this icon set is applied.  Default value is true.            ',
     	format => '',
     	read_only => '',
     		},
     'icon_set_type' => {
     	datatype => 'string',
     	base_name => 'IconSetType',
     	description => 'Get or Set the icon set type to display.  Setting the type will auto check   if the current Cfvos`s count is accord with the new type. If not accord,   old Cfvos will be cleaned and default Cfvos will be added.            ',
     	format => '',
     	read_only => '',
     		},    
});

__PACKAGE__->swagger_types( {
    'cf_icons' => 'ARRAY[ConditionalFormattingIcon]',
    'cfvos' => 'ARRAY[ConditionalFormattingValue]',
    'is_custom' => 'boolean',
    'reverse' => 'boolean',
    'show_value' => 'boolean',
    'icon_set_type' => 'string' 
} );

__PACKAGE__->attribute_map( {
    'cf_icons' => 'CfIcons',
    'cfvos' => 'Cfvos',
    'is_custom' => 'IsCustom',
    'reverse' => 'Reverse',
    'show_value' => 'ShowValue',
    'icon_set_type' => 'IconSetType' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;