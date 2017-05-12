package DBIx::Schema::Changelog::Read;

=head1 NAME

DBIx::Schema::Changelog::Read - Read existing db scheme.

=head1 VERSION

Version 0.9.0


=cut

our $VERSION = '0.9.0';

use utf8;
use strict;
use warnings FATAL => 'all';
use Hash::MD5 qw(sum);
use Moose;
use MooseX::HasDefaults::RO;
use MooseX::Types::Moose qw(ArrayRef Str Defined);
use MooseX::Types::LoadableClass qw(LoadableClass);

use DBIx::Schema::Changelog::Actions;
use DBIx::Schema::Changelog::Changeset;

=head1 ATTRIBUTES


=head2 insert_dblog

    Loaded DBIx::Schema::Changelog::Driver module.

=cut

has insert_dblog => (
    isa     => 'DBI::st',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->dbh()
          ->prepare( "INSERT INTO "
              . $self->db_changelog_table()
              . "(id, author, filename, md5sum, changelog) VALUES (?,?,?,?,?)" );
    },
);

=head2 db_changelog_table

    Loaded DBIx::Schema::Changelog::Driver module.

=cut

has db_changelog_table => ( isa => Str, default => 'databasechangelog' );

=head2 file_type

    Loaded DBIx::Schema::Changelog::Driver module.

=cut

has file_type => ( isa => Str, default => 'Yaml' );

=head2 driver

    Loaded DBIx::Schema::Changelog::Driver module.

=cut

has driver => ( required => 1, );

=head2 driver

    Connected dbh object.

=cut

has dbh => ( required => 1 );

=head2 tables

Connected dbh object.

=cut

has actions => (
    lazy    => 1,
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Actions->new(
            dbh    => $self->dbh,
            driver => $self->driver
        );
    },
);

has changeset => (
    lazy    => 1,
    isa     => 'DBIx::Schema::Changelog::Changeset',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Changeset->new(
            driver  => $self->driver,
            dbh     => $self->dbh,
            actions => $self->actions,
        );
    },
);

has loader_class => (
    isa     => LoadableClass,
    lazy    => 1,
    default => sub {
        'DBIx::Schema::Changelog::File::' . shift->file_type();
    }
);

has loader => (
    does    => 'DBIx::Schema::Changelog::Role::File',
    lazy    => 1,
    default => sub { shift->loader_class()->new(); }
);

=head1 SUBROUTINES/METHODS

=cut

sub _parse_log {
    my ( $self, $file ) = @_;
    foreach ( @{ $self->loader()->load($file) } ) {
        die "No id for changeset found" unless $_->{id};
        my $hash = sum($_);
        next if ( $self->_check_key( $_->{id}, $hash ) );
        print STDOUT __PACKAGE__, " Handle changeset: $_->{id}\n";
        my $handle_time = time();
        $self->changeset()->handle( $_->{entries} )
          if ( defined $_->{entries} );
        $self->insert_dblog()->execute( $_->{id}, $_->{author}, $file, $hash, $VERSION )
          or die $self->dbh()->errstr;
        print STDOUT __PACKAGE__,
          " Changeset: $_->{id} author: $_->{author}  executed.  " . ( time() - $handle_time ) . " \n";
    }
}

sub _check_key {
    my ( $self, $id, $value ) = @_;
    my @resp =
      $self->dbh()
      ->selectrow_array( "select md5sum, changelog from " . $self->db_changelog_table() . " where id = '$id'" )
      or return 0;
    die "MD5 hash changed for changeset: $id expect $value got $resp[0]"
      if ( $resp[0] ne $value );
    return ( @resp >= 1 );
}

=head2 run

Read main changelog file and sub changelog files

=cut

sub run {
    my ( $self, $folder ) = @_;

    my $main = $self->loader()->load( File::Spec->catfile( $folder, 'changelog' ) );

    #first load templates
    $self->actions->tables->load_templates( $main->{templates} );
    $self->actions->tables->prefix(
        ( defined $main->{prefix} && $main->{prefix} ne '' )
        ? $main->{prefix} . '_'
        : ''
    );
    $self->actions->tables->postfix(
        ( defined $main->{postfix} && $main->{postfix} ne '' )
        ? '_' . $main->{postfix}
        : ''
    );

    # now load changelogs
    $self->_parse_log( File::Spec->catfile( $folder, "changelog-$_" ) ) foreach @{ $main->{changelogs} };
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;    # End of DBIx::Schema::Changelog::Read

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

