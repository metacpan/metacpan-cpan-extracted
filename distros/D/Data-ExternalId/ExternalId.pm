package Data::ExternalId;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils 0.28 qw(check_number_id check_required);

our $VERSION = 0.01;

has id => (
	is => 'ro',
);

has key => (
	is => 'ro',
);

has value => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check id.
	check_number_id($self, 'id');

	# Check key.
	check_required($self, 'key');

	# Check value.
	check_required($self, 'value');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::ExternalId - Data object for external identifier.

=head1 DESCRIPTION

Data object for external identifier. It could be defined as identifier key and
value.

=head1 SYNOPSIS

 use Data::ExternalId;

 my $obj = Data::ExternalId->new(%params);
 my $id = $obj->id;
 my $key = $obj->key;
 my $value = $obj->value;

=head1 METHODS

=head2 C<new>

 my $obj = Data::ExternalId->new(%params);

Constructor.

=over 8

=item * C<id>

Unique identifier.

It's optional.

=item * C<key>

External identifier key.

It's required.

=item * C<value>

External identifier value.

It's required.

=back

Returns instance of object.

=head2 C<id>

 my $id = $obj->id;

Get unique identifier.

Returns number.

=head2 C<key>

 my $key = $obj->key;

Get external identifier key.

Returns string.

=head2 C<value>

 my $value = $obj->value;

Get external identifier value.

Returns string.

=head1 ERRORS

 new():
          From Mo::utils::check_number_id():
                  Parameter 'id' must be a natural number.
                         Value: %s
          From Mo::utils::check_required():
                  Parameter 'key' is required.
                  Parameter 'value' is required.

=head1 EXAMPLE

=for comment filename=create_external_id_and_print.pl

 use strict;
 use warnings;

 use Data::ExternalId;

 my $obj = Data::ExternalId->new(
         'key' => 'Wikidata',
         'value' => 'Q27954834',
 );

 # Print out.
 print "External id key: ".$obj->key."\n";
 print "External id value: ".$obj->value."\n";

 # Output:
 # External id key: Wikidata
 # External id value: Q27954834

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-ExternalId>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
