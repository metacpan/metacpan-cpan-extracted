package DBIx::Schema::Changelog::Changeset;

=head1 NAME

DBIx::Schema::Changelog::Changeset - Handles action types.

=head1 VERSION

Version 0.9.0


=cut

our $VERSION = '0.9.0';

use utf8;
use strict;
use warnings;
use Moose;
use MooseX::HasDefaults::RO;
use DBIx::Schema::Changelog::Action::Functions;
use DBIx::Schema::Changelog::Action::Entries;

has driver => ( required => 1 );
has dbh    => ( required => 1 );

has actions => (
    lazy    => 1,
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Actions->new(
            driver => $self->driver(),
            dbh    => $self->dbh(),
        );
    },
);

=head1 SUBROUTINES/METHODS

=over 4

=item handle

Handles different changeset commands

=cut

sub handle {
    my ( $self, $entries ) = @_;
    my $actions = $self->actions;
    foreach (@$entries) {

        # table actions
        $actions->tables->add($_)   if ( $_->{type} eq 'createtable' );
        $actions->tables->drop($_)  if ( $_->{type} eq 'droptable' );
        $actions->tables->alter($_) if ( $_->{type} eq 'altertable' );

        # index actions
        $actions->indices->add($_)   if ( $_->{type} eq 'createindex' );
        $actions->indices->alter($_) if ( $_->{type} eq 'alterindex' );
        $actions->indices->drop($_)  if ( $_->{type} eq 'dropindex' );

        # view actions
        $actions->views->add($_)   if ( $_->{type} eq 'createview' );
        $actions->views->alter($_) if ( $_->{type} eq 'alterview' );
        $actions->views->drop($_)  if ( $_->{type} eq 'dropview' );

        # sequence actions
        $actions->sequences->add($_)   if ( $_->{type} eq 'createsequence' );
        $actions->sequences->alter($_) if ( $_->{type} eq 'altersequence' );
        $actions->sequences->drop($_)  if ( $_->{type} eq 'dropsequence' );

        # function actions
        $actions->functions->add($_)   if ( $_->{type} eq 'createfunction' );
        $actions->functions->alter($_) if ( $_->{type} eq 'alterfunction' );
        $actions->functions->drop($_)  if ( $_->{type} eq 'dropfunction' );

        # function actions
        $actions->trigger->add($_)   if ( $_->{type} eq 'createtrigger' );
        $actions->trigger->alter($_) if ( $_->{type} eq 'altertrigger' );
        $actions->trigger->drop($_)  if ( $_->{type} eq 'droptrigger' );

        # function actions
        $actions->constraints->add($_)   if ( $_->{type} eq 'addconstraint' );
        $actions->constraints->alter($_) if ( $_->{type} eq 'alterconstraint' );
        $actions->constraints->drop($_)  if ( $_->{type} eq 'dropconstraint' );

        # manually called sql statement
        $actions->sql->add($_) if ( $_->{type} eq 'sql' );

        # entry statements
        $actions->entries->add($_) if ( $_->{type} eq 'insert' );
        $actions->entries->add($_) if ( $_->{type} eq 'set' );
        $actions->entries->add($_) if ( $_->{type} eq 'delete' );
    }
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;    # End of DBIx::Schema::Changelog::Changeset

__END__

=back

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mario Zieschang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, trade name, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANT ABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
