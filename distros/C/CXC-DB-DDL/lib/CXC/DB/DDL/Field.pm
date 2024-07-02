package CXC::DB::DDL::Field;

# ABSTRACT: DDL Representation of a field

use v5.26;

use List::Util qw( first );
use Ref::Util  qw( is_coderef is_ref );
use CXC::DB::DDL::Failure;
use CXC::DB::DDL::Constants -all;
use Types::Standard       qw( ArrayRef Bool CodeRef Dict Enum HashRef Int Optional ScalarRef );
use Types::Common::String qw( NonEmptyStr );

use Moo;
use experimental 'signatures', 'postderef', 'declared_refs', 'refaliasing';

our $VERSION = '0.16';

use namespace::clean -except => [ 'has', '_tag_list', '_tags' ];

use MooX::StrictConstructor;

# need _tag_list for CloneClear (MooX::TaggedAttributes)
# need new for MooX::StrictConstructor

with 'CXC::DB::DDL::CloneClear';







has name => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);







has data_type => (
    is       => 'ro',
    isa      => ArrayRef->of( Enum [SQL_TYPE_CONSTANTS] )->plus_coercions( Int, sub { [$_] } ),
    coerce   => 1,
    required => 1,
);







has is_nullable => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);







has is_primary_key => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);







has is_auto_increment => (
    is         => 'ro',
    isa        => Bool,
    clearer    => 1,
    cloneclear => 1,
    default    => 0,
);



















has foreign_key => (
    is  => 'ro',
    isa => NonEmptyStr | Dict [
        table     => NonEmptyStr,
        field     => Optional [NonEmptyStr],
        on_delete => Optional [NonEmptyStr],
        on_update => Optional [NonEmptyStr],
    ],
    clearer    => 1,
    cloneclear => 1,
    predicate  => 1,
);













has check => (
    is         => 'ro',
    isa        => NonEmptyStr,
    clearer    => 1,
    cloneclear => 1,
    predicate  => 1,
);











has default_value => (
    is         => 'ro',
    isa        => NonEmptyStr | ScalarRef | CodeRef,
    clearer    => 1,
    cloneclear => 1,
    predicate  => 1,
);





sub type_name ( $self, $dbh ) {
    return ( $dbh->type_info( $self->data_type )
          // $dbh->type_info( [ SQL_VARCHAR, SQL_LONGVARCHAR ] ) )->{TYPE_NAME};
}
















sub to_sqlt ( $self, $dbh, $table ) {

    require SQL::Translator::Schema::Field;

    my %attr = (
        name              => $self->name,
        table             => $table,
        is_nullable       => $self->is_nullable,
        data_type         => $self->type_name( $dbh ),
        is_auto_increment => $self->is_auto_increment,
        (
            $self->has_default_value
            ? (
                default_value => is_coderef( $self->default_value )
                ? $self->default_value->( $dbh )
                : $self->default_value,
              )
            : ()
        ),
    );


    if ( $self->is_auto_increment && $dbh->{Driver}->{Name} eq DBD_SQLITE ) {
        $self->is_primary_key
          or CXC::DB::DDL::Failure::ddl->throw(
            join( q{.}, $table->name, $self->name )
              . ': SQLite requires an autoincrementing column to be a primary key.', );

        CXC::DB::DDL::Failure::ddl->throw(
            join( q{.}, $table->name, $self->name )
              . ': SQLite requires an autoincrementing column to be of INTEGER type.', )
          if $attr{data_type} ne 'INTEGER';

        # this magic comes from reading the source of
        # SQL::Translator::Generator::DDL::SQLite::field_autoinc()
        $attr{extra} = { auto_increment_type => 'monotonic' };
    }


    if ( $self->has_foreign_key ) {
        require SQL::Translator::Schema::Constraint;

        my \%fk
          = !is_ref( $self->foreign_key )
          ? { table => $self->foreign_key }
          : $self->foreign_key;

        $fk{field} //= $self->name;

        my $reference_table = first { $fk{table} eq $_->name } $table->schema->get_tables;

        $reference_table
          or CXC::DB::DDL::Failure::ddl->throw(
            join( q{.}, $table->name, $self->name ) . ": unknown table in foreign key constraint: $fk{table}" );

        $attr{foreign_key_reference} = SQL::Translator::Schema::Constraint->new(
            table            => $table,
            type             => FOREIGN_KEY,
            fields           => $self->name,
            reference_fields => $fk{field},
            ( defined $fk{on_delete} ? %fk{on_delete} : () ),
            ( defined $fk{on_update} ? %fk{on_update} : () ),
            reference_table => $reference_table,
        );
    }

    # create this before adding table check constraint on this field
    # in case table object needs the field object.
    my $field = $table->add_field( %attr )
      // CXC::DB::DDL::Failure::ddl->throw(
        "error adding field ${ \$self->name } to table ${ \$table->name }" );

    if ( $self->has_check ) {
        $table->add_constraint(
            type       => CHECK_C,
            fields     => $self->name,
            expression => $self->check,
          )
          // CXC::DB::DDL::Failure::ddl->throw(
            "error adding check constraint ( ${ \$self->check } ) on ${ \$self->name } : ${ \$table->error }",
          );
    }

    # SQL::Translator::Schema::Field has a settable is_primary_key
    # attribute which does nothing.  Need to use a table constraint.
    if ( $self->is_primary_key ) {
        $table->add_constraint(
            type   => PRIMARY_KEY,
            fields => $self->name,
          )
          // CXC::DB::DDL::Failure::ddl->throw(
            "error adding PRIMARY constraint on ${ \$self->name }: ${ \$table->error }", );
    }

    if ( $self->has_foreign_key ) {
        $table->add_constraint( $attr{foreign_key_reference} )
          // CXC::DB::DDL::Failure::ddl->throw(
            "error adding FOREIGN KEY constraint on ${ \$self->name }: $attr{foreign_key_reference}", );
    }

    return $field;
}

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::DB::DDL::Field - DDL Representation of a field

=head1 VERSION

version 0.16

=head1 OBJECT ATTRIBUTES

=head2 name => Str

field name

=head2 data_type => Enum [ SQL_TYPE_CONSTANTS ]

field SQL attribute type

=head2 is_nullable => Bool

Should this field be nullable? Defaults to false.

=head2 is_primary_key => Bool

Is this field the primary key? Defaults to false.

=head2 is_auto_increment => Bool

Does this field auto increment?  Defaults to false.

=head2 foreign_key => NonEmptyStr | Dict [table => NonEmptyStr, field => Optional [NonEmptyStr] ]

If this field is linked to a foreign key, this attribute specifies the
table containing the foreign key

If the keys have the same name, this attribute should specify the foreign key's table name.

If the keys have different names, set this to a hash with keys
B<table> and B<field>, where B<field> is the name in the other table.

Required if this column references a foreign key.

=head2 check => NonEmptyStr

DEPRECATED; use a table constraint

Field check constraint.

=head2 default_value => NonEmptyStr | ScalarRef | CodeRef

Default value for a field; may be a string, scalar ref or a coderef.

=head1 METHODS

=head2 has_foreign_key

Returns true if this field has a foreign key.

=head2 has_check

Returns true if a check constraint has been specified.

=head2 has_default_value

Default value

=head2 type_name

=head2 to_sqlt

  $sqlt_field = $field->to_sqlt( $dbh, $table );

Return a L<SQL::Translator::Schema::Field> object for the field in B<$table>

B<$dbh> is a L<DBI> data base handle.

B<$table> is a L<SQL::Translator::Schema::Table> object.

This method is typically not invoked by the user; it is called by
L<CXC::DB::DDL::Table/to_sqlt>;

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
