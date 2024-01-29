package Data::HTML::Element::A;

use strict;
use warnings;

use Error::Pure qw(err);
use List::Util 1.33 qw(none);
use Mo qw(build is);
use Mo::utils qw(check_array);
use Mo::utils::CSS qw(check_css_class);
use Readonly;

Readonly::Array our @DATA_TYPES => qw(plain tags);

our $VERSION = 0.09;

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

has url => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check CSS class.
	check_css_class($self, 'css_class');

	# Check data type.
	if (! defined $self->{'data_type'}) {
		$self->{'data_type'} = 'plain';
	}
	if (none { $self->{'data_type'} eq $_ } @DATA_TYPES) {
		err "Parameter 'data_type' has bad value.";
	}

	# Check data based on type.
	check_array($self, 'data');
	foreach my $data_item (@{$self->{'data'}}) {
		# Plain mode
		if ($self->{'data_type'} eq 'plain') {
			if (ref $data_item ne '') {
				err "Parameter 'data' in 'plain' mode must contain ".
					'reference to array with scalars.';
			}
		# Tags mode.
		} else {
			if (ref $data_item ne 'ARRAY') {
				err "Parameter 'data' in 'tags' mode must contain ".
					"reference to array with references ".
					'to array with Tags structure.';
			}
		}
	}

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
 my $url = $obj->url;

=head1 METHODS

=head2 C<new>

 my $obj = Data::HTML::Element::A->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<css_class>

Form CSS class.

Default value is undef.

=item * C<data>

Data content. It's reference to array.

Data type of data is described in 'data_type' parameter.

Default value is [].

=item * C<data_type>

Data type for content.

Possible value are: plain tags

The 'plain' content are string(s).
The 'tags' content is structure described in L<Tags>.

Default value is 'plain'.

=item * C<url>

URL of link.

Default value is undef.

=back

=head2 C<css_class>

 my $css_class = $obj->css_class;

Get CSS class for form.

Returns string.

=head2 C<data>

 my $data = $obj->data;

Get data inside button element.

Returns reference to array.

=head2 C<data_type>

 my $data_type = $obj->data_type;

Get button data type.

Returns string.

=head2 C<url>

 my $url = $obj->url;

Get URL of link.

Returns string.

=head1 ERRORS

 new():
         Parameter 'data' must be a array.
                Value: %s
                Reference: %s
         Parameter 'data' in 'plain' mode must contain reference to array with scalars.
         Parameter 'data' in 'tags' mode must contain reference to array with references to array with Tags structure.
         Parameter 'data_type' has bad value.

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

L<Error::Pure>,
L<List::Util>,
L<Mo>,
L<Mo::utils>,
L<Mo::utils::CSS>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-HTML-Element>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.09

=cut
