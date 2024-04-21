package Data::Image;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils qw(check_code check_isa check_length check_number check_required);
use Mo::utils::URI qw(check_location);

our $VERSION = 0.04;

has author => (
	is => 'ro',
);

has comment => (
	is => 'ro',
);

has dt_created => (
	is => 'ro',
);

has height => (
	is => 'ro',
);

has id => (
	is => 'ro',
);

has size => (
	is => 'ro',
);

has url => (
	is => 'ro',
);

has url_cb => (
	is => 'ro',
);

has width => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check author.
	check_length($self, 'author', 255);

	# Check comment.
	check_length($self, 'comment', 1000);

	# Check date created.
	check_isa($self, 'dt_created', 'DateTime');

	# Check height.
	check_number($self, 'height');

	# Check id.
	check_number($self, 'id');

	# Check size.
	check_number($self, 'size');

	# Check URL.
	check_length($self, 'url', 255);
	check_location($self, 'url');

	# Check URL callback.
	check_code($self, 'url_cb');

	# Check width.
	check_number($self, 'width');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::Image - Data object for image.

=head1 SYNOPSIS

 use Data::Image;

 my $obj = Data::Image->new(%params);
 my $author = $obj->author;
 my $comment = $obj->comment;
 my $dt_created = $obj->dt_created;
 my $height = $obj->height;
 my $id = $obj->id;
 my $size = $obj->size;
 my $url = $obj->url;
 my $url_cb = $obj->url_cb;
 my $width = $obj->width;

=head1 METHODS

=head2 C<new>

 my $obj = Data::Image->new(%params);

Constructor.

=over 8

=item * C<author>

Image author.

It's optional.

Default value is undef.

=item * C<comment>

Image comment.

It's optional.

Default value is undef.

=item * C<dt_created>

Date and time the image was created.

Value must be L<DateTime> object.

It's optional.

=item * C<height>

Image height.

It's optional.

Default value is undef.

=item * C<id>

Image id.

It's optional.

Default value is undef.

=item * C<size>

Image size.

It's optional.

Default value is undef.

=item * C<url>

URL (location) of image.

It's optional.

Default value is undef.

=item * C<url_cb>

URL callback. To get URL from code.

It's optional.

Default value is undef.

=item * C<width>

Image width.

It's optional.

Default value is undef.

=back

Returns instance of object.

=head2 C<author>

 my $author = $obj->author;

Get image author.

Returns string.

=head2 C<comment>

 my $comment = $obj->comment;

Get image comment.

Returns string.

=head2 C<dt_created>

 my $dt_created = $obj->dt_created;

Get date and time the image was created.

Returns L<DateTime> object.

=head2 C<height>

 my $height = $obj->height;

Get image height.

Returns number.

=head2 C<id>

 my $id = $obj->id;

Get image id.

Returns number.

=head2 C<size>

 my $size = $obj->size;

Get image size.

Returns number.

=head2 C<url>

 my $url = $obj->url;

Get URL (location) of image.

Returns string.

=head2 C<url_cb>

 my $url_cb = $obj->url_cb;

Get URL callback.

Returns code.

=head2 C<width>

 my $width = $obj->width;

Get image width.

Returns number.

=head1 ERRORS

 new():
         From Mo::utils:
                 Parameter 'author' has length greater than '255'.
                         Value: %s
                 Parameter 'comment' has length greater than '1000'.
                         Value: %s
                 Parameter 'dt_created' must be a 'DateTime' object.
                         Value: %s
                         Reference: %s
                 Parameter 'height' must a number.
                         Value: %s
                 Parameter 'id' must a number.
                         Value: %s
                 Parameter 'size' must a number.
                         Value: %s
                 Parameter 'url' has length greater than '255'.
                         Value: %s
                 Parameter 'url_cb' must be a code.
                         Value: %s
                 Parameter 'width' must a number.
                         Value: %s

         From Mo::utils::URI:
                 Parameter 'url' doesn't contain valid location.
                         Value: %s

=head1 EXAMPLE

=for comment filename=create_and_print_image.pl

 use strict;
 use warnings;

 use Data::Image;
 use DateTime;

 my $obj = Data::Image->new(
         'author' => 'Zuzana Zonova',
         'comment' => 'Michal from Czechia',
         'dt_created' => DateTime->new(
                 'day' => 1,
                 'month' => 1,
                 'year' => 2022,
         ),
         'height' => 2730,
         'size' => 1040304,
         'url' => 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
         'width' => 4096,
 );

 # Print out.
 print 'Author: '.$obj->author."\n";
 print 'Comment: '.$obj->comment."\n";
 print 'Height: '.$obj->height."\n";
 print 'Size: '.$obj->size."\n";
 print 'URL: '.$obj->url."\n";
 print 'Width: '.$obj->width."\n";
 print 'Date and time the image was created: '.$obj->dt_created."\n";

 # Output:
 # Author: Zuzana Zonova
 # Comment: Michal from Czechia
 # Height: 2730
 # Size: 1040304
 # URL: https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg
 # Width: 4096
 # Date and time the photo was created: 2022-01-01T00:00:00

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>,
L<Mo::utils::URI>.

=head1 SEE ALSO

=over

=item L<Data::Commons::Image>

Data object for Wikimedia Commons image.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-Image>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
