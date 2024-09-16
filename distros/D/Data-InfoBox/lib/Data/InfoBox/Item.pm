package Data::InfoBox::Item;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils 0.08 qw(check_isa check_length check_required);
use Mo::utils::URI 0.02 qw(check_location);

our $VERSION = 0.01;

has icon_url => (
	is => 'ro',
);

has icon_char => (
	is => 'ro',
);

has text => (
	is => 'ro',
);

has url => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check icon_url.
	check_location($self, 'icon_url');
	# TODO Check image

	# Check icon_char.
	check_length($self, 'icon_char', 1);

	# Check text.
	check_required($self, 'text');
	check_isa($self, 'text', 'Data::Text::Simple');

	# Check url.
	check_location($self, 'url');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::InfoBox::Item - Data object for info box item.

=head1 SYNOPSIS

 use Data::InfoBox;

 my $obj = Data::InfoBox::Item->new(%params);
 my $icon_url = $obj->icon_url;
 my $icon_char = $obj->icon_char;
 my $text = $obj->text;
 my $url = $obj->url;

=head1 METHODS

=head2 C<new>

 my $obj = Data::InfoBox->new(%params);

Constructor.

=over 8

=item * C<icon_url>

Icon URL.

It's optional.

=item * C<icon_char>

Icon character. Could be UTF-8 character. Only one character.

It's optional.

=item * C<text>

Item text. Must me a L<Data::Text::Simple> object.

It's required.

=item * C<url>

URL of item.

It's optional.

=back

Returns instance of object.

=head2 C<icon_url>

 my $icon_url = $obj->icon_url;

Get icon URL.

Returns string.

=head2 C<icon_char>

 my $icon_char = $obj->icon_char;

Get icon character.

Returns string.

=head2 C<text>

 my $text = $obj->text;

Get text of item.

Returns L<Data::Text::Simple> object.

=head2 C<url>

 my $url = $obj->url;

Get URL of item.

Returns string.

=head1 ERRORS

 new():
         From Mo::utils:
                 Parameter 'icon_char' has length greater than '1'.
                         Value: %s
                 Parameter 'text' is required.
                 Parameter 'text' must be a 'Data::Text::Simple' object.
                         Value: %s
                         Reference: %s
                 
         From Mo::utils::URI:
                 Parameter 'icon_url' doesn't contain valid location.
                         Value: %s
                 Parameter 'url' doesn't contain valid location.
                         Value: %s

=head1 EXAMPLE

=for comment filename=create_infobox_item_object_and_print.pl

 use strict;
 use warnings;

 use Data::InfoBox::Item;
 use Data::Text::Simple;

 my $obj = Data::InfoBox::Item->new(
         'icon_url' => 'https://example.com/foo.png',
         'text' => Data::Text::Simple->new(
                 'text' => 'Funny item'
         ),
         'url' => 'https://skim.cz',
 );

 # Print out.
 print "Icon URL: ".$obj->icon_url."\n";
 print "Text: ".$obj->text->text."\n";
 print "URL: ".$obj->url."\n";

 # Output:
 # Icon URL: https://example.com/foo.png
 # Text: Funny item
 # URL: https://skim.cz

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>,
L<Mo::utils::URI>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-InfoBox>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
