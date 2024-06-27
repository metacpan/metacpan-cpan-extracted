package CXC::DB::DDL::Table;

# ABSTRACT: CXC::DB::DDL Table class

use v5.26;
use strict;
use warnings;

our $VERSION = '0.15';

use List::Util qw( any );
use Ref::Util  qw( is_ref is_arrayref is_coderef);

use CXC::DB::DDL::Failure;
use CXC::DB::DDL::Constants -all;
use CXC::DB::DDL::Types -all;
use Type::Params          qw( signature_for  );
use Types::Standard       qw( ArrayRef Bool Dict Enum HashRef InstanceOf Object Optional Undef );
use Types::Common::String qw( NonEmptyStr );

use Moo;
use experimental 'signatures', 'postderef', 'declared_refs';

use namespace::clean -except => 'has';

with 'CXC::DB::DDL::CloneClear';







has _name => (
    is       => 'ro',
    init_arg => 'name',
    isa      => NonEmptyStr,
    required => 1,
);

















has schema => (
    is        => 'ro',
    isa       => NonEmptyStr,
    predicate => 1,
);

has name => (
    is       => 'lazy',
    init_arg => undef,
    builder  => sub ( $self ) {
        return $self->has_schema
          ? join( q{.}, $self->schema, $self->_name )
          : $self->_name;
    },
);







has indexes => (
    is         => 'lazy',
    isa        => Indexes,
    builder    => sub { [] },
    coerce     => 1,
    clearer    => 1,
    cloneclear => 1,
);




















has constraints => (
    is         => 'lazy',
    isa        => ArrayRef->of( Constraint )->plus_coercions( Constraint, q{ [$_] } ),
    coerce     => 1,
    clearer    => 1,
    cloneclear => 1,
    builder    => sub { [] },
);











has checks => (
    is         => 'lazy',
    isa        => ArrayRef [ NonEmptyStr | Dict [ name => NonEmptyStr, expr => NonEmptyStr ], ],
    clearer    => 1,
    cloneclear => 1,
    builder    => sub { [] },
);







has fields => (
    is  => 'lazy',
    isa => ArrayRef( [ InstanceOf ['CXC::DB::DDL::Field'] ] )
      ->plus_coercions( ArrayRef [HashRef], q{ [ map CXC::DB::DDL::Field->new( $_ ), $_->@* ] }, ),
    clearer    => 1,
    cloneclear => 1,
    coerce     => 1,
    builder    => sub { [] },
);






around BUILDARGS => sub ( $orig, $self, @args ) {

    my \%args = $self->$orig( @args );

    if ( defined $args{name} && !defined $args{schema} ) {

        my $pos = index( $args{name}, q{.} );

        if ( $pos == -1 ) {
            delete $args{schema};
        }
        elsif ( $pos > 0 ) {
            $args{schema} = substr( $args{name}, 0, $pos );
            $args{name}   = substr( $args{name}, $pos + 1 );
        }
        else {
            parameter_constraint->throw( sprintf( q{illegal table name: %s}, $self->name ) );
        }
    }

    return \%args;
};











sub to_sqlt ( $self, $dbh, $schema ) {

    my $sqlt_table = $schema->add_table( name => $self->name );

    for my $field ( $self->fields->@* ) {
        $field->to_sqlt( $dbh, $sqlt_table )
          // CXC::DB::DDL::Failure::ddl->throw(
            sprintf( 'Error adding field %s to table %s: %s', $field->name, $self->name, $sqlt_table->error ),
          );
    }

    for my $index ( $self->indexes->@* ) {

        # if $index is a string, it's a normal index on that field
        if ( !is_ref( $index ) ) {
            $index = { fields => $index };
        }

        my %attr = $index->%*;
        $attr{type} //= NORMAL;

        # if name is not specified, create one from the field names and index type.

        $attr{name} //= join( '_',
            $self->_name, 'idx',
            ( $attr{type} ne NORMAL        ? lc( $attr{type} =~ s/\s+/_/gr ) : () ),
            ( is_arrayref( $attr{fields} ) ? $attr{fields}->@*               : $attr{fields} ),
        );

        $sqlt_table->add_index( %attr )
          or CXC::DB::DDL::Failure::ddl->throw(
            sprintf( 'error adding index %s: %s', $attr{name}, $sqlt_table->error, ) );
    }

    my $cstr = 'cstr000';
    for my $constraint ( $self->constraints->@* ) {

        my %attr = $constraint->%*;

        # replace fields => '-all' with all of the fields.
        if ( defined( my $fields = $attr{fields} ) ) {
            $attr{fields} = $self->field_names
              if !ref $fields && $fields eq '-all';
        }

        # if name is not specified, create one from the field names
        $attr{name} //= join(
            '_',
            $self->_name,    # name without schema
            ++$cstr,
            lc( $attr{type} =~ s/\s+/_/gr ),
            defined( $attr{fields} )
            ? (
                is_arrayref( $attr{fields} )
                ? $attr{fields}->@*
                : $attr{fields} )
            : (),
        );

        if ( is_coderef( my $expr = $attr{expression} ) ) {
            $attr{expression} = $expr->( $dbh, $schema->translator, $constraint );
        }

        $sqlt_table->add_constraint( %attr )
          or CXC::DB::DDL::Failure::ddl->throw(
            sprintf( 'error adding constraint %s: %s', $attr{name}, $sqlt_table->error, ) );
    }

    my $check_num = '00';
    for my $check ( $self->checks->@* ) {

        my %attr = is_ref( $check ) ? $check->%* : ( expr => $check );

        $attr{name}
          = join( '_', $self->_name, 'check', $attr{name} // ++$check_num );
        $attr{expression} = delete $attr{expr};

        $sqlt_table->add_constraint( type => CHECK_C, %attr )
          or CXC::DB::DDL::Failure::ddl->throw(
            sprintf( 'error adding check %s: %s', $attr{expression}, $sqlt_table->error, ) );
    }

    return $sqlt_table;
}









sub exists ( $self, $dbh ) {    ## no critic(Subroutines::ProhibitBuiltinHomonyms)

    my $schema = $self->has_schema ? $self->schema : q{%};

    # make sure that we agree on case for key names
    ## no critic( Variables::ProhibitLocalVars )
    local $dbh->{FetchHashKeyName} = 'NAME_lc';

    my $sth = $dbh->table_info( q{%}, $schema, $self->_name, 'TABLE' );

    # Not all DBD drivers can filter properly
    return any { $_->{table_name} eq $self->_name } $sth->fetchall_arrayref( {} )->@*;
}









sub field_names ( $self ) {
    [ map { $_->name } $self->fields->@* ]
}









sub clear ( $self, $dbh ) {
    return 0 unless $self->exists( $dbh );
    $dbh->do( "DELETE FROM ${ \$self->name }" );
    return 1;
}









sub drop ( $self, $dbh ) {
    return 0 unless $self->exists( $dbh );
    $dbh->do( "DROP TABLE ${ \$self->name }" );
    return 1;
}









signature_for add_to_schema => (
    method     => 1,
    positional => [ Object, InstanceOf ['SQL::Translator::Schema'], ] );

sub add_to_schema ( $self, $dbh, $schema ) {

    $self->to_sqlt( $dbh, $schema );
}

around 'clone_simple' => sub ( $orig, $self, @args ) {
    my $fields = $self->fields;
    my $clone  = $self->$orig( @args );
    $clone->fields->@* = map { $_->clone_simple } $fields->@*;
    return $clone;
};

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::DB::DDL::Table - CXC::DB::DDL Table class

=head1 VERSION

version 0.15

=head1 OBJECT ATTRIBUTES

=head2 name

  The table name

=head2 schema

The schema that the table is in. If not specified,
The L</name> attribute is scanned for the schema,
under the assumption that the form is

  <schema>.<table name>

=head2 indexes

The list of table indexes

=head2 constraints

One or more table constraints, either as a single constraint or an
array of constraints.

The constraints must meet the L<CXC::DB::DDL::Types/Constraint> type.

If the constraint attribute B<expression> is a coderef, it is called as

   $expression->( $dbh, $sqlt, $constraint )

where B<$dbh> is L<DBI> handle,  B<$sqlt> is the L<SQL::Translator> object, and must return a scalar
containing the final expression. This is typically used to ensure that identifiers are properly quoted.
See L<DBI/quote> and L<DBI/quote_identifier>.

B<$dbh>, B<$sqlt> and B<$constraint> must B<not> be changed.

=head2 checks

DEPRECATED; add an entry to L</constraints> with fields

   type => CHECK_C, expression => $expr

The list of table check constraints

=head2 fields

The list of fields

=head1 METHODS

=head2 has_schema

true if the L</schema> attribute was set.

=head2 to_sqlt

  $sqlt_table = $table->to_sqlt( $dbh, $schema );

Return a L<SQL::Translator::Schema::Table> object for the table.
Requires a L<DBI> data base handle and an L<SQL::Translator::Schema>
object.

=head2 exists

   $bool = $table->exists;

Check if the table exists in the database

=head2 field_names

   \@field_names = $table->field_names;

return the names of all of the fields

=head2 clear

   $table->clear;

clear the rows from the table

=head2 drop

   $table->drop;

delete the table from the database

=head2 add_to_schema

   $table->add_to_schema( $dbh, $schema );

Add the table to the schema (a L<SQL::Translator::Schema> object).

=for Pod::Coverage BUILDARGS

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
