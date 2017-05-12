package DBIx::Schema::Changelog::Role::Driver;

=head1 NAME

DBIx::Schema::Changelog::Role::Driver - Abstract driver class.

=head1 VERSION

Version 0.9.0


=cut

our $VERSION = '0.9.0';

use utf8;
use strict;
use warnings FATAL => 'all';
use Moose::Role;
use MooseX::Types::PerlVersion qw( PerlVersion );
use MooseX::Types::Moose qw( Maybe Undef );

has min_version => (
    is      => 'ro',
    isa     => PerlVersion,
    coerce  => 1,
    builder => '_min_version',
);

has max_version => (
    is      => 'ro',
    isa     => PerlVersion | Undef,
    coerce  => 1,
    builder => '_max_version',
);

has changelog_table => (
    isa     => 'ArrayRef[Any]',
    is      => 'ro',
    default => sub {
        return [
            {
                name       => 'id',
                type       => 'varchar',
                lenght     => 255,
                primarykey => 1,
                notnull    => 1,
                default    => '\'\''
            },
            {
                name    => 'author',
                type    => 'varchar',
                lenght  => 255,
                notnull => 1,
                default => '\'\''
            },
            {
                name    => 'filename',
                type    => 'varchar',
                lenght  => 255,
                notnull => 1,
                default => '\'\''
            },
            {
                name    => 'flag',
                type    => 'timestamp',
                notnull => 1,
                default => 'current'
            },
            {
                name   => 'orderexecuted',
                type   => 'varchar',
                lenght => 255,
            },
            {
                name    => 'md5sum',
                type    => 'varchar',
                lenght  => 255,
                notnull => 1,
                default => '\'\''
            },
            {
                name   => 'description',
                type   => 'varchar',
                lenght => 255,
            },
            {
                name   => 'comments',
                type   => 'varchar',
                lenght => 255,
            },
            {
                name    => 'changelog',
                type    => 'varchar',
                lenght  => 10,
                notnull => 1,
                default => '\'\''
            },
        ];
    }
);

has origin_types => (
    isa     => 'ArrayRef[Str]',
    is      => 'ro',
    default => sub {
        return [
            'abstime', 'aclitem',    #A
            'bigint', 'bigserial', 'bit', 'varbit', 'blob', 'bool', 'box',
            'bytea',                 #B
            'char', 'character', 'varchar', 'cid', 'cidr', 'circle',    #C
            'date', 'daterange', 'double', 'double_precision', 'decimal',    #D
                                                                             #E
                                                                             #F
            'gtsvector',                                                     #G
                                                                             #H
            'inet', 'int2vector', 'int4range', 'int8range', 'integer',
            'interval',                                                      #I
            'json',                                                          #J
                                                                             #K
            'line',    'lseg',                                               #L
            'macaddr', 'money',                                              #M
            'name',    'numeric', 'numrange',                                #N
            'oid',     'oidvector',                                          #O
            'path',    'pg_node_tree', 'point', 'polygon',                   #P
                                                                             #Q
            'real', 'refcursor', 'regclass', 'regconfig', 'regdictionary',
            'regoper', 'regoperator', 'regproc', 'regprocedure', 'regtype',
            'reltime',                                                       #R
            'serial', 'smallint', 'smallserial', 'smgr',                     #S
            'text', 'tid', 'timestamp', 'timestamp_tz', 'time', 'time_tz',
            'tinterval', 'tsquery', 'tsrange', 'tstzrange', 'tsvector',
            'txid_snapshot',                                                 #T
            'uuid',                                                          #U
                                                                             #V
                                                                             #W
            'xid',                                                           #X
                                                                             #Y
                                                                             #Z
        ];
    }
);

=head1 SUBROUTINES/METHODS

=over 4

=item check_version

=cut

sub check_version {
    my ( $self, $vers ) = @_;

    if ( $self->has_max_version ) {
        return 1
          if ( $self->min_version() <= $vers && $vers <= $self->max_version() );
        die "Unsupported version: "
          . $self->min_version()
          . " <= $vers <= "
          . $self->max_version();
    }
    else {
        return 1 if ( $self->min_version() <= $vers );
        die "Unsupported version: " . $self->min_version() . " <= $vers";
    }
}

=item type

=cut

sub type {
    my ( $self, $col ) = @_;
    my $ret =
      ( grep( /^$col->{type}$/, @{ $self->origin_types() } ) )
      ? $self->types()->{ $col->{type} }
      : undef;
    die "Type: $col->{type} not found.\n" unless $ret;
    $ret .= ( $col->{strict} )         ? '(strict)'         : '';
    $ret .= ( defined $col->{lenght} ) ? "($col->{lenght})" : '';
    return $ret;
}

=item has_max_version

    check if max version is set

=cut

sub has_max_version { defined shift->max_version }

=item has_max_version

    builder for max version

=cut

sub _max_version { }

=item create_changelog_table

=cut

sub create_changelog_table {
    my ( $self, $dbh, $name ) = @_;
    my $sth = $dbh->prepare( $self->select_changelog_table() );
    if ( $sth->execute() or die "Some error $!" ) {
        foreach ( $sth->fetchrow_array() ) {
            return undef if ( $_ =~ /^$name$/ );
        }
    }
    return {
        name    => $name,
        columns => $self->changelog_table()
    };
}

1;    # End of DBIx::Schema::Changelog::Driver

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
