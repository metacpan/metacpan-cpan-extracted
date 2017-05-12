package DBIx::Table::TestDataGenerator;
use Moo;

use strict;
use warnings;

our $VERSION = "0.005";
$VERSION = eval $VERSION;

use Carp;

use aliased 'DBIx::Table::TestDataGenerator::DBIxSchemaDumper';
use aliased 'DBIx::Table::TestDataGenerator::UniqueConstraint';
use aliased 'DBIx::Table::TestDataGenerator::ForeignKey';
use aliased 'DBIx::Table::TestDataGenerator::Randomize';
use aliased 'DBIx::Table::TestDataGenerator::Query';
use aliased 'DBIx::Table::TestDataGenerator::SelfReference';
use aliased 'DBIx::Table::TestDataGenerator::Tree';
use aliased 'DBIx::Table::TestDataGenerator::DBIxHelper';

has dsn => (
    is       => 'ro',
    required => 1,
);

has user => (
    is       => 'ro',
    required => 1,
);

has password => (
    is       => 'ro',
    required => 1,
);

has table => (
    is       => 'ro',
    required => 1,
);

has on_the_fly_schema_sql => (
    is       => 'ro',
    required => 0,
);

has schema => (
    is       => 'rw',
    required => 0,
    init_arg => undef,
);

{

    #database handle for the target database, will be the database
    #the target table is in or a csv file in case csv_dir is defined
    my $dbh_out;
    my $is_autocommit;

    sub create_testdata {
        my ( $self, %args ) = @_;

        my $target_size               = $args{target_size};
        my $num_random                = $args{num_random};
        my $max_tree_depth            = $args{max_tree_depth};
        my $min_children              = $args{min_children};
        my $min_roots                 = $args{min_roots};
        my $roots_have_null_parent_id = $args{roots_have_null_parent_id};
        my $csv_dir                   = $args{csv_dir};
        my $keep_connection_alive     = $args{keep_connection_alive};
        my $transaction_size          = $args{transaction_size};

        my $dumper = DBIxSchemaDumper->new(
            dsn                   => $self->dsn,
            user                  => $self->user,
            password              => $self->password,
            table                 => $self->table,
            on_the_fly_schema_sql => $self->on_the_fly_schema_sql,
        );

        #dump DBIC schema to file and load it
        my ( $dbh, $schema ) = @{ $dumper->dump_schema() };
        $self->schema($schema);

        my ( $num_records_added, $num_roots );

        if ( $num_random < 2 ) {
            croak 'num_random must be greater or equal to two';
        }

        #Exit if only part of the parameters used to handle self-references has
        #been provided.
        if (   defined $max_tree_depth
            || defined $min_children
            || defined $min_roots )
        {
            croak
              'to handle a self-reference, you need to specify max_tree_depth, '
              . 'min_children and min_roots, the min_roots parameter is missing'
              unless defined $min_roots;
            croak
              'to handle a self-reference, you need to specify max_tree_depth, '
              . 'min_children and min_roots, the min_children parameter is missing'
              unless defined $min_children;
            croak
              'to handle a self-reference, you need to specify max_tree_depth, '
              . 'min_children and min_roots, the max_tree_depth parameter is missing'
              unless defined $max_tree_depth;
        }

      #Determine whether the user has provided all informations needed to handle
      #a possible self-reference.
        my $handle_self_ref_wanted =
             defined $max_tree_depth
          && defined $min_children
          && defined $min_roots;

        #Determine original number of records in target table.
        my $num_records_orig =
          Query->num_records( $self->schema, $self->table );

        if ( $num_records_orig == 0 ) {
            croak 'The target table ' . $self->table . ' must not be empty';
        }

        my $num_records_to_insert = $target_size - $num_records_orig;
        if ( $num_records_to_insert <= 0 ) {
            print 'already enough records in table '
              . $self->table
              . "\ncurrent number: $num_records_orig, requested: $target_size\n";
            $dbh->disconnect();
            return;
        }

        #Columns whose name does NOT appear in @handled_cols will get
        #their values from the target table itself.
        my @handled_cols;

        #Determine information about uniqueness constraints
        my $uniq_info = UniqueConstraint->new(
            schema => $self->schema,
            table  => $self->table,
        );

     #Add columns in uniqueness constraints which will be incremented to handled
     #columns list
        my %unique_cols_to_incr = %{ $uniq_info->unique_cols_to_incr };
        push @handled_cols, keys %unique_cols_to_incr;

        #Add primary key column to be increased resp. auto-increment pkey column
        #to list of handled columns.
        push @handled_cols, $uniq_info->pkey_col;

        #determine information about foreign key constraints
        my $fkey_info = ForeignKey->new(
            schema                    => $self->schema,
            table                     => $self->table,
            handle_self_ref_wanted    => $handle_self_ref_wanted,
            pkey_col                  => $uniq_info->pkey_col,
            pkey_col_names            => $uniq_info->pkey_col_names,
            roots_have_null_parent_id => $roots_have_null_parent_id,
        );

        my $tree = Tree->new(
            nodes => $fkey_info->selfref_tree,
            root  => $fkey_info->root
        );
        push @handled_cols, @{ $fkey_info->fkey_cols };

     #Handle the columns where the values are taken from the target table itself
        my @cols = @{ DBIxHelper->column_names( $self->schema, $self->table ) };

        #Filter out already handled columns.
        my @cols_from_target_table =
          grep {
            my $c = $_;
            !( grep { lc $_ eq lc $c } @handled_cols )
          } @cols;

        my ( %fkey_random_val_caches, @target_table_cache, $pkey_val );

        $num_records_added = 0;

        if ($csv_dir) {

            $dbh_out = DBI->connect(
                'dbi:CSV:',
                undef, undef,
                {
                    f_dir           => $csv_dir,
                    f_lock          => 2,
                    f_encoding      => 'utf8',
                    csv_eol         => "\n",
                    csv_sep_char    => '|',
                    csv_quote_char  => '"',
                    csv_escape_char => '"',
                    csv_class       => 'Text::CSV_XS',
                    csv_null        => 1,
                    col_names       => \@cols,
                }
            ) or croak $DBI::errstr;

            #Note: CSV does not support disabling AutoCommit
            $dbh_out->{RaiseError}         = 1;
            $dbh_out->{ShowErrorStatement} = 1;

            $dbh_out->do( 'DROP TABLE IF EXISTS ' . $self->table );
            $dbh_out->do( 'CREATE TABLE '
                  . $self->table . '('
                  . join( ', ', map { "$_ INTEGER" } @cols )
                  . ')' );
        }
        else {
            $dbh_out = $dbh;
        }

        eval { $dbh_out->{AutoCommit} = 0; };
        $is_autocommit = $@ ? 1 : 0;

        eval {
            #Define the prepared insert statement.
            my $sth_insert =
              Query->prepare_insert( $dbh_out, $self->table, \@cols );

            my $random_pkey = (
                values %{ Randomize->random_record(
                        $self->schema, $self->table,
                        [ $fkey_info->parent_pkey_col ]
                    )
                }
            )[0];

            #Main loop, each step determining a new record to be inserted
            for ( 1 .. $num_records_to_insert ) {
                my %insert = ();

                #Select the values from tables referenced by foreign keys.
                foreach ( keys %{ $fkey_info->fkey_tables_ref } ) {
                    my $fkey       = $_;
                    my $fkey_table = $fkey_info->fkey_tables_ref->{$fkey};

                    #If we have already added enough random records, we select
                    #the referenced values from the cache...
                    if ( $num_records_added > $num_random ) {
                        %insert = (
                            %insert,
                            %{
                                @{ $fkey_random_val_caches{$fkey} }
                                  [ int rand $num_random ]
                            }
                        );
                    }

             #...otherwise, get we get the values from randomly selected records
                    else {

                  #Correspondence between columns in target table and referenced
                  #columns:
                        my %refcol_to_col_dict =
                          %{ $fkey_info->all_refcol_to_col_dict->{$fkey} };

                        #List of referenced columns:
                        my $refcol_list = $fkey_info->all_refcol_lists->{$fkey};

                    #If we do not handle a self-reference or the current foreign
                    #key is not the one defining it, take the values randomly
                    #from the referenced table...
                        if (  !$fkey_info->handle_self_ref
                            || $fkey ne $fkey_info->fkey_self_ref )
                        {
                            my %insert_part = %{ Randomize->random_record(
                                    $self->schema, $fkey_table,
                                    $refcol_list,  1
                                )
                            };

                       #To define our insert we need to replace the column names
                       #from the referenced table by those in the target table.
                            for my $key ( keys %insert_part ) {
                                $insert_part{ $refcol_to_col_dict{$key} } =
                                  delete $insert_part{$key};
                            }

                            %insert = ( %insert, %insert_part );

                            #Store the values in a cache.
                            push @{ $fkey_random_val_caches{$fkey} },
                              \%insert_part;
                        }

                        #...otherwise handle the self-reference
                        else {

                      #Only on first run, determine the current number of roots
                      #and increase the number of random samples if necessary to
                      #get a balanced tree.
                            if ( $num_records_added == 0 ) {

                                $num_roots =
                                  SelfReference->num_roots( $self->schema,
                                    $self->table, $roots_have_null_parent_id );
                            }
                        }
                    }

                }    #done with foreign key handling

                #Handle unique, non primary key columns to be incremented,
                #these columns get their new value by applying the appropriate
                #incrementor.
                for ( keys %unique_cols_to_incr ) {
                    $insert{$_} = $unique_cols_to_incr{$_}->();
                }

                #Handle columns selected from target table itself if there
                #are any such columns left to be processed.
                if ( @cols_from_target_table > 0 ) {
                    if ( $num_records_added > $num_random ) {

                        #Select values randomly from the cache.
                        %insert = (
                            %insert,
                            %{ $target_table_cache[ int rand $num_random ] }
                        );
                    }
                    else {

                        #Select values randomly from the target table.
                        my %values = %{ Randomize->random_record(
                                $self->schema, $self->table,
                                \@cols_from_target_table
                            )
                        };

                        #change all keys to lowercase
                        %values =
                          map { lc $_ => $values{$_} } keys %values;
                        %insert = ( %insert, %values );

                        #Store values in cache.
                        push @target_table_cache, \%values;
                    }
                }

                #Handle the values for the primary key column and in case of a
                #self-reference, the value for the referencing field

#Logic:
# I.  self_ref=0: pkey++, no parent_pkey
# II. self_ref=1:
#   (1) auto_incr=0:    pkey++
#         (a) root_node=1:
#               parent_pkey=add_child(...,1)[1]
#
#         (b) root_node=0:
#
#   (2) auto_incr=1:
#         (a) root_node=1:
#               (i)     root_ref_pkey_null=1:   RS::row->pkey, parent_pkey=NULL
#               (ii)    root_ref_pkey_null=0:   RS::row(using dummy existing pkey val for
#                                                parent_pkey)->pkey, parent_pkey:=pkey
#         (b) root_node=0:
#               RS::row(using dummy existing pkey val for parent_pkey)->pkey,
#               parent_pkey=add_child(...,pkey)

                #check if we have a pkey
                if ( defined $uniq_info->pkey_col ) {
                    my $pkey_name = $uniq_info->pkey_col;

                    #if we don't have a self-reference, it's easy
                    if ( !$fkey_info->handle_self_ref ) {
                        $pkey_val = $uniq_info->pkey_col_incrementor->();
                        $insert{$pkey_name} = $pkey_val;
                    }

                    #else handle self-reference
                    else {

                        #get name of the column referencing the pkey column
                        my $parent_pkey_name = $fkey_info->parent_pkey_col;

                        #handle the case where we don't have an auto-increment
                        #pkey column
                        if ( !( $uniq_info->pkey_is_auto_increment ) ) {

                            #the new pkey value is just the increment of the
                            #previous maximum value
                            $pkey_val = $uniq_info->pkey_col_incrementor->();
                            $insert{$pkey_name} = $pkey_val;

                      #we need to handle the column referencing the pkey column.
                      #we either add a root node if there are not enough already
                      #and otherwise we add an arbitrary node (which may be a
                      #root node, too)

                            my $parent_pkey = $tree->add_child(
                                $pkey_val,
                                $min_children,
                                $num_roots < $min_roots ? 1
                                : $max_tree_depth,
                                $min_roots,
                                $num_roots < $min_roots ? 1
                                : undef
                            );

                     #if we have added a root node and parent references of root
                     #nodes must be null, set the value for the referencing
                     #column to null
                            my $is_root_node = $parent_pkey eq $tree->root;
                            $num_roots++ if $is_root_node;

                            if ( $is_root_node && $roots_have_null_parent_id ) {
                                $insert{$parent_pkey_name} = undef;
                            }
                            else {
                                $insert{$parent_pkey_name} = $parent_pkey;
                            }
                            
                            #add value to cache
                            push @{ $fkey_random_val_caches{$fkey_info->fkey_self_ref} },
                              {$fkey_info->fkey_self_ref => $insert{$parent_pkey_name}};

                            #execute the insert
                            my @vals = map { $insert{$_} } @cols;
                            Query->execute_insert( $dbh_out, $sth_insert,
                                \@vals );
                        }

#Auto-increment case:
# $random_pkey is an arbitrary primary key existing before we have started
# adding data to the table (see above)
#
# (i)   First we determine a temp pkey $temp_pkey and reference $temp_ref using
#       add_auto_child(), passing a tree depth of 1 if there are root nodes to be
#       added. Set $is_root_node = 1 if we have added a root node.
#
# (ii)  Then we use a DBIC Row object to add a record to the table, leaving the
#       pkey column empty and setting the ref column to:
#       $random_pkey resp. NULL (depending on the flag $roots_have_null_parent_id)
#       if $is_root_node is true, $temp_ref otherwise.
#       (Reason: $temp_ref does not exist as pkey value if the new tree node is
#       a root node!)
#
# (iii) Let the auto-increment value of the pkey be $pkey_auto. If $is_root_node
#       is true and $roots_have_null_parent_id is false, we update the DBIC Row
#       object by setting the ref column to $pkey_auto. Then we update the
#       foreign key cache.
#
# (iv)  In case $csv_dir has been defined, we need to write the row to the
#       corresponding csv file, too.
#
# (v)   We need to adjust the tree since we have changed the value for the pkey
#       and in case of a root node also the value for the reference column.
#       (Note that we always have pkey = ref for root nodes in the tree, i.e.
#       we ignore the flag $roots_have_null_parent_id w.r.t. tree since it is
#       irrelevant here.)
#       (a) In case we have added a root node, we remove the temp root node from
#           the tree and add a new one having $pkey_auto as parent and child key.
#       (b) Otherwise, we only need to replace $temp_pkey by $pkey_auto.

                        else {

                            #first we add a node to the tree using an temporary
                            #value for the pkey, this defines in particular the
                            #parent key to use
                            #(i)
                            my ( $temp_pkey, $temp_ref ) = @{
                                $tree->add_auto_child(
                                      $num_roots < $min_roots ? $min_roots
                                    : $min_children,
                                    $num_roots < $min_roots ? 1
                                    : $max_tree_depth,
                                    $min_roots,
                                    $num_roots < $min_roots ? 1 : undef
                                )
                            };
                            my $is_root_node = $temp_ref eq $tree->root;

                            #(ii)
                            my $ref;
                            if ($is_root_node) {
                                $ref =
                                  $roots_have_null_parent_id
                                  ? undef
                                  : $random_pkey;
                            }
                            else {
                                $ref = $temp_ref;
                            }
                            $insert{$parent_pkey_name} = $ref;

                            my $row =
                              Query->execute_new_row( $self->schema,
                                $self->table, \%insert );
                            my $pkey_auto =
                              $row->get_column( $uniq_info->pkey_col );

                            #(iii)
                            if ( $is_root_node
                                && !$roots_have_null_parent_id )
                            {
                                $ref = $pkey_auto;
                                $row->update( { $parent_pkey_name => $ref } );
                            }
							
							#add value to cache
                            push @{ $fkey_random_val_caches{$fkey_info->fkey_self_ref} },
                              {$fkey_info->fkey_self_ref => $ref};

                            #(iv)
                            if ($csv_dir) {
                                $insert{$pkey_name}        = $pkey_auto;
                                $insert{$parent_pkey_name} = $ref;
                                my @vals = map { $insert{$_} } @cols;
                                Query->execute_insert( $dbh_out,
                                    $sth_insert, \@vals );
                            }

                            #(v)
                            $tree->remove_leaf_node( $temp_ref, $temp_pkey );
                            $tree->add_leaf_node( $temp_ref, $pkey_auto );

                            $num_roots++ if $is_root_node;
                        }

                    }
                }

                #simple case of no pkey existing
                else {

                    #execute the insert
                    my @vals = map { $insert{$_} } @cols;
                    Query->execute_insert( $dbh_out, $sth_insert, \@vals );
                }

                $num_records_added++;

                #if we are in a transaction and the transaction size has been
                #reached, commit
                if (   $transaction_size
                    && $num_records_added % $transaction_size == 0
                    || !$transaction_size )
                {
                    Query->commit($dbh_out) unless $is_autocommit;
                }
            }

            #Commit all inserts.
            Query->commit($dbh_out)
              if !$is_autocommit
              && (
                (
                       $transaction_size
                    && $num_records_added % $transaction_size != 0
                )
                || !$transaction_size
              );
            Query->disconnect($dbh_out) unless $keep_connection_alive;
        };

        if ($@) {
            warn "Transaction aborted because $@";
            eval { $dbh->rollback };
        }

        return;
    }

    sub disconnect {
        my ($self) = @_;
        Query->disconnect($dbh_out);
        return;
    }

}

1;    # End of DBIx::Table::TestDataGenerator

__END__

=pod

=head1 NAME

DBIx::Table::TestDataGenerator - Automatic test data creation, cross DBMS

=head1 VERSION

Version 0.0.5

=head1 SYNOPSIS

	use DBIx::Table::TestDataGenerator;

	my $generator = DBIx::Table::TestDataGenerator->new(
		dsn                    => 'dbi:Pg:dbname=testdb',
		user                   => 'jose',
		password               => '1234',
		table                  => 'employees',
	);

	#simple usage:
	$generator->create_testdata(
		target_size            => 1000000,
		num_random             => 1000,
	);

	#extended usage handling a self-reference of the target table:
	$generator->create_testdata(
		target_size        => 1000000,
		num_random         => 1000,
		max_tree_depth     => 8,
		min_children       => 2,
		min_roots          => 20,
	);

	#dump test data to a csv file instead
	$generator->create_testdata(
		target_size        => 1000000,
		num_random         => 1000,
		csv_dir            => '/usr/local/tdg_dump',
	);

=head1 DESCRIPTION

The purpose of this module is fuss-free adding of (bulk) test data to database tables and having test data resembling the data already present in the table.

The current module analyzes the structure of a target table and adds a desired number of records. The column values come either from the table itself (incremented if necessary to satisfy uniqueness constraints) or from tables referenced by foreign key constraints. These values are chosen randomly for a number of runs chosen by the user, and afterwards the values are chosen randomly from a cache containing the already chosen values, thus reducing database traffic for performance reasons. (Even when using the cache, there is some randomness involved since the choices from the different caches are random, too.)

A main goal of the module is to reduce configuration to the absolute minimum by automatically determining information about the target table, in particular its constraints and if a primary key column is an auto-increment column or not. Another goal is to support as many DBMSs as possible, which has been achieved by basing it on DBIx::Class modules.

In the synopsis, an extended usage has been mentioned. This refers to the common case of having a self-reference on a table, i.e. a one-column wide foreign key of a table to itself where the referenced column constitutes the primary key. Such a parent-child relationship defines a forest, i.e. a collection of trees. When generating test data it may be useful to have some control over the growth of the trees. One such case is when the parent-child relation represents a navigation tree and a client application processes this structure. In this case, one would like to have a meaningful, balanced tree structure since this corresponds to real-world examples. To control tree creation the parameters max_tree_depth, min_children and min_roots are provided. The tree nodes are being added in a depth-first, right-to-left manner.

You can find an example in the "examples" folder. It contains a script example.sql defining and filling some tables in your target database as well as a small program example.pl using the current module.

=head1 SUBROUTINES/METHODS

=head2 new

Arguments:

=over 4

=item * dsn: DBI data source name (required)

=item * user: database user (required)

=item * password: database user's password (required)

=item * table: name of the target table (required)

=item * on_the_fly_schema_sql: path to an SQL script used to define an in-memory SQLite database. This parameter is only used by the module install to define an in-memory SQLite database to run its test against. (internal, optional)

=back

Return value:

A new TestDataGenerator object

=head2 dsn

Read-only accessor for the DBI data source name.

=head2 user

Read-only accessor for the database user.

=head2 password

Read-only accessor for the database user's password.

=head2 table

Read-only accessor for the name of the target table.

=head2 on_the_fly_schema_sql

Read-only accessor for path to a file containing the definition of the install test database.

=head2 schema

Externally read-only accessor for the DBIx::Class schema created from the target database.

=head2 create_testdata

This is the main method, it creates and adds new records to the target table resp. dumps the data to a csv file, see below. In case one of the arguments max_tree_depth, min_children or min_roots has been provided, the other two must be provided as well.

Arguments:

=over 4

=item * target_size

The number of rows the target table should have after create_testdata has completed.

=item * num_random

The first $num_random number of records use fresh random choices for their values taken from tables referenced by foreign key relations or the target table itself. These values are stored in a cache and re-used for the remaining (target_size - $num_random) records. Note that even for the remaining records there is some randomness since the combination of cached values coming from columns involved in different constraints is random.

=item * max_tree_depth

In case of a self-reference, the maximum depth at which new records will be inserted, old records could of course be on any level. The minimum value for this parameter is 1, the level of the root nodes.

=item * min_children

In case of a self-reference, the minimum number of children each handled parent node will get. The last handled parent node may not get this number of children, of course, if the target number of records is reached before.

=item * min_roots

In case of a self-reference, the minimum number of root elements to create. A record is considered to be a root element if the corresponding parent id is null or equal to the child id.

=item * roots_have_null_parent_id

If true, new root nodes will have NULL as parent id, otherwise the value of their primary key column. Defaults to false. The value should be set according to the convention used in the target table.

=item * csv_dir

Optional path to a csv file which will contain the test data, no data will be written to the target database in this case. If not defined, changes are applied to the target database.

=item * keep_connection_alive

Optional parameter defining if the database handle dbh should still be connected after having created the test data, defaults to false. (For some install tests, we need to set it to true since we are using an in-memory database which would otherwise not be accessible for the tests, but this may also be of use in other scenarios.)

=item * transaction_size

Optional parameter defining a transaction size. In case transactions are not supported, setting the parameter has no effect. If transactions are supported, omitting the parameter resp. setting its value to 0 will result in one big transaction being used.

=back

Returns:

Nothing, only called for the side-effect of adding new records to the target table. (This may change, see the section L</"FURTHER DEVELOPMENT">.)

=head2 disconnect

Arguments: none

Allows to disconnect the connection to the target database in case keep_connection_alive was set to true before when calling create_testdata.

=head1 INSTALLATION AND CONFIGURATION

To install this module, run the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

=head1 LIMITATIONS

=over 4

=item * Only uniqueness and foreign key constraints are taken into account. Constraints such as check constraints, which are very diverse and database specific, are not handled (and most probably will not be).

=item * Uniqueness constraints involving only columns which the Increment class does not know how to increment cannot be handled. Typically, all string and numeric data types are supported and the set of supported data types is defined by the list provided by the TableProbe method get_type_preference_for_incrementing(). I am thinking about allowing date incrementation, too, it would be necessary then to at least add a configuration parameter defining what time incrementation step to use.

=back

=head1 FURTHER DEVELOPMENT

=over 4

=item * The current version handles uniqueness constraints by picking out a column involved in the constraint and incrementing it appropriately. This should be made customizable in future versions.

=item * Currently one cannot specify a seed for the random selections used to define the generated records since the used class DBIx::Class::Helper::ResultSet::Random does not provide this. For reproducible tests this would be a nice feature.

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * Version 0.001:

A big thank you to all perl coders on the dbi-dev, DBIx-Class and perl-modules mailing lists and on PerlMonks who have patiently answered my questions and offered solutions, advice and encouragement, the Perl community is really outstanding.

Special thanks go to Tim Bunce (module name / advice on keeping the module extensible), Jonathan Leffler (module naming discussion / relation to existing modules / multiple suggestions for features), brian d foy (module naming discussion / mailing lists / encouragement) and the following Perl monks (see the threads for user jds17 for details): chromatic, erix, technojosh, kejohm, Khen1950fx, salva, tobyink (3 of 4 discussion threads!), Your Mother.

=item * Version 0.002:

Martin J. Evans was the first developer giving me feedback and nice bug reports on Version 0.001, thanks a lot!

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-table-testdatagenerator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Table-TestDataGenerator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Table::TestDataGenerator

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Table-TestDataGenerator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Table-TestDataGenerator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Table-TestDataGenerator>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Table-TestDataGenerator/>

=back

=head1 AUTHOR

Jose Diaz Seng, C<< <josediazseng at gmx.de> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Jose Diaz Seng.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For more details, see the full text of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose.
