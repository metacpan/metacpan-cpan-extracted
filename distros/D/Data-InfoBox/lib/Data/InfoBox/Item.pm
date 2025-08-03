package Data::InfoBox::Item;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils 0.08 qw(check_isa check_required);
use Mo::utils::URI 0.02 qw(check_uri);

our $VERSION = 0.07;

has icon => (
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

=head1 DESCRIPTION

Data object for one common item in info box. Item could contains icon, text and
URL.

=head1 SYNOPSIS

 use Data::InfoBox::Item;

 my $obj = Data::InfoBox::Item->new(%params);
 my $icon = $obj->icon;
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
                 Parameter 'text' is required.
                 Parameter 'text' must be a 'Data::Text::Simple' object.
                         Value: %s
                         Reference: %s
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

0.07

=cut
