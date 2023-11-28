package Data::MARC::Leader;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils qw(check_strings);
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

our $VERSION = 0.03;

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

TODO

=item * C<char_coding_scheme>

TODO

=item * C<data_base_addr>

TODO

=item * C<descriptive_cataloging_form>

TODO

=item * C<encoding_level>

TODO

=item * C<impl_def_portion_len>

TODO

=item * C<indicator_count>

TODO

=item * C<length>

TODO

=item * C<length_of_field_portion_len>

TODO

=item * C<multipart_resource_record_level>

TODO

=item * C<starting_char_pos_portion_len>

TODO

=item * C<status>

TODO

=item * C<subfield_code_count>

TODO

=item * C<type>

TODO

=item * C<type_of_control>

TODO

=item * C<undefined>

TODO

=back

Returns instance of object.

=head2 C<bibliographic_level>

 my $bibliographic_level = $obj->bibliographic_level;

Get bibliographic level flag.

Returns character.

=head2 C<char_coding_scheme>

 my $char_coding_scheme = $obj->char_coding_scheme;

TODO

=head2 C<data_base_addr>

 my $data_base_addr = $obj->data_base_addr;

TODO

=head2 C<descriptive_cataloging_form>

 my $descriptive_cataloging_form = $obj->descriptive_cataloging_form;

TODO

=head2 C<encoding_level>

 my $encoding_level = $obj->encoding_level;

TODO

=head2 C<impl_def_portion_len>

 my $impl_def_portion_len = $obj->impl_def_portion_len;

TODO

=head2 C<indicator_count>

 my $indicator_count = $obj->indicator_count;

TODO

=head2 C<length>

 my $length = $obj->length;

TODO

=head2 C<length_of_field_portion_len>

 my $length_of_field_portion_len = $obj->length_of_field_portion_len;

TODO

=head2 C<multipart_resource_record_level>

 my $multipart_resource_record_level = $obj->multipart_resource_record_level;

TODO

=head2 C<starting_char_pos_portion_len>

 my $starting_char_pos_portion_len = $obj->starting_char_pos_portion_len;

TODO

=head2 C<status>

 my $status = $obj->status;

TODO

=head2 C<subfield_code_count>

 my $subfield_code_count = $obj->subfield_code_count;

TODO

=head2 C<type>

 my $type = $obj->type;

TODO

=head2 C<type_of_control>

 my $type_of_control = $obj->type_of_control;

TODO

=head2 C<undefined>

 my $undefined = $obj->undefined;

TODO

=head1 ERRORS

 new():
         TODO

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

© 2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
