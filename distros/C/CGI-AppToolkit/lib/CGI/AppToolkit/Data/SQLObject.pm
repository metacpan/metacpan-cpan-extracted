package CGI::AppToolkit::Data::SQLObject;

# Copyright 2002 Robert Giseburt. All rights reserved.
# This library is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

# Email: rob@heavyhosting.net

$CGI::AppToolkit::Data::SQLObject::VERSION = '0.05';

use base 'CGI::AppToolkit::Data::Object';
use Carp;

use strict;
use vars qw/$AUTOLOAD/;

#-------------------------------------#
# OO Methods                          #
#-------------------------------------#

# vars used:
# %key_map
# $table
# $index
# @all_insert_columns
# %default_insert_columns
# @all_update_columns
# %default_update_columns
# @required_columns
# 

# fetch some objects
sub fetch {
	my $self = shift;
	my $args = ref $_[0] eq 'HASH' ? shift : {@_};
	$self->_remap_keys($args);

	my $statement = undef;
	my $values = {};
	
	if ($self->can('prefetch')) {
		($statement, $values) = $self->prefetch($args);	
	}		
	
	unless ($statement) {
		my @name = ();
		my %tables = ($self->get_table() => 1);
		my $name = undef;
		
		$name = $self->_make_statement_name($args, $values);
		
		unless ($statement = $self->get_db_statement($name)) {
			my $sql = "select * from " . join (', ', keys %tables);
			my @order = ();
			
			$sql .= $self->_make_where($args, $name, \@order);
			
#			carp "fetch SQL: $sql\n";
#			carp(join(', ', map{ref $_ eq 'ARRAY' ? @$_ : @_} @{$values}{@order}));
			
			my $sth = $self->get_kit->get_dbi()->prepare($sql);
			
			$statement = [$sth, \@order];
			$self->set_db_statement($name, $statement);
		}
	}
		
	if (!$statement) {
		if ($self->get_kit->get_errors_fatal()) {
			croak "CGI::AppToolkit Data Error (SQLObject): Unable to " . ref $self . "->fetch()";
		} elsif ($^W) {
			carp "CGI::AppToolkit Data Error (SQLObject): Unable to " . ref $self . "->fetch()";
			return undef;
		}
	}
	
	my ($sth, $order) = @$statement;
	
	$sth->execute(map {ref $_ eq 'ARRAY' ? @$_ : @_} @{$values}{@$order});
	
	return $self->_default_return($args, $sth);
}


#-------------------------------------#

# store an object
sub store {
	my $self = shift;
	
	#if we're passed several values, recurse then quit
	if (ref $_[0] eq 'ARRAY') {
		my $ret = [];
		my $stores = shift;
		
		foreach my $args (@$stores) {
			push @$ret, $self->store($args);
		}
			
		return $ret;
	}
	
	my $args = ref $_[0] eq 'HASH' ? shift : {@_};
	$self->_remap_keys($args);

	my $index = $self->get_index();
	my $required_columns = $self->get_required_columns();

	my $error_object = $self->_new_error();
	
	# check for missing args
	foreach my $key (@$required_columns) {
		unless (defined $args->{$key}) {
			$error_object->error("Missing '$key'.");
			$error_object->missing($key);	
		}
	}
	
	return $error_object if $error_object->has_errors;

	if ($self->can('prestore')) {
		$self->prestore($args, $error_object);	
	}		

	return $error_object if $error_object->has_errors;

	# save a new one and return the id
	if ((($index && !$args->{$index}) || $args->{'-insert'}) && !$args->{'-update'}) {

		if ($self->can('preinsert')) {
			$self->preinsert($args, $error_object);	
		
			return $error_object if $error_object->has_errors;
		}		

		my $statement = $self->get_db_statement('insert');
		my ($sth, $order) = @$statement;
	
		return $error_object if $error_object->has_errors;

		$sth->execute(@{$args}{@$order});

		if ($self->can('postinsert')) {
			$self->postinsert($args, $sth);	
		}		
	
		return $error_object if $error_object->has_errors;

		return $args;

	# update and return the old info
	} else {
		
		my $old = undef;
		if (defined wantarray || $self->can('preupdate')) {
			$old = $self->fetch({'id' => $args->{'id'}, '-one' => 1});
		}

		if ($self->can('preupdate')) {
			$self->preupdate($args, $old, $error_object);	
		
			return $error_object if $error_object->has_errors;
		}		
		
		my $statement = $self->get_db_statement('update');
		my ($sth, $order) = @$statement;	
		$sth->execute(@{$args}{@$order});

		if ($self->can('postupdate')) {
			$self->postupdate($args, $old, $sth);	
		}		
				
		return $old if defined wantarray;
	}
}


#-------------------------------------#

# get a prepared db statement
sub update {
	my $self = shift;
	my $name = shift;
		
	#if we're passed several values, recurse then quit
	if (ref $_[0] eq 'ARRAY') {
		my $ret = [];
		my $stores = shift;
		
		foreach my $args (@$stores) {
			push @$ret, $self->update($args);
		}
			
		return $ret;
	}
	
	my $args = ref $_[0] eq 'HASH' ? shift : {@_};

	$args->{'-update'} = 1;
	return $self->store($args);
}

#-------------------------------------#

# delete some objects
sub delete {
	my $self = shift;
	my $args = ref $_[0] eq 'HASH' ? shift : {@_};
	$self->_remap_keys($args);

	my $statement = undef;
	my $values = {};
	
	if ($self->can('predelete')) {
		($statement, $values) = $self->predelete($args);	
	}		
	
	unless ($statement) {
		my $table = $self->get_table();
		my $name = undef;
		
		$name = "delete:" . $self->_make_statement_name($args, $values);
		
		unless ($statement = $self->get_db_statement($name)) {
			my $sql = "delete from $table";
			my @order = ();
			
			$sql .= $self->_make_where($args, $name, \@order);
			
#			carp "delete SQL: $sql\n";
#			carp(join(', ', map{ref $_ eq 'ARRAY' ? @$_ : @_} @{$values}{@order}));
			
			my $sth = $self->get_kit->get_dbi()->prepare($sql);
			
			$statement = [$sth, \@order];
			$self->set_db_statement($name, $statement);
		}
	}
		
	if (!$statement) {
		if ($self->get_kit->get_errors_fatal()) {
			croak "CGI::AppToolkit Data Error (SQLObject): Unable to " . ref $self . "->delete()";
		} elsif ($^W) {
			carp "CGI::AppToolkit Data Error (SQLObject): Unable to " . ref $self . "->delete()";
			return undef;
		}
	}
	
	my ($sth, $order) = @$statement;
	
	$sth->execute(map {ref $_ eq 'ARRAY' ? @$_ : @_} @{$values}{@$order});
	
	return 1;
}


#-------------------------------------#

# get a prepared db statement
sub get_db_statement {
	my $self = shift;
	my $name = shift;
	
	unless ($self->{'_db_cache'}{$name}) {
		my $statement = undef;
		
		if ($self->can('get_db_statement_local')) {
			$statement = $self->get_db_statement_local($name);
		}
		
		if (!$statement) {
			my $db = $self->get_kit->get_dbi();
			my $table = $self->get_table();
			my $index = $self->get_index();

			if ($name eq 'insert') {
				my $all_columns = $self->get_all_insert_columns() || $self->get_all_columns();
				my $default_insert_columns = $self->get_default_insert_columns() || {};
				my @default_insert_columns_keys = sort keys %$default_insert_columns;
				
				my @keys = (@default_insert_columns_keys, @$all_columns);
				unshift @keys, $index if ($index);
				
				my @values = (@{$default_insert_columns}{@default_insert_columns_keys}, ('?') x (scalar @$all_columns));
				unshift @values, '?' if ($index);
				
				my $sth = $db->prepare(
					"INSERT INTO $table (" .
						join(', ', @keys) .
					") VALUES (" .
						join(', ', @values) .
					")"
					);
					
				my @order = (@$all_columns);
				unshift @order, $index if ($index);
				
				$statement = [$sth, \@order];
				
			} elsif (!$statement && $name eq 'update') {
				my $all_columns = $self->get_all_update_columns() || $self->get_all_columns();
				my $default_update_columns = $self->get_default_update_columns() || {};
				my $sth = $db->prepare(
					"update $table set " .
						join(', ', map {"$_=$default_update_columns->{$_}"} sort keys %$default_update_columns) .
						join('=?, ', @$all_columns) .
					"=? where $index=?"
					);
				
				my @order = (@$all_columns, $index);
				
				$statement = [$sth, \@order];
				
			}
		}
				
		$self->{'_db_cache'}{$name} = $statement;
	}
	
	$self->{'_db_cache'}{$name} || undef
}


#-------------------------------------#

# store a prepared db statement
sub set_db_statement {
	my $self = shift;
	my $name = shift;
	
	$self->{'_db_cache'}{$name} = shift;
}


#-------------------------------------#
# Inherited Non-Interface Methods     #
#-------------------------------------#

sub _default_return {
	my $self = shift;
	my $args = shift;
	my $sth = shift;

	my $key_map = $self->get_key_map() || {};
	
	my $old_names = $sth->{'NAME_lc'};
	my @names = map {$key_map->{$_} || $_} @$old_names;

	my $ret = undef;
	
	if ($args->{'-one'}) {
		my $columns = $sth->fetch() || [];
		my $row = {};
		@{$row}{@names} = @$columns;
		$ret = $row;
	} else {
		$ret = [];
		while (my $columns = $sth->fetch()) {
			my $row = {};
			@{$row}{@names} = @$columns;
			push @$ret, $row;
		}
	}
#	
#	my $ret = $args->{'-one'} ?
#			$sth->fetchrow_hashref() :
#			$sth->fetchall_arrayref({}); # note: arrayref of hashrefs
	
	return $self->cleanup($ret);
}


#-------------------------------------#


sub _remap_keys {
	my $self = shift;
	my $args = shift;
	my %$old_args = %$args;
	my $key_map = $self->get_key_map() || {};
	
	map {$args->{$key_map->{$_}} = $old_args->{$_}} keys %$key_map;
	
	$args
}


#-------------------------------------#


sub _make_statement_name {
	my $self = shift;
	my $args = shift;
	my $values = shift;

	if ($args->{'-all'}) {
		return '-all';
	} else {
		my @name = ();
		foreach my $key (sort keys %$args) {
			next if $key =~ /^-/;
			push @name, $key;
	
			if (ref $args->{$key} eq 'ARRAY') {
				$values->{$key} = [@{$args->{$key}}];
	
				$name[-1] .= '/' . $args->{$key}[0] . (scalar(@{$args->{$key}}) - 1);
				shift @{$values->{$key}};
	
			} else {
				$values->{$key} = [$args->{$key}];				
			}
		}
		
		return join '|', @name;
	}
}


#-------------------------------------#


sub _make_where {
	my $self = shift;
	my $args = shift;
	my $name = shift;
	my $order = shift;
	my $sql  = '';
	
	if ($name ne '-all') {
		$sql .= ' where ';
		
		my @where = ();
		
		foreach my $key (sort keys %$args) {
			next if $key =~ /^-/;

			if (ref $args->{$key} eq 'ARRAY') {
				if (lc $args->{$key}[0] eq 'in') {
					push @where,  "$key $args->{$key}[0] (" . join(', ', ('?') x (scalar(@{$args->{$key}}) - 1)) . ")";
				} else {
					push @where,  "$key $args->{$key}[0] ?";
				}
				
				push @$order, $key;
				
			} else {
				push @where,  "$key = ?";
				push @$order, $key;
			}
		}
		
		$sql .= join ' and ', @where;
	}
	
	$sql
}


#-------------------------------------#

__DATA__

=head1 NAME

B<CGI::AppToolkit::Data::SQLObject> - A SQL data source component of L<B<CGI::AppToolkit>|CGI::AppToolkit> that inherits from L<B<CGI::AppToolkit::Data::Object>|CGI::AppToolkit::Data::Object>

=head1 DESCRIPTION

B<CGI::AppToolkit::Data::SQLObject>s provide a common interface to multiple data sources. This interface is an extension of the L<B<CGI::AppToolkit::Data::Object>|CGI::AppToolkit::Data::Object> interface. Providing a SQL data source requires creating an object in the B<CGI::AppToolkit::Data::> namespace that inherits from B<CGI::AppToolkit::Data::SQLObject>.

There is generally a one-to-one correlation between the B<CGI::AppToolkit::Data::SQLObject>s and the SQL tables.

You B<do not> C<use> this module or it's descendants in your code directly, but instead call B<CGI::AppToolkit-E<gt>data()> to load it for you.

=head2 WHAT'S SO GREAT ABOUT SQLObject?

B<CGI::AppToolkit::Data::SQLObject> provides overriden B<fetch()>, B<fetch_one()>, B<store()>, B<update()>, and B<delete()> functions that handle most of the common tasks for you, and allow you to simply inherit them and provide specialized SQL when you need to.

=head2 METHODS TO USE FROM YOUR BASE SCRIPT

=over 4

=item B<fetch(>I<ARGUMENTS>B<)>

=item B<fetch_one(>I<ARGUMENTS>B<)>

This method takes a hash (a hash reference or key =E<gt> value pairs that can easily be placed into a hash) as arguments, makes a SELECT SQL statement based upon those arguments, and returns either an arrayref of hashrefs (called as B<fetch()>) or a hashref (called as B<fetch_one()>). In either case, each hashref represents one row returned from the SELECT statement, with the column names as the keys, like returned from L<B<DBI>|DBI>'s B<$sth-E<gt>fetchall_arrayref({})>. (The column names may be mapped to other names. See the B<key_map> variable later in this document.)

The keys of the hash you provide are used as column names, and the values are used literally. For example:

  $kit->data('person')->fetch_one(name => 'Rob');
  # also: $kit->data('person')->fetch_one({name => 'Rob'});

Will automatically generate the following SQL for you (assuming you don't override it):

  select * from person where name = ?

And then calls DBI like this (metaphorically speaking, of course):

  $sth->execute('Rob');

If you send an arrayref as the 'value', then the first item is assumed to be a comparison operator, and the rest of the items are what's to be compared to. For example:

  $kit->data('person')->fetch_one(id => ['<', 12]);

Generates the following SQL:

  select * from person where id < ?

And then calls DBI like this (again, metaphorically):

  $sth->execute(12);

=item B<store(I<ARGUMENTS>)>

This method takes the arguments provided as a hash or hash reference and makes an INSERT or UPDATE statement based upon them. The keys are used as column names (after column name mapping, see the B<key_map> variable later in this document), and the values are taken literally as column values. If an index (a.k.a. primary key) column is persent and non-B<undef>, then an UPDATE is done in a similar fashion.
B<store()> returns a L<B<CGI::AppToolkit::Data::Object::Error>|CGI::AppToolkit::Data::Object/"CGI::AppToolkit::Data::Object::Error"> upon failure, otherwise it conventionally returns the data that was passed to it, possibly altered (e.g.: an unique ID was assigned, etc.).

=item B<update(I<ARGUMENTS>)>

This method is the same as B<store()>, with the exception that an UPDATE statement is always generated reguarless of the index column.

=item B<delete(I<ARGUMENTS>)>

Similar to fetch, except a DELETE SQL statement is generated. The arguments are used in the same manner. Always returns '1' for now.

=back

=head2 HOW TO EXTEND SQLObject FOR USE

To use B<CGI::AppToolkit::Data::SQLObject> you have to create a module that inherits from B<CGI::AppToolkit::Data::SQLObject> and overrides a few methods. You I<must> override B<init()> at least.

Please see L<B<CGI::AppToolkit::Data::TestSQLObject>|CGI::AppToolkit::Data::TestSQLObject> for example code.

=head2 METHODS TO USE

=over 4

=item B<get_kit()>

(Inherited from L<B<CGI::AppToolkit::Data::Object>|CGI::AppToolkit::Data::Object>.)

Returns the creating B<CGI::AppToolkit> object. This can be used to retrieve required data.

  my $dbi = $self->get_kit()->get_dbi();

In particular, B<CGI::AppToolkit-E<gt>get_dbi()> retrieves the DBI object stored from a call to B<CGI::AppToolkit-E<gt>connect()>.

=back

=head2 METHODS TO OVERRIDE

B<CGI::AppToolkit::Data::SQLObject> has a few methods you can override. You I<must> override B<init()>.

=over 4

=item X<init>B<init(>I<SELF>B<)>

B<You must override this method.> In this method, you must provide certain variables using various accessor methods, like this for the variable B<table>:

  	$self->set_table('test_shebang');

Note that in all cases, case sensitivity of the values are that of the DBD you are using.

B<You MUST provide these variables (the type of value is shown after the name):>

=over 4

=item B<table> - String

Sets the relation database table name accessed primarily by this object.

=item B<index> - String

Provides the name of the relation database table that is the unique identifier.

=item B<all_columns> - Array reference

Provides a list of the names of every column in the table.

See also the optional valiables B<all_insert_columns>, B<default_insert_columns>, B<all_update_columns>, and B<default_update_columns>. If you provide I<both> B<all_insert_columns> I<and> B<all_update_columns>, this variable will be ignored.

=back

B<These variables are optional:>

=over 4

=item B<all_insert_columns> - Array reference

Provides a list of the names of every column in the table used in SQL INSERTs. 

  $self->set_all_insert_columns([qw/address zip password active verified html/]);

=item B<default_insert_columns> - Hash reference

Provides a list of keys (column names) and absolute values of columns in the table used in SQL INSERTs. The columns mentioned I<must not> be in B<all_insert_columns> as well.

  $self->set_default_insert_columns({'start' => 'now()'});

=item B<all_update_columns> - Array reference

Provides a list of the names of every column in the table used in SQL UPDATEs. 

=item B<default_update_columns> - Hash reference

Provides a list of keys (column names) and absolute values of columns in the table used in SQL UPDATEs. The columns mentioned I<must not> be in B<all_update_columns> as well.

=item B<key_map> - Hash reference

Provides a hash of 'fake column name' to 'real column name' mappings. B<fetch()>, B<fetch_one()>, B<store()>, B<update()>, and B<delete()> use this before generating or using any SQL. This can be used to create easy-to-use interface names for ugly table column names. For example:

  $self->set_key_map({id => 'TBL_PERSON_INDEX', name => 'TBL_PERSON_NAME', address => 'TBL_PERSON_ADDRESSX');

Column names that are not referenced by this map are used as is, so you I<don't> have to provide a key mapping for every column. 

=back

=item X<get_db_statement_local>B<get_db_statement_local(>I<SELF>, I<STATEMENT_NAME>B<)>

This method is used to provide SQL to the rest of the B<SQLObject> methods. This method is not required to be overriden, but you most likely want to.

It is passed a reference to the SQLObject object and a statement name, and returns an array ref containing a DBD statement handle (as returned by B<DBD-E<gt>prepare(...)>) and an arrayref of keys to supply to B<DBD-E<gt>execute()> to replace the ('?') placeholders in the SQL. For example, B<get_db_statement_local()> could return like:

  return [$db->prepare('select * from people where id=? and name=?'), [qw/id name/]];

Please see L<B<DBI>|DBI> or the B<DBD> for your database engine for more information about B<prepare()> and placeholders.

The statement name is generated as follows:

=over 4

=item 1

If B<get_db_statement_local()> is called from B<store()>, the name is set to 'update' or 'insert', depending on the type of storing requested, and the rest of the steps are skipped.

=item 2

The arguments passed to the function (such as B<fetch>) are sorted alphanumerically. The arguments that begin with a '-' are ignored.

=item 3

If the value of the argument is an array reference, the first item is assumed to be a comparison operator, and the rest the items to be compared. For example: C<id =E<gt> ['E<lt>', 20]> or C<id =E<gt> ['in', 'this', 'that']>. In this case, a forward slash ('/'), the comparison operator, and the number of items to be 'compared to' are added to the name.

=item 4

The names are combined with pipes ('|').

=item 5

If it's being called from B<delete()> then 'delete:' is prepended to the name.

=back

So, when calling:

  $kit->data('name')->fetch(name => ['in', 'frank', 'george']);

Then B<($self-E<gt>get_db_statement_local('name/in2')> would be called by B<fetch()>. Similarly,

  $kit->data('name')->delete(name => 'john', id => ['<', '12'], address => '1234 Main');

Then B<($self-E<gt>get_db_statement_local('delete:address|id/E<lt>1|name')> would be called by B<delete()>.

An example B<get_db_statement_local> method:

  sub get_db_statement_local {
    my $self = shift;
    my $name = shift;
    
    my $db = $self->get_kit->get_dbi();
    
    if ($name eq 'now') {
      return [$db->prepare('select now() as now'), []];
      
    } elsif ($name eq 'date/<1') {
      return [$db->prepare('select * from people, events where event.person = people.id and event.start < ?'), [qw/date/]];
    }
    
    undef
  }


=item B<prefetch(>I<SELF>, I<ARGS>B<)>

This method is called from B<fetch()>, and is used to override the default SELECT statement.

Only use this method if B<get_db_statement_local()> cannot be used, for some reason.

You must return an array reference and a hash reference. The first array reference contains a DBI statement handle (B<prepare()>d SQL SELECT statement), and the key names of the ARGS to use, in the order to use them. The second returned value, a hash reference, contains the values to use. This can often be the ARGS that were passed.

Return B<undef> to continue as if B<prefetch()> were not defined for the given ARGS.

An example implementation of B<prefetch)>:

  sub prefetch {
    my $self = shift;
    my $args = shift;
    
    my $db = $self->get_kit->get_dbi();
    
    if ($args->{'id'}) {
      return [$db->prepare('select id, name, password where id=? order by id desc'), [qw/id/]], $args;
    }
    
    undef
  }

=item B<predelete(>I<SELF>, I<ARGS>B<)>

This method is basically the same as B<prefetch()>, except called from B<delete()>. It is used to override the UPDATE statement. It's called the same and has the same return style.

Only use this method if B<get_db_statement_local()> cannot be used, for some reason.

=item B<prestore(>I<SELF>, I<ARGS>, I<ERROR OBJECT>B<)>

This method is called during the data error checking portion of the B<store()> call. It is passed the arguments that were passed to B<store()>, and an empty L<B<CGI::AppToolkit::Data::Object::Error>|CGI::AppToolkit::Data::Object/"CGI::AppToolkit::Data::Object::Error"> object. This method allows you to check the ARGS and alter them or use the error object to stop the store process and pass an error back to the caller of B<store()>.

=item B<preinsert(>I<SELF>, I<ARGS>, I<ERROR OBJECT>B<)>

This method is called immediately before an INSERT statment is executed. It is passed the arguments that were passed to B<store()> (after B<prestore()> has been called, possibly altering them), and an empty L<B<CGI::AppToolkit::Data::Object::Error>|CGI::AppToolkit::Data::Object/"CGI::AppToolkit::Data::Object::Error"> object. This method allows you to check the ARGS and alter them or use the error object to stop the store process and pass an error back to the caller of B<store()>.

=item B<postinsert(>I<SELF>, I<ARGS>, I<STATEMENT HANDLE>B<)>

This method is called after the INSERT statement has ben executed. It is passed the arguments that were passed to B<store()> (after B<prestore()> and B<preinsert()> have been called, possibly altering them), and the executed B<DBI>/B<DBD> statement handle. This method allows you to inspect the ARGS and statement handle and possibly alter the ARGS before they are returned to the caller of B<store()>.

=item B<preupdate(>I<SELF>, I<ARGS>, I<OLD DATA>, I<ERROR OBJECT>B<)>

This method is called immediately before an UPDATE statment is executed. It is passed the arguments that were passed to B<store()> or B<update()> (after B<prestore()> has been called, possibly altering them), a hashef of the old data (B<fetch>ed immediately before calling B<preupdate()>), and an empty L<B<CGI::AppToolkit::Data::Object::Error>|CGI::AppToolkit::Data::Object/"CGI::AppToolkit::Data::Object::Error"> object. This method allows you to check the ARGS and the old data and alter the ARGS or use the error object to stop the store process and pass an error back to the caller of B<store()> or B<update()>.

=item B<postupdate(>I<SELF>, I<ARGS>, I<OLD DATA>, I<STATEMENT HANDLE>B<)>

This method is called after the UPDATE statement has ben executed. It is passed the arguments that were passed to B<store()> or B<update()> (after B<prestore()> and B<preinsert()> have been called, possibly altering them), a hashef of the old data (B<fetch>ed immediately before calling B<preupdate()>), and the executed B<DBI>/B<DBD> statement handle. This method allows you to inspect the ARGS and statement handle and possibly alter the ARGS before they are returned to the caller of B<store()> or B<update()>.

=back

=head1 TODO

The primary to-do for now is to provide automatic range/data checking facilities before INSERT/UPDATE statements are made. This way you can catch potentially fatal INSERTS before hand and return to the interface gracefully. This is where data checking should occur, after all.

=head1 AUTHOR

Copyright 2002 Robert Giseburt (rob@heavyhosting.net).  All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Please visit http://www.heavyhosting.net/AppToolkit/ for complete documentation.

=cut