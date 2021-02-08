package DBIx::Table2Hash;

use strict;
use warnings;

use Carp;

our $VERSION = '1.18';

# -----------------------------------------------

# Preloaded methods go here.

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(
		_child_column	=> '',
		_dbh			=> '',
		_skip_columns	=> [],
		_hash_ref		=> '',
		_key_column		=> '',
		_parent_column	=> '',
		_table_name		=> '',
		_value_column	=> '',
		_where			=> '',
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _get_column_names
	{
		my($self, $table_name) = @_;
		my($sth) = $$self{'_dbh'} -> prepare("select * from $table_name where 1=2");

		$sth -> execute();

		$$self{'_column_name'} = $$sth{'NAME_lc'};

		$sth -> finish();

	}	# End of _get_column_names.

	sub _select_tree
	{
		my($self, $root, $children, $parent_id) = @_;
		my($skip)	= join('|', $$self{'_key_column'}, $$self{'_child_column'}, $$self{'_parent_column'}, @{$$self{'_skip_columns'} });
		$skip		= qr/$skip/;

		my($child, $name, $key);

		for my $child (@{$$children{$parent_id} })
		{
			$name			= $$child{$$self{'_key_column'} };
			$$root{$name}	= {};

			for $key (keys %$child)
			{
				next if ($key =~ /$skip/);

				$$root{$name}{$key} = $$child{$key} if ($$child{$key});
			}

			$self -> _select_tree($$root{$$child{$$self{'_key_column'} } }, $children, $$child{$$self{'_child_column'}});
		}

	}	# End of _select_tree.

	sub _standard_keys
	{
		keys %_attr_data;
	}

}	# End of encapsulated class data.

# -----------------------------------------------

sub new
{
	my($class, %arg)	= @_;
	my($self)			= bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($arg{$arg_name}) )
		{
			$$self{$attr_name} = $arg{$arg_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	return $self;

}	# End of new.

# -----------------------------------------------

sub select
{
	my($self, %arg) = @_;

	$self -> set(%arg);

	croak(__PACKAGE__ . '. You must supply a value for the parameters dbh, table_name, key_column and value_column')
		if (! ($$self{'_dbh'} && $$self{'_table_name'} && $$self{'_key_column'} && $$self{'_value_column'}) );

	my($sql) = "select $$self{'_key_column'}, $$self{'_value_column'} from $$self{'_table_name'} $$self{'_where'}";
	my($sth) = $$self{'_dbh'} -> prepare($sql);

	$sth -> execute();

	my($data, %h);

	while ($data = $sth -> fetch() )
	{
		$h{$$data[0]} = $$data[1] if (defined $$data[0]);
	}

	$$self{'_hash_ref'} = \%h;

}	# End of select.

# -----------------------------------------------

sub select_hashref
{
	my($self, %arg) = @_;

	$self -> set(%arg);

	croak(__PACKAGE__ . '. You must supply a value for the parameters dbh, table_name and key_column')
		if (! ($$self{'_dbh'} && $$self{'_table_name'} && $$self{'_key_column'}) );

	$self -> _get_column_names($$self{'_table_name'});

	my(%column_name);

	@column_name{@{$$self{'_column_name'} } } = (1) x @{$$self{'_column_name'} };

	# Due to a bug in MySQL, we cannot say 'col, *', we must say '*, col'.

	my($column_set)	= $column_name{lc $$self{'_key_column'} } ? '*' : "*, $$self{'_key_column'}";
	my($sql)		= "select $column_set from $$self{'_table_name'} $$self{'_where'}";
	my($sth)		= $$self{'_dbh'} -> prepare($sql);

	$sth -> execute();

	my($data, %h);

	while ($data = $sth -> fetchrow_hashref() )
	{
		$h{$$data{$$self{'_key_column'} } } = {%$data} if (defined $$data{$$self{'_key_column'} });
	}

	$$self{'_hash_ref'} = \%h;

}	# End of select_hashref.

# -----------------------------------------------

sub select_tree
{
	my($self, %arg) = @_;

	$self -> set(%arg);

	croak(__PACKAGE__ . '. You must supply a value for the parameters child_column and parent_column')
		if (! ($$self{'_child_column'} && $$self{'_parent_column'}) );

	$self -> select_hashref() if (! $$self{'_hash_ref'});

	my($id, $parent_id, %children);

	for $id (keys %{$$self{'_hash_ref'} })
	{
		$parent_id				= $$self{'_hash_ref'}{$id}{$$self{'_parent_column'} };
		$children{$parent_id}	= [] if (! $children{$parent_id});
		push @{$children{$parent_id} }, $$self{'_hash_ref'}{$id};
	}

	my($tree) = {};

	$self -> _select_tree($tree, \%children, 0);

	$tree;

}	# End of select_tree.

# -----------------------------------------------

sub set
{
	my($self, %arg) = @_;

	for my $arg (keys %arg)
	{
		$$self{"_$arg"} = $arg{$arg} if (exists($$self{"_$arg"}) );
	}

}	# End of set.

# -----------------------------------------------

1;

__END__

=head1 NAME

C<DBIx::Table2Hash> - Read a database table into a hash

=head1 Synopsis

	#!/usr/bin/perl

	use DBIx::Table2Hash;

	my($key2value) = DBIx::Table2Hash -> new
	(
		dbh           => $dbh,
		table_name    => $table_name,
		key_column    => 'name',
		value_column  => 'id'
	) -> select();

	# or

	my($key2hashref) = DBIx::Table2Hash -> new
	(
		dbh           => $dbh,
		table_name    => $table_name,
		key_column    => 'name',
	) -> select_hashref();

	# or

	my($key2tree) = DBIx::Table2Hash -> new
	(
		dbh           => $dbh,
		table_name    => $table_name,
		key_column    => 'name',
		child_column  => 'id',
		parent_column => 'parent_id',
		skip_columns  => ['code']
	) -> select_tree();

=head1 Description

C<DBIx::Table2Hash> is a pure Perl module.

This module reads a database table and stores keys and values in a hash.

The aim is to create a hash which is a simple look-up table. To this end, the module allows the key_column to point to
an SQL expression.

C<select()> and C<select_hashref()> do not nest the hash in any way.

C<select_tree()> returns a nested hash. C<select_tree()> will call C<select_hashref()> if necessary, ie
if you have not called C<select_hashref()> first.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns a C<DBIx::Table2Hash> object.

This is the class's contructor.

Parameters:

Note: These parameters are not checked until you call C<select_*()>, which means the parameters can be passed
in to C<new()>, C<select_*()>, or both.

=over 4

=item *

dbh

A database handle.

This parameter is mandatory.

=item *

table_name

The name of the table to select from.

This parameter is mandatory.

=item *

key_column

When calling C<select()>, C<select_hashref()> and C<select_tree()>, this is the name of the database column,
or the SQL expression, to use for hash keys.

Say you have 2 columns, called col_a and col_b. Then you can concatenate them with:

key_column => 'concat(col_a, col_b)'

or, even fancier,

key_column => "concat(col_a, '-', col_b)"

This parameter is mandatory.

=item *

child_column

When calling C<select_tree()>, this is the name of the database column which, combined with the
parent_column column, defines the relationship between nodes and their children.

This parameter is mandatory if you call C<select_tree()>, and ignored if you call C<select()> or
C<select_hashref()>.

=item *

parent_column

When calling C<select_tree()>, this is the name of the database column which, combined with the
child_column column, defines the relationship between nodes and their children.

This parameter is mandatory if you call C<select_tree()>, and ignored if you call C<select()> or
C<select_hashref()>.

=item *

value_column

The name of the database column to use for hash values.

This parameter is mandatory if you call C<select()>, and ignored if you call C<select_hashref()> or
C<select_tree()>.

=item *

where

The optional where clause, including the word 'where', to add to the select.

=item *

skip_columns

An array ref of column names to ignore when reading the database table.

It defaults to [].

This parameter is optional.

=back

=head1 Method: new(...)

Returns a object of type C<DBIx::Table2Hash>.

See above, in the section called 'Constructor and initialization'.

=head1 Method: select(%parameter)

Returns a hash ref.

Each key in the hash points to a single value.

Named parameters, as documented above, can be passed in to this method.

Calling C<select()> actually executes the SQL select statement, and builds the hash.

The demo program test-table2hash.pl, in the examples/ directory, calls C<select()>.

=head1 Method: select_hashref(%parameter)

Returns a hash ref.

Each key in the hash points to a hashref.

Named parameters, as documented above, can be passed in to this method.

Calling C<select_hashref()> actually executes the SQL select statement, and builds the hash.

The demo program test-table2hash.pl, in the examples/ directory, calls C<select_hashref()>.

=head1 Method: select_tree(%parameter)

Returns a hash ref.

Each key in the hash points to a hashref.

Named parameters, as documented above, can be passed in to this method.

Calling C<select_tree()> automatically calls C<select_hashref()>, if you have not already called
C<select_hashref()>.

The demo program test-table2tree.pl, in the examples/ directory, calls C<select_tree()>.

=head1 DBIx::Table2Hash and CGI::Explorer

The method C<select_tree()> can obviously return a hash with multiple keys at the root level, depending on
the contents of the database table.

Such a hash cannot be passed in to CGI::Explorer V 2.00+. Here's a way around this restriction: Create, on
the fly, a hash key which is The Mother of All Roots. Eg:

	my($t2h)  = DBIx::Table2Hash -> new(...);
	my($tree) = $t2h -> select_tree(...);
	my($exp)  = CGI::Explorer -> new(...) -> from_hash(hashref => {OneAndOnly => $tree});

=head1 FAQ

Q: What is the point of this module?

A 1: To be able to restore a hash from a database rather than from a file.

A 2: To be able to construct, from a database table, a hash suitable for passing in to CGI::Explorer V 2.00.

Q: Can your other module C<DBIx::Hash2Table> be used to save the hash back to the database?

A: Sure.

Q: Do you ship demos for the 3 methods C<select()>, C<select_hashref()> and C<select_tree()>?

A: Yes. See the examples/ directory.

If you installed this module locally via ppm, look in the x86/ directory for the file to unpack.

If you installed this module remotely via ppm, you need to download and unpack the distro itself.

Q: Are there any other modules with similar capabilities?

A: Yes:

=over 4

=item *

C<DBIx::Lookup::Field>

Quite similar.

=item *

C<DBIx::TableHash>

This module takes a very long set of parameters, but unfortunately does not take a database handle.

It does mean the module, being extremely complex, can read in more than one column as the value of a hash key, and it
has caching abilities too.

It works by tieing a hash to an MySQL table, and hence supports writing to the table. It uses MySQL-specific code,
for example, when it locks tables.

Unfortunately, it does not use data binding, so it cannot handle data which contains single quotes!

Further, it uses /^\w+$/ to 'validate' column names, so it cannot accept an SQL expression instead of a column name.

Lastly, it also uses /^\w+$/ to 'validate' table names, so it cannot accept table names and views containing spaces
and other 'funny' characters, eg '&' (both of which I have to deal with under MS Access).

=item *

C<DBIx::Tree>

This module was the inspiration for C<select_tree()>.

As it reads the database table it calls a call-back sub, which you use to process the rows of the table.

=back

=head1 Repository

L<https://github.com/ronsavage/DBIx-Table2Hash>

=head1 Support

Bugs should be reported via the CPAN bug tracker at

L<https://github.com/ronsavage/DBIx-Table2Hash/issues>

=head1 Author

C<DBIx::Table2Hash> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2003.

Home page: L<http://savage.net.au/index.html>

=head1 Copyright

Australian copyright (c) 2003, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
