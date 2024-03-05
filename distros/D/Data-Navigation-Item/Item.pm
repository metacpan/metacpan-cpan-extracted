package Data::Navigation::Item;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils 0.09 qw(check_length check_number check_required);
use Mo::utils::CSS 0.02 qw(check_css_class);
use Mo::utils::URI qw(check_location);

our $VERSION = 0.01;

has class => (
	is => 'ro',
);

has desc => (
	is => 'ro',
);

has id => (
	is => 'ro',
);

has image => (
	is => 'ro',
);

has location => (
	is => 'ro',
);

has title => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check class.
	check_css_class($self, 'class');

	# Check desc.
	check_length($self, 'desc', 1000);

	# Check id.
	check_number($self, 'id');

	# Check image.
	# XXX check image.
	check_location($self, 'image');

	# Check location.
	check_location($self, 'location');

	# Check title.
	check_required($self, 'title');
	check_length($self, 'title', 100);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::Navigation::Item - Data object for navigation item.

=head1 SYNOPSIS

 use Data::Navigation::Item;

 my $obj = Data::Navigation::Item->new(%params);
 my $class = $obj->class;
 my $desc = $obj->desc;
 my $id = $obj->id;
 my $image = $obj->image;
 my $location = $obj->location;
 my $title = $obj->title;

=head1 METHODS

=head2 C<new>

 my $obj = Data::Navigation::Item->new(%params);

Constructor.

=over 8

=item * C<class>

Navigation item class.

Value type is same as CSS class.

It's optional.

Default value is undef.

=item * C<desc>

Navigation item description.

Maximum length is 1000 characters.

Default value is undef.

=item * C<id>

Navigation item id. It's number.

It's optional.

Default value is undef.

=item * C<image>

Navigation item image location.

It's optional.

Default value is undef.

=item * C<location>

Navigation item location. Link to content.

It's optional.

Default value is undef.

=item * C<title>

Navigation item title.

Maximum length is 100 characters.

It's required.

Default value is undef.

=back

Returns instance of object.

=head2 C<class>

 my $class = $obj->class;

Get navigation item class.

Returns string.

=head2 C<desc>

 my $desc = $obj->desc;

Get navigation item description.

Returns string.

=head2 C<id>

 my $id = $obj->id;

Get navigation item id.

Returns number.

=head2 C<image>

 my $image = $obj->image;

Get navigation item image location.

Returns string.

=head2 C<location>

 my $location = $obj->location;

=head2 C<title>

 my $title = $obj->title;

Get navigation item title;

Returns string.

=head1 ERRORS

 new():
         From Mo::utils:
                 Parameter 'class' has bad CSS class name.
                         Value: %s
                 Parameter 'class' has bad CSS class name (number on begin).
                         Value: %s
                 Parameter 'desc' has length greater than '1000'.
                         Value: %s
                 Parameter 'id' must be a number.
                         Value: %s
                 Parameter 'image' doesn't contain valid location.
                         Value: %s
                 Parameter 'location' doesn't contain valid location.
                         Value: %s
                 Parameter 'title' has length greater than '100'.
                         Value: %s
                 Parameter 'title' is required.

=head1 EXAMPLE

=for comment filename=nav_item.pl

 use strict;
 use warnings;

 use Data::Navigation::Item;

 my $obj = Data::Navigation::Item->new(
         'class' => 'nav-item',
         'desc' => 'This is description',
         'id' => 1,
         'image' => '/img/foo.png',
         'location' => '/title',
         'title' => 'Title',
 );

 # Print out.
 print 'Class: '.$obj->class."\n";
 print 'Description: '.$obj->desc."\n";
 print 'Id: '.$obj->id."\n";
 print 'Image: '.$obj->image."\n";
 print 'Location: '.$obj->location."\n";
 print 'Title: '.$obj->title."\n";

 # Output:
 # Class: nav-item
 # Description: This is description
 # Id: 1
 # Image: /img/foo.png
 # Location: /title
 # Title: Title

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>,
L<Mo::utils::CSS>,
L<Mo::utils::URI>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-Navigation-Item>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
