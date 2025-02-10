package Data::InfoBox::Item;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils 0.08 qw(check_isa check_length check_required);
use Mo::utils::URI 0.02 qw(check_location check_uri);

our $VERSION = 0.03;

has icon => (
	is => 'ro',
);

has icon_url => (
	is => 'ro',
);

has icon_char => (
	is => 'ro',
);

has text => (
	is => 'ro',
);

has uri => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check icon.
	check_isa($self, 'icon', 'Data::Icon');

	# Check icon_url.
	check_location($self, 'icon_url');
	# TODO Check image

	# Check icon_char.
	check_length($self, 'icon_char', 1);

	# Check text.
	check_required($self, 'text');
	check_isa($self, 'text', 'Data::Text::Simple');

	# Check URI.
	check_uri($self, 'uri');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::InfoBox::Item - Data object for info box item.

=head1 SYNOPSIS

 use Data::InfoBox::Item;

 my $obj = Data::InfoBox::Item->new(%params);
 my $icon = $obj->icon;
 my $icon_url = $obj->icon_url;
 my $icon_char = $obj->icon_char;
 my $text = $obj->text;
 my $uri = $obj->uri;

=head1 METHODS

=head2 C<new>

 my $obj = Data::InfoBox->new(%params);

Constructor.

=over 8

=item * C<icon>

Icon for item.

It's L<Data::Icon> object.

It's optional.

=item * C<icon_url>

I<Parameter will be deprecated. Use 'icon' parameter.>

Icon URL.

It's optional.

=item * C<icon_char>

I<Parameter will be deprecated. Use 'icon' parameter.>

Icon character. Could be UTF-8 character. Only one character.

It's optional.

=item * C<text>

Item text. Must me a L<Data::Text::Simple> object.

It's required.

=item * C<uri>

URI of item.

It's optional.

=back

Returns instance of object.

=head2 C<icon>

 my $icon = $obj->icon;

Get icon.

Returns L<Data::Icon> instance.

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

=head2 C<uri>

 my $uri = $obj->uri;

Get URI of item.

Returns string.

=head1 ERRORS

 new():
         From Mo::utils:
                 Parameter 'icon' must be a 'Data::Icon' object.
                         Value: %s
                         Reference: %s
                 Parameter 'icon_char' has length greater than '1'.
                         Value: %s
                 Parameter 'text' is required.
                 Parameter 'text' must be a 'Data::Text::Simple' object.
                         Value: %s
                         Reference: %s
         From Mo::utils::URI::check_location():
                 Parameter 'icon_url' doesn't contain valid location.
                         Value: %s
         From Mo::utils::URI::check_uri():
                 Parameter 'uri' doesn't contain valid URI.
                         Value: %s

=head1 EXAMPLE

=for comment filename=create_infobox_item_object_and_print.pl

 use strict;
 use warnings;

 use Data::Icon;
 use Data::InfoBox::Item;
 use Data::Text::Simple;

 my $obj = Data::InfoBox::Item->new(
         'icon' => Data::Icon->new(
                 'url' => 'https://example.com/foo.png',
         ),
         'text' => Data::Text::Simple->new(
                 'text' => 'Funny item'
         ),
         'uri' => 'https://skim.cz',
 );

 # Print out.
 print "Icon URL: ".$obj->icon->url."\n";
 print "Text: ".$obj->text->text."\n";
 print "URI: ".$obj->uri."\n";

 # Output:
 # Icon URL: https://example.com/foo.png
 # Text: Funny item
 # URI: https://skim.cz

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>,
L<Mo::utils::URI>.

=head1 SEE ALSO

=over

=item L<Data::InfoBox>

Data object for info box.

=item L<Test::Shared::Fixture::Data::InfoBox::Street>

Street info box fixture.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-InfoBox>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
