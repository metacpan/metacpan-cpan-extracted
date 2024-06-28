package CXC::DB::DDL::Field::Pg;

# ABSTRACT: DBD::Pg specific Field class

use v5.26;
our $VERSION = '0.15';
use experimental 'signatures';

use Scalar::Util ();
use Ref::Util    ();

package    ## no critic (Modules::ProhibitMultiplePackages)
  CXC::DB::DDL::Field::PgType {
    use base 'CXC::DB::DDL::FieldType';
}

use CXC::DB::DDL::Util 0.15 {
    add_dbd => {
        dbd         => 'Pg',
        tag         => ':pg_types',
        field_class => __PACKAGE__,
        type_class  => __PACKAGE__ . 'Type',
    },
  },
  'SQL_TYPE_NAMES',
  'SQL_TYPE_VALUES';

use Types::Standard 'ArrayRef', 'Enum', 'Int', 'InstanceOf';

use constant DataType => Enum->of( grep { !Ref::Util::is_ref $_ } SQL_TYPE_VALUES )
  | InstanceOf ['CXC::DB::DDL::Field::PgType'];

use Moo;

use namespace::clean;

extends 'CXC::DB::DDL::Field';

has '+data_type' => (
    is     => 'ro',
    isa    => ArrayRef->of( DataType )->plus_coercions( DataType, sub { [$_] } ),
    coerce => 1,
);









sub type_name ( $self, $dbh ) {

    # if the type is an object, it's guaranteed to be one of ours, so
    # use it directly
    for my $type ( $self->data_type->$* ) {
        return $type->name if Scalar::Util::blessed( $type );
    }

    return $self->next::method( $dbh );
}

1;

#
# This file is part of CXC-DB-DDL-Field-Pg
#
# This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::DB::DDL::Field::Pg - DBD::Pg specific Field class

=head1 VERSION

version 0.15

=head1 METHODS

=head2 type_name

   $name = $field->type_name( $dbh );

return the type name for the type

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-db-ddl-field-pg@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-DB-DDL-Field-Pg>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-db-ddl-field-pg

and may be cloned from

  https://gitlab.com/djerius/cxc-db-ddl-field-pg.git

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
