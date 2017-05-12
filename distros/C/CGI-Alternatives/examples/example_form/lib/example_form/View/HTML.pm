package example_form::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
);

=head1 NAME

example_form::View::HTML - TT View for example_form

=head1 DESCRIPTION

TT View for example_form.

=head1 SEE ALSO

L<example_form>

=head1 AUTHOR

Lee Johnson

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
