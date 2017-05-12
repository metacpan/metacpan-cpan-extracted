package Catalyst::Helper::View::Email;

our $VERSION = '0.36';
$VERSION = eval $VERSION;

use strict;

=head1 NAME

Catalyst::Helper::View::Email - Helper for Email Views

=head1 SYNOPSIS

    $ script/myapp_create.pl view Email Email

=head1 DESCRIPTION

Helper for Email Views.

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
use base 'Catalyst::View::Email';

__PACKAGE__->config(
    stash_key => 'email'
);

=head1 NAME

[% class %] - Email View for [% app %]

=head1 DESCRIPTION

View for sending email from [% app %]. 

=head1 AUTHOR

[% author %]

=head1 SEE ALSO

L<[% app %]>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
