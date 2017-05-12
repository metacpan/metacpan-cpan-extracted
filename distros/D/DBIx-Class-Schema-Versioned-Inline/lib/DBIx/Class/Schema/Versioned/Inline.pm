package DBIx::Class::Schema::Versioned::Inline;

=encoding utf8 

=head1 NAME

DBIx::Class::Schema::Versioned::Inline - Defined multiple schema versions within resultset classes

=cut

BEGIN {
    $DBIx::Class::Schema::Versioned::Inline::VERSION = '0.204';
}

=head1 VERSION

Version 0.204

=cut

use warnings;
use strict;

use parent 'DBIx::Class::Schema::Versioned';

use DBIx::Class::Carp;
use Safe::Isa;
use Set::Equivalence;
use SQL::Translator;
use SQL::Translator::Diff;
use Try::Tiny;
use Types::PerlVersion qw/PerlVersion to_PerlVersion/;

__PACKAGE__->mk_classdata( 'schema_versions' =>
      Set::Equivalence->new( type_constraint => PerlVersion, coerce => 1 ) );

sub add_version {
    shift->schema_versions->insert(shift);
}

sub connection {
    my $self = shift;
    $self->next::method(@_);

    my $connect_info = $self->storage->connect_info;
    $self->{vschema} = DBIx::Class::Version->connect(@$connect_info);

    # uncoverable condition right
    my $conn_attrs = $self->{vschema}->storage->_dbic_connect_attributes || {};

    my $version = $conn_attrs->{_version} || $self->get_db_version();

    unless ($version) {

        # TODO: checks for unversioned
        # - do we throw exception?
        # - do we install automatically?
        # - can we be passed some method or connect arg?
        # for now just set $pversion to schema_version
        $version = $self->schema_version;
    }

    $self->versioned_schema( $version, $conn_attrs->{_type} );

    return $self;
}

sub get_db_version {
    return to_PerlVersion( shift->next::method(@_) );
}

sub ordered_schema_versions {
    my ( $self, $order ) = @_;
    $order = defined $order ? $order : 'a';
    if ( $order =~ /^d/i ) {
        return sort { $b <=> $a } $self->schema_versions->members;
    }
    else {
        return sort $self->schema_versions->members;
    }
}

sub schema_first_version {
    my ($self) = @_;
    my $class = ref($self) || $self;

    my $version;
    {
        no strict 'refs';
        $version = ${"${class}::FIRST_VERSION"};
    }
    return to_PerlVersion($version);
}

sub schema_version {
    return to_PerlVersion( shift->next::method(@_) );
}

sub stringified_ordered_schema_versions {
    return map { $_->stringify } shift->ordered_schema_versions(shift);
}

sub upgrade_single_step {
    my ( $self, $db_version, $target_version ) = @_;

    $db_version = to_PerlVersion($db_version)
      unless $db_version->$_isa(PerlVersion);

    $target_version = to_PerlVersion($target_version)
      unless $target_version->$_isa(PerlVersion);

    # db and schema at same version. do nothing
    if ( $db_version eq $target_version ) {
        carp 'Upgrade not necessary';
        return;
    }

    unless ( $db_version eq $self->get_db_version ) {
        $self->throw_exception(
            "Attempt to upgrade DB from $db_version but current version is "
              . $self->get_db_version );
    }

    my $sqlt_type = $self->storage->sqlt_type;

    # add Upgrade before/after subs

    my $upgradeclass = ref($self) . "::Upgrade";
    my ( @before_upgrade_subs, @after_upgrade_subs );
    eval {
        eval "require $upgradeclass" or return;
        @before_upgrade_subs = $upgradeclass->before_upgrade($target_version);
        @after_upgrade_subs  = $upgradeclass->after_upgrade($target_version);
    };

    # translate current schema

    my $curr_sqlt = SQL::Translator->new(
        no_comments   => 1,
        parser        => 'SQL::Translator::Parser::DBIx::Class',
        parser_args   => { dbic_schema => $self, },
        producer      => $sqlt_type,
        show_warnings => 1,
    ) or $self->throw_exception( SQL::Translator->error );
    $curr_sqlt->show_warnings(0);
    $curr_sqlt->translate;

    # translate target schema

    # our target future-versioned connect causes warning messages we don't want
    my $old_DBIC_NO_VERSION_CHECK = $ENV{DBIC_NO_VERSION_CHECK} || 0;
    $ENV{DBIC_NO_VERSION_CHECK} = 1;

    # we'll reuse connect_info from existing schema for target ver connect
    my $connect_info = $self->storage->connect_info;

    # padd out user/pass if they don't exist
    while ( scalar @$connect_info < 3 ) {
        push @$connect_info, undef;
    }

    # add next version
    $connect_info->[3]->{_version} = $target_version;

    my $target_schema = ref($self)->connect(@$connect_info);

    # turn noises back to normal level
    $ENV{DBIC_NO_VERSION_CHECK} = $old_DBIC_NO_VERSION_CHECK;

    my $target_sqlt = SQL::Translator->new(
        no_comments   => 1,
        parser        => 'SQL::Translator::Parser::DBIx::Class',
        parser_args   => { dbic_schema => $target_schema, },
        producer      => $sqlt_type,
        show_warnings => 1,
    ) or $self->throw_exception( SQL::Translator->error );
    $target_sqlt->show_warnings(0);
    $target_sqlt->translate;

    # we need to add renamed_from into $target_sqlt->schema extras

    foreach my $source_name ( $target_schema->sources ) {

        my $source = $target_schema->source($source_name);

        # tables

        my $table        = $target_sqlt->schema->get_table( $source->name );
        my $versioned    = $source->resultset_attributes->{versioned};
        my $table_since  = $versioned->{since};
        my $renamed_from = $versioned->{renamed_from};

        if (   $versioned
            && $renamed_from
            && to_PerlVersion($table_since) eq $target_version )
        {
            if ( grep { $_ eq $renamed_from } $self->sources ) {

                # $renamed_from smells like class name rather than table
                $renamed_from =
                  $self->resultset($renamed_from)->result_source->name;
            }
            $table->extra( renamed_from => $renamed_from );
        }

        # columns

        foreach my $column ( $source->columns ) {
            my $column_info = $source->column_info($column);
            my $versioned   = $column_info->{versioned};
            my $renamed =
              $versioned->{renamed_from} || $column_info->{renamed_from};
            if ($renamed) {
                my $since =
                  $versioned->{since} || $column_info->{since} || $table_since;
                if ( to_PerlVersion($since) eq $target_version ) {
                    my $field = $table->get_field($column);
                    $field->extra( renamed_from => $renamed );
                }
            }
        }
    }

    # now we create the diff which we need as array so we can process one
    # line at a time

    my @diff = SQL::Translator::Diff->new(
        {
            output_db               => $sqlt_type,
            source_schema           => $curr_sqlt->schema,
            target_schema           => $target_sqlt->schema,
            ignore_index_names      => 1,
            ignore_constraint_names => 1,
        }
    )->compute_differences->produce_diff_sql;

    my $exception;
    try {
        $self->txn_do(
            sub {

                # Upgrade.pm before

                foreach my $sub (@before_upgrade_subs) {
                    $sub->($self)
                      or die "Failed upgrade before $target_version sub";
                }

                # execute SQL one line at a time

                foreach my $line (@diff) {

                    # drop comments and BEGIN/COMMIT
                    next if $line =~ /(^--|BEGIN|COMMIT)/;

                    $self->storage->dbh_do(
                        sub {
                            my ( $storage, $dbh ) = @_;
                            if ( $sqlt_type eq 'SQLite' ) {

                                # FIXME: SQLite barfs on FK constraints
                                # during temp table copy
                                if ( $line =~ /CREATE TEMPORARY TABLE/ ) {
                                    $line =~ s/,\n\s*FOREIGN KEY.+?\n/\n/;
                                }
                            }
                            $dbh->do($line);
                        }
                    );
                }

                # Upgrade.pm after

                unless ( $sqlt_type =~ /^(PostgreSQL|SQLite)$/ ) {

                    # FIXME: sadly we can't do this as part of this transaction
                    # in Pg & SQLite - reason still to be determined

                    foreach my $sub (@after_upgrade_subs) {
                        $sub->($target_schema)
                          or die "Failed upgrade after $target_version sub";
                    }
                }
            }
        );

        $self->txn_do(
            sub {
                if ( $sqlt_type =~ /^(PostgreSQL|SQLite)$/ ) {

                    # FIXME: see comments within transaction above
                    # perform the 'after' steps we were forced to skip earlier

                    foreach my $sub (@after_upgrade_subs) {
                        $sub->($target_schema)
                          or die "Failed upgrade after $target_version sub";
                    }
                }
            }
        );
    }
    catch {
        $exception = $_;
    };

    if ( defined $exception ) {
        $self->throw_exception($exception);
    }
    else {

        # set row in dbix_class_schema_versions table
        $self->_set_db_version( { version => "$target_version" } );
    }
}

sub versioned_schema {
    my ( $self, $version ) = @_;

    my $pversion = to_PerlVersion($version);

    my $schema_first_version = $self->schema_first_version;
    $self->add_version($schema_first_version) if defined $schema_first_version;
    $self->add_version($self->schema_version);

    foreach my $source_name ( $self->sources ) {

        my $source = $self->source($source_name);

        unless ( defined $schema_first_version ) {

            # $FIRST_VERSION not defined for schema so we check resultset since
            my $versioned = $source->resultset_attributes->{versioned};
            if ( !defined $versioned || !defined $versioned->{since} ) {
                $self->throw_exception(
"\$FIRST_VERSION not defined for schema and 'since' not defined for '$source_name' - you must use one of them"
                );
            }
        }

        # check columns before deciding on class-level since/until to make sure
        # we don't miss any versions

        foreach my $column ( $source->columns ) {

            my $column_info = $source->column_info($column);
            my $versioned   = $column_info->{versioned};

            my ( $changes, $renamed, $since, $until );
            if ($versioned) {
                $changes = $versioned->{changes};
                $renamed = $versioned->{renamed_from};
                $since   = $versioned->{since};
                $until   = $versioned->{until};
                $until   = $versioned->{till} if defined $versioned->{till};
            }
            else {
                $changes = $column_info->{changes};
                $renamed = $column_info->{renamed_from};
                $since   = $column_info->{since};
                $until   = $column_info->{until};
                $until   = $column_info->{till} if defined $column_info->{till};
            }

            # handle since/until first

            my $name = "$source_name column $column";
            my $sub  = sub {
                my $source = shift;
                $source->remove_column($column);
            };
            $self->_since_until( $pversion, $since, $until, $name, $sub,
                $source );

            # handled renamed column

            if ($renamed) {
                unless ($since) {

                    # catch sitation where class has since but renamed_from
                    # on column does not (renamed PK columns for example)

                    my $rsa_ver = $source->resultset_attributes->{versioned};
                    $since = $rsa_ver->{since} if $rsa_ver->{since};
                }
            }

            # handle changes

            if ($changes) {
                $self->throw_exception("changes not a hasref in $name")
                  unless ref($changes) eq 'HASH';

                foreach my $change_version (
                    sort { to_PerlVersion($a) <=> to_PerlVersion($b) }
                    keys %$changes
                  )
                {

                    my $change_value = $changes->{$change_version};

                    $self->throw_exception(
                        "not a hasref in $name changes $change_version")
                      unless ref($change_value) eq 'HASH';

                    # stash the version
                    $self->add_version($change_version);

                    if ( $pversion >= to_PerlVersion($change_version) ) {
                        unless ( $source->remove_column($column)
                            && $source->add_column( $column => $change_value ) )
                        {
                            $self->throw_exception(
                                "Failed change $change_version for $name");
                        }
                    }
                }
            }
        }

        # check relations

        foreach my $relation_name ( $source->relationships ) {

            my $attrs = $source->relationship_info($relation_name)->{attrs};

            next unless defined $attrs;

            my $versioned = $attrs->{versioned};

            # TODO: changes/renamed_from for relations?
            my ( $since, $until );
            if ($versioned) {
                $since = $versioned->{since};
                $until = $versioned->{until};
                $until = $versioned->{till} if defined $versioned->{till};
            }
            else {
                $since = $attrs->{since};
                $until = $attrs->{until};
                $until = $attrs->{till} if defined $attrs->{till};
            }

            my $name = "$source_name relationship $relation_name";
            my $sub  = sub {
                my $source = shift;
                my %rels   = %{ $source->_relationships };
                delete $rels{$relation_name};
                $source->_relationships( \%rels );
            };
            $self->_since_until( $pversion, $since, $until, $name, $sub,
                $source );
        }

        # check class-level since/until

        my ( $since, $until );

        my $versioned = $source->resultset_attributes->{versioned};

        if ( defined $versioned ) {
            $since = $versioned->{since} if defined $versioned->{since};
            $until = $versioned->{until} if defined $versioned->{until};
        }

        my $name = $source_name;
        my $sub  = sub {
            my $class = shift;
            $class->unregister_source($source_name);
        };
        $self->_since_until( $pversion, $since, $until, $name, $sub, $self );
    }
}

sub _since_until {
    my ( $self, $pversion, $since, $until, $name, $sub, $thing ) = @_;

    my ( $pv_since, $pv_until );

    if ($since) {
        $pv_since = to_PerlVersion($since);
        $self->add_version($pv_since);
    }
    if ($until) {
        $pv_until = to_PerlVersion($until);
        $self->add_version($pv_until);
    }

    if ( $pv_since && $pv_until && $pv_since > $pv_until ) {
        $self->throw_exception("$name has since greater than until");
    }

    # until is absolute so parse before since
    if ( $pv_until && $pversion >= $pv_until ) {
        $sub->($thing);
    }
    if ( $pv_since && $pversion < $pv_since ) {
        $sub->($thing);
    }
}

1;

=head1 SUMMARY

Schema versioning for DBIx::Class with version information embedded
inline in the schema definition.

See L</VERSION NUMBERS> below for important information regarding schema
version numbering.

=head1 SYNOPSIS

 package MyApp::Schema;

 use parent 'DBIx::Class::Schema';

 __PACKAGE__->load_components('Schema::Versioned::Inline');

 our $FIRST_VERSION = '0.001';
 our $VERSION = '0.002';

 __PACKAGE__->load_namespaces;

 ...

 package MyApp::Schema::Result::Bar;

 use base 'DBIx::Class::Core';

 __PACKAGE__->table('bars');

 __PACKAGE__->add_columns(
    "bars_id" => {
        data_type => 'integer', is_auto_increment => 1
    },
    "age" => {
        data_type => "integer", is_nullable => 1
    },
    "height" => {
      data_type => "integer", is_nullable => 1,
      versioned => { since => '0.003' }
    },
    "weight" => {
      data_type => "integer", is_nullable => 1,
      versioned => { until => '0.3' }
    },
 );

 __PACKAGE__->set_primary_key('bars_id');

 __PACKAGE__->has_many(
    'foos', 'TestVersion::Schema::Result::Foo',
    'foos_id', { versioned => { until => '0.003' } },
 );

 __PACKAGE__->resultset_attributes( { versioned => { since => '0.002' } } );

 ...

 package MyApp::Schema::Result::Foo;

 use base 'DBIx::Class::Core';

 __PACKAGE__->table('foos');

 __PACKAGE__->add_columns(
    "foos_id" => {
        data_type => 'integer', is_auto_increment => 1
    },
    "age" => {
        data_type => "integer", is_nullable => 1,
        versioned => { since => '0.002' }
    },
    "height" => {
        data_type => "integer", is_nullable => 1,
        versioned => { until => '0.002' }
    },
    "width" => {
        data_type => "integer", is_nullable => 1,
        versioned => {
            since   => '0.002', renamed_from => 'height',
            changes => {
                '0.0021' => { is_nullable => 0, default_value => 0 }
            },
        }
    },
    "bars_id" => {
        data_type => 'integer', is_foreign_key => 1, is_nullable => 0,
        versioned => { since => '0.002' }
    },
 );

 __PACKAGE__->set_primary_key('foos_id');

 __PACKAGE__->belongs_to(
    'bar',
    'TestVersion::Schema::Result::Bar',
    'bars_id',
    { versioned => { since => '0.002' } },
 );

 __PACKAGE__->resultset_attributes( { versioned => { until => '0.003' } } );

 ...

 package MyApp::Schema::Upgrade;

 use base 'DBIx::Class::Schema::Versioned::Inline::Upgrade';
 use DBIx::Class::Schema::Versioned::Inline::Upgrade qw/before after/;

 before '0.3.3' => sub {
     my $schema = shift;
     $schema->resultset('Foo')->update({ bar => '' });
 };

 after '0.3.3' => sub {
     my $schema = shift;
     # do something else
 };


=head1 DESCRIPTION

This module extends L<DBIx::Class::Schema::Versioned> using simple
'since' and 'until' tokens within result classes to specify the
schema version at which classes and columns were introduced or
removed. Column since/until definitions are included as part of
'versioned' info in add_column(s).

=head2 since

When a class is added to a schema at a specific schema version
version then a 'since' attribute must be added to the class which
returns the version at which the class was added. For example:

 __PACKAGE__->resultset_attributes({ versioned => { since => '0.002' }});

It is not necessary to add this to the initial version of a class
since any class without this atribute is assumed to have existed for
ever.

Using 'since' in a column or relationship definition denotes the
version at which the column/relation was added. For example:

 __PACKAGE__->add_column(
    "age" => {
        data_type => "integer", is_nullable => 1,
        versioned => { since => '0.002' }
    }
 );

For changes to column_info such as a change of data_type see L</changes>.

Note: if the Result containing the column includes a class-level
C<since> then there is no need to add C<since> markers for columns
created at the same version.

Relationships are handled in the same way as columns:

 __PACKAGE__->belongs_to(
    'bar',
    'MyApp::Schema::Result::Bar',
    'bars_id',
    { versioned => { since => '0.002' } },
 );

=head2 until

When used as a class attribute this should be the schema version at
which the class is to be removed. The underlying database table will
be removed when the schema is upgraded to this version. Example
definitions:

 __PACKAGE__->resultset_attributes({ versioned => { until => '0.7' }});

 __PACKAGE__->add_column(
    "age" => {
        data_type => "integer", is_nullable => 1,
        versioned => { until => '0.5' }
    }
 );

Using 'until' in a column or relationship definition will cause
removal of the column/relation from the table when the schema is
upgraded to this version.

=head2 renamed_from

This is always used alongside 'since' in the renamed class/column and
there must also be a corresponding 'until' on the old class/column.

NOTE: when renaming a class the 'renamed_from' value is the table name
of the old class and NOT the class name.

For example when renaming a class:

 package MyApp::Schema::Result::Foo;

 __PACKAGE__->table('foos');
 __PACKAGE__->resultset_attributes({ versioned => { until => '0.5 }});

 package MyApp::Schema::Result::Fooey;

 __PACKAGE__->table('fooeys');
 __PACKAGE__->resultset_attributes({
    versioned => { since => '0.5, renamed_from => 'foos' }
 });

And when renaming a column:

 __PACKAGE__->add_columns(
    "height" => {
        data_type => "integer",
        versioned => { until => '0.002' }
    },
    "width" => {
        data_type => "integer", is_nullable => 0,
        versioned => { since => '0.002', renamed_from => 'height' }
    },
 );

As can been seen in the example it is possible to modify column
definitions at the same time as a rename but care should be taken to
ensure that any data modification (such as ensuring there are no
longer null values when is_nullable => 0 is introduced) must be
handled via L</Upgrade.pm>.

NOTE: if columns are renamed at the same version that a class/table is
renamed (for example a renamed PK) then you MUST also add
C<renamed_from> to the column as otherwise data from that column will
be lost. In this special situation adding C<since> to the column is
not required.

=head2 changes

Column definition changes are handled using the C<changes> token. A
hashref is created for each version where the column definition
changes which details the new column definition in effect from that
change revision. For example:

 __PACKAGE__->add_columns(
    "item_weight",
    {
        data_type => "integer", is_nullable => 1, default_value => 4,
        versioned => { until => '0.001 },
    },
    "weight",
    {
        data_type => "integer", is_nullable => 1,
        versioned => {
            since        => '0.002',
            renamed_from => 'item_weight',
            changes => {
                '0.4' => {
                    data_type   => "numeric",
                    size        => [10,2],
                    is_nullable => 1,
                }
                '0.401' => {
                    data_type   => "numeric",
                    size        => [10,2],
                    is_nullable => 0,
                    default_value => "0.0",
                }
            }
        }
    }
 );

Note: the initial column definition should never be changed since that
is the definition to be used from when the column is first created
until the first change is effected.

=head2 Upgrade.pm

For details on how to apply data modifications that might be required
during an upgrade see L<DBIx::Class::Schema::Versioned::Inline::Upgrade>.

=head1 VERSION NUMBERS

Under the hood all version numbers are handled using L<Perl::Version> which
can lead to confusion if you do not understand how Perl versions are
manipulated. For example:

  $a = Perl::Version->new(0.4)
  $b = Perl::Version->new(0.3)
  $a > $b                           # TRUE

But things can start to look very odd as soon as we use different numbers of
decimal places:


  $a = Perl::Version->new(0.12)
  $b = Perl::Version->new(0.30)
  $a > $b                           # TRUE

And just to add to potential confusion:

  $a = Perl::Version->new(0.12)
  $b = Perl::Version->new("0.30")
  $a > $b                           # FALSE

The motto of this story is that you must be careful how you manage your
versions. Please read L<Perl::Version> pod carefully and make sure you
understand how it operates. To avoid unexpected behaviour it is recommended
that you B<always> quote the version and if possible use a dotted-decimal
with at least three components or use simple cardinal numbers which can
never be confused.

=head1 ATTRIBUTES

=head2 schema_versions

A L<Set::Equivalence> set of L<PerVersion|Types::PerlVersion> objects
containing all of the available schema versions.

Versions should be added using L</add_version>.

=head1 METHODS

Many methods are inherited or overloaded from L<DBIx::Class::Schema::Versioned>.

=head2 add_version( $version [, $v2, ... ] )

Adds one or more versions to L</schema_versions> set. Arguments can either
be L<PerlVersion|Types::PerlVersion> objects or simple scalars which will
be coerced into such.

=cut

=head2 connection

Overloaded method. This checks the DBIC schema version against the DB
version and uses the DB version if it exists or the schema version if
the database is currently unversioned.

=head2 deploy

Inherited method. Same as L<DBIx::Class::Schema/deploy> but also
calls C<install>.

=head2 downgrade

Call this to attempt to downgrade your database from the version it
is at to the version this DBIC schema is at. If they are the same
it does nothing.

=head2 downgrade_single_step

=head2 install

Inherited method. Call this to initialise a previously unversioned
database.

=head2 get_db_version

Override L<DBIx::Class::Schema::Versioned/get_db_version> to return the
version as a L<PerlVersion|Types::PerlVersion> object.

=head2 ordered_schema_versions

  $self->ordered_schema_version('desc');

Optional argument defines the order (ascending or descending). With no arg
(or an arg we cannot determine direction from) results in ascending.

=head2 schema_first_version

Returns the current schema class' $FIRST_VERSION in a normalised way.

If the schema does not define $FIRST_VERSION then all resultsets must
specify the version at which they were added using L</since>.

=head2 schema_version

Override L<DBIx::Class::Schema/schema_version> to return the version as
a L<PerlVersion|Types::PerlVersion> object.

=head2 stringified_ordered_schema_versions

Calls L</ordered_schema_versions> with the same args and converts the returned
list elements to stringified versions.

=head2 upgrade

Inherited method. Call this to attempt to upgrade your database from
the version it is at to the version this DBIC schema is at. If they
are the same it does nothing.

=head2 upgrade_single_step

=over 4
 
=item Arguments: db_version - the version currently within the db
 
=item Arguments: target_version - the version to upgrade to

=back

Overloaded method. Call this to attempt to upgrade your database from
the I<db_version> to the I<target_version>. If they are the same it
does nothing.

All upgrade operations within this step are performed inside a single
transaction so either all succeed or all fail. If successful the
dbix_class_schema_versions table is updated with the I<target_version>.

This method may be called repeatedly by the L</upgrade> method to
upgrade through a series of updates.

=head2 versioned_schema

=over 4

=item Arguments: version - the schema version we want to deploy

=back

Parse schema and remove classes, columns and relationships that are
not valid for the requested version.

=head1 CANDY

See L<DBIx::Class::Schema::Versioned::Inline::Candy>.

=head1 CAVEATS

Please anticipate API changes in this early state of development.

=head1 TODO

=over 4

=item * Sequence renaming in Pg, MySQL (maybe?). Not required for SQLite.

=item * Index renaming for auto-created indexes for UCs, etc - Pg + others?

=item * Downgrades

=item * Schema validation

=back

=head1 AUTHOR

Peter Mottram (SysPete), "peter@sysnix.com"

=head1 CONTRIBUTORS

Slaven Rezić (eserte)
Stefan Hornburg (racke)
Peter Rabbitson (ribasushi)

=head1 BUGS

This is BETA software so bugs and missing features are expected.

Please report any bugs or feature requests via the project's GitHub
issue tracker:

L<https://github.com/Sysnix/dbix-class-schema-versioned-inline/issues>

I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Schema::Versioned::Inline

You can also look for information at:

=over 4

=item * GitHub repository

L<https://github.com/Sysnix/dbix-class-schema-versioned-inline>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-Schema-Versioned-Inline>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Schema-Versioned-Inline>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-Schema-Versioned-Inline/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Best Practical Solutions for the L<Jifty> framework and
L<Jifty::DBI> which inspired this distribution. Many thanks to all of
the L<DBIx::Class> and L<SQL::Translator> developers for those
excellent distributions and especially to ribasushi and ilmari for all
of their help and input.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Peter Mottram (SysPete).

This program is free software; you can redistribute it and/or modify
it under the terms of either: the GNU General Public License as
published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
