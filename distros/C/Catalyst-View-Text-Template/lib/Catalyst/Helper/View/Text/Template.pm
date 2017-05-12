use strict;
package Catalyst::Helper::View::Text::Template;
{
  $Catalyst::Helper::View::Text::Template::VERSION = '0.011';
}
# ABSTRACT: Helper for Text::Template Views


sub mk_compclass {
  my ($self, $helper) = @_;
  my $file = $helper->{file};
  $helper->render_file('compclass', $file);
}


1;

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Helper::View::Text::Template - Helper for Text::Template Views

=head1 VERSION

version 0.011

=head1 SYNOPSIS

  script/create.pl view NameOfMyView Text::Template 

=head1 DESCRIPTION

Helper for Text::Template Views.

=head1 METHODS

=head2 mk_compclass

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>, L<Catalyst::View::Text::Template>

=head1 AUTHORS

=over 4

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Dean Hamstead <dean@fragfest.com.au>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

__compclass__
package [% class %];

use Moose;
use namespace::autoclean;

extends 'Catalyst::View::Text::Template';

__PACKAGE__->config(TEMPLATE_EXTENSION => '.tmpl');

=head1 NAME

[% class %] - Catalyst Text::Template View for [% app %]

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Catalyst Text::Template View for [% app %]

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
