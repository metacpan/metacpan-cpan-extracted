package DBIx::Tree::Persist;

use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

use DBI;

use DBIx::Tree::Persist::Config;

use Hash::FieldHash ':all';

fieldhash my %copy_name      => 'copy_name';
fieldhash my %data_structure => 'data_structure';
fieldhash my %dbh            => 'dbh';
fieldhash my %starting_id    => 'starting_id';
fieldhash my %table_name     => 'table_name';
fieldhash my %verbose        => 'verbose';

use Tree;
use Tree::Persist;

our $VERSION = '1.04';

# -----------------------------------------------

sub build_structure
{
	my($self, @node) = @_;
	my($item_data)   = [];

	my(@children);

	for my $node (@node)
	{
		@children = $node -> children;

		if ($#children >= 0)
		{
			push @$item_data,
			{
				text    => $node -> value,
				submenu =>
				{
					id       => 'id_' . $self -> get_id_of_node($node),
					itemdata => $self -> build_structure(@children),
				},
			};
		}
		else
		{
			push @$item_data, {text => $node -> value};
		}
	}

	return $item_data;

} # End of build_structure.

# -----------------------------------------------
# Note: We use 0, not null, as the parent of the root.
# See comments to sub Create.create_one_table() for more detail.
# Note: This code helps me understand how to build a tree a node at a time.

sub copy_table
{
	my($self)           = @_;
	my($old_table_name) = $self -> table_name;
	my($table_name)     = $self -> copy_name;
	my($record)         = $self -> dbh -> selectall_arrayref("select * from $old_table_name order by id", {Slice => {} });

	my($id);
	my($node);
	my($parent_id);
	my($row, $root_id);
	my(%seen);

	for $row (@$record)
	{
		$id        = $$row{id};
		$parent_id = $$row{parent_id};
		$node      = Tree -> new($$row{value});
		$seen{$id} = $node;

		if ($seen{$parent_id})
		{
			$seen{$parent_id} -> add_child($node);
		}
		elsif ($parent_id == 0)
		{
			$root_id = $id;
		}
	}

	# This writes null, not 0, to the database, as the parent of the root.

	my($writer) = Tree::Persist -> create_datastore
		({
			class_col => 'class',
			dbh       => $self -> dbh,
			table     => $table_name,
			tree      => $seen{$root_id},
			type      => 'DB',
		 });

} # End of copy_table.

# --------------------------------------------------

sub get_id_of_node
{
	my($self, $node) = @_;
	my($meta) = $node -> meta;
	my(@key)  = grep{length} keys %$meta;
	my($id)   = $$meta{$key[0]}{id};

	return $id;

} # End of get_id_of_node;

# -----------------------------------------------

sub log
{
	my($self, $message) = @_;
	$message ||= '';

	if ($self -> verbose)
	{
		print "$message\n";
	}

} # End of log.

# -----------------------------------------------

sub new
{
	my($class, %arg)     = @_;
	$arg{copy_name}      ||= '';
	$arg{dbh}            ||= '';
	$arg{data_structure} ||= 0;
	$arg{starting_id}    ||= 1;
	$arg{table_name}     ||= '';
	$arg{verbose}        ||= 0;
	my($self)            = from_hash(bless({}, $class), \%arg);

	if (! $self -> dbh)
	{
		my($config) = DBIx::Tree::Persist::Config -> new -> config;
		my(@dsn)    = ($$config{dsn}, $$config{username}, $$config{password});
		my($attr)   = {};

		$self -> dbh(DBI -> connect(@dsn, $attr) );
	}

	return $self;

}	# End of new.

# -----------------------------------------------

sub pretty_print
{
	my($self, $tree) = @_;

	my($depth);
	my($id);
	my($value);

	for my $node ($tree -> traverse($tree -> PRE_ORDER) )
	{
		$depth = $node -> depth;
		$id    = $self -> get_id_of_node($node);
		$value = $node -> value;

		$self -> log(' ' x $depth . "$value ($id)");
	}

} # End of pretty_print.

# -----------------------------------------------

sub run
{
	my($self) = @_;

	$self -> copy_name ? $self -> copy_table : $self -> traverse;

	return 0;

} # End of run.

# -----------------------------------------------

sub traverse
{
	my($self) = @_;

	$self -> log('Traversing table ' . $self -> table_name . ' with a starting_id of ' . $self -> starting_id);

	# Read tree from database.

	my($reader) = Tree::Persist -> connect
		({
			class_col => 'class',
			dbh       => $self -> dbh,
			id        => $self -> starting_id,
			table     => $self -> table_name,
			type      => 'DB',
		});
	my($tree) = $reader -> tree;

	# Traverse tree.

	$self -> data_structure ? $self -> ugly_print($tree) : $self -> pretty_print($tree);

} # End of traverse.

# -----------------------------------------------

sub ugly_print
{
	my($self, $tree) = @_;

	$self -> log(Dumper($self -> build_structure($tree) ) );

} # End of ugly_print.

# -----------------------------------------------

1;

=pod

=head1 NAME

DBIx::Tree::Persist - Play with Tree and Tree::Persist a la DBIx::Tree

=head1 Synopsis

First, edit lib/DBIx/Tree/Persist/.htdbix.tree.persist.conf.

Then run the scripts in this order (see scripts/test.sh):

=over 4

=item scripts/drop.tables.pl

Drop tables one and two.

Of course, you only run this after running create.tables.pl.

=item scripts/create.tables.pl

Create tables one and two.

Some notes regarding the ways tables one and two are declared (in C<DBIx::Tree::Persist::Create>):

=over 4

=item Null 'v' Not Null

parent_id is not 'not null', because L<Tree::Persist> stores a null as the parent of the root.

=item Foreign Keys

If parent_id is 'references two(id)', then it cannot be set to 0 for the root, because id 0 does not exist.

However, by omitting 'references two(id)', the parent_id of the root can be (manually) set to 0, and
L<Tree::Persist> still reads in the tree properly.

=back

=item scripts/populate.tables.pl

Populate table two from the text file data/two.txt.

The data comes from the docs for L<DBIx::Tree>.

populate.tables.pl uses neither L<Tree> nor L<Tree::Persist>.

The code in C<DBIx::Tree::Persist::Create> uses 0 as the parent_id of the root, whereas L<Tree::Persist> uses null.

This is both to demonstrate the point made above that L<Tree::Persist> handles this, and to adhere to my convention
to use 'not null' whenever possible. Clearly, this is not possible when it's L<Tree::Persist> writing to the
database. Hence table two which I write can use 'not null', but table one can't use it, since table one is
populated by L<Tree::Persist>.

This convention is adopted from:

	Joe Celko's SQL for Smarties 2nd edition
	Morgan Kaufmann
	1-55860-576-2
	Section 6.9, page 120, Design Advice for NULLs

=item scripts/report.tables.pl

Report the record counts from tables one and two.

=item scripts/tree.pl -t two -v

Traverse and print table two.

This run uses L<Tree::Persist>, and L<Tree>.

=item scripts/tree.pl -t two -c one

Copy table two to table one.

This run uses L<Tree::Persist>, and L<Tree>.

=item scripts/tree.pl -t two -c one

Copy table two to table one, again. Table one now contains 2 independent trees.

=item scripts/tree.pl -t one -s 1 -v

Traverse and print table one, starting from id = 1.

=item scripts/tree.pl -t one -s 21 -v

Traverse and print table one, starting from id = 21.

The tree structures for the 2 trees printed by the last 2 commands will be the same.
However, since the trees are stored at different offsets within table one, the ids
associated with each corresponding node will be different.

=item scripts/tree.pl -t one -d -s 1 -v

Use the -data_structure option to call the C<build_structure()> method, and to output
that structure instead of pretty-printing the tree.

=back

=head1 Description

L<DBIx::Tree::Persist> provides sample code for playing with Tree and Tree::Persist a la DBIx::Tree.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html> for
help on unpacking and installing distros.

=head1 Method: build_structure($root)

Returns a Perl data structure which can be turned into JSON.

The -data_structure option to scripts/tree.pl gives you access to this feature.

=head1 Method: copy_table()

If copy_name is used to pass a table name to new(), sub run() calls sub copy_table().

If copy_name is not used, sub run() calls sub traverse().

sub copy_table() shows how to build a tree based on a linear scan of a dataset.

=head1 Method: new()

See scripts/tree.pl for how to pass sample parameters to new() via a command-line program.

C<new()> takes a hash of parameters:

=over 4

=item copy_name => 'A table name'

copy_name is optional.

If specified, the code copies the data from the table named with the -t option
to the table named with the -c option.

=item dbh => $dbh

dbh is optional.

If specified, the code uses the $dbh provided.

If not specified, the code reads the config file lib/DBIx/Tree/Persist/.htdbix.tree.persist.conf
to get parameters and calls DBI -> connect() to generate a dbh.

This is mainly used for testing. See t/test.t.

=item starting_id => N

starting_id is optional.

If specified, a tree is read from the table named with the -t option, starting at the
id given here.

If not specified, starting_id defaults to 1.

=item table_name => 'A table name'

table_name is mandatory.

The table named with the -t option is always used as input.

It will (probably) have been populated with scripts/populate.tables.pl.

=item verbose => N

verbose is optional.

If specified and > 0, if provides more progress reports.

If not specified, it defaults to 0, which minimizes output.

=back

=head1 Method: pretty_print($root)

Print the tree nicely. This method is called from C<traverse()> if the -data_structure option
is not used.

=head1 Method: run()

After calling new(...), you have to call run(). See scripts/tree.pl for sample code.

=head1 Method: traverse()

If copy_name is used to pass a table name to new(), sub run() calls sub copy_table().

If copy_name is not used, sub run() calls sub traverse().

sub traverse() shows how to build a tree from a disk file, and to then process that tree.

if the -data_structure option (to scripts/tree.pl) is used, the tree is converted to a data structure,
which is then printed using the C<Dumper()> method of L<Data::Dumper::Concise>.

If the -data_structure option is not used, the tree is pretty-printed by calling the method C<pretty_print()>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-Tree-Persist>.

=head1 See Also

L<Data::NestedSet>. This module has its own list of See Also references.

L<DBIx::Tree::NestedSet>. This module has its own list of See Also references.

L<DBIx::Tree>.

L<Tree>.

L<Tree::Persist>.

L<Tree::DAG_Node>.

L<Tree::DAG_Node::Persist>.

=head1 Author

L<DBIx::Tree::Persist> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2010.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2010, Ron Savage.

All Programs of mine are 'OSI Certified Open Source Software';
you can redistribute them and/or modify them under the terms of
The Artistic License, a copy of which is available at:
L<http://www.opensource.org/licenses/index.html>.

=cut
