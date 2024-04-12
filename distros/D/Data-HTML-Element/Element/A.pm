package Data::HTML::Element::A;

use strict;
use warnings;

use Data::HTML::Element::Utils qw(check_data check_data_type);
use Error::Pure qw(err);
use List::Util 1.33 qw(none);
use Mo qw(build is);
use Mo::utils qw(check_array check_strings);
use Mo::utils::CSS qw(check_css_class);
use Readonly;

Readonly::Array our @TARGETS => qw(_blank _parent _self _top);

our $VERSION = 0.13;

has css_class => (
	is => 'ro',
);

has data => (
	default => [],
	ro => 1,
);

has data_type => (
	ro => 1,
);

has id => (
	ro => 1,
);

has target => (
	ro => 1,
);

has url => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check CSS class.
	check_css_class($self, 'css_class');

	# Check data type.
	check_data_type($self);

	# Check data based on type.
	check_data($self);

	# Check target.
	check_strings($self, 'target', \@TARGETS);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::HTML::Element::A - Data object for HTML a element.

=head1 SYNOPSIS

 use Data::HTML::Element::A;

 my $obj = Data::HTML::Element::A->new(%params);
 my $css_class = $obj->css_class;
 my $data = $obj->data;
 my $data_type = $obj->data_type;
 my $id = $obj->id;
 my $target = $obj->target;
 my $url = $obj->url;

=head1 METHODS

=head2 C<new>

 my $obj = Data::HTML::Element::A->new(%params);

Constructor.

=over 8

=item * C<css_class>

A element CSS class.

Default value is undef.

=item * C<data>

Data content. It's reference to array.

Data type of data is described in 'data_type' parameter.

Default value is [].

=item * C<data_type>

Data type for content.

Possible value are: cb plain tags

The 'cb' content is code reference.
The 'plain' content are string(s).
The 'tags' content is structure described in L<Tags>.

Default value is 'plain'.

=item * C<id>

Id.

Default value is undef.

=item * C<target>

Target.

Possible values are:

=over

=item * C<_blank>

=item * C<_parent>

=item * C<_self>

=item * C<_top>

=back

Default value is undef.

=item * C<url>

URL of link.

Default value is undef.

=back

Returns instance of object.

=head2 C<css_class>

 my $css_class = $obj->css_class;

Get CSS class for A element.

Returns string.

=head2 C<data>

 my $data = $obj->data;

Get data inside button element.

Returns reference to array.

=head2 C<data_type>

 my $data_type = $obj->data_type;

Get button data type.

Returns string.

=head2 C<id>

 my $id = $obj->id;

Get element id.

Returns string.

=head2 C<url>

 my $url = $obj->url;

Get URL of link.

Returns string.

=head1 ERRORS

 new():
         Parameter 'css_class' has bad CSS class name.
                 Value: %s
         Parameter 'css_class' has bad CSS class name (number on begin).
                 Value: %s
         Parameter 'data' must be a array.
                Value: %s
                Reference: %s
         Parameter 'data' in 'plain' mode must contain reference to array with scalars.
         Parameter 'data' in 'tags' mode must contain reference to array with references to array with Tags structure.
         Parameter 'data_type' has bad value.
         Parameter 'target' must have strings definition.
         Parameter 'target' must have right string definition.
         Parameter 'target' must be one of defined strings.
                 String: %s
                 Possible strings: %s

=head1 EXAMPLE1

=for comment filename=a.pl

 use strict;
 use warnings;

 use Data::HTML::Element::A;

 my $obj = Data::HTML::Element::A->new(
         'css_class' => 'link',
         'data' => ['Michal Josef Spacek homepage'],
         'url' => 'https://skim.cz',
 );

 # Print out.
 print 'CSS class: '.$obj->css_class."\n";
 print 'Data: '.(join '', @{$obj->data})."\n";
 print 'Data type: '.$obj->data_type."\n";
 print 'URL: '.$obj->url."\n";

 # Output:
 # CSS class: link
 # Data: Michal Josef Spacek homepage
 # Data type: plain
 # URL: https://skim.cz

=head1 EXAMPLE2

=for comment filename=a_tags.pl

 use strict;
 use warnings;

 use Data::HTML::Element::A;
 use Tags::Output::Raw;

 my $obj = Data::HTML::Element::A->new(
         'css_class' => 'link',
         # Tags(3pm) structure.
         'data' => [
                 ['b', 'span'],
                 ['a', 'class', 'span-link'],
                 ['d', 'Link'],
                 ['e', 'span'],
         ],
         'data_type' => 'tags',
         'url' => 'https://skim.cz',
 );

 my $tags = Tags::Output::Raw->new;

 # Serialize data to output.
 $tags->put(@{$obj->data});
 my $data = $tags->flush(1);

 # Print out.
 print 'CSS class: '.$obj->css_class."\n";
 print 'Data (serialized): '.$data."\n";
 print 'Data type: '.$obj->data_type."\n";
 print 'URL: '.$obj->url."\n";

 # Output:
 # CSS class: link
 # Data (serialized): <span class="span-link">Link</span>
 # Data type: tags
 # URL: https://skim.cz

=head1 DEPENDENCIES

L<Data::HTML::Element::Utils>,
L<Error::Pure>,
L<List::Util>,
L<Mo>,
L<Mo::utils>,
L<Mo::utils::CSS>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-HTML-Element>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.13

=cut
