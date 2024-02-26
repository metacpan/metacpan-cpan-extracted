=begin comment

Copyright (c) 2024 Aspose.Cells Cloud
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

package AsposeCellsCloud::Object::Protection;

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


__PACKAGE__->class_documentation({description => 'Represents the various types of protection options available for a worksheet.            ',
                                  class => 'Protection',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'allow_deleting_column' => {
     	datatype => 'boolean',
     	base_name => 'AllowDeletingColumn',
     	description => 'Represents if the deletion of columns is allowed on a protected worksheet. ',
     	format => '',
     	read_only => '',
     		},
     'allow_deleting_row' => {
     	datatype => 'boolean',
     	base_name => 'AllowDeletingRow',
     	description => 'Represents if the deletion of rows is allowed on a protected worksheet. ',
     	format => '',
     	read_only => '',
     		},
     'allow_filtering' => {
     	datatype => 'boolean',
     	base_name => 'AllowFiltering',
     	description => 'Represents if the user is allowed to make use of an AutoFilter that was created before the sheet was protected. ',
     	format => '',
     	read_only => '',
     		},
     'allow_formatting_cell' => {
     	datatype => 'boolean',
     	base_name => 'AllowFormattingCell',
     	description => 'Represents if the formatting of cells is allowed on a protected worksheet. ',
     	format => '',
     	read_only => '',
     		},
     'allow_formatting_column' => {
     	datatype => 'boolean',
     	base_name => 'AllowFormattingColumn',
     	description => 'Represents if the formatting of columns is allowed on a protected worksheet ',
     	format => '',
     	read_only => '',
     		},
     'allow_formatting_row' => {
     	datatype => 'boolean',
     	base_name => 'AllowFormattingRow',
     	description => 'Represents if the formatting of rows is allowed on a protected worksheet ',
     	format => '',
     	read_only => '',
     		},
     'allow_inserting_column' => {
     	datatype => 'boolean',
     	base_name => 'AllowInsertingColumn',
     	description => 'Represents if the insertion of columns is allowed on a protected worksheet ',
     	format => '',
     	read_only => '',
     		},
     'allow_inserting_hyperlink' => {
     	datatype => 'boolean',
     	base_name => 'AllowInsertingHyperlink',
     	description => 'Represents if the insertion of hyperlinks is allowed on a protected worksheet ',
     	format => '',
     	read_only => '',
     		},
     'allow_inserting_row' => {
     	datatype => 'boolean',
     	base_name => 'AllowInsertingRow',
     	description => 'Represents if the insertion of rows is allowed on a protected worksheet ',
     	format => '',
     	read_only => '',
     		},
     'allow_sorting' => {
     	datatype => 'boolean',
     	base_name => 'AllowSorting',
     	description => 'Represents if the sorting option is allowed on a protected worksheet. ',
     	format => '',
     	read_only => '',
     		},
     'allow_using_pivot_table' => {
     	datatype => 'boolean',
     	base_name => 'AllowUsingPivotTable',
     	description => 'Represents if the user is allowed to manipulate pivot tables on a protected worksheet. ',
     	format => '',
     	read_only => '',
     		},
     'allow_editing_content' => {
     	datatype => 'boolean',
     	base_name => 'AllowEditingContent',
     	description => 'Represents if the user is allowed to edit contents of locked cells on a protected worksheet. ',
     	format => '',
     	read_only => '',
     		},
     'allow_editing_object' => {
     	datatype => 'boolean',
     	base_name => 'AllowEditingObject',
     	description => 'Represents if the user is allowed to manipulate drawing objects on a protected worksheet. ',
     	format => '',
     	read_only => '',
     		},
     'allow_editing_scenario' => {
     	datatype => 'boolean',
     	base_name => 'AllowEditingScenario',
     	description => 'Represents if the user is allowed to edit scenarios on a protected worksheet. ',
     	format => '',
     	read_only => '',
     		},
     'password' => {
     	datatype => 'string',
     	base_name => 'Password',
     	description => 'Represents the password to protect the worksheet. ',
     	format => '',
     	read_only => '',
     		},
     'allow_selecting_locked_cell' => {
     	datatype => 'boolean',
     	base_name => 'AllowSelectingLockedCell',
     	description => 'Represents if the user is allowed to select locked cells on a protected worksheet. ',
     	format => '',
     	read_only => '',
     		},
     'allow_selecting_unlocked_cell' => {
     	datatype => 'boolean',
     	base_name => 'AllowSelectingUnlockedCell',
     	description => 'Represents if the user is allowed to select unlocked cells on a protected worksheet. ',
     	format => '',
     	read_only => '',
     		},    
});

__PACKAGE__->swagger_types( {
    'allow_deleting_column' => 'boolean',
    'allow_deleting_row' => 'boolean',
    'allow_filtering' => 'boolean',
    'allow_formatting_cell' => 'boolean',
    'allow_formatting_column' => 'boolean',
    'allow_formatting_row' => 'boolean',
    'allow_inserting_column' => 'boolean',
    'allow_inserting_hyperlink' => 'boolean',
    'allow_inserting_row' => 'boolean',
    'allow_sorting' => 'boolean',
    'allow_using_pivot_table' => 'boolean',
    'allow_editing_content' => 'boolean',
    'allow_editing_object' => 'boolean',
    'allow_editing_scenario' => 'boolean',
    'password' => 'string',
    'allow_selecting_locked_cell' => 'boolean',
    'allow_selecting_unlocked_cell' => 'boolean' 
} );

__PACKAGE__->attribute_map( {
    'allow_deleting_column' => 'AllowDeletingColumn',
    'allow_deleting_row' => 'AllowDeletingRow',
    'allow_filtering' => 'AllowFiltering',
    'allow_formatting_cell' => 'AllowFormattingCell',
    'allow_formatting_column' => 'AllowFormattingColumn',
    'allow_formatting_row' => 'AllowFormattingRow',
    'allow_inserting_column' => 'AllowInsertingColumn',
    'allow_inserting_hyperlink' => 'AllowInsertingHyperlink',
    'allow_inserting_row' => 'AllowInsertingRow',
    'allow_sorting' => 'AllowSorting',
    'allow_using_pivot_table' => 'AllowUsingPivotTable',
    'allow_editing_content' => 'AllowEditingContent',
    'allow_editing_object' => 'AllowEditingObject',
    'allow_editing_scenario' => 'AllowEditingScenario',
    'password' => 'Password',
    'allow_selecting_locked_cell' => 'AllowSelectingLockedCell',
    'allow_selecting_unlocked_cell' => 'AllowSelectingUnlockedCell' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;