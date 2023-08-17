package Data::Commons::Image;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils qw(check_isa check_length check_number check_required);

extends 'Data::Image';

our $VERSION = 0.06;

has commons_name => (
	is => 'ro',
);

has dt_uploaded => (
	is => 'ro',
);

has license => (
	is => 'ro',
);

has page_id => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check commons_name.
	check_required($self, 'commons_name');
	check_length($self, 'commons_name', 255);

	# Check date uploaded.
	check_isa($self, 'dt_uploaded', 'DateTime');

	# Check page_id.
	check_number($self, 'page_id');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::Commons::Image - Data object for Wikimedia Commons image.

=head1 SYNOPSIS

 use Data::Commons::Image;

 my $obj = Data::Commons::Image->new(%params);
 my $author = $obj->author;
 my $comment = $obj->comment;
 my $commons_name = $obj->commons_name;
 my $dt_created = $obj->dt_created;
 my $dt_uploaded = $obj->dt_uploaded;
 my $height = $obj->height;
 my $id = $obj->id;
 my $license = $obj->license;
 my $page_id = $obj->page_id;
 my $size = $obj->size;
 my $url = $obj->url;
 my $url_cb = $obj->url_cb;
 my $width = $obj->width;

=head1 DESCRIPTION

Data object for Wikimedia Commons image. Inherits L<Data::Image> common object.

=head1 METHODS

=head2 C<new>

 my $obj = Data::Commons::Image->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<author>

Image author.
It's optional.
Default value is undef.

=item * C<comment>

Image comment.
It's optional.
Default value is undef.

=item * C<commons_name>

Image name in Wikimedia Commons.
It's required.

=item * C<dt_created>

Date and time the image was created.
Value must be L<DateTime> object.
It's optional.

=item * C<dt_uploaded>

Date and time the image was uploaded to Wikimedia Commons.
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

=item * C<license>

Image license.
It's optional.
Default value is undef.

=item * C<page_id>

Image page id on Wikimedia Commons.
It's used for structured data with 'M' prefix.
It's optional.
Default value is undef.

=item * C<size>

Image size.
It's optional.
Default value is undef.

=item * C<url>

URL of image.
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

=head2 C<author>

 my $author = $obj->author;

Get image author.

Returns string.

=head2 C<comment>

 my $comment = $obj->comment;

Get image comment.

Returns string.

=head2 C<commons_name>

 my $commons_name = $obj->commons_name;

Get image name in Wikimedia Commons.

Returns string.

=head2 C<dt_created>

 my $dt_created = $obj->dt_created;

Get date and time the image was created.

Returns L<DateTime> object.

=head2 C<dt_uploaded>

 my $dt_uploaded = $obj->dt_uploaded;

Get date and time the image was uploaded to Wikimedia Commons.

Returns L<DateTime> object.

=head2 C<height>

 my $height = $obj->height;

Get image height.

Returns number.

=head2 C<id>

 my $id = $obj->id;

Get image id.

Returns number.

=head2 C<license>

 my $license = $obj->license;

Get image license.

Returns string.

=head2 C<page_id>

 my $page_id = $obj->page_id;

Get image page id.

Returns number.

=head2 C<size>

 my $size = $obj->size;

Get image size.

Returns number.

=head2 C<url>

 my $url = $obj->url;

Get URL of image.

Returns string.

=head2 C<url_cb>

 my $url_cb = $obj->url_cb;

Get URL callback.

Returns code.

=head2 C<width>

 my $width = $obj->width;

Get image width.

Returns number.

 new():
         From Data::Image:
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
         Parameter 'commons_name' is required.
         Parameter 'commons_name' has length greater than '255'.
                 Value: %s
         Parameter 'dt_uploaded' must be a 'DateTime' object.
                 Value: %s
                 Reference: %s
         Parameter 'page_id' must a number.
                 Value: %s

=head1 EXAMPLE

=for comment filename=create_and_print_image.pl

 use strict;
 use warnings;

 use Data::Commons::Image;
 use DateTime;

 my $obj = Data::Commons::Image->new(
         'author' => 'Zuzana Zonova',
         'comment' => 'Michal from Czechia',
         'commons_name' => 'Michal_from_Czechia.jpg',
         'dt_created' => DateTime->new(
                 'day' => 1,
                 'month' => 1,
                 'year' => 2022,
         ),
         'dt_uploaded' => DateTime->new(
                 'day' => 14,
                 'month' => 7,
                 'year' => 2022,
         ),
         'height' => 2730,
         'license' => 'cc-by-sa-4.0',
         'page_id' => '95648152',
         'size' => 1040304,
         'url' => 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
         'width' => 4096,
 );

 # Print out.
 print 'Author: '.$obj->author."\n";
 print 'Comment: '.$obj->comment."\n";
 print 'Wikimedia Commons name: '.$obj->commons_name."\n";
 print 'Height: '.$obj->height."\n";
 print 'Size: '.$obj->size."\n";
 print 'URL: '.$obj->url."\n";
 print 'Width: '.$obj->width."\n";
 print 'License: '.$obj->license."\n";
 print 'Page id: '.$obj->page_id."\n";
 print 'Date and time the photo was created: '.$obj->dt_created."\n";
 print 'Date and time the photo was uploaded: '.$obj->dt_uploaded."\n";

 # Output:
 # Author: Zuzana Zonova
 # Comment: Michal from Czechia
 # Wikimedia Commons name: Michal_from_Czechia.jpg
 # Height: 2730
 # Size: 1040304
 # URL: https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg
 # Width: 4096
 # License: cc-by-sa-4.0
 # Page id: 95648152
 # Date and time the photo was created: 2022-01-01T00:00:00
 # Date and time the photo was uploaded: 2022-07-14T00:00:00

=head1 DEPENDENCIES

L<Data::Image>,
L<Mo>,
L<Mo::utils>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-Commons-Image>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.06

=cut
