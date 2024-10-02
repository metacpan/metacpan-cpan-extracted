package CXC::DB::DDL::FieldType;

# ABSTRACT: Class for non-DBI types

use v5.26;

use strict;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.17';

use constant { NAME => 0, TYPE => 1 };






sub new ( $class, $name, $type ) {
    return bless [ $name, $type ], $class;
}










sub name ( $self ) { $self->[NAME]; }









sub type ( $self ) { $self->[TYPE]; }

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::DB::DDL::FieldType - Class for non-DBI types

=head1 VERSION

version 0.17

=head1 CONSTRUCTORS

=head2 new

=head1 METHODS

=head2 name

  $name = $type->name;

Return the name of the type.

=head2 type

  $type = $type->type;

Return the type code of the type.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-db-ddl@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-DB-DDL>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-db-ddl

and may be cloned from

  https://gitlab.com/djerius/cxc-db-ddl.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::DB::DDL|CXC::DB::DDL>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
