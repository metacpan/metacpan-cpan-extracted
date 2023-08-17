package CXC::Form::Tiny::Plugin::OptArgs2::Class;

# ABSTRACT: Class role for OptArgs2

use v5.20;

use warnings;

our $VERSION = '0.05';

use Hash::Fold ();

use Moo::Role;
use experimental 'signatures', 'postderef';

use namespace::clean;










sub optargs ( $self ) {
    return $self->form_meta->optargs;
}










sub set_input_from_optargs ( $self, $optargs ) {
    # inflate the flat hash into the nested structure and set the
    # form's input
    $self->set_input( $self->inflate_optargs( $optargs ) );
}












sub inflate_optargs ( $self, $optargs ) {
    return $self->form_meta->inflate_optargs( $optargs );
}


#
# This file is part of CXC-Form-Tiny-Plugin-OptArgs2
#
# This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory optargs

=head1 NAME

CXC::Form::Tiny::Plugin::OptArgs2::Class - Class role for OptArgs2

=head1 VERSION

version 0.05

=head1 DESCRIPTION

This role is applied to the L<Form::Tiny> class by the
L<CXC::Form::Tiny::Plugin::OptArgs2> plugin.

It provides methods which allow the form to access the options defined
by the DSL commands C<option> and C<argument> as well as to set the
form data from the output of the L<OptArgs2> C<optargs> or
C<class_optargs>.

=head1 METHODS

=head2 optargs

  \@optargs = $form->optargs;

Return an C<OptArgs2> compatible specification for the form fields

=head2 set_input_from_optargs

   $form->set_input_from_optargs( \%optargs );

Set the input form data from the output of L<OptArgs2>'s C<optargs> or
C<class_optargs> functions.

=head2 inflate_optargs

  \%options = $self->inflate( \%optargs );

Inflate the "flat" options hash returned by L<OptArgs2> into the full
hash required to initialize the form.  See
L<CXC::Form::Tiny::Plugin::OptArgs2::Meta/inflate_optargs> for more
information.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-form-tiny-plugin-optargs@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Form-Tiny-Plugin-OptArgs>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-form-tiny-plugin-optargs

and may be cloned from

  https://gitlab.com/djerius/cxc-form-tiny-plugin-optargs.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::Form::Tiny::Plugin::OptArgs2|CXC::Form::Tiny::Plugin::OptArgs2>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
