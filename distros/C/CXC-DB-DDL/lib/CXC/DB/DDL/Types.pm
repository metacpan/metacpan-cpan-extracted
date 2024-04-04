package CXC::DB::DDL::Types;

# ABSTRACT: Types, oh my!

use v5.26;
use strict;
use warnings;

our $VERSION = '0.13';

use CXC::DB::DDL::Constants -all;

use Type::Library -base, -declare => ( qw(
      Index
      Indexes
      Constraint
) );

use Type::Utils -all;
use Types::Standard qw( ArrayRef Bool Dict Enum HashRef Optional Str );

declare Indexes, as ArrayRef [Index];

coerce Indexes, from ArrayRef [Str], q/ [ { fields => $_ } ] /;

declare Index,
  as Dict [
    name    => Optional [Str],
    fields  => Optional [ Str | ArrayRef [Str] ],
    type    => Optional [ Enum [SCHEMA_CONSTANTS] ],
    options => Optional [HashRef],
  ];

coerce Index, from ArrayRef [Str], q[ { fields => $_ } ];


declare Constraint,
  as Dict [
    type              => Optional [ Enum [SCHEMA_CONSTANTS] ],
    name              => Optional [Str],
    deferrable        => Optional [Bool],
    expression        => Optional [Str],
    fields            => Optional [ Str | ArrayRef [Str] ],
    referenced_fields => Optional [ Str | ArrayRef [Str] ],
    reference_table   => Optional [Str],
    match_type        => Optional [ Enum [SCHEMA_CONSTRAINT_MATCH_TYPES] ],
    on_delete         => Optional [ Enum [SCHEMA_CONSTRAINT_ON_DELETE] ],
    on_update         => Optional [ Enum [SCHEMA_CONSTRAINT_ON_UPDATE] ],
    options           => Optional [HashRef],
  ];


1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::DB::DDL::Types - Types, oh my!

=head1 VERSION

version 0.13

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
