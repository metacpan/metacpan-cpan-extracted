package CXC::Form::Tiny::Plugin::OptArgs2::Class;

# ABSTRACT: Class role for OptArgs2

use v5.20;

use warnings;

our $VERSION = '0.04';

use Hash::Fold ();

use Moo::Role;
use experimental 'signatures', 'postderef';

use namespace::clean;

my $folder = Hash::Fold->new( delimiter => chr( 0 ) );









sub optargs ( $self ) {
    return $self->form_meta->optargs;
}










sub set_input_from_optargs ( $self, $optargs ) {

    # the options hash coming from OptArgs is a flat (single level) hash.
    my %flat = $optargs->%*;

    # translate the OptArgs names into that required by the Form::Tiny structure
    $self->form_meta->rename_options( \%flat );

    # and now inflate the flat hash into the nested structure.
    $self->set_input( $folder->unfold( \%flat ) );
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

version 0.04

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
