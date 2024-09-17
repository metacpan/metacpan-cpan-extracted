package Data::InfoBox;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils 0.21 qw(check_array_object check_array_required);

our $VERSION = 0.02;

has items => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check items.
	check_array_object($self, 'items', 'Data::InfoBox::Item');
	check_array_required($self, 'items');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::InfoBox - Data object for info box.

=head1 SYNOPSIS

 use Data::InfoBox;

 my $obj = Data::InfoBox->new(%params);
 my $items_ar = $obj->items;

=head1 METHODS

=head2 C<new>

 my $obj = Data::InfoBox->new(%params);

Constructor.

=over 8

=item * C<items>

List of L<Data::InfoBox::Item> items. Must be as reference to array.

It's required.

=back

Returns instance of object.

=head2 C<items>

 my $items_ar = $obj->items;

Get list of items in info box.

Returns reference to array with L<Data::InfoBox::Item> objects.

=head1 EXAMPLE

=for comment filename=create_infobox_object_and_print.pl

 use strict;
 use warnings;

 use Data::InfoBox;
 use Data::InfoBox::Item;
 use Data::Text::Simple;

 my $obj = Data::InfoBox->new(
         'items' => [
                Data::InfoBox::Item->new(
                        'text' => Data::Text::Simple->new(
                                'text' => 'First item',
                        ),
                ),
                Data::InfoBox::Item->new(
                        'text' => Data::Text::Simple->new(
                                'text' => 'Second item',
                        ),
                ),
         ],
 );

 # Print out.
 my $num = 0;
 foreach my $item (@{$obj->items}) {
         $num++;
         print "Item $num: ".$item->text->text."\n";
 }

 # Output:
 # Item 1: First item
 # Item 2: Second item

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>.

=head1 SEE ALSO

=over

=item L<Data::InfoBox::Item>

Data object for info box item.

=item L<Test::Shared::Fixture::Data::InfoBox::Street>

Street info box fixture.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-InfoBox>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
