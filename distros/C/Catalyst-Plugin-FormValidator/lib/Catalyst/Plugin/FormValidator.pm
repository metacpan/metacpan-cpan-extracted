package Catalyst::Plugin::FormValidator;

use strict;
use MRO::Compat;
use Data::FormValidator;

our $VERSION = '0.094';
$VERSION = eval $VERSION;

=head2 prepare

Override Catalyst's prepare

=cut

sub prepare {
    my $c = shift;
    $c = $c->maybe::next::method(@_);
    $c->{form} = Data::FormValidator->check( $c->request->parameters, {} );
    return $c;
}


=head2 form

$c->form object

=cut 

sub form {
    my $c = shift;
    if ( $_[0] ) {
        my $form = $_[1] ? {@_} : $_[0];
        $c->{form} =
          Data::FormValidator->check( $c->request->parameters, $form );
    }
    return $c->{form};
}
=head1 NAME

Catalyst::Plugin::FormValidator - Data::FormValidator
plugin for Catalyst.

=head1 SYNOPSIS

    use Catalyst 'FormValidator';

    $c->form( optional => ['rest'] );
    print $c->form->valid('rest');


Note that not only is this plugin disrecommended (as it takes over the global
C<< $c->form >> method, rather than being applyable in only part of your
application), but L<Data::FormValidator> itself is not recommended for use.

=head1 DESCRIPTION

This plugin uses L<Data::FormValidator> to validate and set up form data
from your request parameters. It's a quite thin wrapper around that
module, so most of the relevant information can be found there.

=head2 EXTENDED METHODS

=head2 METHODS

=head3 form

Merge values with FormValidator.

    $c->form( required => ['yada'] );

Returns a L<Data::FormValidator::Results> object.

    $c->form->valid('rest');

The actual parameters sent to $c->form are the same as the profile in
L<Data::FormValidator>'s check function.

=cut

=head1 SEE ALSO

L<Catalyst>, L<Data::FormValidator>

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>

=head1 CONTRIBUTORS

Devin Austin C<(dhoss@cpan.org)>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
