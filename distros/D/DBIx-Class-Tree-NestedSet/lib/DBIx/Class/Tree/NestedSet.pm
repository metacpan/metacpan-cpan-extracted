package DBIx::Class::Tree::NestedSet;

use strict;
use warnings;

use Carp qw/croak/;
use base 'DBIx::Class';

our $VERSION = '0.10';
$VERSION = eval $VERSION;

__PACKAGE__->mk_classdata( _tree_columns => {} );

# specify the tree columns and define the relationships
#
sub tree_columns {
    my ($class, $args) = @_;

    if (defined $args) {

        my ($root, $left, $right, $level) = map {
            my $col = $args->{"${_}_column"};
            croak("required param $_ not specified") if !defined $col;
            $col;
        } qw/root left right level/;

        my $table        = $class->table;
        my %join_cond    = ( "foreign.$root" => "self.$root" );

        $class->belongs_to(
            'root' => $class,
            \%join_cond,{
                where    => \"me.$left = 1",                              #"
            },
        );

        $class->belongs_to(
            'parent' => $class,
            \%join_cond,{
                where    => \"child.$left > me.$left AND child.$right < me.$right AND me.$level = child.$level - 1",       #"
                from     => "$table me, $table child",
            },
        );

        $class->has_many(
            'nodes' => $class,
            \%join_cond,{
                order_by        => "me.$left",
                cascade_delete  => 0,
            },
        );

        $class->has_many(
            'descendants' => $class,
            \%join_cond, {
                where           => \"me.$left > parent.$left AND me.$right < parent.$right",     #"
                order_by        =>  "me.$left",
                from            =>  "$table me, $table parent",
                cascade_delete  => 0,
            },
        );

        $class->has_many(
            'children' => $class,
            \%join_cond, {
                where           => \"me.$left > parent.$left AND me.$right < parent.$right AND me.$level = parent.$level + 1",     #"
                order_by        =>  "me.$left",
                from            =>  "$table me, $table parent",
                cascade_delete  => 0,
            },
        );

        $class->has_many(
            'ancestors' => $class,
            \%join_cond, {
                where           => \"child.$left > me.$left AND child.$right < me.$right",       #"
                order_by        =>  "me.$right",
                from            =>  "$table me, $table child",
                cascade_delete  => 0,
            },
        );

        $class->_tree_columns($args);
    }

    return $class->_tree_columns;
}

# Insert a new node.
#
# If the 'right' column is not defined it assumes that we are inserting a root
# node.
#
sub insert {
    my ($self, @args) = @_;

    my ($root, $left, $right, $level) = $self->_get_columns;

    if (!$self->$right) {
        $self->set_columns({
            $left  => 1,
            $right => 2,
            $level => 0,
        });
    }

    my $row;
    my $get_row = $self->next::can;
    $self->result_source->schema->txn_do(sub {
        $row = $get_row->($self, @args);

        # If the root column is not defined, it uses the primary key so long as it is a
        # single column primary key
        if (!defined $row->$root) {
            my @primary_columns = $row->result_source->primary_columns;
            if (scalar @primary_columns > 1) {
                croak('Only single column primary keys are supported for default root selection in nested set tree classes');
            }

            $row->update({
                $root => \"$primary_columns[0]",            #"
            });

            $row->discard_changes;
        }
    });

    return $row;
}

# Delete the current node, and all sub-nodes.
#
sub delete {
    my ($self) = shift;

    my ($root, $left, $right, $level) = $self->_get_columns;

    my $p_lft = $self->$left;
    my $p_rgt = $self->$right;

    my $del_row = $self->next::can;
    $self->result_source->schema->txn_do(sub {
        $self->discard_changes;

        my $descendants = $self->descendants;
        while (my $descendant = $descendants->next) {
            $del_row->($descendant);
        }

        $self->nodes_rs->update({
            $left  => \"CASE WHEN $left  > $p_rgt THEN $left  - 2 ELSE $left  END",     #"
            $right => \"CASE WHEN $right > $p_rgt THEN $right - 2 ELSE $right END",     #"
        });
        $del_row->($self);
    });
}

# Create a related node with special handling for relationships
#
sub create_related {
    my ($self, $rel, $col_data) = @_;

    if (! grep {$rel eq $_} qw(descendants children nodes ancestors)) {
        return $self->next::method($rel => $col_data);
    }

    my ($root, $left, $right, $level) = $self->_get_columns;

    my $row;
    my $get_row = $self->next::can;
    $self->result_source->schema->txn_do(sub {
        $self->discard_changes;

        # With create related ancestor, make it a parent of this child
        if ($rel eq 'ancestors') {
            my $p_lft   = $self->$left;
            my $p_rgt   = $self->$right;
            my $p_level = $self->$level;

            # Update all the nodes to the right of this sub-tree
            $self->nodes_rs->update({
                $left  => \"CASE WHEN $left  > $p_rgt THEN $left  + 2 ELSE $left  END",     #"
                $right => \"CASE WHEN $right > $p_rgt THEN $right + 2 ELSE $right END",     #"
            });

            # Update all the nodes of this sub-tree
            $self->nodes_rs->search({
                $left   => { '>=', $p_lft },
                $right  => { '<=', $p_rgt }
                })->update({
                $left   => \"$left + 1",                                                    #"
                $right  => \"$right + 1",                                                   #"
                $level  => \"$level + 1",                                                   #"
            });

            $self->discard_changes;
            $col_data->{$root}  = $self->$root;
            $col_data->{$left}  = $p_lft;
            $col_data->{$right} = $p_rgt+2;
            $col_data->{$level} = $p_level;
        }
        else {
            # insert a descendant, node or a child as a right-most child
            my $p_rgt = $self->$right;

            # Update all the nodes to the right of this sub-tree
            $self->nodes_rs->update({
                $left  => \"CASE WHEN $left  >  $p_rgt THEN $left  + 2 ELSE $left  END",    #"
                $right => \"CASE WHEN $right >= $p_rgt THEN $right + 2 ELSE $right END",    #"
            });
            $self->discard_changes;
            $col_data->{$root}  = $self->$root;
            $col_data->{$left}  = $p_rgt;
            $col_data->{$right} = $p_rgt+1;
            $col_data->{$level} = $self->$level+1;

        }
        $row = $get_row->($self, $rel => $col_data);
    });

    return $row;
}

# search_related with special handling for relationships
#
sub search_related {
    my ($self, $rel, $cond, @rest) = @_;
    my $pk = ($self->result_source->primary_columns)[0];

    $cond ||= {};
    if ($rel eq 'descendants' || $rel eq 'children') {
        $cond->{"parent.$pk"} = $self->$pk,
    }
    elsif ($rel eq 'ancestors' || $rel eq 'parent') {
        $cond->{"child.$pk"} = $self->$pk,
    }

    return $self->next::method($rel, $cond, @rest);
}
*search_related_rs = \&search_related;

# Insert a node anywhere in the tree
#   left
#   right
#   level
#   other_args
#
sub _insert_node {
    my ($self, $args) = @_;
    my $rset   = $self->result_source->resultset;
    my $schema = $self->result_source->schema;

    my ($root, $left, $right, $level) = $self->_get_columns;

    # our special arguments
    my $o_args = delete $args->{other_args};
    my $pivot  = $args->{$left};

    # Use same level as self by default
    $args->{$level}  = $self->$level unless defined $args->{$level};
    $args->{$root}   = $self->$root unless defined $args->{$root};

    # make room and create it
    my $new_record;
    $schema->txn_do(sub {
        $self->discard_changes;
        $rset->search({
            "me.$right" => {'>=', $pivot},
            $root       => $self->$root,
        })->update({
            $right => \"$right + 2",                                #"
        });

        $rset->search({
            "me.$left"  => {'>=', $pivot},
            $root       => $self->$root,
        })->update({
            $left => \"$left + 2",                                  #"
        });
        $self->discard_changes;

        $new_record = $rset->create({%$o_args, %$args});
    });
    return $new_record;
}

# Attach a node anywhere in the tree
#   node
#   left_delta (relative to $self->$left
# (or) right_delta (relative to $self->$right
#   level
#
sub _attach_node {
    my ($self, $node, $args) = @_;
    my $rset   = $self->result_source->resultset;
    my $schema = $self->result_source->schema;
    my ($root, $left, $right, $level) = $self->_get_columns;

    # $self cannot be a descendant of $node or $node itself
    if ($self->$root == $node->$root && $self->$left >= $node->$left && $self->$right <= $node->$right) {
        croak("Cannot _attach_node to it's own descendant ");
    }

    $schema->txn_do(sub {
        $self->discard_changes;
        $node->discard_changes;
        # Move the node to the end (right most child of root)
        $node->_move_to_end;
        $self->discard_changes;
        $node->discard_changes;
        # Graft the node to the specified location
        my $left_val;
        if (defined $args->{left_delta}) {
            $left_val = $self->$left + $args->{left_delta};
        }
        else {
            $left_val = $self->$right + $args->{right_delta};
        }
        $self->_graft_branch({
            node    => $node,
            $left   => $left_val,
            $level  => $args->{$level}
        });
    });
}


# Graft a branch of nodes (or a leaf) at this point
# The assumption made here is that the nodes being moved here are
# either a root node of another tree or the rightmost child of
# this or another trees root (see _move_to_end)
#
sub _graft_branch {
    my ($self, $args) = @_;

    my ($root, $left, $right, $level) = $self->_get_columns;
    my $rset    = $self->result_source->resultset;

    my $node        = $args->{node};
    my $arg_left    = $args->{$left};
    my $arg_level   = $args->{$level};
    my $node_is_root = $node->is_root;
    my $node_root   = $node->root;

    if ($node_is_root) {
        # Cannot graft our own root
        croak "Cannot graft our own root node!" if $node->$root == $self->$root;
    }
    else {
        # Node must be rightmost child of it's root
        croak "Can only graft rightmost child of root!" if $node->$right + 1 != $node_root->$right;
    }

    # If the position we are grafting to is the rightmost child of root then there is nothing to do
    if ($self->$root == $node->$root && $self->is_root && $self->$left + $arg_left > $node_root->$right) {
        return;
    }

    # Determine the size of the branch to add in.
    my $offset = $node->$right + 1 - $node->$left;

    # Make a hole in the tree to accept the graft
    $self->discard_changes;
    $rset->search({
        "me.$right" => {'>=', $arg_left},
        $root       => $self->$root,
    })->update({
        $right      => \"$right + $offset",                         #"
    });
    $rset->search({
        "me.$left"  => {'>=', $arg_left},
        $root       => $self->$root,
    })->update({
        $left       => \"$left + $offset",                          #"
    });

    # make the graft
    $node->discard_changes;
    my $node_left   = $node->$left;
    my $node_right  = $node->$right;
    my $level_offset= $arg_level - $node->$level;
    my $graft_offset= $arg_left - $node->$left;

    $self->discard_changes;
    $rset->search({
        "me.$left"  => {'>=', $node_left},
        "me.$right" => {'<=', $node_right},
        $root       => $node->$root,
    })->update({
        $left       => \"$left + $graft_offset",                    #"
        $right      => \"$right + $graft_offset",                   #"
        $level      => \"$level + $level_offset",                   #"
        $root       => $self->$root,
    });

    # adjust the right value of the root node to take into account the
    # moved nodes
    if (! $node_is_root) {
        $node_root->discard_changes;
        $node_root->$right($node_root->$right - $offset);
        $node_root->update;
    }

    $self->discard_changes;
    $node->discard_changes;
}

# Move nodes to end of tree
# This will help make it easier to prune the nodes from
# the tree since there will be nothing to the right of them
#
sub _move_to_end {
    my ($self) = @_;

    my ($root, $left, $right, $level) = $self->_get_columns;
    my $rset    = $self->result_source->resultset;

    my $root_node   = $self->root;
    my $old_left    = $self->$left;
    my $old_right   = $self->$right;
    my $offset      = $root_node->$right - $self->$left;
    my $level_offset= $self->$level - 1;

    # If it is the root or already on the right, do nothing
    if ($self->is_root || $old_right + 1 == $root_node->$right) {
        return;
    }

    # Move all sub-nodes to the right (adjusting their level)
    $self->discard_changes;
    $rset->search({
        "me.$left"  => {'>=', $old_left},
        "me.$right" => {'<=', $old_right},
        $root       => $self->$root,
    })->update({
        $left       => \"$left + $offset",                          #"
        $right      => \"$right + $offset",                         #"
        $level      => \"$level - $level_offset",                   #"
    });

    # Now move everything (except the root) back to fill in the gap
    $offset = $self->$right + 1 - $self->$left;
    $rset->search({
        "me.$right" => {'>=', $old_right},
        $left       => {'!=', 1},               # Root needs no adjustment
        $root       => $self->$root,
    })->update({
        $right      => \"$right - $offset",                         #"
    });
    $rset->search({
        "me.$left"  => {'>=', $old_right},
        $root       => $self->$root,
    })->update({
        $left       => \"$left - $offset",                          #"
    });
    $self->discard_changes;
}

# Convenience routine to get the names of the table columns
#
sub _get_columns {
    my ($self) = @_;

    my ($root, $left, $right, $level) = map {
        $self->tree_columns->{"${_}_column"}
    } qw/root left right level/;

    return ($root, $left, $right, $level);
}

# Attach a node as the rightmost child of the current node
#
sub attach_rightmost_child {
    my $self = shift;

    my ($root, $left, $right, $level) = $self->_get_columns;

    foreach my $node (@_) {
        $self->_attach_node($node, {
            right_delta => 0,
            $level      => $self->$level + 1,
        });
    }
    return $self;
}
*append_child = \&attach_rightmost_child;

# Attach a node as the leftmost child of the current node
#
sub attach_leftmost_child {
    my $self = shift;

    my ($root, $left, $right, $level) = $self->_get_columns;

    foreach my $node (@_) {
        $self->_attach_node($node, {
            left_delta  => 1,
            $level      => $self->$level + 1,
        });
    }
    return $self;
}
*prepend_child = \&attach_leftmost_child;

# Attach a node as a sibling to the right of self
#
sub attach_right_sibling {
    my $self = shift;

    my ($root, $left, $right, $level) = $self->_get_columns;

    foreach my $node (@_) {
        $self->_attach_node($node, {
            right_delta => 1,
            $level      => $self->$level,
        });
    }
    return $self;
}
*attach_after = \&attach_right_sibling;

# Attach a node as a sibling to the left of self
#
sub attach_left_sibling {
    my $self = shift;

    my ($root, $left, $right, $level) = $self->_get_columns;

    foreach my $node (@_) {
        $self->_attach_node($node, {
            left_delta  => 0,
            $level      => $self->$level,
        });
    }
    return $self;
}
*attach_before = \&attach_left_sibling;

# take_cutting
# Given a node, cut it from it's current tree and make it the root of a new tree
# NOTE2: The root ID must be specified for multi-key primary keys
# otherwise it comes from the primary key
#
sub take_cutting {
    my $self = shift;

    my ($root, $left, $right, $level) = $self->_get_columns;

    $self->result_source->schema->txn_do(sub {
        my $p_lft = $self->$left;
        my $p_rgt = $self->$right;
        return $self if $p_lft == $p_rgt + 1;

        my $pk = ($self->result_source->primary_columns)[0];

        $self->discard_changes;
        my $root_id = $self->$root;

        my $p_diff = $p_rgt - $p_lft;
        my $l_diff = $self->$level - 1;
        my $new_id = $self->$pk;
        # I'd love to use $self->descendants->update(...),
        # but it dies with "_strip_cond_qualifiers() is unable to
        # handle a condition reftype SCALAR".
        # tough beans.
        $self->nodes_rs->search({
            $root   => $root_id,
            $left   => {'>=' => $p_lft },
            $right  => {'<=' => $p_rgt },
        })->update({
            $left   => \"$left - $p_lft + 1",               #"
            $right  => \"$right - $p_lft + 1",              #"
            $root   => $new_id,
            $level  => \"$level - $l_diff",                 #"
        });

        # fix up the rest of the tree
        $self->nodes_rs->search({
            $root   => $root_id,
            $left   => { '>=' => $p_rgt},
        })->update({
            $left   => \"$left  - $p_diff",                 #"
            $right  => \"$right - $p_diff",                 #"
        });
    });
    return $self;
}

sub dissolve {
    my $self = shift;
    my ($root, $left, $right, $level) = $self->_get_columns;
    my $pk = ($self->result_source->primary_columns)[0];
    $self->nodes_rs->search({$root => $self->$root})->update({
        $level  => 1,
        $left   => 1,
        $right  => 2,
        $root   => \"$pk",                                  #"
    });
    return $self;
}

# Move a node to the left
# Swap position with the sibling on the left
# returns the node it exchanged with on success, undef if it is already leftmost sibling
#
sub move_left {
    my ($self) = @_;

    my $previous = $self->left_sibling;
    if (! $previous) {
        return;
    }
    $previous->attach_left_sibling($self);
    return $previous;
}
*move_previous = \&move_left;

# Move a node to the right
# Swap position with the sibling on the right
# returns the node it exchanged with on success, undef if it is already rightmost sibling
#
sub move_right {
    my ($self) = @_;

    my $next = $self->right_sibling;
    if (! $next) {
        return;
    }
    $next->attach_right_sibling($self);
    return $next;
}
*move_next = \&move_right;

# Move a node to be the leftmost child
# Make this node the leftmost sibling
# returns the node it exchanged with on success, undef if it is already leftmost sibling
sub move_leftmost {
    my ($self) = @_;

    my $first = $self->leftmost_sibling;
    if (! $first) {
        return;
    }
    $first->attach_left_sibling($self);
    return $first;
}
*move_first = \&move_leftmost;

# Make this node the rightmost sibling
# returns 1 on success, 0 if it is already rightmost sibling
sub move_rightmost {
    my ($self) = @_;

    my $last = $self->rightmost_sibling;
    if (! $last) {
        return;
    }
    $last->attach_right_sibling($self);
    return $last;
}
*move_last = \&move_rightmost;

# Move this node to the specified position
# Returns 1 on success, 0 if it is already in that position
#
sub move_to {
}

# Return a resultset of all siblings excluding the one called on
#
sub siblings {
    my ($self) = @_;

    my ($root, $left, $right, $level) = $self->_get_columns;

    if ($self->is_root) {
        # Root has no siblings
        return;
    }
    if (wantarray()) {
        my @siblings = $self->parent->children({
            "me.$left" => {'!=', $self->$left },
        });
        return @siblings;
    }
    my $siblings_rs = $self->parent->children({
        "me.$left" => {'!=', $self->$left },
    });
    return $siblings_rs;
}

# Returns a resultset of all siblings to the left of this one
#
sub left_siblings {
    my ($self) = @_;

    my ($root, $left, $right, $level) = $self->_get_columns;

    if ($self->is_root) {
        # Root has no siblings
        return;
    }
    if (wantarray()) {
        my @siblings = $self->parent->children({
            "me.$left" => {'<', $self->$left },
        });
        return @siblings;
    }
    my $siblings_rs = $self->parent->children({
        "me.$left" => {'<', $self->$left },
    });
    return $siblings_rs;
}
*previous_siblings = \&left_siblings;

# Returns a resultset of all siblings to the right of this one
#
sub right_siblings {
    my ($self) = @_;

    my ($root, $left, $right, $level) = $self->_get_columns;

    if ($self->is_root) {
        # Root has no siblings
        return;
    }
    if (wantarray()) {
        my @siblings = $self->parent->children({
            "me.$left" => {'>', $self->$left },
        });
        return @siblings;
    }
    my $siblings_rs = $self->parent->children({
        "me.$left" => {'>', $self->$left },
    });
    return $siblings_rs;
}
*next_siblings = \&right_siblings;


# return the sibling to the left of this one
#
sub left_sibling {
    my ($self) = @_;

    my ($root, $left, $right, $level) = $self->_get_columns;

    if ($self->is_root) {
        # Root has no siblings
        return;
    }

    my $sibling = $self->left_siblings->search({
        "me.$right" => $self->$left - 1,
        },{
        rows        => 1,
    })->first;

    return $sibling;
}
*previous_sibling = \&left_sibling;

# return the sibling to the right of this one
#
sub right_sibling {
    my ($self) = @_;

    my ($root, $left, $right, $level) = $self->_get_columns;

    if ($self->is_root) {
        # Root has no siblings
        return;
    }

    my $sibling = $self->right_siblings->search({
        "me.$left" => $self->$right + 1,
        },{
        rows        => 1,
    })->first;

    return $sibling;
}
*next_sibling = \&right_sibling;

# Returns the leftmost sibling or undef if this is the first sibling
#
sub leftmost_sibling {
    my ($self) = @_;

    my ($root, $left, $right, $level) = $self->_get_columns;

    if ($self->is_root) {
        # Root has no siblings
        return;
    }

    my $sibling = $self->left_siblings->search({},{
        order_by    => "me.$left",
        rows        => 1,
    })->first;

    return $sibling;
}
*first_sibling = \&leftmost_sibling;

# Returns the rightmost sibling or undef if this is the rightmost sibling
#
sub rightmost_sibling {
    my ($self) = @_;

    my ($root, $left, $right, $level) = $self->_get_columns;

    if ($self->is_root) {
        # Root has no siblings
        return;
    }

    my $sibling = $self->right_siblings->search({},{
        order_by    => "me.$left desc",
        rows        => 1,
    })->first;

    return $sibling;
}
*last_sibling = \&rightmost_sibling;

# Insert a sibling to the right of this one
#
sub create_right_sibling {
    my ($self, $args) = @_;

    my ($root, $left, $right, $level) = $self->_get_columns;

    return $self->_insert_node({
        $left       => $self->$right + 1,
        $right      => $self->$right + 2,
        $level      => $self->$level,
        other_args  => $args,
    });
}

# Insert a sibling to the left of this one
#
sub create_left_sibling {
    my ($self, $args) = @_;

    my ($root, $left, $right, $level) = $self->_get_columns;

    return $self->_insert_node({
        $left       => $self->$left,
        $right      => $self->$left + 1,
        $level      => $self->$level,
        other_args  => $args,
    });
}

# Insert a rightmost child
#
sub create_rightmost_child {
    my ($self, $args) = @_;

    my ($root, $left, $right, $level) = $self->_get_columns;

    return $self->_insert_node({
        $left       => $self->$right,
        $right      => $self->$right + 1,
        $level      => $self->$level + 1,
        other_args  => $args,
    });
}

# Insert a leftmost child
#
sub create_leftmost_child {
    my ($self, $args) = @_;

    my ($root, $left, $right, $level) = $self->_get_columns;

    return $self->_insert_node({
        $left       => $self->$left + 1,
        $right      => $self->$left + 2,
        $level      => $self->$level + 1,
        other_args  => $args,
    });
}

# Given a primary key, determine if it is a descendant of
# this object
#
sub has_descendant {
    my ($self) = shift;

    my $descendant = $self->result_source->resultset->find(@_);
    if (! $descendant) {
        return;
    }

    my ($root, $left, $right, $level) = $self->_get_columns;

    if ($descendant->$left > $self->$left && $descendant->$right < $self->$right) {
        return 1;
    }
    return;
}

# Given a primary key, determine if it is an ancestor of
# this object
#
sub has_ancestor {
    my ($self) = shift;

    my $ancestor = $self->result_source->resultset->find(@_);
    if (! $ancestor) {
        return;
    }

    my ($root, $left, $right, $level) = $self->_get_columns;

    if ($self->$left > $ancestor->$left && $self->$right < $ancestor->$right) {
        return 1;
    }
    return;
}

# returns true if this node is a root node
#
sub is_root {
    my ($self) = @_;

    if ($self->get_column( $self->tree_columns->{level_column} ) == 0) {
        return 1;
    }
    return;
}

# returns true if this node is a leaf node (no children)
#
sub is_leaf {
    my ($self) = @_;

    if ($self->get_column( $self->tree_columns->{right_column}) - $self->get_column( $self->tree_columns->{left_column}) == 1) {
        return 1;
    }
    return;
}

# returns true if this node is a branch (has children)
#
sub is_branch {
    my ($self) = @_;

    return !$self->is_leaf;
}

1;

=head1 NAME

DBIx::Class::Tree::NestedSet - Manage trees of data using the nested set model

=head1 SYNOPSIS

Create a table for your tree data.

    CREATE TABLE Department (
      id       INTEGER PRIMARY KEY AUTOINCREMENT,
      root_id  integer,
      lft      integer NOT NULL,
      rgt      integer NOT NULL,
      level    integer NOT NULL,
      name     text NOT NULL,
    );

In your Schema or DB class add Tree::NestedSet to the top
of the component list.

  __PACKAGE__->load_components(qw( Tree::NestedSet ... ));

Specify the columns required by the module.

  package My::Department;
  __PACKAGE__->tree_columns({
      root_column     => 'root_id',
      left_column     => 'lft',
      right_column    => 'rgt',
      level_column    => 'level',
  });

Using it:

  my $root        = My::Department->create({ ... });
  my $child       = $root->add_to_children({ ... });

  my $rs          = $root->children;
  my @descendants = $root->children;

  my $parent      = $child->parent;
  my $rs          = $child->ancestors;
  my @ancestors   = $child->ancestors;

=head1 DESCRIPTION

This module provides methods for working with nested set trees. The nested tree
model is a way of representing hierarchical information in a database. This
takes a different approach to the Adjacency List implementation. (see
L<DBIx::Class::Tree::AdjacencyList> which uses C<parent> relationships in a recursive manner.

The NestedSet implementation can be more efficient for most searches than the Adjacency List Implementation,
for example, to obtain all descendants requires recursive queries in the Adjacency List
implementation but is a single query in the NestedSet implementation.

The trade-off is that NestedSet inserts are more expensive so it is most useful if
you have an application that does many reads but few inserts.

More about NestedSets can be found at L<http://en.wikipedia.org/wiki/Nested_set_model>

Oh, and although I give some code examples of familial relationships (where there are usually
two parents), both Adjacency List and NestedSet implementations can only have one parent.

=head1 RELATIONS

This module automatically creates several relationships.

=head2 root

  $root_node = $node->root;

A belongs_to relation to the root of C<$node>s tree.

=head2 nodes

  $all_nodes = $node->nodes;
  $new_node  = $node->add_to_nodes({name => 'Mens Wear'});

A has_many relationship to all the nodes of C<$node>s tree.

Adding to this relationship creates a rightmost child to C<$node>.

=head2 parent

  $parent = $node->parent;

A belongs_to relationship to the parent node of C<$node>s tree.

Note that only the root node does not have a parent.

=head2 children

  $rs          = $node->children;
  @children    = $node->children;
  $child       = $node->add_to_children({name => 'Toys'});

A has_many relation to the children of C<$node>.

Adding to this relationship creates a rightmost child to C<$node>.

=head2 descendants

  $rs          = $node->descendants;
  @descendants = $node->descendants;
  $child       = $node->add_to_descendants({name => 'Mens Wear'});

A has_many relation to the descendants of C<$node>.

Adding to this relationship creates a rightmost child to C<$node>.

=head2 ancestors

  $rs          = $node->ancestors;
  @ancestors   = $node->ancestors;
  $parent      = $node->add_to_ancestors({name => 'Head office'});

A has_many relation to the ancestors of C<$node>.

Adding to this relationship creates a new node in place of C<$node>
and makes it the parent of C<$node>. All descendants of C<$node>
will likewise be pushed town the hierarchy.

=head1 METHODS

Many methods have alternative names, e.g. C<left_siblings> and C<previous_siblings>

This is in deference to the L<DBIx::Class::Ordered> module which uses terms
C<previous> C<next> C<first> and C<last>.

Similarly L<DBIx::Class::Tree::AdjacencyList::Ordered> uses terms C<append>, C<prepend>,
C<before> and C<after>

However, my preference to use terms C<left> and C<right> consistently when using
this module. However, the other names are available if you are more familiar with
those modules.

=head2 tree_columns

  __PACKAGE__->tree_columns({
      left_column   => 'lft',
      right_column  => 'rgt',
      root_column   => 'root_id',
      level_column  => 'level',
  });

Declare the name of the columns defined in the database schema.

None of these columns should be modified outside if this module. left_column
and right_column are unlikely to be of any use to your application. They
should be integer fields.

Multiple trees are allowed in the same table, each tree will have a unique
value in the root_column. In the current implementation this should be an
integer field

The level_column may be of use in your application, it defines the depth of
each node in the tree (with the root at level zero).

=head2 create

  my $tree    = $schema->resultset('My::Department')->create({
      name    = 'Head Office',
  });

  my $tree    = $schema->resultset('My::Department')->create({
      name    = 'UK Office',
      root_id = $uk_office_ident,
  });

Creates a new root node.

If the root_column (root_id) is not provided then it defaults to producing
a node where the root_column has the same value as the primary key. This will
croak if the table is defined with multiple key primary index.

Note that no checks (yet) are made to stop you creating another key with
the same root_id as an existing tree. If you do so you will get into a terrible
mess!

=head2 delete

  $department->delete;

This will delete the node and all descendants. Cascade Delete is turned off
in the has_many relationships C<nodes> C<children> C<descendants> so that
delete DTRT.

=head2 is_root

  if ($node->is_root) {
      print "Node is a root\n";
  }

Returns true if the C<$node> is a root node

=head2 is_branch

  $has_children = $node->is_branch;

Returns true if the node is a branche (i.e. has children)

=head2 is_leaf

  $is_terminal_node = $node->is_leaf;

Returns true if the node is a leaf (i.e. it has no children)

=head2 siblings

  @siblings    = $node->siblings;
  $siblings_rs = $node->siblings;

Returns all siblings of this C<$node> excluding C<$node> itself.

Since a root node has no siblings it returns undef.

=head2 left_siblings (or previous_siblings)

  @younger_siblings    = $node->left_siblings;
  $younger_siblings_rs = $node->left_siblings;

Returns all siblings of this C<$node> to the left this C<$node>.

Since a root node has no siblings it returns undef.

=head2 right_siblings (or next_siblings)

  @older_siblings      = $node->right_siblings;
  $older_siblings_rs   = $node->right_siblings;

Returns all siblings of this C<$node> to the right of this C<$node>.

Since a root node has no siblings it returns undef.

=head2 left_sibling (or previous_sibling)

  $younger_sibling = $node->left_sibling;

Returns the sibling immediately to the left of this C<$node> (if any).

=head2 right_sibling (or next_sibling)

  $older_sibling = $node->right_sibling;

Returns the sibling immediately to the right of this C<$node> (if any).

=head2 leftmost_sibling (or first_sibling)

  $youngest_sibling = $node->leftmost_sibling;

Returns the left most sibling relative to this C<$node> (if any).

Does not return this C<$node> if this node is the leftmost sibling.

=head2 rightmost_sibling (or last_sibling)

  $oldest_sibling = $node->rightmost_sibling;

Returns the right most sibling relative to this C<$node> (if any).

Does not return this C<$node> if this node is the rightmost sibling.

=head2 CREATE METHODS

The following create methods create a new node in relation to an
existing node.

=head2 create_right_sibling

  $bart->create_right_sibling({ name => 'Lisa' });

Create a new node as a right sibling to C<$bart>.

=head2 create_left_sibling

  $bart->create_left_sibling({ name => 'Maggie' });

Create a new node as a left sibling to C<$bart>.

=head2 create_rightmost_child

  $homer->create_rightmost_child({ name => 'Lisa' });

Create a new node as a rightmost child to C<$homer>

=head2 create_leftmost_child

  $homer->create_leftmost_child({ name => 'Maggie' });

Create a new node as a leftmost child to C<$homer>


=head2 ATTACH METHODS

The following attach methods take an existing node (and all of it's
descendants) and attaches them to the tree in relation to an existing node.

The node being inserted can either be from the same tree (as identified
by the root_column) or from another tree. If the root of another tree is
attached then the whole of that tree becomes a sub-tree of this node's
tree.

The only restriction is that the node being attached cannot be an ancestor
of this node.

When attaching multiple nodes we try to DWIM so that the order they are specified
in the call represents the order they appear in the siblings list.

e.g. if we had a parent with children A,B,C,D,E

and we attached nodes 1,2,3 in the following calls, we expect the following results.

  $parent->attach_rightmost_child    1,2,3 gives us children A,B,C,D,E,1,2,3

  $parent->attach_leftmost_child     1,2,3 gives us children 1,2,3,A,B,C,D,E

  $child_C->attach_right_sibling     1,2,3 gives us children A,B,C,1,2,3,D,E

  $child_C->attach_left_sibling      1,2,3 gives us children A,B,1,2,3,C,D,E

  $child_C->attach_rightmost_sibling 1,2,3 gives us children A,B,C,D,E,1,2,3

  $child_C->attach_leftmost_sibling  1,2,3 gives us children 1,2,3,A,B,C,D,E

=head2 attach_rightmost_child (or append_child)

  $parent->attach_rightmost_child($other_node);
  $parent->attach_rightmost_child($other_node_1, $other_node_2, ...);

Attaches the other_nodes to C<$parent> as the rightmost children.

=head2 attach_leftmost_child

  $parent->attach_leftmost_child($other_node);
  $parent->attach_leftmost_child($other_node_1, $other_node_2, ...);

Attaches the other_nodes to C<$parent> as the leftmost children.

=head2 attach_right_sibling (or attach_after)

  $node->attach_right_sibling($other_node);
  $node->attach_right_sibling($other_node_1, $other_node_2, ...);

Attaches the other_nodes to C<$node> as it's siblings.

=head2 attach_left_sibling

  $node->attach_left_sibling($other_node);
  $node->attach_left_sibling($other_node_1, $other_node_2, ...);

Attaches the other_nodes to C<$node> as it's left siblings.

=head2 attach_rightmost_sibling

  $node->attach_rightmost_sibling($other_node);
  $node->attach_rightmost_sibling($other_node_1, $other_node_2, ...);

Attaches the other_nodes to C<$node> as it's rightmost siblings.

=head2 attach_leftmost_sibling

  $node->attach_leftmost_sibling($other_node);
  $node->attach_leftmost_sibling($other_node_1, $other_node_2, ...);

Attaches the other_nodes to C<$node> as it's leftmost siblings.

=head2 move_left (or move_previous)

  $node->move_left;

Exchange the C<$node> with the sibling immediately to the left and return the
node it exchanged with.

If the C<$node> is already the leftmost node then no exchange takes place
and the method returns undef.

=head2 move_right (or move_next)

  $node->move_right;

Exchange the C<$node> with the sibling immediately to the right and return the
node it exchanged with.

If the C<$node> is already the rightmost node then no exchange takes place
and the method returns undef.

=head2 move_leftmost (or move_first)

  $node->move_leftmost;

Exchange the C<$node> with the leftmost sibling and return the
node it exchanged with.

If the C<$node> is already the leftmost node then no exchange takes place
and the method returns undef.

=head2 move_rightmost (or move_last)

  $node->move_rightmost;

Exchange the C<$node> with the rightmost sibling and return the
node it exchanged with.

If the C<$node> is already the rightmost node then no exchange takes place
and the method returns undef.

=head2 CUTTING METHODS

=head2 take_cutting

Cuts the invocant and its descendants out of the tree they are in,
making the invocant the root of a new tree. Returns the modified
invocant.

=head2 dissolve

Dissolves the entire thread, that is turn each node of the thread into a
single-item tree of its own.

=head1 CAVEATS

=head2 Multiple Column Primary Keys

Support for Multiple Column Primary Keys is limited (mainly because I rarely
use them) but I have tried to make it possible to use them. Please let me
know if this does not work as well as you expect.

=head2 discard_changes

By the nature of Nested Set implementations, moving, inserting or deleting
nodes in the tree will potentially update many (sometimes most) other nodes.

Even if you have preloaded some of the objects, if you make a change to one
object the other objects will not reflect their new value until you have
reloaded them from the database.
(see L<DBIx::Class::Row/discard_changes>)

A simple demonstration of this

  $grampa   = $schema->schema->resultset('Simpsons')->create({ name => 'Abraham' });
  $homer    = $grampa->add_children({name => 'Homer'});
  $bart     = $homer->add_children({name => 'Bart'});

The methods in this module will do their best to keep instances that they know
about updated. For example the first call to C<add_children> in the above example
will update C<$grampa> and C<$homer> with the latest changes to the database.

However, the second call to C<add_children> only knows about C<$homer> and C<$bart>
and in adding a new node to the tree it will update the C<$grampa> node in
the database. To ensure you have the latest changes do the following.

  $grampa->discard_changes.

Not doing so will have unpredictable results.

=head1 AUTHORS

Code by Ian Docherty E<lt>pause@iandocherty.comE<gt>

Based on original code by Florian Ragwitz E<lt>rafl@debian.orgE<gt>

Incorporating ideas and code from Pedro Melo E<lt>melo@simplicidade.orgE<gt>

Special thanks to Moritz Lenz who sent in lots of patches and changes for version 0.08

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009-2011 The above authors

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
