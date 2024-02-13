package Data::MARC::Leader::Utils;

use strict;
use warnings;

use Class::Utils qw(set_params);
use English;
use Error::Pure qw(err);
use Readonly;

our $VERSION = 0.06;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Language.
	$self->{'lang'} = 'eng';

	# Process parameters.
	set_params($self, @params);

	$self->{'_lang_class'} = 'Data::MARC::Leader::Utils::'.uc($self->{'lang'});
	eval "require $self->{'_lang_class'};";
	if ($EVAL_ERROR) {
		err "Cannot load texts in language '$self->{'lang'}'.",
			'Error', $EVAL_ERROR,
		;
	}

	return $self;
}

sub desc_bibliographic_level {
	my ($self, $level_code) = @_;

	return $self->_text('BIBLIOGRAPHIC_LEVEL', $level_code);
}

sub desc_char_coding_scheme {
	my ($self, $char_coding_scheme) = @_;

	return $self->_text('CHAR_CODING_SCHEME', $char_coding_scheme);
}

sub desc_descriptive_cataloging_form {
	my ($self, $descriptive_cataloging_form) = @_;

	return $self->_text('DESCRIPTIVE_CATALOGING_FORM', $descriptive_cataloging_form);
}

sub desc_encoding_level {
	my ($self, $encoding_level) = @_;

	return $self->_text('ENCODING_LEVEL', $encoding_level);
}

sub desc_impl_def_portion_len {
	my ($self, $impl_def_portion_len) = @_;

	return $self->_text('IMPL_DEF_PORTION_LEN', $impl_def_portion_len);
}

sub desc_indicator_count {
	my ($self, $indicator_count) = @_;

	return $self->_text('INDICATOR_COUNT', $indicator_count);
}

sub desc_length_of_field_portion_len {
	my ($self, $length_of_field_portion_len) = @_;

	return $self->_text('LENGTH_OF_FIELD_PORTION_LEN', $length_of_field_portion_len);
}

sub desc_multipart_resource_record_level {
	my ($self, $multipart_resource_record_level) = @_;

	return $self->_text('MULTIPART_RESOURCE_RECORD_LEVEL', $multipart_resource_record_level);
}

sub desc_starting_char_pos_portion_len {
	my ($self, $starting_char_pos_portion_len) = @_;

	return $self->_text('STARTING_CHAR_POS_PORTION_LEN', $starting_char_pos_portion_len);
}

sub desc_status {
	my ($self, $status_code) = @_;

	return $self->_text('STATUS', $status_code);
}

sub desc_subfield_code_count {
	my ($self, $subfield_code_count) = @_;

	return $self->_text('SUBFIELD_CODE_COUNT', $subfield_code_count);
}

sub desc_type {
	my ($self, $type_code) = @_;

	return $self->_text('TYPE', $type_code);
}

sub desc_type_of_control {
	my ($self, $type_of_control) = @_;

	return $self->_text('TYPE_OF_CONTROL', $type_of_control);
}

sub desc_undefined {
	my ($self, $undefined) = @_;

	return $self->_text('UNDEFINED', $undefined);
};

sub _text {
	my ($self, $hash, $key) = @_;

	my $text = eval '$'.$self->{'_lang_class'}.'::'.$hash.'{$key};';
	if ($EVAL_ERROR) {
		err "Cannot get text.",
			'Error', $EVAL_ERROR,
		;
	}

	return $text;
}

1;

__END__
