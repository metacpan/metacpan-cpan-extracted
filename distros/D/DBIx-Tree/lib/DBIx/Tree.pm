package DBIx::Tree;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Carp;

use DBI;

our $VERSION = '1.97';

# ------------------------------------------------

sub do_query
{
    my $self = shift;

    carp "do_query() is now a private function - you need not call it yourself"
	if $^W;

    $self->_do_query(@_);

} # End of do_query.

# ------------------------------------------------

sub _do_query
{
    my ($self, $parentid, $id, $level) = @_;

    my $sth;

    unless ($sth = $self->{sth}) {
	my $columns = join(', ', @{ $self->{columns} } );

	my $sql = "SELECT $columns FROM " . ($self->{table});
	if ( $self->{match_data} ) {
	    $sql .= " WHERE $self->{data_column} like '$self->{match_data}%'";
	}
	$sql .= ' order by ' . $self->{order_column} . ' ' .
	    $self->{order_direction} ;
	if ( $self->{limit} ) {
	    $sql .= " LIMIT $self->{limit_left}";
	}
	$sth = $self->{dbh}->prepare($sql);
    } elsif (!ref $self->{sth}) {
	$sth = $self->{dbh}->prepare($self->{sth});
    } else {
	$sth = $self->{sth};
    }

    if (defined($parentid) || defined($id)) {
	# need to modify the statement
	my $sql = $sth->{Statement};
	my $conj = 'WHERE';

	my ($where, $extra);
	if ($sql =~ m/\s+WHERE\s+(.*)/i) {
	    $where = $1;
	    ($extra) = $where =~ m/((?:GROUP\s+BY|ORDER\s+BY|LIMIT).*)/si;
	    $where =~ s/((?:GROUP\s+BY|ORDER\s+BY|LIMIT).*)//si;
	    $sql =~ s/\s+WHERE\s+.*//; # strip where/extra off sql
	} else {
	    $where = '';
	    ($extra) = $sql =~ m/((?:GROUP\s+BY|ORDER\s+BY|LIMIT).*)/si;
	    $sql =~ s/((?:GROUP\s+BY|ORDER\s+BY|LIMIT).*)//si;
	}

	if ($where) {
	    $where = "$conj ( $where )";
	    $conj = 'AND';
	}

	if (defined $parentid) {
	    $where .= "$conj $self->{parent_id_column} = ?";
	    $conj = ' AND';
	}

	if (defined $id) {
	    $where .= "$conj $self->{id_column} = ?";
	    $conj = ' AND';
	}

	$sql .= " $where $extra";
	$sth = $self->{dbh}->prepare_cached($sql);
    }

    my $rc = $sth->execute(defined $parentid ? $parentid : (),
			   defined       $id ?       $id : ()
			  );
    if (!$rc) {
	carp("Could not issue query: $DBI::errstr");
	return 0;
    }

    $self->{data} = $sth->fetchall_arrayref({});
    $sth->finish if $sth->{Active};

    if (!defined($level) || ($level >= $self->{threshold}) ) {
	$self->{limit_left} -= @{$self->{data}};
    }
    $self->{limit_left} = 0 if $self->{limit_left} < 0;

    1; # return success

} # End of _do_query.

# ------------------------------------------------

sub _handle_node
{
    my ($self,
	$id,
	$item,
	$parentids,
	$parentnames,
	$level) = @_;

    unless (defined $item) {
	$self->_do_query(undef, $id, $level); # special root finding invocation
	$item = $self->{data}->[0]->{$self->{data_column}};
    }

	# $item is not defined when the constructor is called with:
	# o match_data = 'Some value', and
	# o start_id   = Some value, and (presumably)
	# o The id of the match data is not start_id.
	# In this case, the above special call for finding the root does
	# not return a valid value for item.

    if (defined($item) && $self->{method} && ($level >= $self->{threshold}) )
	{
    $self->{method}->
	( item        => $item,
	  level       => $level,
	  id          => $id,
	  parent_id   => $parentids,
	  parent_name => $parentnames );
	}

    $self->_do_query($id, undef, $level);
    push @{$parentids}, $id;
    push @{$parentnames}, $item;

    for my $child (@{$self->{data}}) {
	$self->_handle_node($child->{$self->{id_column}},
			    $child->{$self->{data_column}},
			    $parentids,
			    $parentnames,
			    $level+1);
    }

    pop @{$parentids};
    pop @{$parentnames};

    if (defined($item) && $self->{post_method} && ($level >= $self->{threshold}) )
	{
    $self->{post_method}->
	( item        => $item,
	  level       => $level,
	  id          => $id,
	  parent_id   => $parentids,
	  parent_name => $parentnames );
	}

} # End of _handle_node.

# ------------------------------------------------

sub new
{
    my $proto =  shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

    my %args = @_;

    $self->{dbh}    = $args{connection};

#    $self->{dbh}->trace(1);
    $self->{dbh}->{RaiseError} = 1;

    $self->{table}  = $args{table};
    $self->{method} = $args{method};
    $self->{post_method} = $args{post_method};
    $self->{sth}    = $args{sth} || $args{sql};

    my $columns = $args{columns};
    $self->{columns}          = $columns;
    $self->{id_column}        = $columns->[0];
    $self->{data_column}      = $columns->[1];
    $self->{parent_id_column} = $columns->[2];
    $self->{order_column}     = $columns->[3] if $#$columns > 2;
    $self->{order_column}   ||= $self->{data_column};
    $self->{order_direction}  = $columns->[4] if $#$columns > 3;
    $self->{order_direction}||= ''; # hush undefined warnings

    $self->{start_id} = $args{start_id} || 1;
    $self->{threshold} = $args{threshold} || 1;
    $self->{match_data} = $args{match_data};
    $self->{limit} = $args{limit};

    $self->{recursive} = $args{recursive} || 1;

    return $self;

} # End of new.

# ------------------------------------------------

sub traverse
{
    my $self = shift;

    # allow local arguments to override defaults set in constructor:
    my %args = @_;
    while (my ($key, $val) = each %args) {
	($self->{$key}, $args{$key}) = ($args{$key}, $self->{$key})
    }

    # reset limit counter:
    $self->{limit_left} = $self->{limit};

    my $rc;
    unless ($self->{recursive} || ($self->{threshold} gt 1 && $self->{limit}) ) {
	$rc = $self->_traverse_linear;
    } else {
	$rc = $self->_traverse_recursive;
    }

    # restore object defaults:
    while (my ($key, $val) = each %args) {
	($self->{$key}, $args{$key}) = ($args{$key}, $self->{$key})
    }

    return $rc;

} # End of traverse.

# ------------------------------------------------

sub _traverse_linear
{
  my $self = shift;

  $self->_do_query();

  my ($current, @order, @stack);

  my (%id_cols, %id_pnts);

  my $i = -1;
  foreach my $aitem (@{ $self->{data} }) {
    $i++;
    if ( defined $aitem->{$self->{parent_id_column}} ) {
      push @{ $id_pnts{ $aitem->{$self->{parent_id_column}} } }, $aitem->{$self->{id_column}};
    }
    if ( defined $aitem->{$self->{id_column}} ) {
      $id_cols{ $aitem->{$self->{id_column}} } = $i;
    }
  }

  my $level = 1;

  # this non-recursive algorithm requires the use of a stack in order
  # to process each element. After each element is processed, it is
  # removed from the stack and its children on the next level are
  # added to the stack. Then it starts all over again until we run out
  # of elements.

  push @order, $self->{start_id};
  push @stack, 1;

  # $level starts out at 1. Every time we run out of items to process
  # at the current level (if $levelFound == 0) $level is
  # decremented. If we get to 0, we have run out of items to process,
  # and can call it quits.

  my (@parent_id, @parent_name);

  while ($level) {

    # search the stack for an item whose level matches $level.

    my $levelFound = 0;
    my $i = -1;
    foreach my $index (@stack) {
      $i++;
      if ($index == $level) {

	# if we have found something whose level is equal to $level,
	# set the variable $current so we can refer to it later. Also,
	# set the flag $levelFound

	$current = $order[$i];
	$levelFound = 1;

	# since we've found record we don't need it on stack

	splice(@order,$i,1);
	splice(@stack,$i,1);

	last;
      }
    }

    # if we found something at the current level, its id will be in
    # $current, so let's process it. Otherwise, we drop through this,
    # decrement $level, and if $level is not 0, start the process over
    # again.

    if ($levelFound) {

      ######################################
      #
      # loop through the array of rows until we find the record with
      # the id that matches $current. This is the id of the item we
      # pulled off of $stack
      #
      ######################################
      my $item;

      my $aryitem = $id_cols{ $current };
      if (defined $aryitem) {

	  ###############################
	  #
	  # the data column is used to get $item, which is the label
	  # in the tree diagram.
	  #
	  # The cartid property is the id of the shopping cart that
	  # was created in the new method
	  #
	  ###############################
	  $item = $self->{data}->[$aryitem]->{$self->{data_column}};

	  ###############################
	  #
	  # if the calling program defined a target script, define
	  # this item on the tree as a hyperlink.  include variables
	  # for id and cartid.
	  #
	  # Otherwise, just add the item as it is.
	  #
	  ###############################
	  $self->{method}->
	      ( item        => $item,
		level       => $level,
		id          => $current,
		parent_id   => \@parent_id,
		parent_name => \@parent_name )
		  if ($self->{method} && $level >= $self->{threshold});


      }

      #################################
      #
      # add all the children (if any) of the current item to the stack
      #
      ###############################

      my $aitem = $id_pnts{ $current };
      if (defined $aitem) {
          foreach my $id ( @{ $aitem } ) {
	    push @stack, $level + 1;
	    push @order, $id;
	  }
      }

      if ($item && $current) {
          push @parent_id, $current;
          push @parent_name, $item;
      }
      $level++ ;

    } else {

      my $current = pop @parent_id;
      my $item = pop @parent_name;

      if ($self->{post_method} && ($level >= $self->{threshold}) )
	  {
      $self->{post_method}->
	  ( item        => $item,
	    level       => $level,
	    id          => $current,
	    parent_id   => \@parent_id,
	    parent_name => \@parent_name );
	  }

      $level--;
    }

  }

  return 1;

} # End of _traverse_linear.

# ------------------------------------------------

sub _traverse_recursive
{
    my $self = shift;

    $self->_handle_node($self->{start_id}, undef, [], [], 1);

} # End of _traverse_recursive.

# ------------------------------------------------

sub tree
{
    carp("tree() use is deprecated; use traverse() instead.\n")
	if $^W;

    my $self = shift;
    return $self->traverse(@_);

} # End of tree.

# ------------------------------------------------

1;

=pod

=head1 NAME

DBIx::Tree - Generate a tree from a self-referential database table

=head1 Synopsis

  use DBIx::Tree;
  # have DBIx::Tree build the necessary SQL from table & column names:
  my $tree = new DBIx::Tree(connection => $dbh,
                            table      => $table,
                            method     => sub { disp_tree(@_) },
                            columns    => [$id_col, $label_col, $parent_col],
                            start_id   => $start_id);
  $tree->traverse;

  # alternatively, use your own custom SQL statement

  my $sql = <<EOSQL;
SELECT nodes.id, labels.label, nodes.parent_id
FROM nodes
  INNER JOIN labels
  ON nodes.id = labels.node_id
WHERE labels.type = 'preferred label'
ORDER BY label ASC

EOSQL

  my $tree = new DBIx::Tree(connection => $dbh,
                            sql        => $sql,
                            method     => sub { disp_tree(@_) },
                            columns    => ['id', 'label', 'parent_id'],
                            start_id   => $start_id);

  $tree->traverse;

  # or use an already prepared DBI statement handle:

  my $sth = $dbh->prepare($sql);
  my $tree = new DBIx::Tree(connection => $dbh,
                            sth        => $sth,
                            method     => sub { disp_tree(@_) },
                            columns    => ['id', 'label', 'parent_id'],
                            start_id   => $start_id);

  $tree->traverse;

=head1 Description

When you've got one of those nasty self-referential tables that you
want to bust out into a tree, this is the module to check out.
Assuming there are no horribly broken nodes in your tree and (heaven
forbid) any circular references, this module will turn something like:

    food                food_id   parent_id
    ==================  =======   =========
    Food                001       NULL
    Beans and Nuts      002       001
    Beans               003       002
    Nuts                004       002
    Black Beans         005       003
    Pecans              006       004
    Kidney Beans        007       003
    Red Kidney Beans    008       007
    Black Kidney Beans  009       007
    Dairy               010       001
    Beverages           011       010
    Whole Milk          012       011
    Skim Milk           013       011
    Cheeses             014       010
    Cheddar             015       014
    Stilton             016       014
    Swiss               017       014
    Gouda               018       014
    Muenster            019       014
    Coffee Milk         020       011

into:

    Food (001)
      Dairy (010)
        Beverages (011)
          Coffee Milk (020)
          Whole Milk (012)
          Skim Milk (013)
        Cheeses (014)
          Cheddar (015)
          Stilton (016)
          Swiss (017)
          Gouda (018)
          Muenster (019)
      Beans and Nuts (002)
        Beans (003)
          Black Beans (005)
          Kidney Beans (007)
            Red Kidney Beans (008)
            Black Kidney Beans (009)
        Nuts (004)
          Pecans (006)

See the examples/ directory for two Tk examples.

=head1 Installation

Install L<DBIx::Tree> as you would for any C<Perl> module:

Run:

	cpanm DBIx::Tree

	Note: cpanm ships in App::cpanminus. See also App::perlbrew.

or run:

	sudo cpan DBIx::Tree

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

=head2 Calling new()

C<new()> is called as C<< my($obj) = DBIx::Tree -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<DBIx::Tree>.

Key-value pairs accepted in the parameter list:

=over 4

=item o columns => $ara_ref

A reference to a list of three column names that can be found in the
table/result set:

  id_col:     The name of the column containing the unique id.
  label_col:  The name of the column containing the textual data
              of the row, like a name.
  parent_col: The name of the column containing the id of the
              row's parent.

Optional additional columns; note that these will only be used in
queries built by DBIx::Tree from 'table' specifications - i.e. they
will not be used with 'sth'- or 'sql'-type query parameters
(presumably you can provide this functionality yourself when using one
of those query types).

  order_col:  The name of a column to use for ordering the results;
              defaults to the column name specified by label_col.
              This column name does not need to exist in the result
              set, but should exist in the table being queried.

  order_dir:  An SQL directive specifying the directionality of the
              ordering; for most databases this is either 'ASC' or
              'DESC'.  The default is an empty string, which leaves
              the decision to the database (in most cases, this will
              be ascending)

=item o connection => $dbh

A DBI connection handle. This parameter is always required. Earlier versions of this doc said it was
not necessary when using the $sth option, but in that case omitting it gets an error on prepare_cached.

=item o limit => $integer

Limit the number of rows using an SQL LIMIT clause - not all SQL
servers support this. This feature was supplied by Ilia Lobsanov
<ilia@lobsanov.com>

=item o match_data => $string

The value of a partial match to look for - if this is supplied, only
rows whose label_col matches (match_data + '%') this will be
selected. This feature was supplied by Ilia Lobsanov
<ilia@lobsanov.com>

=item o method => $sub_name

A callback method to be invoked each time a tree item is
encountered. This method will be given a hash as a parameter,
containing the following elements:

  item:        the name of the item
  level (1-n): the nesting level of the item.
  id:          the unique id of the item.
  parent_id:   an array ref containing the geneology of parent id's
               for the current item
  parent_name: an array ref containing the geneology of parent name's
               for the current item

If the 'threshold' parameter has been set (either via the new()
constructor or in the call to traverse()), the callback will only
occur if the tree item is 'threshold' or more levels deep in the
hierarchy.

=item o post_method => $sub_name

A callback method to be invoked after all the children of a tree item
have been encountered. This method will be given a hash as a
parameter, containing the following elements:

  item:        the name of the item
  level (0-n): the nesting level of the item.
  id:          the unique id of the item.
  parent_id:   an array ref containing the geneology of parent id's
               for the current item
  parent_name: an array ref containing the geneology of parent name's
               for the current item

If the 'threshold' parameter has been set (either via the new()
constructor or in the call to traverse()), the callback will only
occur if the tree item is 'threshold' or more levels deep in the
hierarchy.

=item o recursive => $Boolean

Specifies which of two methods DBIx::Tree will use to traverse the
tree.  The default is non-recursively, which is efficient in that it
requires only a single database query, but it also loads the entire
tree into memory at once.  The recursive method queries the database
repetitively, but has smaller memory requirements.  The recursive
method will also be more efficient when an alternative start_id is
specified.  Note that if you supply both a limit argument and a
threshold argument (implying that you want to see at most N records at
or below the given threshold), the recursive method will be used
automatically for efficiency.

=item o sql => $sql_statement

A string containing a custom "SELECT" SQL query statement that returns
the hierarchical data.  Unnecessary if all of the id/label/parent
columns come from the same table specified by the 'table' parameter.
Use only when you need to bring in supplementary information from
other tables via custom "joins".  Note that providing an 'sql'
argument will override any other 'table' specification.

=item o start_id => $integer

The unique id of the root item.  Defaults to 1.  May be overriden by
the 'start_id' argument to traverse().

=item o sth => $db_sth

A prepared (but not yet executed!) DBI statement handle.  Unnecessary
if you plan to provide either a basic table name via 'table' or a
custom SQL statement via 'sql'.  Note that providing an 'sth' argument
will override any other 'sql' or 'table' specification.

=item o table => $table_name

The database table containing the hierarchical data.  Unnecessary if
you plan to provide either a custom SQL statement via the 'sql'
parameter or a prepared DBI statement handle via the 'sth' parameter.

=item o threshold => $integer

The level in the hierarchical tree at which to begin processing items.
The root of the tree is considered to be at level 1.  May be overriden
by the 'threshold' argument to traverse().

=back

=head1 Methods

=head2 new(%args)

  my $tree = new DBIx::Tree(connection => $dbh,
                            table      => $table,
                            sql        => $sql,
                            sth        => $sth,
                            method     => sub { disp_tree(@_) },
                            columns    => [$id_col, $label_col, $parent_col],
                            start_id   => $start_id,
                            threshold  => $threshold,
                            match_data => $match_data,
                            limit      => $limit
                            recursive  => 1 || 0);

=head2 traverse(%args)

Begins a depth-first traversal of the hierarchical tree.  The optional
%args hash provides locally overriding values for the identical
parameters set in the new() constructor.

=head1 TODO

Graceful handling of circular references.
Better docs.
Rewrite the algorithm.
Separate data acquisition from data formatting.

=head1 See Also

L<DBIx::Tree::Persist>.

L<Tree>.

L<Tree::Binary>.

L<Tree::DAG_Node>. My favourite.

L<Tree::DAG_Node::Persist>.

L<Tree::Persist>.

L<Tree::Simple>.

L<Tree::Simple::Visitor::Factory>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Repository

L<https://github.com/ronsavage/DBIx-Tree>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-Tree>.

=head1 Authors

Brian Jepson, bjepson@ids.net

This module was inspired by the Expanding Hierarchies example that I
stumbled across in the Microsoft SQL Server Database Developer's
Companion section of the Microsoft SQL Server Programmer's Toolkit.

Jan Mach <machj@ders.cz> contributed substantial performance
improvements, ordering handling for tree output, and other bug fixes.

Aaron Mackey <amackey@virginia.edu> has continued active development
on the module based on Brian Jepson's version 0.91 release.

Co-maintenance since V 1.91 is by Ron Savage <rsavage@cpan.org>.
Uses of 'I' in previous versions is not me, but will be hereafter.

=cut
