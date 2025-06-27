package Data::MARC::Field008::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use List::Util 1.33 qw(none);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_book_biography check_book_festschrift
	check_book_illustration check_book_literary_form check_book_nature_of_content
	check_cataloging_source check_computer_file_item_form check_computer_file_type
	check_conference_publication check_continuing_resource_entry_convention
	check_continuing_resource_form_of_original_item
	check_continuing_resource_frequency check_continuing_resource_nature_of_content
	check_continuing_resource_nature_of_entire_work
	check_continuing_resource_original_alphabet_or_script
	check_continuing_resource_regularity
	check_continuing_resource_type check_date check_government_publication
	check_index check_item_form check_map_cartographic_material_type
	check_map_projection check_map_relief check_map_special_format
	check_modified_record check_music_accompanying_matter
	check_music_composition_form check_music_format check_music_literary_text
	check_music_parts check_music_transposition_and_arrangement
	check_visual_material_running_time check_visual_material_technique
	check_visual_material_type check_target_audience check_type_of_date);
Readonly::Array our @BOOK_BIOGRAPHIES => (' ', 'a', 'b', 'c', 'd', '|');
Readonly::Array our @BOOK_FESTSCHRIFTS => qw(0 1 |);
Readonly::Array our @BOOK_LITERARY_FORMS => qw(0 1 d e f h i j m p s u |);
Readonly::Array our @CATALOGING_SOURCES => (' ', 'c', 'd', 'u', '|');
Readonly::Array our @COMPUTER_FILE_ITEM_FORMS => (' ', 'o', 'q', '|');
Readonly::Array our @COMPUTER_FILE_TYPE => qw(a b c d e f g h i j m u z |);
Readonly::Array our @CONFERENCE_PUBLICATIONS => qw(0 1 |);
Readonly::Array our @CONTINUING_RESOURCES_ENTRY_CONVENTIONS => qw(0 1 2 |);
Readonly::Array our @CONTINUING_RESOURCES_FORMS_OF_ORIGINAL_ITEM => (' ', 'a',
	'b', 'c', 'd', 'e', 'f', 'o', 'q', 's', '|');
Readonly::Array our @CONTINUING_RESOURCES_FREQUENCIES => (' ', 'a', 'b', 'c',
	'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'm', 'q', 's', 't', 'u', 'w',
	'z', '|');
Readonly::Array our @CONTINUING_RESOURCES_NATURE_OF_ENTIRE_WORKS => (' ', 'a',
	'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'k', 'l', 'm', 'n', 'o', 'p',
	'q', 'r', 's', 't', 'u', 'v', 'w', 'y', 'z', '5', '6', '|');
Readonly::Array our @CONTINUING_RESOURCES_ORIGINAL_ALPHABETS_OR_SCRIPTS => (' ',
	'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'u', 'z',
	'|');
Readonly::Array our @CONTINUING_RESOURCES_REGULARITIES => qw(n r u x |);
Readonly::Array our @CONTINUING_RESOURCES_TYPES => (' ', 'd', 'g', 'h', 'j',
	'l', 'm', 'n', 'p', 'r', 's', 't', 'w', '|');
Readonly::Array our @GOVERNMENT_PUBLICATIONS => (' ', 'a', 'c', 'f', 'i',
	'l', 'm', 'o', 's', 'u', 'z', '|');
Readonly::Array our @INDEXES => qw(0 1 |);
Readonly::Array our @ITEM_FORMS => (' ', 'a', 'b', 'c', 'd', 'f', 'o', 'q',
	'r', 's', '|');
Readonly::Array our @MAP_CARTOGRAPHIC_MATERIAL_TYPES => qw(a b c d e f g u z |);
Readonly::Array our @MAP_PROJECTIONS => ('  ', 'aa', 'ab', 'ac', 'ad', 'ae',
	'af', 'ag', 'am', 'an', 'ap', 'au', 'az', 'ba', 'bb', 'bc', 'bd', 'be',
	'bf', 'bg', 'bh', 'bi', 'bj', 'bk', 'bl', 'bo', 'br', 'bs', 'bu', 'bz',
	'ca', 'cb', 'cc', 'ce', 'cp', 'cu', 'cz', 'da', 'db', 'dc', 'dd', 'de',
	'df', 'dg', 'dh', 'dl', 'zz', '||');
Readonly::Array our @MODIFIED_RECORDS => (' ', 'd', 'o', 'r', 's', 'x', '|');
Readonly::Array our @MUSIC_COMPOSITION_FORMS => qw(an bd bg bl bt ca cb cc cg ch
	cl cn co cp cr cs ct cy cz df dv fg fl fm ft gm hy jz mc md mi mo mp mr
	ms mu mz nc nn op or ov pg pm po pp pr ps pt pv rc rd rg ri rp rq sd sg
	sn sp st su sy tc tl ts uu vi vr wz za zz ||);
Readonly::Array our @MUSIC_FORMATS => qw(a b c d e g h i j k l m n p u z |);
Readonly::Array our @MUSIC_PARTS => (' ', 'd', 'e', 'f', 'n', 'u', '|');
Readonly::Array our @MUSIC_TRANSPOSITIONS_AND_ARRANGEMENTS => (' ', 'a', 'b',
	'c', 'n', 'u', '|');
Readonly::Array our @VISUAL_MATERIAL_TECHNIQUES => qw(a c l n u z |);
Readonly::Array our @VISUAL_MATERIAL_TYPES => qw(a b c d f g i k l m n o p q r s
	t v w z |);
Readonly::Array our @TARGET_AUDIENCES => (' ', 'a', 'b', 'c', 'd', 'e', 'f',
	'g', 'j', '|');
Readonly::Array our @TYPE_OF_DATES => qw(b c d e i k m n p q r s t u |);

our $VERSION = 0.03;

sub check_book_biography {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@BOOK_BIOGRAPHIES);

	return;
}

sub check_book_festschrift {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@BOOK_FESTSCHRIFTS);

	return;
}

sub check_book_illustration {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 4);
	if ($self->{$key} !~ m/^[\ abcdefghijklmop\|]{4}$/ms) {
		err "Parameter '$key' contains bad book illustration character.",
			'Value', $self->{$key},
		;
	}
	if ($self->{$key} ne '||||' && $self->{$key} =~ m/\|/ms) {
		err "Parameter '$key' has value with pipe character.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_book_literary_form {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@BOOK_LITERARY_FORMS);

	return;
}

sub check_book_nature_of_content {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 4);
	if ($self->{$key} !~ m/^[\ abcdefgijklmnopqrstuvwyz256\|]{4}$/ms) {
		err "Parameter '$key' has bad value.",
			'Value', $self->{$key},
		;
	}
	if ($self->{$key} ne '||||' && $self->{$key} =~ m/\|/ms) {
		err "Parameter '$key' has value with pipe character.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_cataloging_source {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@CATALOGING_SOURCES);

	return;
}

sub check_computer_file_item_form {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@COMPUTER_FILE_ITEM_FORMS);

	return;
}

sub check_computer_file_type {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@COMPUTER_FILE_TYPE);

	return;
}

sub check_conference_publication {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@CONFERENCE_PUBLICATIONS);

	return;
}

sub check_continuing_resource_entry_convention {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@CONTINUING_RESOURCES_ENTRY_CONVENTIONS);

	return;
}

sub check_continuing_resource_form_of_original_item {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@CONTINUING_RESOURCES_FORMS_OF_ORIGINAL_ITEM);

	return;
}

sub check_continuing_resource_frequency {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@CONTINUING_RESOURCES_FREQUENCIES);

	return;
}

sub check_continuing_resource_nature_of_content {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 3);
	if ($self->{$key} !~ m/^[\ abcdefghiklmnopqrstuvwyz56\|]{3}$/ms) {
		err "Parameter '$key' has bad value.",
			'Value', $self->{$key},
		;
	}
	if ($self->{$key} ne '|||' && $self->{$key} =~ m/\|/ms) {
		err "Parameter '$key' has value with pipe character.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_continuing_resource_nature_of_entire_work {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@CONTINUING_RESOURCES_NATURE_OF_ENTIRE_WORKS);

	return;
}

sub check_continuing_resource_original_alphabet_or_script {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@CONTINUING_RESOURCES_ORIGINAL_ALPHABETS_OR_SCRIPTS);

	return;
}

sub check_continuing_resource_regularity {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@CONTINUING_RESOURCES_REGULARITIES);

	return;
}

sub check_continuing_resource_type {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@CONTINUING_RESOURCES_TYPES);

	return;
}

sub check_date {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 4);
	if ($self->{$key} !~ m/^[\ \|\du]{4}$/ms) {
		err "Parameter '$key' has bad value.",
			'Value', $self->{$key},
		;
	}
	if ($self->{$key} ne '    ' && $self->{$key} =~ m/\ /ms) {
		err "Parameter '$key' has value with space character.",
			'Value', $self->{$key},
		;
	}
	if ($self->{$key} ne '||||' && $self->{$key} =~ m/\|/ms) {
		err "Parameter '$key' has value with pipe character.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_government_publication {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@GOVERNMENT_PUBLICATIONS);

	return;
}

sub check_index {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@INDEXES);

	return;
}

sub check_item_form {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@ITEM_FORMS);

	return;
}

sub check_map_cartographic_material_type {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@MAP_CARTOGRAPHIC_MATERIAL_TYPES);

	return;
}

sub check_map_projection {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 2);
	_check_bad_value($self, $key, \@MAP_PROJECTIONS);

	return;
}

sub check_map_relief {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 4);
	if ($self->{$key} !~ m/^[\ abcdefgijkmz\|]{4}$/ms) {
		err "Parameter '$key' contains bad relief character.",
			'Value', $self->{$key},
		;
	}
	if ($self->{$key} ne '||||' && $self->{$key} =~ m/\|/ms) {
		err "Parameter '$key' has value with pipe character.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_map_special_format {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 2);
	if ($self->{$key} !~ m/^[\ ejklnoprz\|]{2}$/ms) {
		err "Parameter '$key' contains bad special format characteristics character.",
			'Value', $self->{$key},
		;
	}
	if ($self->{$key} ne '||' && $self->{$key} =~ m/\|/ms) {
		err "Parameter '$key' has value with pipe character.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_modified_record {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@MODIFIED_RECORDS);

	return;
}

sub check_music_accompanying_matter {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 6);
	if ($self->{$key} !~ m/^[\ abcdefghikrsz\|]{6}$/ms) {
		err "Parameter '$key' contains bad music accompanying matter character.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_music_composition_form {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 2);
	_check_bad_value($self, $key, \@MUSIC_COMPOSITION_FORMS);

	return;
}

sub check_music_format {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@MUSIC_FORMATS);

	return;
}

sub check_music_literary_text {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 2);
	if ($self->{$key} !~ m/^[\ abcdefghijklmnoprstz\|]{2}$/ms) {
		err "Parameter '$key' contains bad music literary text character.",
			'Value', $self->{$key},
		;
	}
	if ($self->{$key} ne '||' && $self->{$key} =~ m/\|/ms) {
		err "Parameter '$key' has value with pipe character.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_music_parts {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@MUSIC_PARTS);

	return;
}

sub check_music_transposition_and_arrangement {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@MUSIC_TRANSPOSITIONS_AND_ARRANGEMENTS);

	return;
}

sub check_visual_material_running_time {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 3);
	if ($self->{$key} !~ m/^[\d\-n\|]{3}$/ms) {
		err "Parameter '$key' contains bad visual material running time.",
			'Value', $self->{$key},
		;
	}
	if ($self->{$key} ne '---' && $self->{$key} =~ m/\-/ms) {
		err "Parameter '$key' has value with dash character.",
			'Value', $self->{$key},
		;
	}
	if ($self->{$key} ne '|||' && $self->{$key} =~ m/\|/ms) {
		err "Parameter '$key' has value with pipe character.",
			'Value', $self->{$key},
		;
	}
	if ($self->{$key} ne 'nnn' && $self->{$key} =~ m/n/ms) {
		err "Parameter '$key' has value with 'n' character.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_visual_material_technique {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@VISUAL_MATERIAL_TECHNIQUES);

	return;
}

sub check_visual_material_type {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@VISUAL_MATERIAL_TYPES);

	return;
}

sub check_target_audience {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@TARGET_AUDIENCES);

	return;
}

sub check_type_of_date {
	my ($self, $key) = @_;

	_check_base($self, $key);
	_check_length($self, $key, 1);
	_check_bad_value($self, $key, \@TYPE_OF_DATES);

	return;
}

sub _check_bad_value {
	my ($self, $key, $keys_ar) = @_;

	if (none { $self->{$key} eq $_ } @{$keys_ar}) {
		err "Parameter '$key' has bad value.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub _check_base {
	my ($self, $key) = @_;

	if (! exists $self->{$key} || ! defined $self->{$key}) {
		err "Parameter '$key' is required.";
	}
	if (ref $self->{$key} ne '') {
		err "Parameter '$key' must be a scalar value.",
			'Reference', (ref $self->{$key}),
		;
	}

	return;
}

sub _check_length {
	my ($self, $key, $exp_length) = @_;

	if (length $self->{$key} != $exp_length) {
		err "Parameter '$key' length is bad.",
			'Length', (length $self->{$key}),
			'Value', $self->{$key},
			'Expected length', $exp_length,
		;
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::MARC::Field008::Utils - Utilities to check MARC field008 values.

=head1 SYNOPSIS

 use Data::MARC::Field008::Utils qw(check_book_biography check_book_festschrift
         check_book_illustration check_book_literary_form check_book_nature_of_content
         check_cataloging_source check_computer_file_item_form check_computer_file_type
         check_conference_publication check_continuing_resource_entry_convention
         check_continuing_resource_form_of_original_item
         check_continuing_resource_frequency check_continuing_resource_nature_of_content
         check_continuing_resource_nature_of_entire_work
         check_continuing_resource_original_alphabet_or_script
         check_continuing_resource_regularity
         check_continuing_resource_type check_date check_government_publication
         check_index check_item_form check_map_cartographic_material_type
         check_map_projection check_map_relief check_map_special_format
         check_modified_record check_music_accompanying_matter
         check_music_composition_form check_music_format check_music_literary_text
         check_music_parts check_music_transposition_and_arrangement
         check_visual_material_running_time check_visual_material_technique
         check_visual_material_type check_target_audience check_type_of_date);

 check_book_biography($self, $key);
 check_book_festschrift($self, $key);
 check_book_illustration($self, $key);
 check_book_literary_form($self, $key);
 check_book_nature_of_content($self, $key);
 check_cataloging_source($self, $key);
 check_computer_file_item_form($self, $key);
 check_computer_file_type($self, $key);
 check_conference_publication($self, $key);
 check_continuing_resource_entry_convention($self, $key);
 check_continuing_resource_form_of_original_item($self, $key);
 check_continuing_resource_frequency($self, $key);
 check_continuing_resource_nature_of_content($self, $key);
 check_continuing_resource_nature_of_entire_work($self, $key);
 check_continuing_resource_original_alphabet_or_script($self, $key);
 check_continuing_resource_regularity($self, $key);
 check_continuing_resource_type($self, $key);
 check_date($self, $key);
 check_government_publication($self, $key);
 check_index($self, $key);
 check_item_form($self, $key);
 check_map_cartographic_material_type($self, $key);
 check_map_projection($self, $key);
 check_map_relief($self, $key);
 check_map_special_format($self, $key);
 check_modified_record($self, $key);
 check_music_accompanying_matter($self, $key);
 check_music_composition_form($self, $key);
 check_music_format($self, $key);
 check_music_literary_text($self, $key);
 check_music_parts($self, $key);
 check_music_transposition_and_arrangement($self, $key);
 check_visual_material_running_time($self, $key);
 check_visual_material_technique($self, $key);
 check_visual_material_type($self, $key);
 check_target_audience($self, $key);
 check_type_of_date($self, $key);

=head1 DESCRIPTION

The Perl module with common utilities for check with L<Data::MARC::Field008> values.

=head1 SUBROUTINES

=head2 C<check_book_biography>

 check_book_biography($self, $key);

Check parameter defined by C<$key> which is book biography.

Put error if check isn't ok.

Returns undef.

=head2 C<check_book_festschrift>

 check_book_festschrift($self, $key);

Check parameter defined by C<$key> which is book festschrift.

Put error if check isn't ok.

Returns undef.

=head2 C<check_book_illustration>

 check_book_illustration($self, $key);

Check parameter defined by C<$key> which is book illustration.

Put error if check isn't ok.

Returns undef.

=head2 C<check_book_literary_form>

 check_book_literary_form($self, $key);

Check parameter defined by C<$key> which is book literary form.

Put error if check isn't ok.

Returns undef.

=head2 C<check_book_nature_of_content>

 check_book_nature_of_content($self, $key);

Check parameter defined by C<$key> which is book nature of content.

Put error if check isn't ok.

Returns undef.

=head2 C<check_cataloging_source>

 check_cataloging_source($self, $key);

Check parameter defined by C<$key> which is cataloging source.

Put error if check isn't ok.

Returns undef.

=head2 C<check_computer_file_item_form>

 check_computer_file_item_form($self, $key);

Check parameter defined by C<$key> which is computer file form of item.

Put error if check isn't ok.

Returns undef.

=head2 C<check_computer_file_type>

 check_computer_file_type($self, $key);

Check parameter defined by C<$key> which is computer file file type.

Put error if check isn't ok.

Returns undef.

=head2 C<check_conference_publication>

 check_conference_publication($self, $key);

Check parameter defined by C<$key> which is conference publication.

Put error if check isn't ok.

Returns undef.

=head2 C<check_continuing_resource_entry_convention>

 check_continuing_resource_entry_convention($self, $key);

Check parameter defined by C<$key> which is continuing resource entry
convention.

Put error if check isn't ok.

Returns undef.

=head2 C<check_continuing_resource_form_of_original_item>

 check_continuing_resource_form_of_original_item($self, $key);

Check parameter defined by C<$key> which is continuing resource form of original
item.

Put error if check isn't ok.

Returns undef.

=head2 C<check_continuing_resource_frequency>

 check_continuing_resource_frequency($self, $key);

Check parameter defined by C<$key> which is continuing resource frequency.

Put error if check isn't ok.

Returns undef.

=head2 C<check_continuing_resource_nature_of_content>

 check_continuing_resource_nature_of_content($self, $key);

Check parameter defined by C<$key> which is continuing resource nature of
content.

Put error if check isn't ok.

Returns undef.

=head2 C<check_continuing_resource_nature_of_entire_work>

 check_continuing_resource_nature_of_entire_work($self, $key);

Check parameter defined by C<$key> which is continuing resource nature of
entire work.

Put error if check isn't ok.

Returns undef.

=head2 C<check_continuing_resource_original_alphabet_or_script>

 check_continuing_resource_original_alphabet_or_script($self, $key);

Check parameter defined by C<$key> which is continuing resource original
alphabet or script of title.

Put error if check isn't ok.

Returns undef.

=head2 C<check_continuing_resource_regularity>

 check_continuing_resource_regularity($self, $key);

Check parameter defined by C<$key> which is continuing resource regularity.

Put error if check isn't ok.

Returns undef.

=head2 C<check_continuing_resource_type>

 check_continuing_resource_type($self, $key);

Check parameter defined by C<$key> which is continuing resource type.

Put error if check isn't ok.

Returns undef.

=head2 C<check_date>

 check_date($self, $key);

Check parameter defined by C<$key> which is field 008 date.

Put error if check isn't ok.

Returns undef.

=head2 C<check_government_publication>

 check_government_publication($self, $key);

Check parameter defined by C<$key> which is government publication.

Put error if check isn't ok.

Returns undef.

=head2 C<check_index>

 check_index($self, $key);

Check parameter defined by C<$key> which is index.

Put error if check isn't ok.

Returns undef.

=head2 C<check_item_form>

 check_item_form($self, $key);

Check parameter defined by C<$key> which is form of item.

Put error if check isn't ok.

Returns undef.

=head2 C<check_map_cartographic_material_type>

 check_map_cartographic_material_type($self, $key);

Check parameter defined by C<$key> which is map type of cartographic material.

Put error if check isn't ok.

Returns undef.

=head2 C<check_map_projection>

 check_map_projection($self, $key);

Check parameter defined by C<$key> which is map projection.

Put error if check isn't ok.

Returns undef.

=head2 C<check_map_relief>

 check_map_relief($self, $key);

Check parameter defined by C<$key> which is map relief.

Put error if check isn't ok.

Returns undef.

=head2 C<check_map_special_format>

 check_map_special_format($self, $key);

Check parameter defined by C<$key> which is map special format characteristics.

Put error if check isn't ok.

Returns undef.

=head2 C<check_modified_record>

 check_modified_record($self, $key);

Check parameter defined by C<$key> which is modified record.

Put error if check isn't ok.

Returns undef.

=head2 C<check_music_accompanying_matter>

 check_music_accompanying_matter($self, $key);

Check parameter defined by C<$key> which is music accompanying matter.

Put error if check isn't ok.

Returns undef.

=head2 C<check_music_composition_form>

 check_music_composition_form($self, $key);

Check parameter defined by C<$key> which is music form of composition.

Put error if check isn't ok.

Returns undef.

=head2 C<check_music_format>

 check_music_format($self, $key);

Check parameter defined by C<$key> which is music format.

Put error if check isn't ok.

Returns undef.

=head2 C<check_music_literary_text>

 check_music_literary_text($self, $key);

Check parameter defined by C<$key> which is music literary text for sound recordings.

Put error if check isn't ok.

Returns undef.

=head2 C<check_music_parts>

 check_music_parts($self, $key);

Check parameter defined by C<$key> which is music parts.

Put error if check isn't ok.

Returns undef.

=head2 C<check_music_transposition_and_arrangement>

 check_music_transposition_and_arrangement($self, $key);

Check parameter defined by C<$key> which is music transposition and arrangement.

Put error if check isn't ok.

Returns undef.

=head2 C<check_visual_material_running_time>

 check_visual_material_running_time($self, $key);

Check parameter defined by C<$key> which is visual material running time for motion pictures and videorecordings.

Put error if check isn't ok.

Returns undef.

=head2 C<check_visual_material_technique>

 check_visual_material_technique($self, $key);

Check parameter defined by C<$key> which is visual material technique.

Put error if check isn't ok.

Returns undef.

=head2 C<check_visual_material_type>

 check_visual_material_type($self, $key);

Check parameter defined by C<$key> which is visual material type.

Put error if check isn't ok.

Returns undef.

=head2 C<check_target_audience>

 check_target_audience($self, $key);

Check parameter defined by C<$key> which is target audience.

Put error if check isn't ok.

Returns undef.

=head2 C<check_type_of_date>

 check_type_of_date($self, $key);

Check parameter defined by C<$key> which is type of date.

Put error if check isn't ok.

Returns undef.

=head1 ERRORS

 check_book_biography():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_book_festschrift()
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_book_illustration():
         Parameter '%s' contains bad book illustration character.
                 Value: %s
         Parameter '%s' has value with pipe character.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 4
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_book_literary_form()
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_book_nature_of_content():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' has value with pipe character.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 4
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_cataloging_source():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_computer_file_item_form():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_computer_file_type():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_conference_publication():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_continuing_resource_entry_convention():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_continuing_resource_form_of_original_item():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_continuing_resource_frequency():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_continuing_resource_nature_of_content():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' has value with pipe character.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_continuing_resource_nature_of_entire_work():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_continuing_resource_original_alphabet_or_script():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_continuing_resource_regularity():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_continuing_resource_type():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_date():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' has value with pipe character.
                 Value: %s
         Parameter '%s' has value with space character.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_government_publication():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_index():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_item_form():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_map_cartographic_material_type():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_map_projection():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 2
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_map_relief():
         Parameter '%s' contains bad relief character.
                 Value: %s
         Parameter '%s' has value with pipe character.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 4
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_map_special_format():
         Parameter '%s' contains bad special format characteristics character.
                 Value: %s
         Parameter '%s' has value with pipe character.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 2
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_modified_record():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_music_accompanying_matter():
         Parameter '%s' contains bad music accompanying matter character.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' must be a scalar value.
                 Reference: %s
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 6

 check_music_composition_form():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 2
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_music_format():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_music_literary_text():
         Parameter '%s' contains bad music literary text character.
                 Value: %s
         Parameter '%s' has value with pipe character.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' must be a scalar value.
                 Reference: %s
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 2

 check_music_parts():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_music_transposition_and_arrangement():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_visual_material_running_time():
         Parameter '%s' contains bad visual material running time.
                 Value: %s
         Parameter '%s' has value with 'n' character.
                 Value: %s
         Parameter '%s' has value with dash character.
                 Value: %s
         Parameter '%s' has value with pipe character.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: %s
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_visual_material_technique():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_visual_material_type():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_target_audience():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

 check_type_of_date():
         Parameter '%s' has bad value.
                 Value: %s
         Parameter '%s' is required.
         Parameter '%s' length is bad.
                 Length: %s
                 Value: %s
                 Expected length: 1
         Parameter '%s' must be a scalar value.
                 Reference: %s

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<List::Util>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Data::MARC::Field008>

Data object for MARC field 008.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-MARC-Field008>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
