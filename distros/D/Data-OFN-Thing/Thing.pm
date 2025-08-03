package Data::OFN::Thing;

use strict;
use warnings;

use Mo qw(build default is);
use Mo::utils 0.08 qw(check_isa);
use Mo::utils::Array qw(check_array_object);
use Mo::utils::IRI 0.02 qw(check_iri);
use Mo::utils::Number qw(check_positive_natural);

our $VERSION = 0.02;

has attachment => (
	default => [],
	is => 'ro',
);

has created => (
	is => 'ro',
);

has description => (
	default => [],
	is => 'ro',
);

has id => (
	is => 'ro',
);

has invalidated => (
	is => 'ro',
);

has iri => (
	is => 'ro',
);

has name => (
	default => [],
	is => 'ro',
);

has relevant_to => (
	is => 'ro',
);

has updated => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'attachment'.
	check_array_object($self, 'attachment', 'Data::OFN::DigitalObject',
		'Digital object');

	# Check 'created'.
	check_isa($self, 'created', 'Data::OFN::Common::TimeMoment');

	# Check 'description'.
	check_array_object($self, 'description', 'Data::Text::Simple', 'Description');

	# Check 'id'.
	check_positive_natural($self, 'id');

	# Check 'invalidated'.
	check_isa($self, 'invalidated', 'Data::OFN::Common::TimeMoment');

	# Check 'iri'.
	check_iri($self, 'iri');

	# Check 'name'.
	check_array_object($self, 'name', 'Data::Text::Simple', 'Name');

	# Check 'relevant_to'.
	check_isa($self, 'relevant_to', 'Data::OFN::Common::TimeMoment');

	# Check 'updated'.
	check_isa($self, 'updated', 'Data::OFN::Common::TimeMoment');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::OFN::Thing - Data object for OFN thing.

=head1 SYNOPSIS

 use Data::OFN::Thing;

 my $obj = Data::OFN::Thing->new(%params);
 my $attachment_ar = $obj->attachment;
 my $created = $obj->created;
 my $description_ar = $obj->description;
 my $id = $obj->id;
 my $invalidated = $obj->invalidated;
 my $iri = $obj->iri;
 my $name_ar = $obj->name;
 my $relevant_to = $obj->relevant_to;
 my $updated = $obj->updated;

=head1 DESCRIPTION

Immutable data object for OFN (Otevřené formální normy) representation of
thing in the Czech Republic.

This object is actual with L<2020-07-01|https://ofn.gov.cz/v%C4%9Bc/2020-07-01/> version of
OFN thing standard.

The thing is base object for other OFN objects.

=head1 METHODS

=head2 C<new>

 my $obj = Data::OFN::Thing->new(%params);

Constructor.

=over 8

=item * C<attachment>

The thing attachments.
It's reference to array with L<Data::OFN::DigitalObject> instances.

It's optional.

Default value is [].

=item * C<created>

Time moment when the thing was created.
It's L<Data::OFN::Comment::TimeMoment> instance.

It's optional.

Default value is undef.

=item * C<description>

The description of the thing.
It's reference to array with L<Data::Text::Simple> instances.

It's optional.

Default value is [].

=item * C<id>

The thing id.

This is not official identifier of address in the Czech Republic.
It's used for internal identification like database.

It's optional.

Default value is undef.

=item * C<invalidated>

Time moment when the thing was invalidated.
It's L<Data::OFN::Comment::TimeMoment> instance.

It's optional.

Default value is undef.

=item * C<iri>

IRI of the thing.

It's optional.

Default value is undef.

=item * C<name>

The name of the thing.
It's reference to array with L<Data::Text::Simple> instances.

It's optional.

Default value is [].

=item * C<relevant_to>

Time moment to which the thing is relevant.
It's L<Data::OFN::Comment::TimeMoment> instance.

It's optional.

Default value is undef.

=item * C<updated>

Time moment when the thing was updated.
It's L<Data::OFN::Comment::TimeMoment> instance.

It's optional.

Default value is undef.

=back

Returns instance of object.

=head2 C<attachment>

 my $attachment_ar = $obj->attachment;

Get list of attachments.

Returns reference to array with L<Data::OFN::DigitalObject> instances.

=head2 C<created>

 my $created = $obj->created;

Get time moment when the thing was created.

Returns L<Data::OFN::Common::TimeMoment> instance.

=head2 C<description>

 my $description_ar = $obj->description;

Get description of the thing.

Returns reference to array with L<Data::Text::Simple> instances.

=head2 C<id>

 my $id = $obj->id;

Get OFN thing id.

Returns positive natural number.

=head2 C<invalidated>

 my $invalidated = $obj->invalidated;

Get time moment when the thing was invalidated.

Returns L<Data::OFN::Common::TimeMoment> instance.

=head2 C<iri>

 my $iri = $obj->iri;

Get IRI of the thing.

Returns string with IRI.

=head2 C<name>

 my $name_ar = $obj->name;

Get name of the thing.

Returns reference to array with L<Data::Text::Simple> instances.

=head2 C<relevant_to>

 my $relevant_to = $obj->relevant_to;

Get time moment to which the thing is relevant.

Returns L<Data::OFN::Common::TimeMoment> instance.

=head2 C<updated>

 my $updated = $obj->updated;

Get time moment when the thing was updated.

Returns L<Data::OFN::Common::TimeMoment> instance.

=head1 ERRORS

 new():
         From Mo::utils::check_isa():
                 Parameter 'created' must be a 'Data::OFN::Common::TimeMoment' object.
                         Value: %s
                         Reference: %s
                 Parameter 'invalidated' must be a 'Data::OFN::Common::TimeMoment' object.
                         Value: %s
                         Reference: %s
                 Parameter 'relevant_to' must be a 'Data::OFN::Common::TimeMoment' object.
                         Value: %s
                         Reference: %s
                 Parameter 'updated' must be a 'Data::OFN::Common::TimeMoment' object.
                         Value: %s
                         Reference: %s

         From Mo::utils::Array::check_array_object():
                 Parameter 'attachment' must be a array.
                         Value: %s
                         Reference: %s
                 Parameter 'attachment' with array must contain 'Data::OFN::DigitalObject' objects.
                         Value: %s
                         Reference: %s
                 Parameter 'description' must be a array.
                         Value: %s
                         Reference: %s
                 Parameter 'description' with array must contain 'Data::Text::Simple' objects.
                         Value: %s
                         Reference: %s
                 Parameter 'name' must be a array.
                         Value: %s
                         Reference: %s
                 Parameter 'name' with array must contain 'Data::Text::Simple' objects.
                         Value: %s
                         Reference: %s

         From Mo::utils::IRI::check_iri():
                 Parameter 'iri' doesn't contain valid IRI.
                         Value: %s

         From Mo::utils::Number::check_positive_natural():
                 Parameter 'id' must be a positive natural number.
                         Value: %s

=head1 EXAMPLE1

=for comment filename=thing_simple.pl

 use strict;
 use warnings;

 use Data::OFN::Common::TimeMoment;
 use Data::OFN::Thing;
 use Data::Text::Simple;
 use DateTime;
 use Unicode::UTF8 qw(decode_utf8 encode_utf8);

 my $obj = Data::OFN::Thing->new(
         'created' => Data::OFN::Common::TimeMoment->new(
                 'date_and_time' => DateTime->new(
                         'day' => 27,
                         'month' => 9,
                         'year' => 2019,
                         'hour' => 9,
                         'minute' => 30,
                         'time_zone' => '+02:00',
                 ),
         ),
         'description' => [
                 Data::Text::Simple->new(
                         'lang' => 'cs',
                         'text' => decode_utf8("Ve čtvrtek 26. září večer došlo k loupeži banky na Masarykově náměstí.\nLupič pak prchal směrem ven z města. Obsluha městského kamerového systému incident zaznamenala,\nstrážníci městské policie zastavili auto ve Francouzské ulici a přivolali státní policii.\nTi záležitost převzali k dořešení. Pachateli hrozí až 10 let za mřížemi."),
                 ),
                 Data::Text::Simple->new(
                         'lang' => 'en',
                         'text' => decode_utf8("On Thursday evening, September 26, the bank was robbed on Masaryk Square.\nThe robber then fled out of town. The operator of the city's camera system recorded the incident,\nthus the city police officers were able to identify and stop the car in Francouzská Street and called the state police.\nThey took over the matter. Offenders face up to 10 years behind bars."),
                 ),
         ],
         'id' => 7,
         'iri' => decode_utf8('https://www.trebic.cz/zdroj/aktualita/2020/dopadení-lupiče-na-francouzské-ulici'),
         'name' => [
                 Data::Text::Simple->new(
                         'lang' => 'cs',
                         'text' => decode_utf8('Díky policistům byl lupič dopaden'),
                 ),
                 Data::Text::Simple->new(
                         'lang' => 'en',
                         'text' => 'Culprit was immediately caught, thanks to the police.',
                 ),
         ],
         'relevant_to' => Data::OFN::Common::TimeMoment->new(
                 'date_and_time' => DateTime->new(
                         'day' => 27,
                         'month' => 11,
                         'year' => 2019,
                         'hour' => 9,
                         'time_zone' => '+02:00',
                 ),
         ),
 );

 sub _text {
         my $obj = shift;

         return encode_utf8($obj->text.' ('.$obj->lang.')');
 }

 # Print out.
 print 'Id: '.$obj->id."\n";
 print 'Name: '._text($obj->name->[0])."\n";
 print 'Name: '._text($obj->name->[1])."\n";
 print 'Description: '._text($obj->description->[0])."\n";
 print 'Description: '._text($obj->description->[1])."\n";
 print 'IRI: '.encode_utf8($obj->iri)."\n";
 print 'Created: '.$obj->created->date_and_time."\n";
 print 'Relevant to: '.$obj->relevant_to->date_and_time."\n";

 # Output:
 # Id: 7
 # Name: Díky policistům byl lupič dopaden (cs)
 # Name: Culprit was immediately caught, thanks to the police. (en)
 # Description: Ve čtvrtek 26. září večer došlo k loupeži banky na Masarykově náměstí.
 # Lupič pak prchal směrem ven z města. Obsluha městského kamerového systému incident zaznamenala,
 # strážníci městské policie zastavili auto ve Francouzské ulici a přivolali státní policii.
 # Ti záležitost převzali k dořešení. Pachateli hrozí až 10 let za mřížemi. (cs)
 # Description: On Thursday evening, September 26, the bank was robbed on Masaryk Square.
 # The robber then fled out of town. The operator of the city's camera system recorded the incident,
 # thus the city police officers were able to identify and stop the car in Francouzská Street and called the state police.
 # They took over the matter. Offenders face up to 10 years behind bars. (en)
 # IRI: https://www.trebic.cz/zdroj/aktualita/2020/dopadení-lupiče-na-francouzské-ulici
 # Created: 2019-09-27T09:30:00
 # Relevant to: 2019-11-27T09:00:00

=head1 EXAMPLE2

=for comment filename=thing_invalidated.pl

 use strict;
 use warnings;

 use Data::OFN::Common::TimeMoment;
 use Data::OFN::Thing;
 use DateTime;

 my $obj = Data::OFN::Thing->new(
         'iri' => 'https://www.spilberk.cz/',
         'invalidated' => Data::OFN::Common::TimeMoment->new(
                 'date_and_time' => DateTime->new(
                         'day' => 27,
                         'month' => 11,
                         'year' => 2019,
                         'hour' => 9,
                         'time_zone' => '+02:00',
                 ),
         ),
 );

 # Print out.
 print 'IRI: '.$obj->iri."\n";
 print 'Invalidated: '.$obj->invalidated->date_and_time."\n";

 # Output:
 # IRI: https://www.spilberk.cz/
 # Invalidated: 2019-11-27T09:00:00

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>,
L<Mo::utils::Array>,
L<Mo::utils::IRI>,
L<Mo::utils::Number>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-OFN-Thing>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
