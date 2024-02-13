package Data::MARC::Leader;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils 0.22 qw(check_length_fix check_strings);
use Readonly;

Readonly::Array our @BIBLIOGRAPHIC_LEVEL => qw(a b c d i m s);
Readonly::Array our @CHAR_CODING_SCHEME => (' ', 'a');
Readonly::Array our @DESCRIPTIVE_CATALOGING_FORM => (' ', 'a', 'c', 'i', 'n', 'u');
Readonly::Array our @ENCODING_LEVEL => (' ', 1, 2, 3, 4, 5, 7, 8, 'u', 'z');
Readonly::Array our @IMPL_DEF_PORTION_LEN => qw(0);
Readonly::Array our @INDICATOR_COUNT => qw(2);
Readonly::Array our @LENGTH_OF_FIELD_PORTION_LEN => qw(4);
Readonly::Array our @MULTIPART_RESORCE_RECORD_LEVEL => (' ', 'a', 'b', 'c');
Readonly::Array our @STARTING_CHAR_POS_PORTION_LEN => qw(5);
Readonly::Array our @STATUS => qw(a c d n p);
Readonly::Array our @SUBFIELD_CODE_COUNT => qw(2);
Readonly::Array our @TYPE => qw(a c d e f g i j k m o p r t);
Readonly::Array our @TYPE_OF_CONTROL => (' ', 'a');
Readonly::Array our @UNDEFINED => ('0');

our $VERSION = 0.06;

has bibliographic_level => (
	is => 'ro',
);

has char_coding_scheme => (
	is => 'ro',
);

has data_base_addr => (
	is => 'ro',
);

has descriptive_cataloging_form => (
	is => 'ro',
);

has encoding_level => (
	is => 'ro',
);

has impl_def_portion_len => (
	is => 'ro',
);

has indicator_count => (
	is => 'ro',
);

has length => (
	is => 'ro',
);

has length_of_field_portion_len => (
	is => 'ro',
);

has multipart_resource_record_level => (
	is => 'ro',
);

has raw => (
	is => 'ro',
);

has starting_char_pos_portion_len => (
	is => 'ro',
);

has status => (
	is => 'ro',
);

has subfield_code_count => (
	is => 'ro',
);

has type => (
	is => 'ro',
);

has type_of_control => (
	is => 'ro',
);

has undefined => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check bibliographic_level.
	check_strings($self, 'bibliographic_level', \@BIBLIOGRAPHIC_LEVEL);

	# Check char_coding_scheme.
	check_strings($self, 'char_coding_scheme', \@CHAR_CODING_SCHEME);

	# Check descriptive_cataloging_form.
	check_strings($self, 'descriptive_cataloging_form',
		\@DESCRIPTIVE_CATALOGING_FORM);

	# Check encoding_level.
	check_strings($self, 'encoding_level', \@ENCODING_LEVEL);

	# Check impl_def_portion_len.
	check_strings($self, 'impl_def_portion_len', \@IMPL_DEF_PORTION_LEN);

	# Check indicator_count.
	check_strings($self, 'indicator_count', \@INDICATOR_COUNT);

	# Check length_of_field_portion_len.
	check_strings($self, 'length_of_field_portion_len',
		\@LENGTH_OF_FIELD_PORTION_LEN);

	# Check multipart_resource_record_level.
	check_strings($self, 'multipart_resource_record_level',
		\@MULTIPART_RESORCE_RECORD_LEVEL);

	# Check raw.
	check_length_fix($self, 'raw', 24);

	# Check starting_char_pos_portion_len.
	check_strings($self, 'starting_char_pos_portion_len',
		\@STARTING_CHAR_POS_PORTION_LEN);

	# Check status.
	check_strings($self, 'status', \@STATUS);

	# Check subfield_code_count.
	check_strings($self, 'subfield_code_count', \@SUBFIELD_CODE_COUNT);

	# Check type.
	check_strings($self, 'type', \@TYPE);

	# Check type_of_control.
	check_strings($self, 'type_of_control', \@TYPE_OF_CONTROL);

	# Check undefined.
	check_strings($self, 'undefined', \@UNDEFINED);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::MARC::Leader - Data object for MARC leader.

=head1 SYNOPSIS

 use Data::MARC::Leader;

 my $obj = Data::MARC::Leader->new(%params);
 my $bibliographic_level = $obj->bibliographic_level;
 my $char_coding_scheme = $obj->char_coding_scheme;
 my $data_base_addr = $obj->data_base_addr;
 my $descriptive_cataloging_form = $obj->descriptive_cataloging_form;
 my $encoding_level = $obj->encoding_level;
 my $impl_def_portion_len = $obj->impl_def_portion_len;
 my $indicator_count = $obj->indicator_count;
 my $length = $obj->length;
 my $length_of_field_portion_len = $obj->length_of_field_portion_len;
 my $multipart_resource_record_level = $obj->multipart_resource_record_level;
 my $raw = $obj->raw;
 my $starting_char_pos_portion_len = $obj->starting_char_pos_portion_len;
 my $status = $obj->status;
 my $subfield_code_count = $obj->subfield_code_count;
 my $type = $obj->type;
 my $type_of_control = $obj->type_of_control;
 my $undefined = $obj->undefined;

=head1 METHODS

=head2 C<new>

 my $obj = Data::MARC::Leader->new(%params);

Constructor.

=over 8

=item * C<bibliographic_level>

Bibliographic level flag.

Default values is undef.

=item * C<char_coding_scheme>

Character coding scheme.

Default values is undef.

=item * C<data_base_addr>

Base address of data.

Default values is undef.

=item * C<descriptive_cataloging_form>

Descriptive cataloging form.

Default values is undef.

=item * C<encoding_level>

Encoding level.

Default values is undef.

=item * C<impl_def_portion_len>

Length of the implementation-defined portion.

Default values is undef.

=item * C<indicator_count>

Indicator count.

Default values is undef.

=item * C<length>

Record length.

Default values is undef.

=item * C<length_of_field_portion_len>

Length of the length-of-field portion.

Default values is undef.

=item * C<multipart_resource_record_level>

Multipart resource record level.

Default values is undef.

=item * C<raw>

Raw leader value.

Default values is undef.

=item * C<starting_char_pos_portion_len>

Length of the starting-character-position portion.

Default values is undef.

=item * C<status>

Record status.

Default values is undef.

=item * C<subfield_code_count>

Subfield code count.

Default values is undef.

=item * C<type>

Type of record.

Default values is undef.

=item * C<type_of_control>

Type of control.

Default values is undef.

=item * C<undefined>

Undefined.

Default values is undef.

=back

Returns instance of object.

=head2 C<bibliographic_level>

 my $bibliographic_level = $obj->bibliographic_level;

Get bibliographic level flag.

Returns character.

=head2 C<char_coding_scheme>

 my $char_coding_scheme = $obj->char_coding_scheme;

Get character coding scheme.

Returns character.

=head2 C<data_base_addr>

 my $data_base_addr = $obj->data_base_addr;

Get base address of data.

Returns number.

=head2 C<descriptive_cataloging_form>

 my $descriptive_cataloging_form = $obj->descriptive_cataloging_form;

Get descriptive cataloging form.

Returns character.

=head2 C<encoding_level>

 my $encoding_level = $obj->encoding_level;

Get encoding level.

Returns character.

=head2 C<impl_def_portion_len>

 my $impl_def_portion_len = $obj->impl_def_portion_len;

Get length of the implementation-defined portion.

Returns character.

=head2 C<indicator_count>

 my $indicator_count = $obj->indicator_count;

Get indicator count.

Returns character.

=head2 C<length>

 my $length = $obj->length;

Get record length.

Returns number.

=head2 C<length_of_field_portion_len>

 my $length_of_field_portion_len = $obj->length_of_field_portion_len;

Get length of the length-of-field portion

Returns character.

=head2 C<multipart_resource_record_level>

 my $multipart_resource_record_level = $obj->multipart_resource_record_level;

Get multipart resource record level.

Returns character.

=head2 C<raw>

 my $raw = $obj->raw;

Get raw leader value.

Returns string.

=head2 C<starting_char_pos_portion_len>

 my $starting_char_pos_portion_len = $obj->starting_char_pos_portion_len;

Get length of the starting-character-position portion.

Returns character.

=head2 C<status>

 my $status = $obj->status;

Get record status.

Returns character.

=head2 C<subfield_code_count>

 my $subfield_code_count = $obj->subfield_code_count;

Get subfield code count.

Returns character.

=head2 C<type>

 my $type = $obj->type;

Get type of record.

Returns character.

=head2 C<type_of_control>

 my $type_of_control = $obj->type_of_control;

Get type of control.

Returns character.

=head2 C<undefined>

 my $undefined = $obj->undefined;

Get undefined.

Returns character.

=head1 ERRORS

 new():
         Parameter 'bibliographic_level' must be one of defined strings.
                 String: %s
                 Possible strings: a b c d i m s
         Parameter 'char_coding_scheme' must be one of defined strings.
                 String: %s
                 Possible strings: ' ' a
         Parameter 'descriptive_cataloging_form' must be one of defined strings.
                 String: %s
                 Possible strings: ' ' a c i n u
         Parameter 'encoding_level' must be one of defined strings.
                 String: %s
                 Possible strings: ' ' 1 2 3 4 5 7 8 u z
         Parameter 'impl_def_portion_len' must be one of defined strings.
                 String: %s
                 Possible strings: 0
         Parameter 'indicator_count' must be one of defined strings.
                 String: %s
                 Possible strings: 2
         Parameter 'length_of_field_portion_len' must be one of defined strings.
                 String: %s
                 Possible strings: 4
         Parameter 'multipart_resource_record_level' must be one of defined strings.
                 String: %s
                 Possible strings: ' ' a b c
         Parameter 'raw' has length different than '24'.
                 Value: %s
         Parameter 'starting_char_pos_portion_len' must be one of defined strings.
                 String: %s
                 Possible strings: 5
         Parameter 'status' must be one of defined strings.
                 String: %s
                 Possible strings: a c d n p
         Parameter 'subfield_code_count' must be one of defined strings.
                 String: %s
                 Possible strings: 2
         Parameter 'type' must be one of defined strings.
                 String: %s
                 Possible strings: a c d e f g i j k m o p r t
         Parameter 'type_of_control' must be one of defined strings.
                 String: %s
                 Possible strings: ' ' a
         Parameter 'undefined' must be one of defined strings.
                 String: %s
                 Possible strings: 0

=head1 EXAMPLE

=for comment filename=create_and_dump_marc_leader.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Data::MARC::Leader;

 my $obj = Data::MARC::Leader->new(
         'bibliographic_level' => 'm',
         'char_coding_scheme' => 'a',
         'data_base_addr' => 541,
         'descriptive_cataloging_form' => 'i',
         'encoding_level' => ' ',
         'impl_def_portion_len' => '0',
         'indicator_count' => '2',
         'length' => 2200,
         'length_of_field_portion_len' => '4',
         'multipart_resource_record_level' => ' ',
         'raw' => '02200cem a2200541 i 4500',
         'starting_char_pos_portion_len' => '5',
         'status' => 'c',
         'subfield_code_count' => '2',
         'type' => 'e',
         'type_of_control' => ' ',
         'undefined' => '0',
 );

 # Print out.
 p $obj;

 # Output:
 # Data::MARC::Leader  {
 #     parents: Mo::Object
 #     public methods (3):
 #         BUILD
 #         Mo::utils:
 #             check_strings
 #         Readonly:
 #             Readonly
 #     private methods (0)
 #     internals: {
 #         bibliographic_level               "m",
 #         char_coding_scheme                "a",
 #         data_base_addr                    541,
 #         descriptive_cataloging_form       "i",
 #         encoding_level                    " ",
 #         impl_def_portion_len              0,
 #         indicator_count                   2,
 #         length                            2200,
 #         length_of_field_portion_len       4,
 #         multipart_resource_record_level   " ",
 #         raw                               "02200cem a2200541 i 4500",
 #         starting_char_pos_portion_len     5,
 #         status                            "c",
 #         subfield_code_count               2,
 #         type                              "e",
 #         type_of_control                   " ",
 #         undefined                         0
 #     }
 # }

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-MARC-Leader>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.06

=cut
