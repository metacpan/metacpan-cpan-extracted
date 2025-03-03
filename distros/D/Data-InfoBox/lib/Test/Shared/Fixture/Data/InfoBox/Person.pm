package Test::Shared::Fixture::Data::InfoBox::Person;

use base qw(Data::InfoBox);
use strict;
use warnings;

use Data::Icon;
use Data::InfoBox::Item;
use Data::Text::Simple;
use Unicode::UTF8 qw(decode_utf8);

our $VERSION = 0.06;

sub new {
	my $class = shift;

	my @params = (
		'items' => [
			Data::InfoBox::Item->new(
				'icon' => Data::Icon->new(
					'char' => decode_utf8('🧍'),
				),
				'text' => Data::Text::Simple->new(
					'text' => decode_utf8('Michal Josef Špaček'),
				),
			),
			Data::InfoBox::Item->new(
				'icon' => Data::Icon->new(
					'char' => decode_utf8('☎'),
				),
				'text' => Data::Text::Simple->new(
					'text' => '+420777623160',
				),
			),
		],
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Test::Shared::Fixture::Data::InfoBox::Person - Person info box fixture.

=head1 SYNOPSIS

 use Test::Shared::Fixture::Data::InfoBox::Person;

 my $obj = Test::Shared::Fixture::Data::InfoBox::Person->new;
 my $items_ar = $obj->items;

=head1 METHODS

=head2 C<new>

 my $obj = Test::Shared::Fixture::Data::InfoBox::Person->new;

Constructor.

Returns instance of object.

=head2 C<items>

 my $items_ar = $obj->items;

Get list of items in info box.

Returns reference to array with L<Data::InfoBox::Item> objects.

=head1 EXAMPLE

=for comment filename=create_person_fixture_object_and_print.pl

 use strict;
 use warnings;

 use Test::Shared::Fixture::Data::InfoBox::Person;
 use Unicode::UTF8 qw(encode_utf8);

 my $obj = Test::Shared::Fixture::Data::InfoBox::Person->new;

 # Print out.
 my $num = 0;
 foreach my $item (@{$obj->items}) {
         $num++;
         print "Item $num: ".encode_utf8($item->text->text)."\n";
 }

 # Output:
 # Item 1: Michal Josef Špaček
 # Item 2: +420777623160

=head1 DEPENDENCIES

L<Data::InfoBox>,
L<Data::InfoBox::Item>,
L<Data::Text::Simple>,
L<Unicode::UTF8>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-InfoBox>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.06

=cut
