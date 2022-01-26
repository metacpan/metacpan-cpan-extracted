##############################################################################
#    
#    Copyright (C) 2012 Agile Business Group sagl (<http://www.agilebg.com>)
#    Copyright (C) 2012 Domsense srl (<http://www.domsense.com>)
#    Copyright (C) 2012 Associazione OpenERP Italia
#    (<http://www.openerp-italia.org>).
#    Copyright (C) 2022 Res Binaria Di Paolo Capaldo(<https://www.resbinaria.com/>)
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

package CBI::Wrapper::Disposal;

use warnings;
use strict;

# ABSTRACT: CBI Disposal.
# 1 disposal <=> n records.

use CBI::Wrapper::Record;
use CBI::Wrapper::RecordMapping;
# libscalar-list-utils-perl in debian.
use Scalar::Util;
# croak.
use Carp;

sub new {
	my $class = shift;
	my $self = {
		_records => shift, # arrayref (see Record.pm).
	};

	bless $self, $class;

    $self->set_records([]) unless defined $self->get_records(); 

    return $self;
}

# Getters and Setters

sub set_records {
    my ( $self, $records) = @_;

    $self->{_records} = $records;
}

sub get_records {
    my ( $self) = @_;

    return $self->{_records};
}

sub set_record {
	my( $self, $key, $item) = @_;

    # Type check.
	unless (Scalar::Util::blessed($item) eq 'CBI::Wrapper::Record') {
		croak('[TypeError] You can only write Record objects');
	}

	for my $record (@{$self->get_records()}) {
		$record = $item if $record->get_field_content('tipo_record') eq $key;
		croak('[IndexError] Impossible to find field with key ' . $key);
	}
} 

sub get_record {
	my( $self, $key) = @_;
	for my $record (@{$self->get_records()}) {
		return $record if $record->get_field_content('tipo_record') eq $key; 
	}
	croak('[IndexError] Impossible to find record ' . $key);
}

# Add record to disposal.
sub append_record {
	my( $self, $item) = @_;

	# Type check.
	unless (Scalar::Util::blessed($item) eq 'CBI::Wrapper::Record') {
		croak('[TypeError] You can only write Record objects');
	}

    my $records = $self->get_records();
    push(@$records, $item);
    $self->set_records($records);
}

1;
