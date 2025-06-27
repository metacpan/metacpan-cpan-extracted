package Data::MARC::Field008::Music;

use strict;
use warnings;

use Data::MARC::Field008::Utils qw(check_item_form
	check_music_accompanying_matter check_music_composition_form
	check_music_format check_music_literary_text check_music_parts
	check_music_transposition_and_arrangement check_target_audience);
use Error::Pure qw(err);
use Error::Pure::Utils qw(clean err_get);
use Mo qw(build is);
use Mo::utils 0.22 qw(check_length_fix check_required);

our $STRICT = 1;

our $VERSION = 0.03;

has accompanying_matter => (
	is => 'ro',
);

has form_of_composition => (
	is => 'ro',
);

has form_of_item => (
	is => 'ro',
);

has format_of_music => (
	is => 'ro',
);

has literary_text_for_sound_recordings => (
	is => 'ro',
);

has music_parts => (
	is => 'ro',
);

has raw => (
	is => 'ro',
);

has target_audience => (
	is => 'ro',
);

has transposition_and_arrangement => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'raw'
	check_length_fix($self, 'raw', 17);

	# Check 'accompanying_matter'.
	eval { check_music_accompanying_matter($self, 'accompanying_matter'); };

	# Check 'form_of_composition'.
	eval { check_music_composition_form($self, 'form_of_composition'); };

	# Check 'form_of_item'.
	eval { check_item_form($self, 'form_of_item'); };

	# Check 'format_of_music'.
	eval { check_music_format($self, 'format_of_music'); };

	# Check 'literary_text_for_sound_recordings'.
	eval { check_music_literary_text($self, 'literary_text_for_sound_recordings'); };

	# Check 'music_parts'.
	eval { check_music_parts($self, 'music_parts'); };

	# Check 'target_audience'.
	eval { check_target_audience($self, 'target_audience'); };

	# Check 'transposition_and_arrangement'.
	eval { check_music_transposition_and_arrangement($self, 'transposition_and_arrangement'); };

	if ($STRICT) {
		my @errors = err_get();
		if (@errors) {
			err "Couldn't create data object of music.",
				defined $self->raw ? ('Raw string', $self->raw) : (),
			;
		}
	} else {
		clean();
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::MARC::Field008::Music - Data object for MARC field 008 music material.

=head1 SYNOPSIS

 use Data::MARC::Field008::Music;

 my $obj = Data::MARC::Field008::Music->new(%params);
 my $accompanying_matter = $obj->accompanying_matter;
 my $form_of_composition = $obj->form_of_composition;
 my $form_of_item = $obj->form_of_item;
 my $format_of_music = $obj->format_of_music;
 my $literary_text_for_sound_recordings = $obj->literary_text_for_sound_recordings;
 my $music_parts = $obj->music_parts;
 my $raw = $obj->raw;
 my $target_audience = $obj->target_audience;
 my $transposition_and_arrangement = $obj->transposition_and_arrangement;

=head1 METHODS

=head2 C<new>

 my $obj = Data::MARC::Field008::Music->new(%params);

Constructor.

=over 8

=item * C<accompanying_matter>

Accompanying matter. The length of the string is 6 characters.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'k',
'r', 's', 'z' or '|'.

It's required.

Default value is undef.

=item * C<form_of_composition>

Form of composition. The length of the string is 2 characters.
Possible strings are 'an', 'bd', 'bg', 'bl', bt', 'ca', 'cb', 'cc', 'cg', 'ch',
'cl', 'cn', 'co', 'cp', 'cr', 'cs', 'ct', 'cy', 'cz', 'df', 'dv', 'fg', 'fl',
'fm', 'ft', 'gm', 'hy', 'jz', 'mc', 'md', 'mi', 'mo', 'mp', 'mr', 'ms', 'mu',
'mz', 'nc', 'nn', 'op', 'or', 'ov', 'pg', 'pm', 'po', 'pp', 'pr', 'ps', 'pt',
'pv', 'rc', 'rd', 'rg', 'ri', 'rp', 'rq', 'sd', 'sg', 'sn', 'sp', 'st', 'su',
'sy', 'tc', 'tl', 'ts', 'uu', 'vi', 'vr', 'wz', 'za', 'zz' or '||'.

It's required.

Default value is undef.

=item * C<form_of_item>

Form of item. The length of the item is 1 character.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'f', 'o', 'q', 'r', 's' or '|'.

It's required.

Default value is undef.

=item * C<format_of_music>

Format of music. The length of the item is 1 character.
Possible characters are 'a', 'b', 'c', 'd', 'e', 'g', 'h', 'i', 'j', 'k', 'l',
'm', 'n', 'p', 'u', 'z' or '|'.

It's required.

Default value is undef.

=item * C<literary_text_for_sound_recordings>

Literary text for sound recordings. The length of the item is 2 characters.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
'k', 'l', 'm', 'n', 'o', 'p', 'r', 's', 't', 'z' or '|'.

It's required.

Default value is undef.

=item * C<music_parts>

Music parts. The length of the item is 1 character.
Possible characters are ' ', 'd', 'e', 'f', 'n', 'u' or '|'.

It's required.

Default value is undef.

=item * C<raw>

Raw string of material. The length of the string is 17 characters.

It's optional.

Default value is undef.

=item * C<target_audience>

Target audience. The length of the item is 1 character.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'j' or '|'.

It's required.

Default value is undef.

=item * C<transposition_and_arrangement>

Transposition and arrangement. The length of the item is 1 character.
Possible characters are ' ', 'a', 'b', 'c', 'n', 'u' or '|'.

It's required.

Default value is undef.

=back

Returns instance of object.

=head2 C<accompanying_matter>

 my $accompanying_matter = $obj->accompanying_matter;

Get accompanying matter.

Returns string.

=head2 C<form_of_composition>

 my $form_of_composition = $obj->form_of_composition;

Get form of composition.

Returns string.

=head2 C<form_of_item>

 my $form_of_item = $obj->form_of_item;

Get form of item.

Returns string.

=head2 C<format_of_music>

 my $format_of_music = $obj->format_of_music;

Get format of music.

Returns string.

=head2 C<literary_text_for_sound_recordings>

 my $literary_text_for_sound_recordings = $obj->literary_text_for_sound_recordings;

Get literary text for sound recordings.

Returns string.

=head2 C<music_parts>

 my $music_parts = $obj->music_parts;

Get music parts.

Returns string.

=head2 C<raw>

 my $raw = $obj->form_of_item;

Get raw string of the block.

Returns string.

=head2 C<target_audience>

 my $target_audience = $obj->target_audience;

Get target audience.

Returns string.

=head2 C<transposition_and_arrangement>

 my $transposition_and_arrangement = $obj->transposition_and_arrangement;

Get transposition and arrangement.

Returns string.

=head1 ERRORS

 new():
         Couldn't create data object of music.
                 Raw string: %s
         Parameter 'raw' has length different than '17'.
                 Value: %s
         From Data::MARC::Field008::Utils::check_item_form():
                 Parameter 'form_of_item' has bad value.
                         Value: %s
                 Parameter 'form_of_item' is required.
                 Parameter 'form_of_item' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'form_of_item' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_music_accompanying_matter():
                 Parameter 'accompanying_matter' contains bad music accompanying matter character.
                         Value: %s
                 Parameter 'accompanying_matter' is required.
                 Parameter 'accompanying_matter' must be a scalar value.
                         Reference: %s
                 Parameter 'accompanying_matter' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 6
         From Data::MARC::Field008::Utils::check_music_composition_form():
                 Parameter 'form_of_composition' has bad value.
                         Value: %s
                 Parameter 'form_of_composition' is required.
                 Parameter 'check_music_composition_form' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 2
                 Parameter 'check_music_composition_form' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_music_format():
                 Parameter 'format_of_music' has bad value.
                         Value: %s
                 Parameter 'format_of_music' is required.
                 Parameter 'format_of_music' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'format_of_music' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_music_literary_text():
                 Parameter 'literary_text_for_sound_recordings' contains bad music literary text character.
                         Value: %s
                 Parameter 'literary_text_for_sound_recordings' has value with pipe character.
                         Value: %s
                 Parameter 'literary_text_for_sound_recordings' is required.
                 Parameter 'literary_text_for_sound_recordings' must be a scalar value.
                         Reference: %s
                 Parameter 'literary_text_for_sound_recordings' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 2
         From Data::MARC::Field008::Utils::check_music_parts():
                 Parameter 'music_parts' has bad value.
                         Value: %s
                 Parameter 'music_parts' is required.
                 Parameter 'music_parts' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'music_parts' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_music_transposition_and_arrangement():
                 Parameter 'transposition_and_arrangement' has bad value.
                         Value: %s
                 Parameter 'transposition_and_arrangement' is required.
                 Parameter 'transposition_and_arrangement' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'transposition_and_arrangement' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_target_audience():
                 Parameter 'target_audience' has bad value.
                         Value: %s
                 Parameter 'target_audience' is required.
                 Parameter 'target_audience' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'target_audience' must be a scalar value.
                         Reference: %s

=head1 EXAMPLE

=for comment filename=create_and_dump_marc_field_008_music_material.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Data::MARC::Field008::Music;

 # cnb000012142
 my $obj = Data::MARC::Field008::Music->new(
         'accompanying_matter' => '      ',
         'form_of_composition' => 'sg',
         'form_of_item' => ' ',
         'format_of_music' => 'z',
         'literary_text_for_sound_recordings' => 'nn',
         'music_parts' => ' ',
         #         89012345678901234
         'raw' => 'sgz g       nn   ',
         'target_audience' => 'g',
         'transposition_and_arrangement' => ' ',
 );

 # Print out.
 p $obj;

 # Output:
 # Data::MARC::Field008::Music  {
 #     parents: Mo::Object
 #     public methods (13):
 #         BUILD
 #         Data::MARC::Field008::Utils:
 #             check_item_form, check_music_accompanying_matter, check_music_composition_form, check_music_format, check_music_literary_text, check_music_parts, check_music_transposition_and_arrangement, check_target_audience
 #         Error::Pure:
 #             err
 #         Error::Pure::Utils:
 #             err_get
 #         Mo::utils:
 #             check_length_fix, check_required
 #     private methods (0)
 #     internals: {
 #         accompanying_matter                  "      ",
 #         format_of_music                      "z",
 #         form_of_composition                  "sg",
 #         form_of_item                         " ",
 #         literary_text_for_sound_recordings   "nn",
 #         music_parts                          " ",
 #         raw                                  "sgz g       nn   ",
 #         target_audience                      "g",
 #         transposition_and_arrangement        " "
 #     }
 # }

=head1 DEPENDENCIES

L<Data::MARC::Field008::Utils>,
L<Error::Pure>
L<Error::Pure::Utils>
L<Mo>,
L<Mo::utils>.

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
