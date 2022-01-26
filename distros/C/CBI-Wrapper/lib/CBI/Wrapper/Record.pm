##############################################################################
#       
#    Copyright (C) 2012 Agile Business Group sagl (<http://www.agilebg.com>)
#    Copyright (C) 2012 Domsense srl (<http://www.domsense.com>)
#    Copyright (C) 2012 Associazione OpenERP Italia
#    (<http://www.openerp-italia.org>).
#    Copyright (C) 2022 Res Binaria Di Paolo Capaldo (<https://www.resbinaria.com/>)
#    All Rights Reserved
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published
#    by the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
##############################################################################

package CBI::Wrapper::Record;

use warnings;
use strict;

# ABSTRACT: Row in a CBI file.


use CBI::Wrapper::Field;
use CBI::Wrapper::RecordMapping;
use Scalar::Util;
use Carp;

sub new {
	my $class = shift;
	my $self  = {
		_raw_record => shift,    
		_flow_type  => shift,    # see RecordMapping.pm.
		_fields     => [],      
		_code       => '',       # Record code (see RecordMapping.pm).
	};

    bless $self, $class;

	# Check row length.
	if (length($self->get_raw_record()) == 2 or length($self->get_raw_record()) == 120) {
		$self->set_code($self->get_raw_record());
	} else {
		croak('[TypeError] String (' . $self->get_raw_record() . ') must contain 2 or 120 chars');
	}

	
	$self->set_code($self->get_raw_record()) if length($self->get_code()) == 2;

	
	$self->set_code(substr($self->get_raw_record(), 1, 2)) if length($self->get_code()) == 120;

	my $flow_type = defined $self->get_flow_type() ? $self->get_flow_type() : $CBI::Wrapper::RecordMapping::FLOW_TYPE;

	$self->set_flow_type($CBI::Wrapper::RecordMapping::RECORD_MAPPING->{$flow_type});

    $flow_type = $self->get_flow_type();
	unless (exists $flow_type->{$self->get_code()}) {
		croak('[IndexError] Unknown record type ' . $self->get_code());
	}


	# Fields creation.
	for my $field_args (@{$flow_type->{$self->get_code()}}) {

		my $new_field = new CBI::Wrapper::Field($field_args);

		if ($new_field->get_type() eq 'tipo_record') {
			$new_field->set_content($self->get_code());
		}

		$self->append_field($new_field);
	}

	$self->insert_fields_content($self->get_raw_record()) if length($self->get_raw_record()) == 120;

	return $self;
}

sub set_raw_record {
    my ($self, $raw_record) = @_;

    $self->{_raw_record} = $raw_record;
}

sub get_raw_record {
    my ($self) = @_;

    return $self->{_raw_record};
}

sub set_flow_type {
    my ($self, $flow_type) = @_;

    $self->{_flow_type} = $flow_type;
}

sub get_flow_type {
    my ($self) = @_;

    return $self->{_flow_type};
}

sub set_code {
    my ($self, $code) = @_;

    $self->{_code} = $code;
}

sub get_code {
    my ($self) = @_;

    return $self->{_code};
}

sub set_fields {
    my ($self, $fields) = @_;

    $self->{_fields} = $fields;
}

sub get_fields {
    my ($self) = @_;

    return $self->{_fields};
}

# Set a string in content.
# The key param can be:
# 1. arrayref with start and end column (es. [1,3]).
# 2. name of the field
sub set_field_content {
	my ($self, $key, $content) = @_;

	if (ref $key eq 'ARRAY') {
		for my $field (@{$self->get_fields()}) {
			if ($field->get_from_position() == $key->[0] and $field->get_to_position() == $key->[1]) {
				$field->set_content($content);
				return;
			}
		}
		croak('[IndexError] Impossible to find field with position ' . $key->[0] . ', ' . $key->[1]);
	} else {
		for my $field (@{$self->get_fields()}) {
			if ($field->get_name() eq $key) {
                #say STDERR $field->get_name() . ' - ' . $content;
				$field->set_content($content);
				return;
			}
		}
	}

	#use Data::Dumper;
	#say STDOUT 'SELF'. Dumper($self->{_fields});
	croak('[IndexError] Impossible to find field with key ' . $key);
}

# Get a string from a field in the current record.
# The key param can be:
# 1. arrayref with start and end column (es. [1,3]).
# 2. name of the field
sub get_field_content {
	my ($self, $key) = @_;
	if (ref $key eq 'ARRAY') {
		return substr($self->to_string(), $key->[0], $key->[1]);
	} else {
		for my $field (@{$self->get_fields()}) {
			if ($field->get_name() eq $key) {
				my $ret = $field->get_content();
				$ret =~ s/^\s+|\s+$//g;
				return $ret;
			}
		}
		croak('[IndexError] Impossible to find field with key ' . $key);
	}
}


sub append_field {
	my ($self, $field) = @_;

	# Type check
	unless (Scalar::Util::blessed($field) eq 'CBI::Wrapper::Field') {
		croak('[TypeError] You can only append Field objects');
	}

	for my $f (@{$self->get_fields()}) {
		if ($f->get_name() eq $field->get_name()) {
			croak('[IndexError] Field name ' . $field->get_name() . ' already present');
		}
	}

    my $fields = $self->get_fields();
    push(@$fields, $field);
    $self->set_fields($fields);
}

sub insert_fields_content {
	my ($self, $raw_record) = @_;

	for my $field (@{$self->get_fields()}) {
		my $from_position = $field->get_from_position() - 1;
		my $to_position   = $field->get_to_position();
		$to_position -= $from_position;
		$field->set_content(substr($raw_record, $from_position, $to_position));
	}
}

# Convert to string (row in CBI file).
sub to_string {
	my ($self) = @_;
	my $c = '';
	for my $field (@{$self->get_fields()}) {
		$c .= $field->get_content();
	}
	return $c;
}

1;

