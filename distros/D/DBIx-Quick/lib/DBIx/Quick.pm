package DBIx::Quick;

use v5.16.3;
use strict;
use warnings;

use Import::Into;
use Data::Dumper;
use SQL::Abstract::More;

my %SEARCHABLE_FIELDS;
my %TABLES;
my %COLUMNS;
my %FIELDS;
my %FIXED;
my %PRIMARY_KEYS;
my %CONVERTERS;

our $VERSION = "0.8";

sub import {
    my $caller          = caller;
    my $caller_instance = "${caller}::Instance";
    require Moo;
    Moo->import::into($caller);
    Moo->import::into($caller_instance);
    {
        no strict 'refs';

        *{"${caller}::field"} = sub {
            _field_sub( $caller, $caller_instance, @_ );
        };

        *{"${caller}::table"} = sub {
            my $tablename = shift;
            $TABLES{$caller} = $tablename;
        };

        *{"${caller}::fix"} = sub {
            die "To fix the object $caller fill the table name"
              if !$TABLES{$caller};
            die "A pk field is needed to fix $caller"
              if !$PRIMARY_KEYS{$caller};
            $caller_instance->can('has')->( dbh => ( is => 'ro' ) );
            $caller->can('with')->('DBIx::Quick::Role');
            {
                *{"${caller_instance}::fetch_again"} = sub {
                    my ($self)     = @_;
                    my ($instance) = @{
                        $caller->new( dbh => $self->dbh )->search(
                            $PRIMARY_KEYS{$caller} =>
                              $self->can( $PRIMARY_KEYS{$caller} )->($self)
                        )
                    };
                    return $instance;
                };
            }
            $FIXED{$caller} = 1;
        };

        *{"${caller}::instance_has"} = sub {
            my (@args) = @_;
            $caller_instance->can('has')->(@args);
        };

        *{"${caller}::instance_sub"} = sub {
            if ( @_ != 2 ) {
                die 'Wrong number of arguments, expected <name> <coderef>.';
            }
            my ( $name, $code ) = @_;
            if ( 'CODE' ne ref $code ) {
                die 'Expected coderef in the second argument';
            }
            *{"${caller_instance}::${name}"} = $code;
        };

        *{"${caller}::insert"} = sub {
            my ( $self, $instance ) = @_;
            _insert( $caller, $self, $instance );
        };

        *{"${caller}::update"} = sub {
            my ( $self, $instance, @to_update ) = @_;
            _update( $caller, $self, $instance, @to_update );
        };

        *{"${caller}::delete"} = sub {
            my ( $self, $instance ) = @_;
            _delete( $caller, $self, $instance );
        };

        *{"${caller}::search"} = sub {
            my ( $self, %search_params ) = @_;
            _search( $caller, $self, %search_params );
        };

        *{"${caller}::free_search"} = sub {
            my ( $self, %search_params ) = @_;
            _advanced_search( $caller, $self, %search_params );
        }
    }
}

sub _delete {
    my ( $caller, $self, $instance ) = @_;
    _check_fixed($caller);
    my $dbh  = $self->dbh;
    my $sqla = SQL::Abstract::More->new;
    my ( $sql, @bind ) = $sqla->delete(
        -from  => $TABLES{$caller},
        -where => {
            $PRIMARY_KEYS{$caller} =>
              $instance->can( $PRIMARY_KEYS{$caller} )->($instance),
        }
    );
    $dbh->do( $sql, undef, @bind );
}

sub _insert {
    my ( $caller, $self, $instance ) = @_;
    _check_fixed($caller);
    my $dbh  = $self->dbh;
    my $sqla = SQL::Abstract::More->new;
    my ( $sql, @bind ) = $sqla->insert(
        -into   => $TABLES{$caller},
        -values => _filter_undef( _values_from_instance( $caller, $instance ) ),
    );
    return $dbh->do( $sql, undef, @bind );
}

sub _filter_undef {
    my $values = shift;
    my %final_hash;
    for my $key ( keys %$values ) {
        next if !defined $values->{$key};
        $final_hash{$key} = $values->{$key};
    }
    return \%final_hash;
}

sub _update {
    my ( $caller, $self, $instance, @values_to_update ) = @_;
    _check_fixed($caller);
    my $pk_col   = _get_primary_key_column($caller);
    my $pk_field = $PRIMARY_KEYS{$caller};
    my $dbh      = $self->dbh;
    my $sqla     = SQL::Abstract::More->new;
    my ( $sql, @bind ) = $sqla->update(
        -table => $TABLES{$caller},
        -set   => _filter_values(
            $caller, _values_from_instance( $caller, $instance ),
            @values_to_update
        ),
        -where => {
            $pk_col => $instance->can($pk_field)->($instance),
        }
    );
    return $dbh->do( $sql, undef, @bind );
}

sub _filter_values {
    my ( $caller, $values, @only_if_present_here ) = @_;
    my %final_values;
    for my $key ( keys %$values ) {
        if (
            !List::Util::any { $_ eq $FIELDS{$caller}{$key} }
            @only_if_present_here
          )
        {
            next;
        }
        $final_values{$key} = $values->{$key};
    }
    return \%final_values;
}

sub _get_primary_key_column {
    my ($caller) = @_;
    return $COLUMNS{$caller}{ $PRIMARY_KEYS{$caller} };
}

sub _values_from_instance {
    my ( $caller, $instance ) = @_;
    my %columns = %{ $COLUMNS{$caller} };
    my %final_hash;
    for my $field ( keys %columns ) {
        my $value = $instance->can($field)->($instance);
        if ( defined $CONVERTERS{$caller}{$field} ) {
            $value = $CONVERTERS{$caller}{$field}->to_db($value);
        }
        $final_hash{ $columns{$field} } = $value;
    }
    return \%final_hash;
}

sub _check_fixed {
    my ($caller) = @_;
    die "$caller must be fixed before using it!" if !$FIXED{$caller};
}

sub _advanced_search {
    my ( $caller, $object, %search_params ) = @_;
    _check_fixed($caller);
    my $dbh  = $object->dbh;
    my $sqla = SQL::Abstract::More->new;
    my @columns =
      sort { $a cmp $b } map { $TABLES{$caller} . '.' . $COLUMNS{$caller}{$_} }
      keys %{ $COLUMNS{$caller} };
    if ( defined delete $search_params{'-from'} ) {
        warn '-from not supported in free search use -join';
    }
    if ( defined delete $search_params{'-columns'} ) {
        warn '-columns not supported in free search, use a normal'
          . ' query with dbh instead, this returns rows of the DAO'
          . ' with SQL::Abstract::More you can have all this module querying features.';
    }
    my $join = delete $search_params{'-join'} // [];
    if ( 'ARRAY' ne ref $join ) {
        die '-join must be an arrayref';
    }
    my @joins = @{$join};
    my ( $sql, @bind ) = $sqla->select(
        -columns => [@columns],
        -from    => [ -join => $TABLES{$caller}, (@joins) ],
        %search_params,
    );
    return [ map { _row_to_instance( $caller, $object, $_ ) }
          @{ $dbh->selectall_arrayref( $sql, { Slice => {} }, @bind ) } ];
}

sub _search {
    my ( $caller, $object, %search_params ) = @_;
    _check_fixed($caller);
    my $dbh  = $object->dbh;
    my $sqla = SQL::Abstract::More->new;
    my @columns =
      sort { $a cmp $b } map { $TABLES{$caller} . '.' . $COLUMNS{$caller}{$_} }
      keys %{ $COLUMNS{$caller} };
    my %final_search;
    for my $param_key ( keys %search_params ) {
        my $column = $COLUMNS{$caller}{$param_key};
        if ( !defined $column ) {
            die "$param_key in $caller doesn't exist";
        }
        if ( !defined $SEARCHABLE_FIELDS{$caller}{$param_key} ) {
            die "$param_key in $caller is not searchable";
        }
        $final_search{$column} = $search_params{$param_key};
    }
    my ( $sql, @bind ) = $sqla->select(
        -columns => [ @columns, ],
        -from    => $TABLES{$caller},
        (
              (%final_search)
            ? ( -where => { %final_search, } )
            : ()
        )
    );
    return [ map { _row_to_instance( $caller, $object, $_ ) }
          @{ $dbh->selectall_arrayref( $sql, { Slice => {} }, @bind ) } ];
}

sub _row_to_instance {
    my ( $caller, $object, $row ) = @_;
    my %final_hash;
    for my $column ( keys %$row ) {
        my $field = $FIELDS{$caller}{$column};
        my $value = $row->{$column};
        if ( defined $CONVERTERS{$caller}{$field} ) {
            $value = $CONVERTERS{$caller}{$field}->from_db($value);
        }
        $final_hash{$field} = $value;
    }
    return ( $caller . '::Instance' )->new( %final_hash, dbh => $object->dbh );
}

sub _field_sub {
    my ( $caller, $caller_instance, $field, @args ) = @_;
    my %params     = @args;
    my $searchable = delete $params{search};
    my $fk         = delete $params{fk};
    my $column     = delete $params{column} // $field;
    my $pk         = delete $params{pk};
    my $converter  = delete $params{converter};
    if ( defined $converter ) {
        if ( !eval { $converter->does('DBIx::Quick::Converter') } ) {
            die
"$field converter must implement the DBIx::Quick::Converter Role and be a Moo class";
        }
        $CONVERTERS{$caller}{$field} = $converter;
    }
    $COLUMNS{$caller}{$field} = $column;
    $FIELDS{$caller}{$column} = $field;

    if ($pk) {
        $PRIMARY_KEYS{$caller} = $field;
    }
    _parse_fk( $caller, $caller_instance, $field, $fk );
    _mark_searchable( $caller, $searchable, $field );
    _create_instance_attribute( $caller_instance, $field, %params );
}

sub _create_instance_attribute {
    my ( $caller_instance, $field, %args ) = @_;
    $caller_instance->can('has')->( $field, %args );
}

sub _parse_fk {
    my ( $caller, $caller_instance, $field, $fk ) = @_;
    if ( defined $fk && ( 'ARRAY' ne ref $fk || 3 > scalar @$fk ) ) {
        die
"${caller}::${field} fk parameter must be an arrayref containing <remote_object> <remote_attr> <remote_object_name_in_this_object> [<this_object_name_in_the_remote_object>]";
    }
    if ( defined $fk ) {
        my (
            $remote_object, $remote_attr,
            $remote_object_name_in_this_object,
            $this_object_name_in_the_remote_object
        ) = @$fk;
        no strict 'refs';
        if ( defined $this_object_name_in_the_remote_object ) {

            # One to one doesn't require this thingy.
            *{      $remote_object
                  . '::Instance::'
                  . $this_object_name_in_the_remote_object } = sub {
                my ($self) = shift;
                if ( !defined $self->dbh ) {
                    die 'This is not an object found by the ORM';
                }
                return $caller->new( dbh => $self->dbh )
                  ->search( $field => $self->can($remote_attr)->($self) );
                  };
        }
        *{ $caller_instance . '::' . $remote_object_name_in_this_object } =
          sub {
            my ($self) = shift;
            if ( !defined $self->dbh ) {
                die 'This is not an object found by the ORM';
            }
            return $remote_object->new( dbh => $self->dbh )
              ->search( $remote_attr => $self->can($field)->($self) );

          };
        $SEARCHABLE_FIELDS{$caller}{$field} = 1;
    }
}

sub _mark_searchable {
    my ( $caller, $searchable, $field ) = @_;
    if ($searchable) {
        $SEARCHABLE_FIELDS{$caller}{$field} = 1;
    }
}
1;

=pod

=encoding utf-8

=head1 NAME

DBIx::Quick - Object Relational Mapping for the lazy programmer

=head1 SYNOPSIS

 package MyApp::DAO::Users;
 
 use strict;
 use warnings;
 
 use DBIx::Quick;

 table 'users';

 has dbh => (is => 'ro', required => 1);

 field id => (is => 'ro', search => 1, pk => 1);
 field username => (is => 'rw', search => 1, required => 1, column => 'user_name');
 field id_address => (is => 'rw', search => 1, fk => ['MyApp::DAO::Addresses', 'id', 'addresses', 'users']);
 field timestamp => (is => 'rw', search => 1, converter => MyApp::DB::Converters::DateTime->new);

 fix;

And elsewhere:

 my $user = MyApp::DAO::Users::Instance->new(username => 'lazybastard', id_address => 5);
 my $dao = MyApp::DAO::Users->new(dbh => DBI->connect(...));
 $dao->insert($user)
 ($user) = @{$dao->search(username => 'lazybastard')};
 $user->username('lazyandproductive');
 $dao->update($user, 'username');
 $user = $user->fetch_again; 
 $dao->delete($user);

=head1 DESCRIPTION

L<DBIx::Quick> is the needed bridge between L<Moo> and your database, you create DAO objects in a similar fashion to L<Moo> and those objects auto-create
the corresponding instances under the same package plus ::Instance, importing this module becomes your package into a L<Moo> class and the created
class is also a L<Moo> one.

Many times writing object to relational database mapping you find yourself having to repeat the same information once and once again which becomes
tiring for the developer, Models and DAO are created in a single step in a single file to prevent this, but they remain completely separate classes,
methods are provided to take full advantage of the separation.

The L<Moo> syntax also provides shorter code overall.

This module is preliminar, meaning the syntax is probably not the definitive one, if you are a programmer who wants to spend less effort into
making full blown applications feel free to join the development with suggestions or patches.

If you are needing too fancy autocomplete or templates just to be productive maybe you instead need L<DBIx::Quick>.

To check an example project that uses this code you can check L<https://github.com/sergiotarxz/Perl-App-RSS-Social>.

=head1 DAO DECLARATIONS

While declaring a L<DBIx::Quick> mapping you can use the following subs autoimported into your package namespace.

=head2 table

 table 'transactions';

Specify the table this DAO maps to.

=head2 field

 field id => (is => 'ro', pk => 1, search => 1);
 field amount => (is => 'ro', required => 1, search => 1, column => 'amnt');
 field tax => (is => 'ro');
 field id_user => (is => 'ro', required => 1, search => 1, fk => ['MyApp::DAO::Users', 'id', 'users', 'transactions']);

field is the equivalent to L<Moo> C<has> sub implementing all its options (useful or not) to represent a column into the table.

It provides the following extra options:

=head3 pk

Defines the primary key if sent a trueish value

=head3 search

Marks this column as searchable for the generated search method.

=head3 column

Allows to change the destination column by default it would be called as the field itself. 

=head3 fk

Takes four arguments: The destination class, the destination field, the method to represent in our model the remote class and optionally the remote instance method to represent our own class.

=head3 converter

See L<DBIx::Quick::Converter>

=head2 fix

Ensures the class is ready to be used and marks the class as ready.

=head2 instance_sub

 instance_sub uppercase_username => sub {
 	my $self = shift;
 	return uc($self->username);
 };

and later:

 $user->uppercase_username;

Declares a subroutine to be added to the generated ::Instance Object.

=head2 instance_has

 instance_has cache => (is => 'lazy');
 instance_sub _build_cache => sub {
 	my $redis = Redis->new;
	return $redis;
 };

Makes a L<Moo> attribute available to the ::Instance Object with the same syntax than L<Moo> has.

=head2 dbh

You must declare a dbh method or a L<Moo> attribute returning a DBI connection.

=head1 DAO METHODS

=head2 search

 my @transactions = @{$dao->search(
	# SQL::Abstract::More where syntax using field names instead of columns
 	amnt => { '>', 10000 },
 	tax  =>	21,
 )}

Searchs ::Instance Objects in the table using L<SQL::Abstract::More> where syntax but replacing the column names by field names.

=head2 free_search

 my @transactions = @{$dao->free_search(
 	-join => [
 		'users.id=transactions.id_user users',
 	],
        -where => {
 		'users.surname' => {-like => 'Gar%'},
 	},
 )};

Searchs ::Instance Objects in the table using all the syntax of L<SQL::Abstract::More> select, columns are the real columns not fields.

-columns and -from are not allowed to be used. -from should be substituted by -join and -columns is not needed.

=head2 insert

 $dao->insert(MyApp::DAO::Users::Instance->new(username => 'ent'));

Inserts a row in the table, doesn't return the inserted field. You can use UUIDs or other known unique attributes of the table to search for
the inserted object.

=head2 update

 $user->username('X');
 $user->surname('González');
 $dao->update($user, 'username', 'surname');

Takes an instance and a list of the fields that should be updated in db with the instance data for that row, updates them and doesn't have a
meaningful return. Searches the object to update by the primary key.

=head2 delete

 $dao->delete($user);

Vanishes the instance of the database. Searches by the primary key.

=head1 INSTANCE SUBS

=head2 fetch_again

 $user = $user->fetch_again;

Get remote updates the ::Instance object may have.

=head2 dbh

 $user->dbh($dbh);

Sets a database to be used in the constructor of the corresponding DAO while doing fetch_again.

=head1 BUGS AND LIMITATIONS

Every DAO/Instance must be associated directly with a table, if you need something extra, the good old and reliable L<SQL::Abstract::More> is 
enough to you.

Errors must be improved to allow users to debug easier faulty code.

API is not stable since this program is so early in its development that I do not know if incorrect assumptions or bad design is hiding here.

No many to many easy wrapper, use free_search, I could not come up with something that would be better than directly creating your own
queries with free_search.

=head1 AUTHOR

SERGIOXZ - Sergio Iglesias

=head1 CONTRIBUTORS

SERGIOXZ - Sergio Iglesias

=head1 COPYRIGHT

Copyright © Sergio Iglesias (2025)

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<https://dev.perl.org/licenses/>.

=cut
