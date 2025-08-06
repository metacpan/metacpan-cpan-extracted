package CXC::DB::DDL::Table;

# ABSTRACT: A Table

use v5.26;
use strict;
use warnings;

our $VERSION = '0.21';

use List::Util qw( any );
use Ref::Util  qw( is_ref is_arrayref is_coderef is_plain_hashref);

use CXC::DB::DDL::Failure;
use CXC::DB::DDL::Constants -all;
use CXC::DB::DDL::Types -all;
use Type::Params    qw( signature_for  );
use Types::Standard qw( ArrayRef Bool Dict Enum HashRef InstanceOf Object Optional Str Undef );
use Types::Common::String qw( NonEmptyStr );

use Moo;
use experimental 'signatures', 'postderef', 'declared_refs';

use namespace::clean -except => 'has';

with 'CXC::DB::DDL::CloneClear';

# use after namespace::clean to avoid cleaning out important bits.
use MooX::StrictConstructor;







use constant FIELD_CLASS => 'CXC::DB::DDL::Field';

my sub croak {
    require Carp;
    goto \&Carp::croak;
}

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







has temporary => (
    is      => 'ro',
    isa     => Bool,
    default => !!0,
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
    is         => 'lazy',
    isa        => ArrayRef( [ InstanceOf [FIELD_CLASS] ] ),
    clearer    => 1,
    cloneclear => 1,
    builder    => sub { [] },
);























































































around BUILDARGS => sub ( $orig, $class, @args ) {

    my \%args = $class->$orig( @args );

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
            parameter_constraint->throw( "illegal table name: $args{name}" );
        }
    }

    if ( defined $args{fields} && is_arrayref( $args{fields} ) ) {
        require Module::Load;
        Module::Load::load( $class->field_class );

        my @fields = $args{fields}->@*;

        $_ = $class->field_class->new( $_ ) for grep { is_plain_hashref( $_ ) } @fields;

        $args{fields} = \@fields;
    }

    return \%args;
};

sub BUILD ( $self, $args ) {

    # convert constraints' fields into array refs if required; handle
    # a scalar of '-all' as well.  ATM, constraints are hashes which
    # pass the CXC::DB::DDL::Types::Constraint constraint.
    for my $constraint ( $self->constraints->@* ) {

        my $fields = $constraint->{fields};

        # only worry about scalars
        next if !defined( $fields ) || ref $fields;

        $constraint->{fields} =
          # replace fields => '-all' with all of the fields (->field_names() returns a copy)
          $fields eq '-all'
          ? $self->field_names
          # otherwise turn it into an array
          : [$fields];
    }

}









sub field_class { FIELD_CLASS }












sub to_sqlt ( $self, $dbh, $schema ) {

    my %extra;

    if ( $self->temporary ) {

        # this works for SQL::Translator::Producer::PostgreSQL, but not for
        # SQL::Translator::Producer::SQLite; that gets monkey-patched in CXC::DB::DDL
        $extra{temporary} = $self->temporary;

        my $dbd = $dbh->{Driver}->{Name};

        # SYNC THIS CODE WITH THE OVERRIDE FUNCTION IN CXC::DB::DDL.
        croak(
            "SQL::Translator either doesn't support temp tables for DBD::$dbd, or we don't know how to make it do so",
        ) unless $dbd eq DBD_SQLITE || $dbd eq DBD_POSTGRESQL;
    }


    my $sqlt_table = $schema->add_table( name => $self->name, extra => \%extra );

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

        # if name is not specified, create one from the field names
        $attr{name} //= join(
            '_',
            $self->_name,    # name without schema
            ++$cstr,
            lc( $attr{type} =~ s/\s+/_/gr ),
            defined( $attr{fields} )
            ? (
                $attr{fields}->@*
              )
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

#
# This file is part of CXC-DB-DDL
#
# This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::DB::DDL::Table - A Table

=head1 VERSION

version 0.21

=head1 DESCRIPTION

B<CXC::DB::DDL::Table> represents a database table, including its fields, indexes, and constraints.

=head1 OBJECT ATTRIBUTES

=head2 schema

The schema that the table is in.

=head2 name

The table name, qualified with its schema.

=head2 temporary

true if the table should be created as a temporary table

=head2 indexes

A list of table indexes, see the L</indexes> constructor parameter for more information.

=head2 constraints

A list of table constraints, see the L</constraints> constructor parameter for more information.

=head2 checks

DEPRECATED.

A list of table check constraints, see the L</check> constructor parameter for more information.

=head2 fields

The list of fields as instances of the L<CXC::DB::DDL::Field> class (or
a subclass). See the L</fields> constructor parameter.

=head1 CONSTRUCTORS

=head2 new

  $table = CXC::DB::DDL::Table->new( %params );

C<%params> may have the following entries:

=over

=item C<name> I<string>

The table name. If the name is qualified with a schema, e.g.

   <schema-name>.<table-name>

The schema will be extracted for the L</schema> parameter.

Note that if a separate schema is provided via the L</schema>
parameter, the table name is I<not> parsed for a schema, so
don't specify one or things will break.

=item C<schema> => I<string>

An optional schema.

=item C<temporary> => I<boolean>

True if the table should be created as a temporary table

=item C<indexes> => I<arrayref>

An array of indexes; an index is a hashref; see
L<CXC::DB::DDL::Types/Index> for its structure.

=item C<constraints>

One or more table constraints, as either a single constraint or as an
array of constraints.

Constraints must meet the L<CXC::DB::DDL::Types/Constraint> type.

If the constraint attribute B<expression> is a coderef, it is called
as

   $expression->( $dbh, $sqlt, $constraint )

where B<$dbh> is L<DBI> handle, B<$sqlt> is the L<SQL::Translator>
object, and must return a scalar containing the final expression. This
is typically used to ensure that identifiers are properly quoted.  See
L<DBI/quote> and L<DBI/quote_identifier>.

B<$dbh>, B<$sqlt> and B<$constraint> must B<not> be changed.

=item C<checks>  B<DEPRECATED>

Use a check constraint instead by adding an entry to L</constraints> with fields

   type => CHECK_C, expression => $expr

Originally: The list of table check constraints

=item C<fields>

A list of field specifications.  A specification is either:

=over

=item an instance of L<CXC::DB::DDL::Field> or a subclass

=item a hashref which can be passed to a field constructor.

The default class is L<CXC::CB::DDL::Field>. To change the default,
subclass this class, and override the L</field_class> class method.

=back

=back

=head1 CLASS METHODS

=head2 field_class

returns the name of the class used by the constructor to create a
field object from a hash field specification.  Override this in a
subclass to change it.

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

=head1 SUBROUTINES

=head2 FIELD_CLASS

=begin Pod::Coverage




=end Pod::Coverage

=for Pod::Coverage BUILDARGS
BUILD

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
