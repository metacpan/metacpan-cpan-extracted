package Test::Shared::Fixture::Data::InfoBox::Items;

use base qw(Data::InfoBox);
use strict;
use warnings;

use Data::Icon;
use Data::InfoBox::Item 0.03;
use Data::Text::Simple;
use Unicode::UTF8 qw(decode_utf8);

our $VERSION = 0.05;

sub new {
	my $class = shift;

	my @params = (
		'items' => [
			Data::InfoBox::Item->new(
				'icon' => Data::Icon->new(
					'color' => 'green',
					'char' => decode_utf8('✓'),
				),
				'text' => Data::Text::Simple->new(
					'lang' => 'en',
					'text' => 'Create project',
				),
			),
			Data::InfoBox::Item->new(
				'text' => Data::Text::Simple->new(
					'lang' => 'en',
					'text' => 'Present project',
				),
			),
			Data::InfoBox::Item->new(
				'icon' => Data::Icon->new(
					'color' => 'red',
					'char' => decode_utf8('✗'),
				),
				'text' => Data::Text::Simple->new(
					'lang' => 'en',
					'text' => 'Add money to project',
				),
			),
			Data::InfoBox::Item->new(
				'text' => Data::Text::Simple->new(
					'lang' => 'en',
					'text' => 'Finish project',
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

Test::Shared::Fixture::Data::InfoBox::Items - Items info box fixture.

=head1 SYNOPSIS

 use Test::Shared::Fixture::Data::InfoBox::Items;

 my $obj = Test::Shared::Fixture::Data::InfoBox::Items->new;
 my $items_ar = $obj->items;

=head1 METHODS

=head2 C<new>

 my $obj = Test::Shared::Fixture::Data::InfoBox::Items->new;

Constructor.

Returns instance of object.

=head2 C<items>

 my $items_ar = $obj->items;

Get list of items in info box.

Returns reference to array with L<Data::InfoBox::Item> objects.

=head1 EXAMPLE

=for comment filename=create_items_fixture_object_and_print.pl

 use strict;
 use warnings;

 use Term::ANSIColor;
 use Test::Shared::Fixture::Data::InfoBox::Items;
 use Unicode::UTF8 qw(encode_utf8);

 my $obj = Test::Shared::Fixture::Data::InfoBox::Items->new;

 # Print out.
 my $num = 0;
 foreach my $item (@{$obj->items}) {
         $num++;
         my $icon_char = defined $item->icon
		? color($item->icon->color).encode_utf8($item->icon->char).color('reset')
		: ' ';
         print $icon_char.' '.encode_utf8($item->text->text)."\n";
 }

 # Output (real output is colored):
 # ✓ Create project
 #   Present project
 # ✗ Add money to project
 #   Finish project

=head1 DEPENDENCIES

L<Data::Icon>,
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

0.05

=cut
