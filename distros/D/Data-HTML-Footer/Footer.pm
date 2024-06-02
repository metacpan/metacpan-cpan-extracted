package Data::HTML::Footer;

use strict;
use warnings;

use Mo qw(build default is);
use Mo::utils::CSS 0.07 qw(check_css_unit);
use Mo::utils::URI qw(check_location);

our $VERSION = 0.02;

has author => (
	is => 'ro',
);

has author_url => (
	is => 'ro',
);

has copyright_years => (
	is => 'ro',
);

has height => (
	is => 'ro',
);

has version => (
	is => 'ro',
);

has version_url => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check author_url.
	check_location($self, 'author_url');

	# Check copyright years.
	# TODO

	# Check height.
	check_css_unit($self, 'height');

	# Check version_url.
	check_location($self, 'version_url');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::HTML::Footer - Data object for HTML footer.

=head1 SYNOPSIS

 use Data::HTML::Footer;

 my $obj = Data::HTML::Footer->new(%params);
 my $author = $obj->author;
 my $author_url = $obj->author_url;
 my $copyright_years = $obj->copyright_years;
 my $height = $obj->height;
 my $version = $obj->version;
 my $version_url = $obj->version_url;

=head1 METHODS

=head2 C<new>

 my $obj = Data::HTML::Footer->new(%params);

Constructor.

=over 8

=item * C<author>

Author to present in footer.

It's optional.

Default value is undef.

=item * C<author_url>

Author absolute or relative URL.

It's optional.

Default value is undef.

=item * C<copyright_years>

Copyright years.

It's optional.

Default value is undef.

=item * C<version>

Version of application for present in footer.

It's optional.

Default value is undef.

=item * C<version_url>

Version absolute or relative URL.

It's optional.

Default value is undef.

=back

Returns instance of object.

=head2 C<author>

 my $author = $obj->author;

Get author string.

Returns string.

=head2 C<athor_url>

 my $author_url = $obj->author_url;

Get author URL.

Returns string.

=head2 C<copyright_years>

 my $copyright_years = $obj->copyright_years;

Get copyright years.

Returns string.

=head2 C<height>

 my $height = $obj->height;

Get height of HTML footer.

Returns CSS unit.

=head2 C<version>

 my $version = $obj->version;

Get version of application.

Returns string.

=head2 C<version_url>

 my $version_url = $obj->version_url;

Get version URL.

Returns string.

=head1 ERRORS

 new():
         From Mo::utils::CSS::check_css_unit():
                 Parameter 'height' contain bad unit.
                         Unit: %s
                         Value: %s
                 Parameter 'height' doesn't contain unit name.
                         Value: %s
                 Parameter 'height' doesn't contain unit number.
                         Value: %s
         From Mo::utils::URI::check_location():
                 Parameter 'author_url' doesn't contain valid location.
                         Value: %s
                 Parameter 'version_url' doesn't contain valid location.
                         Value: %s

=head1 EXAMPLE1

=for comment filename=footer.pl

 use strict;
 use warnings;

 use Data::HTML::Footer;

 my $obj = Data::HTML::Footer->new(
         'author' => 'John',
         'author_url' => 'https://example.com',
         'copyright_years' => '2023-2024',
         'height' => '40px',
         'version' => 0.07,
         'version_url' => '/changes',
 );

 # Print out.
 print 'Author: '.$obj->author."\n";
 print 'Author URL: '.$obj->author_url."\n";
 print 'Copyright years: '.$obj->copyright_years."\n";
 print 'Footer height: '.$obj->height."\n";
 print 'Version: '.$obj->version."\n";
 print 'Version URL: '.$obj->version_url."\n";

 # Output:
 # Author: John
 # Author URL: https://example.com
 # Copyright years: 2023-2024
 # Footer height: 40px
 # Version: 0.07
 # Version URL: /changes

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils::CSS>,
L<Mo::utils::URI>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-HTML-Footer>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

cut
