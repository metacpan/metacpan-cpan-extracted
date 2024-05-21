package Data::HTML::Element;

use strict;
use warnings;

our $VERSION = 0.17;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::HTML::Element - Data objects for HTML elements.

=head1 DESCRIPTION

Collection of immutable data objects for HTML elements. All methods should be related to
main element with exception with inner content defined via 'data' method.

Intent behind data objects is control of information inside it.

This data objects are used in L<Tags::HTML::Element> helpers and in other high
level objects in L<Tags::HTML> namespace.

=head1 SEE ALSO

=over

=item L<Data::HTML::Element::A>

Data object for HTML a element.

=item L<Data::HTML::Element::Button>

Data object for HTML button element.

=item L<Data::HTML::Element::Form>

Data object for HTML form element.

=item L<Data::HTML::Element::Input>

Data object for HTML input element.

=item L<Data::HTML::Element::Option>

Data object for HTML option element.

=item L<Data::HTML::Element::Select>

Data object for HTML select element.

=item L<Data::HTML::Element::Textarea>

Data object for HTML textarea element.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-HTML-Element>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.17

=cut
