package Data::MARC::Field008::VisualMaterial;

use strict;
use warnings;

use Data::MARC::Field008::Utils qw(check_government_publication check_item_form
	check_visual_material_running_time check_visual_material_technique
	check_target_audience);
use Error::Pure qw(err);
use Error::Pure::Utils qw(clean err_get);
use Mo qw(build is);
use Mo::utils 0.22 qw(check_length_fix check_required);

our $STRICT = 1;

our $VERSION = 0.03;

has form_of_item => (
	is => 'ro',
);

has government_publication => (
	is => 'ro',
);

has raw => (
	is => 'ro',
);

has running_time_for_motion_pictures_and_videorecordings => (
	is => 'ro',
);

has target_audience => (
	is => 'ro',
);

has technique => (
	is => 'ro',
);

has type_of_visual_material => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'raw'
	check_length_fix($self, 'raw', 17);

	# Check 'form_of_item'.
	eval { check_item_form($self, 'form_of_item'); };

	# Check 'government_publication'.
	eval { check_government_publication($self, 'government_publication'); };

	# Check 'running_time_for_motion_pictures_and_videorecordings'.
	eval { check_visual_material_running_time($self, 'running_time_for_motion_pictures_and_videorecordings'); };

	# Check 'target_audience'.
	eval { check_target_audience($self, 'target_audience'); };

	# Check 'technique'.
	eval { check_visual_material_technique($self, 'technique'); };

	# Check 'type_of_visual_material'.
	eval { check_visual_material_type($self, 'type_of_visual_material'); };

	if ($STRICT) {
		my @errors = err_get();
		if (@errors) {
			err "Couldn't create data object of visual material.",
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

Data::MARC::Field008::VisualMaterial - Data object for MARC field 008 visual material.

=head1 SYNOPSIS

 use Data::MARC::Field008::VisualMaterial;

 my $obj = Data::MARC::Field008::VisualMaterial->new(%params);
 my $form_of_item = $obj->form_of_item;
 my $government_publication = $obj->government_publication;
 my $raw = $obj->raw;
 my $running_time_for_motion_pictures_and_videorecordings = $obj->running_time_for_motion_pictures_and_videorecordings;
 my $target_audience = $obj->target_audience;
 my $technique = $obj->technique;
 my $type_of_visual_material = $obj->type_of_visual_material;

=head1 METHODS

=head2 C<new>

 my $obj = Data::MARC::Field008::VisualMaterial->new(%params);

Constructor.

=over 8

=item * C<form_of_item>

Form of item. The length of the item is 1 character.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'f', 'o', 'q', 'r', 's' or '|'.

It's required.

Default value is undef.

=item * C<government_publication>

Government publication. The length of the string is 1 character.
Possible characters are ' ', 'a', 'c', 'f', 'i', 'l', 'm', 'o', 's', 'u', 'z' or '|'.

It's required.

Default value is undef.

=item * C<raw>

Raw string of material. The length of the string is 17 characters.

It's optional.

Default value is undef.

=item * C<running_time_for_motion_pictures_and_videorecordings>

Running time for motion pictures and videorecordings. The length of the string is 3 characters.
Possible strings are decimal string, 'nnn', '---' or '|||'.

It's required.

Default value is undef.

=item * C<target_audience>

Target audience. The length of the item is 1 character.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'j' or '|'.

It's required.

Default value is undef.

=item * C<technique>

Technique. The length of the string is 1 character.
Possible characters are 'a', 'c', 'l', 'n', 'u', 'z' or '|'.

It's required.

Default value is undef.

=item * C<type_of_visual_material>

Type of visual material. The length of the string is 1 character.
Possible characters are 'a', 'b', 'c', 'd', 'f', 'g', 'i', 'k', 'l', 'm', 'n',
'o', 'p', 'q', 'r', 's', 't', 'v', 'w', 'z' or '|'.

It's required.

Default value is undef.

=back

Returns instance of object.

=head2 C<form_of_item>

 my $form_of_item = $obj->form_of_item;

Get for of item.

Returns string.

=head2 C<government_publication>

 my $government_publication = $obj->government_publication;

Get governent publication.

Returns string.

=head2 C<raw>

 my $raw = $obj->raw;

Get raw string of the block.

Returns string.

=head2 C<running_time_for_motion_pictures_and_videorecordings>

 my $running_time_for_motion_pictures_and_videorecordings = $obj->running_time_for_motion_pictures_and_videorecordings;

Get running time for motion pictures and videorecordings.

Returns string.

=head2 C<target_audience>

 my $target_audience = $obj->target_audience;

Get target audience.

Returns string.

=head2 C<technique>

 my $technique = $obj->technique;

Get technique.

Returns string.

=head2 C<type_of_visual_material>

 my $type_of_visual_material = $obj->type_of_visual_material;

Get type of visual material.

Returns string.

=head1 ERRORS

 new():
         Couldn't create data object of visual material.
                 Raw string: %s
         Parameter 'raw' has length different than '17'.
                 Value: %s
         From Data::MARC::Field008::Utils::check_government_publication():
                 Parameter 'government_publication' has bad value.
                         Value: %s
                 Parameter 'government_publication' is required.
                 Parameter 'government_publication' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'government_publication' must be a scalar value.
                         Reference: %s
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
         From Data::MARC::Field008::Utils::check_visual_material_running_time():
                 Parameter 'running_time_for_motion_pictures_and_videorecordings' contains bad visual material running time.
                         Value: %s
                 Parameter 'running_time_for_motion_pictures_and_videorecordings' has value with 'n' character.
                         Value: %s
                 Parameter 'running_time_for_motion_pictures_and_videorecordings' has value with dash character.
                         Value: %s
                 Parameter 'running_time_for_motion_pictures_and_videorecordings' has value with pipe character.
                         Value: %s
                 Parameter 'running_time_for_motion_pictures_and_videorecordings' is required.
                 Parameter 'running_time_for_motion_pictures_and_videorecordings' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: %s
                 Parameter 'running_time_for_motion_pictures_and_videorecordings' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_visual_material_technique():
                 Parameter 'technique' has bad value.
                         Value: %s
                 Parameter 'technique' is required.
                 Parameter 'technique' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'technique' must be a scalar value.
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

=for comment filename=create_and_dump_marc_field_008_visual_material.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Data::MARC::Field008::VisualMaterial;

 # cnb000027064
 my $obj = Data::MARC::Field008::VisualMaterial->new(
         'form_of_item' => ' ',
         'government_publication' => ' ',
         #         89012345678901234
         'raw' => 'nnn g          kn',
         'running_time_for_motion_pictures_and_videorecordings' => 'nnn',
         'target_audience' => 'g',
         'technique' => 'n',
         'type_of_visual_material' => 'k',
 );

 # Print out.
 p $obj;

 # Output:
 # Data::MARC::Field008::VisualMaterial  {
 #     parents: Mo::Object
 #     public methods (10):
 #         BUILD
 #         Data::MARC::Field008::Utils:
 #             check_government_publication, check_item_form, check_target_audience, check_visual_material_running_time, check_visual_material_technique
 #         Error::Pure:
 #             err
 #         Error::Pure::Utils:
 #             err_get
 #         Mo::utils:
 #             check_length_fix, check_required
 #     private methods (0)
 #     internals: {
 #         form_of_item                                           " ",
 #         government_publication                                 " ",
 #         raw                                                    "nnn g          kn",
 #         running_time_for_motion_pictures_and_videorecordings   "nnn",
 #         target_audience                                        "g",
 #         technique                                              "n",
 #         type_of_visual_material                                "k"
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
