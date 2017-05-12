package DBIx::Schema::Changelog::File::Yaml;

=head1 NAME

DBIx::Schema::Changelog::File::Yaml - module for DBIx::Schema::Changelog::File to load changeset from YAML files.

=head1 VERSION

Version 0.9.0


=cut

our $VERSION = '0.9.0';

use strict;
use warnings FATAL => 'all';
use Moose;
use YAML::XS qw/LoadFile DumpFile/;

with 'DBIx::Schema::Changelog::Role::File';

has tpl_main => (
    isa     => 'Str',
    is      => 'ro',
    default => q~
---
templates:
    - name: tpl_std
      columns:
      - name: id
        type: integer
        notnull: 1
        primarykey: 1
        default: inc

changelogs: 
  - "01"~,
);

has tpl_sub => (
    isa     => 'Str',
    is      => 'ro',
    default => q~- id: 001.01-maz
  author: "Mario Zieschang"
  entries:
    - type: createtable
      name: 'client'
      columns:
        - tpl: 'tpl_std'
~,
);

has ending => (
    is      => 'ro',
    isa     => 'Str',
    default => '.yml',
);

=head1 SUBROUTINES/METHODS

=over 4

=item load

    Called to load defined Yaml files

=cut

sub load {
    my ( $self, $file ) = @_;

    $file = $file . $self->ending();

    open my $rfh, '<', $file or die "can't open config file: $file $!";
    print STDERR __PACKAGE__, ". Read changelog file '$file'. \n";

    return LoadFile($file);
}

=item write

Called to write defined Yaml files

=cut

sub write {
    my ( $self, $dir, $data ) = @_;
    my $file = $dir . $self->ending;
    print STDERR __PACKAGE__, ". Write changelog file '$file'. \n";
    return DumpFile( $file, $data );
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;    # End of DBIx::Schema::Changelog::File

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
