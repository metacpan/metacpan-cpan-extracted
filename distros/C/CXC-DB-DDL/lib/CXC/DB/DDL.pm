package CXC::DB::DDL;

use v5.26;
use strict;
use warnings;

our $VERSION = '0.19';

# ABSTRACT: DDL for table creation, based on SQL::Translator::Schema

use DBI::Const::GetInfoType;
use List::Util   qw( first notall all );
use Scalar::Util qw( blessed );
use Hash::Ordered;
use SQL::Translator::Schema;
use SQL::Translator::Schema::Table;

use Ref::Util qw( is_hashref is_arrayref );
use CXC::DB::DDL::Util 'sqlt_entity_map', 'db_version';
use CXC::DB::DDL::Failure;
use CXC::DB::DDL::Table;
use CXC::DB::DDL::Constants '-all';
use Type::Params    qw( signature_for );
use Types::Standard qw( ArrayRef Bool Dict Enum HashRef InstanceOf Object Optional Str Slurpy );

use Moo;
use Feature::Compat::Try;
use experimental 'signatures', 'postderef', 'declared_refs', 'refaliasing';

use constant AutoCommit => 'AutoCommit';

use namespace::clean;

# use after namespace::clean to avoid cleaning out important bits.
use MooX::StrictConstructor;

my sub wrap_producers;


my sub coerce_table_arrayref {
    Hash::Ordered->new(
        map {
            my $table = CXC::DB::DDL::Table->new( $_ );
            $table->name, $table
        } $_->@*,
    );
}

has _tables => (
    is       => 'ro',
    init_arg => 'tables',
    isa      => InstanceOf( ['Hash::Ordered'] )->plus_coercions(
        ArrayRef [HashRef],
        \&coerce_table_arrayref,
        HashRef,
        sub { local $_ = [$_]; coerce_table_arrayref; },
        ArrayRef [ InstanceOf ['CXC::DB::DDL::Table'] ] => sub {
            Hash::Ordered->new( map { $_->name, $_ } $_->@* );
        },
    ),
    coerce  => 1,
    default => sub { Hash::Ordered->new },
    handles => [qw( get set exists )],
);






around BUILDARGS => sub ( $orig, $class, @args ) {

    # handle ->new( \@tables );
    if ( is_arrayref( $args[0] ) ) {
        unshift @args, 'tables';
    }

    # handle ->new( \%table );
    elsif ( is_hashref( $args[0] ) && !exists $args[0]{table} ) {

        $args[0] = [ $args[0] ];
        unshift @args, 'tables';
    }

    return $class->$orig( @args );
};













signature_for table => (
    method     => 1,
    positional => [ Optional [Str] ],
);

sub table ( $self, @table_name ) {
    if ( @table_name ) {
        $self->get( $table_name[0] );
    }
    elsif ( $self->_tables->values == 1 ) {
        ( $self->_tables->values )[0];
    }
    else {
        return;
    }
}









sub tables ( $self ) {
    [ $self->_tables->values ];
}







signature_for add_table => (
    method     => 1,
    positional => [ InstanceOf ['CXC::DB::DDL::Table'] ] );

sub add_table ( $self, $table ) {
    CXC::DB::DDL::Failure::parameter_constraint->throw(
        "attempt to add existing table: ${ \$table->name } " )
      if $self->exists( $table->name );

    $self->set( $table->name, $table );
}



































signature_for sql => (
    method => 1,
    head   => [Object],    # $dbh
    named  => [ (
            create => Optional [ Enum [CREATE_CONSTANTS] ],
            { default => CREATE_ONCE },
        ),
        ( sqlt_comments          => Optional [Bool], { default => !!1 } ),
        ( sqlt_quote_identifiers => Optional [Bool], ),
        ( sqlt_debug             => Optional [Bool], { default => !!0 } ),
        ( sqlt_trace             => Optional [Bool], { default => !!0 } ),
    ],
);

sub sql ( $self, $dbh, $opt ) {

    my @tables   = $self->tables->@*;
    my @missing  = grep { !$_->exists( $dbh ) } @tables;
    my @existing = grep { $_->exists( $dbh ) } @tables;

    my $create      = $opt->create;
    my $no_comments = !$opt->sqlt_comments;


    my $add_drop_table = !!0;
    # drop and create
    if ( $create == CREATE_ALWAYS ) {
        $add_drop_table = !!1;
    }

    # only create the missing tables
    elsif ( $create == CREATE_IF_NOT_EXISTS ) {
        return () if !@missing;
    }

    # try to create and die if already created.
    elsif ( $create == CREATE_ONCE && @existing ) {
        CXC::DB::DDL::Failure::create->throw(
            'attempt to create tables which already exist: ' . join( q{, }, map { $_->name } @existing ) );
    }

    require SQL::Translator;
    my $tr = SQL::Translator->new(
        add_drop_table => $add_drop_table,
        no_comments    => $no_comments,
        (
            $opt->has_sqlt_quote_identifiers
            ? ( quote_identifiers => $opt->sqlt_quote_identifiers )
            : ()
        ),
        debug => $opt->sqlt_debug,
        trace => $opt->sqlt_trace,
    );
    my $schema = $tr->schema;

    # create entire schema, as this ensures that all foreign key
    # dependencies are met
    $_->add_to_schema( $dbh, $schema ) for @tables;

    # unless CREATE_ALWAYS, remove existing tables from the
    # schema, so the DDL for them isn't created.
    $schema->drop_table( $_->name ) for $create == CREATE_ALWAYS ? () : @existing;

    my $dbd      = $dbh->{Driver}->{Name};
    my $guard    = wrap_producers( $dbd );                ## no critic(Variables::ProhibitUnusedVarsStricter)
    my $producer = sqlt_entity_map( $dbd, 'producer' );

    my %producer_args = (
        no_transaction => 1,                              # we handle this ourselves.
    );

    if ( defined( my $db_version_arg = sqlt_entity_map( $dbd, 'db_version' ) ) ) {
        $producer_args{$db_version_arg} = db_version( $dbh );
    }

    $tr->producer_args( \%producer_args );

    # SQL::Translator::translate() is calling context aware, so we need to
    # do the same.
    ## no critic (Community::Wantarray)

    if ( wantarray ) {
        my @res = $tr->translate( to => $producer );
        return @res if defined $res[0];
    }
    else {
        my $res = $tr->translate( to => $producer );
        return $res if defined $res;
    }

    CXC::DB::DDL::Failure::create->throw( $tr->error );
}



















signature_for create => (
    method     => 1,
    positional => [ Object, Slurpy [HashRef] ] );

sub create ( $self, $dbh, $opt ) {

    my @sql = $self->sql( $dbh, $opt->%* );
    return unless @sql;

    my $in_txn = !$dbh->{AutoCommit};

    my $statement;
    try {
        $dbh->begin_work unless $in_txn;
        while ( $statement = shift @sql ) {
            next if all { /\s*--/ } split( /\n+/, $statement );
            die( "error running $statement" )
              if !defined $dbh->do( $statement );
        }
        $dbh->commit unless $in_txn;
    }
    catch ( $e ) {
        $dbh->rollback unless $in_txn;
        CXC::DB::DDL::Failure::create->throw( "$e: " . ( $statement // q{} ) );
    };
}










sub clear ( $self, $dbh ) {
    return map { $_->name } grep { !$_->clear( $dbh ) } $self->tables->@*;
}









sub drop ( $self, $dbh ) {
    $_->drop( $dbh ) for reverse $self->tables->@*;
}










sub clone_simple ( $self ) {
    return blessed( $self )->new( tables => [ map $_->clone_simple, $self->tables->@* ] );
}

my %WrapProducer = (
    +( DBD_SQLITE ) => {
        'SQL::Translator::Producer::SQLite::create_table' => sub ( $orig, $table, $options ) {
            $options->{temporary_table} = $table->extra->{temporary};
            $orig->( $table, $options );
        },
    },
);

sub wrap_producers ( $dbd ) {

    my $wrapper = $WrapProducer{$dbd} // return undef;

    require Module::Runtime;
    require Sub::Override;
    my $override = Sub::Override->new;

    for my $name ( keys %{$wrapper} ) {
        Module::Runtime::require_module( $name =~ s/::[^:]+$//r );
        $override->wrap( $name => $wrapper->{$name} );
    }

    return $override;
}

1;

#
# This file is part of CXC-DB-DDL
#
# This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory sql

=head1 NAME

CXC::DB::DDL - DDL for table creation, based on SQL::Translator::Schema

=head1 VERSION

version 0.19

=head1 DESCRIPTION

B<CXC::DB::DDL> provides a procedural interface to generating DDL to create and drop database tables.

It uses L<SQL::Translator> to create the required SQL, and provides a
little bit of extra DSL sauce in L<CXC::DB::DDL::Util>.

See L<CXC::DB:DDL::Manual::Intro>.

=head1 METHODS

=head2 table

   # return CXC::DB::DDL::Table object for named table
   $table = $ddl->table( $table_name );

   # If only one table, return CXC::DB::DDL::Table object for it
   $table = $ddl->table;

Returns C<undef> if no matching table or no tables.

=head2 tables

   \@tables = $ddl->tables

Return the tables.

=head2 add_table

  $ddl->add_table( InstanceOf ['CXC::DB::DDL::Table'] );

=head2 sql

  $ddl->sql( $dbh, %options )

Create the SQL associated with the C<$ddl> object using the L<DBI>
database handle, C<$dbh>. Various options may be specified:

=over

=item create

One of the constants (see <CXC::DB::DDL::Constants>) C<CREATE_ONCE>,
C<CREATE_ALWAYS>, C<CREATE_IF_NOT_EXISTS>.

=item sqlt_comments I<Bool>

Add comments in SQL [Default: true].

=item sqlt_quote_identifiers I<Bool>

Quote identifiers (Default: producer specific)

=item sqlt_debug I<Bool>

L<SQL::Translator> constructor C<debug> option.

=item sqlt_trace

L<SQL::Translator> constructor C<trace> option.

=back

=head2 create

  $ddl->create( $dbh, ?$create = CREATE_ONCE | CREATE_ALWAYS | CREATE_IF_NOT_EXISTS );

Create the tables associated with the C<$ddl> object using the L<DBI>
database handle, C<$dbh>.  C<$create> defaults to C<CREATE_ONCE>;

B<CREATE_ALWAYS> drops the tables and creates them.

B<CREATE_IF_NOT_EXISTS> checks if there are any missing tables; if not it returns.

B<CREATE_ONCE> will attempt to create the tables, and will throw an exception
if one exists.

Returns true if tables were created.

=head2 clear

  @not_cleared = $ddl->clear( $dbh );

Clear the contents of the tables in the DDL schema.  DDL::Table
objects for tables which do not exist are returned.

=head2 drop

  $ddl->drop( $dbh );

Drop all of the tables in the DDL schema in reverse order of addition.

=head2 clone_simple

  $cloned_ddl = $ddl->clone_simple

Return a new object based on the current one, running
L<CXC::DB::DDL::Table::clone_simple> on the tables.

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

L<CXC::DB::DDL::Manual::Intro|CXC::DB::DDL::Manual::Intro>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
