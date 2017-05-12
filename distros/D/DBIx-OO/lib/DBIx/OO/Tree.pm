package DBIx::OO::Tree;

use strict;
use vars qw(@EXPORT);
use version; our $VERSION = qv('0.0.1');

use Carp;

require Exporter;
*import = \&Exporter::import;
@EXPORT = qw(
                tree_append
                tree_insert_before
                tree_insert_after
                tree_get_subtree
                tree_compute_levels
                tree_reparent
                tree_move_after
                tree_move_before
                tree_delete
                tree_get_path
                tree_get_next_sibling
                tree_get_prev_sibling
                tree_get_next
                tree_get_prev
           );

=head1 NAME

DBIx::OO::Tree -- manipulate hierarchical data using the "nested sets" model

=head1 SYNOPSYS

    CREATE TABLE Categories (
        id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        label VARCHAR(255),

        -- these columns are required by DBIx::OO::Tree
        parent INTEGER UNSIGNED,
        lft INTEGER UNSIGNED NOT NULL,
        rgt INTEGER UNSIGNED NOT NULL,
        mvg TINYINT DEFAULT 0,

        INDEX(lft),
        INDEX(rgt),
        INDEX(mvg),
        INDEX(parent)
    );

                               *  *  *

    package Category;
    use base 'DBIx::OO';
    use DBIx::OO::Tree;

    __PACKAGE__->table('Categories');
    __PACKAGE__->columns(P => [ 'id' ],
                         E => [ 'label', 'parent' ]);

    # note it's not necessary to declare lft, rgt, mvg or parent.  We
    # declare parent simply because it might be useful, but
    # DBIx::OO:Tree works with low-level SQL therefore it doesn't
    # require that the DBIx::OO object has these fields.

    # the code below creates the structure presented in [1]

    my $electronics = Category->tree_append({ label => 'electronics' });
    my $tvs = $electronics->tree_append({ label => 'televisions' });
    my $tube = $tvs->tree_append({ label => 'tube' });
    my $plasma = $tvs->tree_append({ label => 'plasma' });
    my $lcd = $plasma->tree_insert_before({ label => 'lcd' });
    my $portable = $tvs->tree_insert_after({ label => 'portable electronics' });
    my $mp3 = $portable->tree_append({ label => 'mp3 players' });
    my $flash = $mp3->tree_append({ label => 'flash' });
    my $cds = $portable->tree_append({ label => 'cd players' });
    my $radios = Category->tree_append($portable->id,
                                       { label => '2 way radios' });

    # fetch and display a subtree

    my $data = $electronics->tree_get_subtree({
        fields => [qw( label lft rgt parent )]
    });
    my $levels = Category->tree_compute_levels($data);

    foreach my $i (@$data) {
        print '  ' x $levels->{$i->{id}}, $i->{label}, "\n";
    }

    ## or, create DBIx::OO objects from returned data:

    my $array = Category->init_from_data($data);
    print join("\n", (map { '  ' x $levels->{$_->id} . $_->label } @$array));

    # display path info

    my $data = $flash->tree_get_path;
    print join("\n", (map { $_->{label} } @$data));

    # move nodes around

    $mp3->tree_reparent($lcd->id);
    $tvs->tree_reparent($portable->id);
    $cds->tree_reparent(undef);

    $plasma->tree_move_before($tube->id);
    $portable->tree_move_before($electronics->id);

    # delete nodes

    $lcd->tree_delete;

=head1 OVERVIEW

This module is a complement to DBIx::OO to facilitate storing trees in
database using the "nested sets model", presented in [1].  Its main
ambition is to be extremely fast at retrieving data (sacrificing for
this the performance of UPDATE-s, INSERT-s or DELETE-s).  Currently
this module B<requires> you to have these columns in the table:

 - id: primary key (integer)
 - parent: integer, references the parent node (NULL for root nodes)
 - lft, rgt: store the node position
 - mvg: used only when moving nodes

"parent" and "mvg" are not esentially required by the nested sets
model as presented in [1], but they are necessary for this module to
work.  In particular, "mvg" is only required by functions that move
nodes, such as tree_reparent().  If you don't want to move nodes
around you can omit "mvg".

Retrieval functions should be very fast (one SQL executed).  To
further promote speed, they don't return DBIx::OO blessed objects, but
an array of hashes instead.  It's easy to create DBIx::OO objects from
these, if required, by calling DBIx::OO->init_from_data() (see
DBIx::OO for more information).

Insert/delete/move functions, however, need to ensure the tree
integrity.  Here's what happens currently:

 - tree_append, tree_insert_before, tree_insert_after -- these execute
   one SELECT and two UPDATE-s (that potentially could affect a lot of
   rows).

 - tree_delete: execute one SELECT, one DELETE and two UPDATE-s.

 - tree_reparent -- executes 2 SELECT-s and 7 UPDATE-s.  I know, this
   sounds horrible--if you have better ideas I'd love to hear them.

B<Note:> this module could well work with Class::DBI, although it is
untested.  You just need to provide the get_dbh() method to your
packages, comply to this module's table requirements (i.e. provide the
right columns) and it should work just fine.  Any success/failure
stories are welcome.

=head1 DATABASE INTEGRITY

Since the functions that update the database need to run multiple
queries in order to maintain integrity, they should normally do this
inside a transaction.  However, it looks like MySQL does not support
nested transactions, therefore if I call transaction_start /
transaction_commit inside these functions they will mess with an
eventual transaction that might have been started by the calling code.

In short: you should make sure the updates happen in a transaction,
but we can't enforce this in our module.

=head1 API

=head2 tree_append($parent_id, \%values)

Appends a new node in the subtree of the specified parent.  If
$parent_id is undef, it will add a root node.  When you want to add a
root node you can as well omit specifying the $parent_id (our code
will realize that the first argument is a reference).

$values is a hash as required by DBIx::OO::create().

Examples:

    $node = Category->tree_append({ label => 'electronics' });
    $node = Category->tree_append(undef, { label => 'electronics' });

    $lcd = Category->tree_append($tvs->id, { label => 'lcd' });
    $lcd->tree_append({ label => 'monitors' });

As you can see, you can call it both as a package method or as an
object method.  When you call it as a package method, it will look at
the type of the first argument.  If it's a reference, it will guess
that you want to add a root node.  Otherwise it will add the new node
under the specified parent.

Beware of mistakes!  Do NOT call it like this:

    $tvs = Category->search({ label => 'televisions' })->[0];
    Category->tree_append($tvs, { label => 'lcd' });

If you specify a parent, it MUST be its ID, not an object!

=cut

sub tree_append {
    my $self = shift;
    my ($parent, $val);
    if (ref $self) {
        $parent = $self->id;
    } else {
        $parent = shift;
        if (ref $parent eq 'HASH') {
            # assuming $val and no parent
            $val = $parent;
            $parent = undef;
        } elsif (ref $parent) {
            $parent = $parent->id;
        }
    }
    $val ||= shift;

    my $orig = 0;
    my $dbh = $self->get_dbh;
    my $table = $self->table;

    if (defined $parent) {
        my $a = $dbh->selectrow_arrayref("SELECT rgt FROM `$table` WHERE id = $parent");
        $orig = $a->[0] - 1;
        $dbh->do("UPDATE `$table` SET rgt = rgt + 2 WHERE rgt > $orig");
        $dbh->do("UPDATE `$table` SET lft = lft + 2 WHERE lft > $orig");
    } else {
        my $a = $dbh->selectrow_arrayref("SELECT MAX(rgt) FROM `$table` WHERE parent IS NULL");
        $orig = $a ? ($a->[0] || 0) : 0;
    }

    delete $val->{lft};
    delete $val->{rgt};
    delete $val->{mvg};
    delete $val->{parent};

    my %args = ( lft     => $orig + 1,
                 rgt     => $orig + 2,
                 parent  => $parent );
    @args{keys %$val} = values %$val
      if $val;
    return $self->create(\%args);
}

=head2 tree_insert_before, tree_insert_after  ($anchor, \%values)

Similar in function to tree_append, but these functions allow you to
insert a node before or after a specified node ($anchor).

Examples:

    $lcd->tree_insert_after({ label => 'plasma' });
    $lcd->tree_insert_before({ label => 'tube' });

    # Or, as a package method:

    Category->tree_insert_after($lcd->id, { label => 'plasma' });
    Category->tree_insert_before($lcd->id, { label => 'tube' });

Note that specifying the parent is not required, because it's clearly
that the new node should have the same parent as the anchor node.

=cut

sub tree_insert_before {
    my $self = shift;
    my ($pos, $val);
    if (ref $self) {
        $pos = $self->id;
    } else {
        $pos = shift;
    }
    $val = shift;

    Carp::croak('$pos MUST be a scalar (the ID of the referred node)')
        if ref $pos;

    my $dbh = $self->get_dbh;
    my $table = $self->table;

    my $a = $dbh->selectrow_arrayref("SELECT lft, parent FROM `$table` WHERE id = $pos");
    my ($orig, $parent) = @$a;

    $dbh->do("UPDATE `$table` SET rgt = rgt + 2 WHERE rgt >= $orig");
    $dbh->do("UPDATE `$table` SET lft = lft + 2 WHERE lft >= $orig");

    delete $val->{lft};
    delete $val->{rgt};
    delete $val->{mvg};
    delete $val->{parent};

    my %args = ( lft     => $orig,
                 rgt     => $orig + 1,
                 parent  => $parent );
    @args{keys %$val} = values %$val
      if $val;
    return $self->create(\%args);
}

sub tree_insert_after {
    my $self = shift;
    my ($pos, $val);
    if (ref $self) {
        $pos = $self->id;
    } else {
        $pos = shift;
    }
    $val = shift;

    Carp::croak('$pos MUST be a scalar (the ID of the referred node)')
        if ref $pos;

    my $dbh = $self->get_dbh;
    my $table = $self->table;

    my $a = $dbh->selectrow_arrayref("SELECT rgt, parent FROM `$table` WHERE id = $pos");
    my ($orig, $parent) = @$a;

    $dbh->do("UPDATE `$table` SET rgt = rgt + 2 WHERE rgt > $orig");
    $dbh->do("UPDATE `$table` SET lft = lft + 2 WHERE lft > $orig");

    delete $val->{lft};
    delete $val->{rgt};
    delete $val->{mvg};
    delete $val->{parent};

    my %args = ( lft     => $orig + 1,
                 rgt     => $orig + 2,
                 parent  => $parent );
    @args{keys %$val} = values %$val
      if $val;
    return $self->create(\%args);
}

=head2 tree_reparent($source_id, $dest_id)

This function will remove the $source node from its current parent
and append it to the $dest node.  As with the other functions, you can
call it both as a package method or as an object method.  When you
call it as an object method, it's not necessary to specify $source.

You can specify I<undef> for $dest_id, in which case $source will
become a root node (as if it would be appended with
tree_append(undef)).

No nodes are DELETE-ed nor INSERT-ed by this function.  It simply
moves I<existing> nodes, which means that any node ID-s that you
happen to have should remain valid and point to the same nodes.
However, the tree structure is changed, so if you maintain the tree in
memory you have to update it after calling this funciton.  Same
applies to tree_move_before() and tree_move_after().

Examples:

    # the following are equivalent

    Category->tree_reparent($lcd->id, $plasma->id);
    $lcd->tree_reparent($plasma->id);

This function does a lot of work in order to maintain the tree
integrity, therefore it might be slow.

NOTE: it doesn't do any safety checks to make sure moving the node is
allowed.  For instance, you can't move a node to one of its child
nodes.

=cut

# sub _check_can_move {
#     my ($src_lft, $dest_lft, $dest_rgt) = @_;
# }

sub tree_reparent {
    my $self = shift;
    my ($source, $dest);
    if (ref $self) {
        $source = $self->id;
    } else {
        $source = shift;
    }
    $dest = shift;

    Carp::croak('arguments MUST be scalars (source and destination parent node IDs)')
        if ref $dest or ref $source;

    my $dbh = $self->get_dbh;
    my $table = $self->table;

    # get source info
    my $a = $dbh->selectrow_arrayref("SELECT lft, rgt FROM `$table` WHERE id = $source");
    my ($orig_left, $orig_right) = @$a;
    my $width = $orig_right - $orig_left + 1;

    # hint to ignore subtree items in further computation
    $dbh->do("UPDATE `$table` SET mvg = 1 WHERE lft BETWEEN $orig_left AND $orig_right");

    # "collapse" tree by reducing rgt and lft for nodes after the removed one
    $dbh->do("UPDATE `$table` SET rgt = rgt - $width WHERE rgt > $orig_right");
    $dbh->do("UPDATE `$table` SET lft = lft - $width WHERE lft > $orig_right");

    my $diff;

    if (defined $dest) {
        # get destination info (it's important to do it here as it can be modified by the UPDATE-s above)
        $a = $dbh->selectrow_arrayref("SELECT rgt FROM `$table` WHERE id = $dest");
        my ($dest_right) = @$a;
        $diff = $dest_right - $orig_left;

        $dbh->do("UPDATE `$table` SET rgt = rgt + $width WHERE NOT mvg AND rgt >= $dest_right");
        $dbh->do("UPDATE `$table` SET lft = lft + $width WHERE NOT mvg AND lft >= $dest_right");
    } else {
        # appending a root node
        my $a = $dbh->selectrow_arrayref("SELECT MAX(rgt) FROM `$table` WHERE parent IS NULL");
        my ($dest_right) = @$a;
        $diff = $dest_right - $orig_left + 1;
        $dest = 'NULL';
    }

    # finally, update subtree items and remove the ignore hint
    $dbh->do("UPDATE `$table` SET lft = lft + $diff, rgt = rgt + $diff, mvg = 0 WHERE mvg");
    $dbh->do("UPDATE `$table` SET parent = $dest WHERE id = $source");
}

=head2 tree_move_before, tree_move_after  ($source_id, $anchor_id)

These functions are similar to a reparent operation, but they allow
one to specify I<where> to put the $source node, in the subtree of
$anchor's parent.  See tree_reparent().

Examples:

    $portable->tree_move_before($electronics->id);
    Category->tree_move_after($lcd->id, $flash->id);

=cut

sub tree_move_before {
    my ($self) = shift;
    my ($source, $anchor);
    if (ref $self) {
        $source = $self->id;
    } else {
        $source = shift;
    }
    $anchor = shift;

    Carp::croak('arguments MUST be scalars (source and destination parent node IDs)')
        if ref $anchor or ref $source;

    my $dbh = $self->get_dbh;
    my $table = $self->table;

    # get source info
    my $a = $dbh->selectrow_arrayref("SELECT lft, rgt FROM `$table` WHERE id = $source");
    my ($orig_left, $orig_right) = @$a;
    my $width = $orig_right - $orig_left + 1;

    # hint to ignore subtree items in further computation
    $dbh->do("UPDATE `$table` SET mvg = 1 WHERE lft BETWEEN $orig_left AND $orig_right");

    # "collapse" tree by reducing rgt and lft for nodes after the removed one
    $dbh->do("UPDATE `$table` SET rgt = rgt - $width WHERE rgt > $orig_right");
    $dbh->do("UPDATE `$table` SET lft = lft - $width WHERE lft > $orig_right");

    # get destination info (it's important to do it here as it can be modified by the UPDATE-s above)
    $a = $dbh->selectrow_arrayref("SELECT lft, parent FROM `$table` WHERE id = $anchor");
    my ($dest_left, $dest_parent) = @$a;
    if (!defined $dest_parent) {
        $dest_parent = 'NULL';
    }
    my $diff = $dest_left - $orig_left;

    $dbh->do("UPDATE `$table` SET rgt = rgt + $width WHERE NOT mvg AND rgt >= $dest_left");
    $dbh->do("UPDATE `$table` SET lft = lft + $width WHERE NOT mvg AND lft >= $dest_left");

    # finally, update subtree items and remove the ignore hint
    $dbh->do("UPDATE `$table` SET lft = lft + $diff, rgt = rgt + $diff, mvg = 0 WHERE mvg");
    $dbh->do("UPDATE `$table` SET parent = $dest_parent WHERE id = $source");
}

sub tree_move_after {
    my ($self) = shift;
    my ($source, $anchor);
    if (ref $self) {
        $source = $self->id;
    } else {
        $source = shift;
    }
    $anchor = shift;

    Carp::croak('arguments MUST be scalars (source and destination parent node IDs)')
        if ref $anchor or ref $source;

    my $dbh = $self->get_dbh;
    my $table = $self->table;

    # get source info
    my $a = $dbh->selectrow_arrayref("SELECT lft, rgt FROM `$table` WHERE id = $source");
    my ($orig_left, $orig_right) = @$a;
    my $width = $orig_right - $orig_left + 1;

    # hint to ignore subtree items in further computation
    $dbh->do("UPDATE `$table` SET mvg = 1 WHERE lft BETWEEN $orig_left AND $orig_right");

    # "collapse" tree by reducing rgt and lft for nodes after the removed one
    $dbh->do("UPDATE `$table` SET rgt = rgt - $width WHERE rgt > $orig_right");
    $dbh->do("UPDATE `$table` SET lft = lft - $width WHERE lft > $orig_right");

    # get destination info (it's important to do it here as it can be modified by the UPDATE-s above)
    $a = $dbh->selectrow_arrayref("SELECT rgt, parent FROM `$table` WHERE id = $anchor");
    my ($dest_right, $dest_parent) = @$a;
    if (!defined $dest_parent) {
        $dest_parent = 'NULL';
    }
    my $diff = $dest_right + 1 - $orig_left;

    $dbh->do("UPDATE `$table` SET rgt = rgt + $width WHERE NOT mvg AND rgt > $dest_right");
    $dbh->do("UPDATE `$table` SET lft = lft + $width WHERE NOT mvg AND lft > $dest_right");

    # finally, update subtree items and remove the ignore hint
    $dbh->do("UPDATE `$table` SET lft = lft + $diff, rgt = rgt + $diff, mvg = 0 WHERE mvg");
    $dbh->do("UPDATE `$table` SET parent = $dest_parent WHERE id = $source");
}

=head2 tree_delete($node_id)

Removes a node (and its full subtree) from the database.

Equivalent examples:

    Category->tree_delete($lcd->id);
    $lcd->tree_delete;

=cut

sub tree_delete {
    my ($self) = shift;
    my $id;
    if (ref $self) {
        $id = $self->id;
    } else {
        $id = shift;
    }

    my $dbh = $self->get_dbh;
    my $table = $self->table;

    my $a = $dbh->selectrow_arrayref("SELECT lft, rgt FROM `$table` WHERE id = $id");
    my ($left, $right) = @$a;
    my $width = $right - $left + 1;

    $dbh->do("DELETE FROM `$table` WHERE lft BETWEEN $left AND $right");
    $dbh->do("UPDATE `$table` SET rgt = rgt - $width WHERE rgt > $right");
    $dbh->do("UPDATE `$table` SET lft = lft - $width WHERE lft > $right");
}

=head2 tree_get_subtree(\%args)

Retrieves the full subtree of a specified node.  $args is a hashref
that can contain:

 - parent : the ID of the node whose subtree we want to get
 - where  : an WHERE clause in SQL::Abstract format
 - limit  : allows you to limit the results (using SQL LIMIT)
 - offset : SQL OFFSET
 - fields : (arrayref) allows you to specify a list of fields you're
            interested in

This can be called as a package method, or as an object method.

Examples first:

    $all_nodes = Category->tree_get_subtree;

    $nodes = Category->tree_get_subtree({ parent => $portable->id });
    ## OR
    $nodes = $portable->tree_get_subtree;

    # Filtering:
    $nodes = Category->tree_get_subtree({ where => { label => { -like => '%a%' }}});

    # Specify fields:
    $nodes = Category->tree_get_subtree({ fields => [ 'label' ] });

This function returns an array of hashes that contain the fields you
required.  If you specify no fields, 'id' and 'parent' will be
SELECT-ed by default.  Even if you do specify an array of field names,
'id' and 'parent' would still be included in the SELECT (so you don't
want to specify them).

Using this array you can easily create DBIx::OO objects (or in our
sample, Category objects):

    $arrayref = Category->init_from_data($nodes);

OK, let's get to a more real-world example.  Suppose we have a forum
and we need to list all messages in a thread ($thread_id).  Here's
what we're going to do:

    $data = ForumMessage->tree_get_subtree({
        parent => $thread_id,
        fields => [qw( subject body author date )],
    });

    # the above runs one SQL query

    $objects = ForumMessage->init_from_data($data);

    # the above simply initializes ForumMessage objects from the
    # returned data, B<without> calling the database (since we have
    # the primary key automatically selected by tree_get_subtree, and
    # also have cared to select the fields we're going to use).

    # compute the level of each message, to indent them easily

    $levels = ForumMessage->tree_compute_levels($data);

    # and now display them

    foreach my $msg (@$objects) {
        my $class = 'level' . $levels{$msg->id};
        print "<div class='$class'>", $msg->subject, "<br><br>",
              $msg->body, "<br><br>By: ", $msg->author, "</div>";
    }

    # and indentation is now a matter of CSS. ;-) (define level0,
    # level1, level2, etc.)

All this can be done with a single SQL query.  Of course, note that we
didn't even need to initialize the $objects array--that's mainly
useful when you want to update the database.

=cut

sub tree_get_subtree {
    my ($self, $args) = @_;
    my ($parent, $where, $order);
    if (defined $args->{parent}) {
        $parent = $args->{parent}
    } elsif (ref $self) {
        $parent = $self->id;
    }
    $where = $args->{where};
    $order = $args->{order} || 'TREE_NODE.lft';
    if (defined $parent) {
        $where ||= {};
        $where->{'TREE_PARENT.id'} = $parent;
    }
    my @keys = qw(id parent lft rgt);
    push @keys, @{$args->{fields}}
      if ($args->{fields});
    my @fields = map { "TREE_NODE.`$_`" } @keys;
    my $sa = $self->get_sql_abstract;
    my @bind;
    if ($where) {
        ($where, @bind) = $sa->where($where);
    } else {
        $where = '';
    }
    my $table = $self->table;
    my $select = 'SELECT ' . join(', ', @fields) . " FROM `$table` AS TREE_NODE INNER JOIN `$table` AS TREE_PARENT " .
      'ON TREE_NODE.lft BETWEEN TREE_PARENT.lft AND TREE_PARENT.rgt' .
        $where .
          ' GROUP BY TREE_NODE.lft' .
            $sa->order_and_limit($order, $args->{limit}, $args->{offset});
    my $sth = $self->_run_sql($select, \@bind);
    my @ret = ();
    while (my $row = $sth->fetchrow_arrayref) {
        my %h;
        @h{@keys} = @$row;
        push @ret, \%h;
    }
    return wantarray ? @ret : \@ret;
}

=head2 tree_get_path(\%args)

Retrieves the path of a given node.  $args is an hashref that can
contain:

 - id     : the ID of the node whose path you're interested in
 - fields : array of field names to be SELECT-ed (same like
   tree_get_subtree)

This returns data in the same format as tree_get_subtree().

=cut

sub tree_get_path {
    my ($self, $args) = @_;
    my $id;
    if (defined $args->{id}) {
        $id = $args->{id};
    } elsif (ref $self) {
        $id = $self->id;
    }
    my @keys = qw(id parent lft rgt);
    push @keys, @{$args->{fields}}
      if ($args->{fields});
    my @fields = map { "TREE_PARENT.`$_`" } @keys;
    my $table = $self->table;
    my $select = 'SELECT ' . join(', ', @fields) . " FROM `$table` AS TREE_NODE INNER JOIN `$table` AS TREE_PARENT " .
      'ON TREE_NODE.lft BETWEEN TREE_PARENT.lft AND TREE_PARENT.rgt' .
        " WHERE TREE_NODE.id = $id ORDER BY TREE_PARENT.lft";
    my $sth = $self->_run_sql($select);
    my @ret = ();
    while (my $row = $sth->fetchrow_arrayref) {
        my %h;
        @h{@keys} = @$row;
        push @ret, \%h;
    }
    return wantarray ? @ret : \@ret;
}

=head2 tree_get_next_sibling, tree_get_prev_sibling

XXX: this info may be inaccurate

Return the next/previous item in the tree view.  C<$args> has the same
significance as in L</tree_get_path>.  $args->{id} defines the
reference node; if missing, it's assumed to be $self.

=cut

sub tree_get_next_sibling {
    my ($self, $args) = @_;
    my $id;
    if (defined $args->{id}) {
        $id = $args->{id};
    } elsif (ref $self) {
        $id = $self->id;
    }
    my @keys = qw(id parent lft rgt);
    push @keys, @{$args->{fields}}
      if ($args->{fields});
    my @fields = map { "T1.`$_`" } @keys;
    my $table = $self->table;
    my $select = 'SELECT ' . join(', ', @fields) . " FROM `$table` AS T1 INNER JOIN `$table` AS T2 " .
      'ON T1.lft = T2.rgt + 1' .
        " WHERE T2.id = $id LIMIT 1";
    my $sth = $self->_run_sql($select);
    my @ret = ();
    my $row = $sth->fetchrow_arrayref;
    if ($row) {
        my %h;
        @h{@keys} = @$row;
        return \%h;
    }
    return undef;
}

sub tree_get_prev_sibling {
    my ($self, $args) = @_;
    my $id;
    if (defined $args->{id}) {
        $id = $args->{id};
    } elsif (ref $self) {
        $id = $self->id;
    }
    my @keys = qw(id parent lft rgt);
    push @keys, @{$args->{fields}}
      if ($args->{fields});
    my @fields = map { "T1.`$_`" } @keys;
    my $table = $self->table;
    my $select = 'SELECT ' . join(', ', @fields) . " FROM `$table` AS T1 INNER JOIN `$table` AS T2 " .
      'ON T1.rgt = T2.lft - 1' .
        " WHERE T2.id = $id LIMIT 1";
    my $sth = $self->_run_sql($select);
    my @ret = ();
    my $row = $sth->fetchrow_arrayref;
    if ($row) {
        my %h;
        @h{@keys} = @$row;
        return \%h;
    }
    return undef;
}

=head2 tree_get_next, tree_get_prev

XXX: this info may be inaccurate

Similar to L</tree_get_next_sibling> / L</tree_get_prev_sibling> but
allow $args->{where} to contain a WHERE clause (in SQL::Abstract
format) and returns the next/prev item that matches the criteria.

=cut

sub tree_get_next {
    my ($self, $args) = @_;
    my $id;
    if (defined $args->{id}) {
        $id = $args->{id};
    } elsif (ref $self) {
        $id = $self->id;
    }
    my $where = $args->{where};
    my @bind;
    my $sa = $self->get_sql_abstract;
    if ($where) {
        ($where, @bind) = $sa->where($where);
    }
    my @keys = qw(id parent lft rgt);
    push @keys, @{$args->{fields}}
      if ($args->{fields});
    my @fields = map { "T1.`$_`" } @keys;
    my $table = $self->table;
    my $select = 'SELECT ' . join(', ', @fields) . " FROM `$table` AS T1 INNER JOIN `$table` AS T2 " .
      "ON T1.lft > T2.lft AND T2.id = $id $where ORDER BY T1.lft LIMIT 1";
    my $sth = $self->_run_sql($select, \@bind);
    my @ret = ();
    my $row = $sth->fetchrow_arrayref;
    if ($row) {
        my %h;
        @h{@keys} = @$row;
        return \%h;
    }
    return undef;
}

sub tree_get_prev {
    my ($self, $args) = @_;
    my $id;
    if (defined $args->{id}) {
        $id = $args->{id};
    } elsif (ref $self) {
        $id = $self->id;
    }
    my $where = $args->{where};
    my @bind;
    my $sa = $self->get_sql_abstract;
    if ($where) {
        ($where, @bind) = $sa->where($where);
    }
    my @keys = qw(id parent lft rgt);
    push @keys, @{$args->{fields}}
      if ($args->{fields});
    my @fields = map { "T1.`$_`" } @keys;
    my $table = $self->table;
    my $select = 'SELECT ' . join(', ', @fields) . " FROM `$table` AS T1 INNER JOIN `$table` AS T2 " .
      "ON T1.lft < T2.lft AND T2.id = $id $where ORDER BY T1.lft DESC LIMIT 1";
    my $sth = $self->_run_sql($select, \@bind);
    my @ret = ();
    my $row = $sth->fetchrow_arrayref;
    if ($row) {
        my %h;
        @h{@keys} = @$row;
        return \%h;
    }
    return undef;
}

=head2 tree_compute_levels($data)

This is an utility function that computes the level of each node in
$data (where $data is an array reference as returned by
tree_get_subtree or tree_get_path).

This is generic, and it's simply for convenience--in particular cases
you might find it faster to compute the levels yourself.

It returns an hashref that maps node ID to its level.

In [1] we can see there is a method to compute the subtree depth
directly in SQL, I will paste the relevant code here:

  SELECT node.name, (COUNT(parent.name) - (sub_tree.depth + 1)) AS depth
  FROM nested_category AS node,
	nested_category AS parent,
	nested_category AS sub_parent,
	(
		SELECT node.name, (COUNT(parent.name) - 1) AS depth
		FROM nested_category AS node,
		nested_category AS parent
		WHERE node.lft BETWEEN parent.lft AND parent.rgt
		AND node.name = 'PORTABLE ELECTRONICS'
		GROUP BY node.name
		ORDER BY node.lft
	)AS sub_tree
  WHERE node.lft BETWEEN parent.lft AND parent.rgt
	AND node.lft BETWEEN sub_parent.lft AND sub_parent.rgt
	AND sub_parent.name = sub_tree.name
  GROUP BY node.name
  ORDER BY node.lft;

I find it horrible.

=cut

sub tree_compute_levels {
    my ($self, $data) = @_;
    my %levels = ();
    my @par;
    my $l = 0;
    foreach my $h (@$data) {
        while (@par > 0) {
            my $prev = $par[$#par];
            if ($h->{lft} < $prev->{rgt}) {
                # contained
                ++$l;
                last;
            } else {
                pop @par;
                if (@par) {
                    --$l;
                }
            }
        }
        push @par, $h;
        $levels{$h->{id}} = $l;
    }
    return \%levels;
}

1;

=head1 TODO

 - Allow custom names for the required fields (lft, rgt, mvg, id,
   parent).

 - Allow custom types for the primary key (currently they MUST be
   integers).

=head1 REFERENCES

 [1] MySQL AB: Managing Hierarchical Data in MySQL, by Mike Hillyer
     http://dev.mysql.com/tech-resources/articles/hierarchical-data.html

=head1 SEE ALSO

L<DBIx::OO>

=head1 AUTHOR

Mihai Bazon, <mihai.bazon@gmail.com>
    http://www.dynarch.com/
    http://www.bazon.net/mishoo/

=head1 COPYRIGHT

Copyright (c) Mihai Bazon 2006.  All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
