package Catalyst::Helper::View::Email::Template;

use strict;
our $VERSION = '0.36';
$VERSION = eval $VERSION;

=head1 NAME

Catalyst::Helper::View::Email::Template - Helper for Templated Email Views

=head1 SYNOPSIS

    $ script/myapp_create.pl view Email::Template Email::Template

=head1 DESCRIPTION

Helper for Template-based Email Views.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

L<Catalyst::View::Email>

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

J. Shirley C<jshirley@gmail.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::Email::Template';

__PACKAGE__->config(
    stash_key       => 'email',
    template_prefix => ''
);

=head1 NAME

[% class %] - Templated Email View for [% app %]

=head1 DESCRIPTION

View for sending template-generated email from [% app %]. 

=head1 AUTHOR

[% author %]

=head1 SEE ALSO

L<[% app %]>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
