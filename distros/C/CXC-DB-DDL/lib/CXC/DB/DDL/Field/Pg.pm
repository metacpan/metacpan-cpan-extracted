package CXC::DB::DDL::Field::Pg;

use v5.26;
our $VERSION = '0.14';
use experimental 'signatures';

use List::Util ();

use CXC::DB::DDL::Util { add_dbd => { dbd => 'Pg', tag => ':pg_types', field_class => __PACKAGE__ },
  },
  'SQL_TYPE_NAMES',
  'SQL_TYPE_VALUES';


# very crude method of mapping pg_type id to name. It'd be more
# appropriate to use the DBI::Pg 'pg_type_data' C routine, but that
# isn't exposed to Perl.
my %TypeMap;
@TypeMap{ +SQL_TYPE_NAMES } = SQL_TYPE_VALUES;
delete @TypeMap{ grep !/^PG_/, SQL_TYPE_NAMES };
$TypeMap{s/^PG_//r} = delete $TypeMap{$_} for keys %TypeMap;
my %RevTypeMap = reverse %TypeMap;

use Types::Standard 'ArrayRef', 'Enum', 'Int';

use Moo;

use namespace::clean;

extends 'CXC::DB::DDL::Field';

has '+data_type' => (
    is     => 'ro',
    isa    => ArrayRef->of( Enum [SQL_TYPE_VALUES] )->plus_coercions( Int, sub { [$_] } ),
    coerce => 1,
);

sub type_name ( $self, $dbh ) {
    return List::Util::first { defined }
    ( map { $RevTypeMap{$_} } $self->data_type->@* ), $self->next::method( $dbh );
}

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::DB::DDL::Field::Pg

=head1 VERSION

version 0.14

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
