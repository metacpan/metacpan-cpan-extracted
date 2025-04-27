package Data::Person;

use strict;
use warnings;

use Mo qw(build default is);
use Mo::utils 0.21 qw(check_array_object check_length check_strings);
use Mo::utils::Number qw(check_positive_natural);
use Mo::utils::Email qw(check_email);
use Readonly;

Readonly::Array our @SEX => qw(female male unknown);

our $VERSION = 0.05;

has email => (
	is => 'ro',
);

has external_ids => (
	default => [],
	is => 'ro',
);

has id => (
	is => 'ro',
);

has name => (
	is => 'ro',
);

has sex => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check email.
	check_email($self, 'email');

	# Check external_ids.
	check_array_object($self, 'external_ids', 'Data::ExternalId', 'External id');

	# Check id.
	check_positive_natural($self, 'id');

	# Check name.
	check_length($self, 'name', 255);

	# Check sex.
	check_strings($self, 'sex', \@SEX);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::Person - Data object for person.

=head1 SYNOPSIS

 use Data::Person;

 my $obj = Data::Person->new(%params);
 my $email = $obj->email;
 my $external_ids_ar = $obj->external_ids;
 my $id = $obj->id;
 my $name = $obj->name;
 my $sex = $obj->sex;

=head1 DESCRIPTION

The immutable data object for representation of person.

=head1 METHODS

=head2 C<new>

 my $obj = Data::Person->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<email>

Person's email for external identification.
It's optional.
Default value is undef.

=item * C<external_ids>

Person external ids.
It's optional.
Value must be a instance of L<Data::ExternalId> object.
Default value is [].

=item * C<id>

Id of person.
It's natural number.
It's optional.
Default value is undef.

=item * C<name>

Name of person.
Length of name is 255.
It's optional.

=item * C<sex>

Sex of person.
Possible values are: female, male and unknown.
It's optional.

=back

=head2 C<email>

 my $email = $obj->email;

Get person email.

Returns string.

=head2 C<external_ids>

 my $external_ids_ar = $obj->external_ids;

Get external ids.

Returns reference to array with L<Data::ExternalId> instances.

=head2 C<id>

 my $id = $obj->id;

Get person id.

Returns number.

=head2 C<name>

 my $name = $obj->name;

Get person name.

Returns string.

=head2 C<sex>

 my $sex = $obj->sex;

Get person sex.

Returns string.

=head1 ERRORS

 new():
         From Mo::utils::check_array_object():
                 Parameter 'external_ids' must be a array.
                         Value: %s
                         Reference: %s
                 External id isn't 'Data::ExternalId' object.
                         Value: %s
                         Reference: %s
         From Mo::utils::Number::check_positive_natural():
                 Parameter 'id' must a positive natural number.
                         Value: %s
         Parameter 'name' has length greater than '255'.
                 Value: %s
         Parameter 'sex' must be one of defined strings.
                 String: %s
                 Possible strings: %s

=head1 EXAMPLE

=for comment filename=create_and_print_person.pl

 use strict;
 use warnings;

 use Data::ExternalId;
 use Data::Person;
 use DateTime;
 use Unicode::UTF8 qw(decode_utf8 encode_utf8);

 my $obj = Data::Person->new(
         'email' => 'skim@cpan.org',
         'external_ids' => [
                 Data::ExternalId->new(
                         'key' => 'Wikidata',
                         'value' => 'Q27954834',
                 ),
         ],
         'id' => 1,
         'name' => decode_utf8('Michal Josef Špaček'),
         'sex' => 'male',
 );

 # Print out.
 print 'Id: '.$obj->id."\n";
 print 'Name: '.encode_utf8($obj->name)."\n";
 print 'Email: '.$obj->email."\n";
 print 'Sex: '.$obj->sex."\n";
 foreach my $external_id (@{$obj->external_ids}) {
        print 'External id - '.$external_id->key.': '.$external_id->value."\n";
 }

 # Output:
 # Id: 1
 # Name: Michal Josef Špaček
 # Email: skim@cpan.org
 # Sex: male
 # External id - Wikidata: Q27954834

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>,
L<Mo::utils::Email>,
L<Mo::utils::Number>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-Person>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
