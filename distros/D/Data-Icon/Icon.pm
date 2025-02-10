package Data::Icon;

use strict;
use warnings;

use Error::Pure qw(err);
use Mo qw(build is);
use Mo::utils 0.05 qw(check_length);
use Mo::utils::CSS 0.03 qw(check_css_color);
use Mo::utils::URI 0.02 qw(check_location);

our $VERSION = 0.02;

has alt => (
	is => 'ro',
);

has bg_color => (
	is => 'ro',
);

has char => (
	is => 'ro',
);

has color => (
	is => 'ro',
);

has url => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check alt.
	check_length($self, 'alt', 100);

	# Check bg_color.
	check_css_color($self, 'bg_color');

	# Check char.
	check_length($self, 'char', 1);

	# Check color.
	check_css_color($self, 'color');

	# Check url.
	check_location($self, 'url');
	# TODO Check image

	if (defined $self->{'char'} && defined $self->{'url'}) {
		err "Parameter 'url' is in conflict with parameter 'char'.";
	}

	if (defined $self->{'char'} && defined $self->{'alt'}) {
		err "Parameter 'char' don't need parameter 'alt'.";
	}

	if (defined $self->{'url'}) {
		if (defined $self->{'color'}) {
			err "Parameter 'url' don't need parameter 'color'.";
		}
		if (defined $self->{'bg_color'}) {
			err "Parameter 'url' don't need parameter 'bg_color'.";
		}
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::Icon - Data object for icon.

=head1 DESCRIPTION

Data object for description of icon. It could be defined as URL with alternate
text or as UTF-8 character with colors.

=head1 SYNOPSIS

 use Data::Icon;

 my $obj = Data::Icon->new(%params);
 my $alt = $obj->alt;
 my $bg_color = $obj->bg_color;
 my $char = $obj->char;
 my $color = $obj->color;
 my $url = $obj->url;

=head1 METHODS

=head2 C<new>

 my $obj = Data::Icon->new(%params);

Constructor.

=over 8

=item * C<alt>

Alternate text for image icon.

It's optional.

=item * C<bg_color>

Background color for UTF-8 character.

It's optional.

=item * C<char>

Icon character. Could be UTF-8 character. Only one character.

It's optional.

=item * C<color>

Character color.

It's optional.

=item * C<url>

Icon URL.

It's optional.

=back

Returns instance of object.

=head2 C<alt>

 my $alt = $obj->alt;

Get alternate text for image icon.

Returns string.

=head2 C<bg_color>

 my $bg_color = $obj->bg_color;

Get background color for UTF-8 character.

Returns string.

=head2 C<char>

 my $char = $obj->char;

Get icon character.

Returns string.

=head2 C<color>

 my $color = $obj->color;

Get character color.

Returns CSS color string.

=head2 C<url>

 my $url = $obj->url;

Get icon URL.

Returns string.

=head1 ERRORS

 new():
         Parameter 'char' don't need parameter 'alt'.
         Parameter 'url' don't need parameter 'bg_color'.
         Parameter 'url' don't need parameter 'color'.
         Parameter 'url' is in conflict with parameter 'char'.
         From Mo::utils:
                 Parameter 'alt' has length greater than '100'.
                         Value: %s
                 Parameter 'char' has length greater than '1'.
                         Value: %s
         From Mo::utils::CSS::check_css_color():
                 Parameter '%s' has bad color name.
                         Value: %s
                 Parameter '%s' has bad rgb color (bad hex number).
                         Value: %s
                 Parameter '%s' has bad rgb color (bad length).
                         Value: %s
         From Mo::utils::URI::check_location():
                 Parameter 'url' doesn't contain valid location.
                         Value: %s

=head1 EXAMPLE1

=for comment filename=create_image_icon_and_print.pl

 use strict;
 use warnings;

 use Data::Icon;

 my $obj = Data::Icon->new(
         'alt' => 'Foo icon',
         'url' => 'https://example.com/foo.png',
 );

 # Print out.
 print "Alternate text: ".$obj->alt."\n";
 print "Icon URL: ".$obj->url."\n";

 # Output:
 # Alternate text: Foo icon
 # Icon URL: https://example.com/foo.png

=head1 EXAMPLE2

=for comment filename=create_char_icon_and_print.pl

 use strict;
 use warnings;

 use Data::Icon;
 use Unicode::UTF8 qw(decode_utf8 encode_utf8);

 my $obj = Data::Icon->new(
         'bg_color' => 'grey',
         'char' => decode_utf8('†'),
         'color' => 'red',
 );

 # Print out.
 print "Character: ".encode_utf8($obj->char)."\n";
 print "CSS color: ".$obj->color."\n";
 print "CSS background color: ".$obj->bg_color."\n";

 # Output:
 # Character: †
 # CSS color: red
 # CSS background color: grey

=head1 DEPENDENCIES

L<Error::Pure>,
L<Mo>,
L<Mo::utils>,
L<Mo::utils::CSS>,
L<Mo::utils::URI>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-Icon>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
