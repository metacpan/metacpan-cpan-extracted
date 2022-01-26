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

package CBI::Wrapper::Field;

use warnings;
use strict;

#ABSTRACT: Field of a Record.
# There are 120 chars in every Record;
# a Fields is a substring in the Record.
# Es. Testata IB
# IBT123405428040122DEMORIBA                                                                             1$05428  E
# ' '     -> primo campo
# 'IB'    -> secondo campo
# 'T1234' -> terzo campo
# ecc..
# Each field has his own length (see RecordMapping.pm)

sub new {
	my $class = shift;
	my $args  = shift;
	my $self  = {
		_from_position => $args->{from},                                             # Start column.
		_to_position   => $args->{to},                                               # End column.
		_name          => $args->{name},                                             # Field name.
		_type          => defined $args->{type} ? $args->{type} : 'an',              # Data type ('n' numeric, 'an' text (default))
		_truncate     => defined $args->{truncate} ? $args->{truncate} : 'no',      # 'yes' truncable, 'no' otherwise  (default).
		_content       => shift,                                                     # Field content.
	};

	bless $self, $class;

	# Content default value if not defined.
	$self->set_content(' ' x $self->get_length()) unless defined $self->get_content();

	return $self;
}

# Getters and Setters.
sub get_length {
	my ($self) = @_;
	return ($self->get_to_position() - $self->get_from_position()) + 1;
}


sub set_content {
	my ($self, $content) = @_;

	if (length($content) > $self->get_length()) {
		if ($self->get_truncate() eq 'yes') {
            $content = substr($content, 0, $self->get_length());
		} else {
            croak('[BufferError] Specified field value ' . $self->get_name() . ' = ' . $content . ' passes field capacity of ' . $self->get_length());
		}
	}

	if ($self->get_type() eq 'n') {
		my $no_spaces = $content;

		# Trim content.
		$no_spaces =~ s/\ //g;

		if ($no_spaces eq '') {

			# Pad with ''.
			$content = sprintf('%-' . $self->get_length() . 's', $no_spaces);
		} else {

			# Pad with zeros.
			$content = sprintf('%0' . $self->get_length() . 'd', (defined $content and $content ne '') ? $content : 0);
		}
	} else {

		# Pad with ''.
		$content = sprintf('%-' . $self->get_length() . 's', $content);
	}

	$self->{_content} = $content;
}

sub get_content {
	my ($self) = @_;
	return $self->{_content};
}

sub set_name {
    my ($self, $name) = @_;

    $self->{_name} = $name;
}

sub get_name {
	my ($self) = @_;
	return $self->{_name};
}

sub set_type {
	my ($self, $type) = @_;
	$self->{_type} = $type;
}

sub get_type {
	my ($self) = @_;
	return $self->{_type};
}

sub set_truncate {
	my ($self, $truncate) = @_;
	$self->{_truncate} = $truncate;
}

sub get_truncate {
	my ($self) = @_;
	return $self->{_truncate};
}

sub set_from_position {
    my ($self, $from_position) = @_;

    $self->{_from_position} = $from_position;
}

sub get_from_position {
	my ($self) = @_;
	return $self->{_from_position};
}

sub set_to_position {
    my ($self, $to_position) = @_;

    $self->{_to_position} = $to_position;
}

sub get_to_position {
	my ($self) = @_;
	return $self->{_to_position};
}

1;

