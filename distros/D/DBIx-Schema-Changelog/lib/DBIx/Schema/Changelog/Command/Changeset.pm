package DBIx::Schema::Changelog::Command::Changeset;

=head1 NAME

DBIx::Schema::Changelog::Command::Changeset - Create a new changeset project from template for DBIx::Schema::Changelog!

=head1 VERSION

Version 0.9.0


=cut

our $VERSION = '0.9.0';

use strict;
use warnings FATAL => 'all';
use Moose;
use File::Path qw( mkpath );
use MooseX::Types::Moose qw(Str);
use MooseX::HasDefaults::RO;
use MooseX::Types::LoadableClass qw(LoadableClass);

with 'DBIx::Schema::Changelog::Command::Base';

has dir => (
    isa      => Str,
    required => 1,
);

has file_type => (
    isa     => Str,
    default => 'Yaml'
);

has loader_class => (
    isa     => LoadableClass,
    lazy    => 1,
    default => sub { 'DBIx::Schema::Changelog::File::' . shift->file_type(); }
);

has loader => (
    is      => 'ro',
    does    => 'DBIx::Schema::Changelog::Role::File',
    lazy    => 1,
    default => sub { shift->loader_class()->new(); }
);

=head1 SUBROUTINES/METHODS

=head2 make

=cut

sub make {
    my ($self) = @_;
    mkpath( File::Spec->catfile( $self->dir(), 'changelog' ), 0755 );
    _write_file(
        File::Spec->catfile( $self->dir(), 'changelog', 'changelog' )
            . $self->loader()->ending(),
        _replace_spare( $self->loader()->tpl_main(), [] )
    );
    _write_file(
        File::Spec->catfile( $self->dir(), 'changelog', 'changelog-01' )
            . $self->loader()->ending(),
        _replace_spare( $self->loader()->tpl_sub(), [] )
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

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
