package DBIx::Path;

use strict;
use warnings;
use DBI;
use Carp qw(croak);

our $VERSION=0.03;

=head1 NAME

DBIx::Path - resolve a path in an in-database tree or directed graph

=head1 SYNOPSIS

    use DBIx::Path;
    my $root=DBIx::Path->new(dbh => $dbh, table => 'treetable');
    my $node=$root->resolve(split '/', 'one/two/three')
		or die "Can't resolve path: $! at $DBIx::Path::FAILED[0]";
    print $_->name, "\t", $_->id, "\n" for $node->list;

=head1 DESCRIPTION

DBIx::Path is used to navigate through trees or directed graphs described by 
self-referential SQL database tables.  It can be used to browse most trees where 
each row contains a unique ID and the ID of its parent, as well as graphs structured 
similarly but with multiple parents for a given node (presumably with the actual data 
for a given ID stored in a different table).

The module is designed to work with tables with at least three columns.  One
is called the parent ID (pid); one is called the name; and one is the ID.  The 
combination of a particular pid and name must be unique in the entire table.
The three columns can be of any type, but pid and id should probably be of the 
same type.  The columns can have any name you want--you're not confined to 
"id", "pid", and "name".  It is possible to have the id and name be the same
column.

An example layout:

    CREATE TABLE tree (
        pid INTEGER NOT NULL,
        name VARCHAR(16) NOT NULL,
        id INTEGER NOT NULL,
        PRIMARY KEY (pid, name)
    )

In MySQL, you might want to use a layout with a TIMESTAMP column:

    CREATE TABLE tree (
        pid INTEGER NOT NULL,
        name VARCHAR(16) NOT NULL,
        id INTEGER NOT NULL,
        mtime TIMESTAMP,
        PRIMARY KEY (pid, name)
    )

In this table, name and ID are one:

    CREATE TABLE folders (
        parent VARCHAR(16) NOT NULL,
        name VARCHAR(16) NOT NULL,
        PRIMARY KEY (pid, name)
    )

The parent/child relationship is expressed through the pid field--each node contains
its parent's ID in its pid field.  DBIx::Path's primary purpose is to retrieve the ID 
for a particular pid/name combination, with the ability to descend through the tree
via the C<resolve> method.

An object of type DBIx::Path represents a node, and in this document it will always
be referred to as a node.

=head2 Constructor

=head3 new

    $root_node = DBIx::Path->new( %config );
    $node = $root_node->new( id => $id );    # If the ID is known

Manually creates an object to represent the tree's root node.  Note that there doesn't 
actually need to be an ID in the table for this node, although it doesn't hurt!  The 
C<pid> and C<name> methods will always return C<undef> for a node created through C<new>, 
but nodes created through C<new> otherwise behave identically to those created with 
C<get>, C<set>, C<add>, or C<resolve>.

C<new> can also be used as a copy constructor.  This can be used to create a DBIx::Path
object from a known ID.

The arguments comprise a hash (not a hash reference) with the following keys:

=over 4

=item * C<dbh>

An already-opened DBI database handle.  Required.

=item * C<table>

The name of the table containing the tree/graph being traversed.
Required.

=item * C<id_column>

The name of the ID field.  Optional; defaults to "id".

=item * C<pid_column>

The name of the pid field.  Optional; defaults to "pid".

=item * C<name_column>

The name of the name field.  Optional; defaults to "name".

=item * C<id>

The ID of the root.  Optional; defaults to 0.  Note that C<id> 
cannot be C<undef> (C<NULL>), due to the SQL used to retrieve nodes.

=item * C<hooks>

A hashref of sub references which C<DBIx::Path> will call at appropriate
time.  Optional; current hooks include:

=over 4

=item C<lock>

Called at the beginning of any operation involving a database query.  The first
parameter is the database handle; the second is 'r' for a read operation (which
recommends a shared lock) or 'w' for a write operation (which recommends an
exclusive lock).

=item C<unlock>

Called after the operation which needed a lock is complete.  Parameters are the
same as C<lock>.

=back 4

=back 4

The return value is a DBIx::Path object, which can then be used normally.

=cut

sub new {
	my($me, %config)=@_;
	
	# This is NOT cargo culting, dammit.
	%config=(%$me, %config) if ref $me;
	
	$config{dbh} or croak "Invalid or missing database handle";
	$config{table} or croak "Invalid or missing table name";
    my $dbh=$config{dbh};
	
	$config{id_column} ||= 'id';
	$config{pid_column} ||= 'pid';
	$config{name_column} ||= 'name';
	$config{id} ||= 0;
	
    unless($config{sth}) {
	    #These statement handles will be needed later.
	    $config{sth}{get}=$dbh->prepare(<<"END") or die "DBIx::Path->new: couldn't prepare 'get' statement: $DBI::errstr";
SELECT		$config{id_column}, $config{pid_column}, $config{name_column}
	FROM	$config{table} 
	WHERE	$config{pid_column} = ?
		AND	$config{name_column} = ?
END
	    $config{sth}{add}=$dbh->prepare(<<"END") or die "DBIx::Path->new: couldn't prepare 'add' statement: $DBI::errstr";
INSERT INTO	$config{table}
			($config{id_column}, $config{pid_column}, $config{name_column})
	VALUES	(?, ?, ?)
END
	    $config{sth}{del}=$dbh->prepare(<<"END") or die "DBIx::Path->new: couldn't prepare 'del' statement: $DBI::errstr";
DELETE FROM $config{table}
	WHERE	$config{pid_column} = ?
		AND $config{name_column} = ?
END
	    $config{sth}{list}=$dbh->prepare(<<"END") or die "DBIx::Path->new: couldn't prepare 'list' statement: $DBI::errstr";
SELECT		$config{id_column}, $config{pid_column}, $config{name_column}
	FROM	$config{table} 
	WHERE	$config{pid_column} = ?
END
        $config{sth}{parents}=$dbh->prepare(<<"END") or die "DBIx::Path->new: couldn't prepare 'parents' statement: $DBI::errstr";
SELECT      $config{id_column}, $config{pid_column}, $config{name_column}
    FROM    $config{table}
    WHERE   $config{id_column} = ?
END
    }

	#Once again, no cargo-culting here.  You can go about your business.  Move along!
	return bless \%config, ref $me || $me;
}

=head2 Methods

=head3 get

    $node = $node->get( $name )

The C<get> method retrieves the immediate child of $node named $name.
It returns C<undef> and sets $! to ENOENT if no child by that name
exists.

=cut

sub get {
	my($me, $name)=@_;
    $me->_lock('r');
	$me->{sth}{get}->execute($me->{id}, $name);
    $me->_unlock('r');
	my $r=$me->{sth}{get}->fetchrow_arrayref() or do {
		require POSIX;
		$!=POSIX::ENOENT();
		return;
	};
	$me->{sth}{get}->finish();
	return $me->_row_to_obj($r);
}

=head3 add

    $node = $node->add( $name, $id )

Adds $id as a child of $node named $name, then returns the newly-added node.
This is done with a SQL INSERT statement.  If the statement failed (because, 
for example, C<(pid, name)> is a primary key and that particular combination 
already exists), returns C<undef> and sets $! to EEXIST.

=cut

sub add {
	my($me, $name, $id)=@_;
	$id = $id->id if ref $id;    #Be nice to the poor, dumb hacker.

    $me->_lock('w');
    #Make sure such a row doesn't exist first.
	my $affected=(
        ! $me->get($name) &&
        $me->{sth}{add}->execute($id, $me->{id}, $name)
    );
    
    if(!defined $affected or $affected == 0) {
        $me->_unlock('w');
		require POSIX;
		$!=POSIX::EEXIST();
		return;
	}
    else {
	    my $ret=$me->get($name);
        $me->_unlock('w');
        return $ret;
	}
}

=head3 del

    $ok = $node->del( $name )

Deletes the relation between $node and $name.  Returns 1 if successful.  
If the SQL statement failed, returns C<undef> and sets $! to ENOENT.

=cut

sub del {
	my($me, $name)=@_;
    
    $me->_lock('w');
    my $affected=$me->{sth}{del}->execute($me->{id}, $name);
    $me->_unlock('w');

    if(!defined $affected or $affected == 0) {
		require POSIX;
		$!=POSIX::ENOENT();
		return;
	}
    else {
	    return 1;
    }
}

=head3 set

    $node = $node->set( $name, $id )

Deletes the old relation between $node and $name, then creates a new one
making $id the child of $node named $name.  A simple wrapper around
C<del> and C<add>.  Return values are the same as C<add>, but note that
$! may still be set due to the result of C<del>.

This method may be subject to race conditions unless the C<lock> and
C<unlock> hooks are specified.

=cut

sub set {
	my($me, $name, $id)=@_;
    $me->_lock('w');
	$me->del($name);
	my $ret=$me->add($name, $id);
    $me->_unlock('w');
    return $ret;
}

=head3 parents

    @list = $node->parents()

Finds all references to the current node--in other words, all parents which count this
node as their child.  In scalar context, returns the number of parents; in list context,
returns a hash whose keys are the IDs of the parents and whose values are an arrayref of
names the current node is found under.

=cut

sub parents {
    my($me)=@_;
    my %ret;

    $me->_lock('r');
    $me->{sth}{parents}->execute($me->id);
    $me->_unlock('r');
    while(my $r=$me->{sth}{parents}->fetchrow_arrayref) {
        push @{$ret{$r->[1]}}, $r->[2];
    }

    return wantarray ? %ret : scalar keys %ret;
}


=head3 resolve

    $node = $node->resolve( @components )

The C<resolve> method traverses the provided path; that is, it looks
up the child of $node named $components[0], then looks up the child of
the just-retrieved node named $components[1], and so on.  Components
which are undefined or consist of the empty string will be ignored.

Return value is the same as C<get> when a name anywhere in @components
does not resolve.

After it is run, @DBIx::Path::RESOLVED will contain all components it
resolved, and $DBIx::Path::PARENT will contain the node resolved from
$RESOLVED[-1].  That is, after a successful run, @RESOLVED will be a
copy of the @components list, and $PARENT will contain the parent of
the returned node.

After a failed attempt to resolve, @RESOLVED will contain all components
that resolved successfully.  An additional variable, @DBIx::Path::FAILED,
will contain the remaining components.  $PARENT will contain the node which
didn't have a child named $FAILED[0].  These variables are intended to augment
the simple ENOENT placed in $! by C<get>.

=cut

sub resolve {
	my($me, @components)=@_;
	my $cursor=$me;
	local $_;
	
	our @RESOLVED=();
	our @FAILED=@components;
	our $PARENT=$me;
	
    $me->_lock('r');
	for(@components) {
        next unless defined $_ and $_ ne '';
		$PARENT=$cursor;
		$cursor=$cursor->get($_);
		last unless defined $cursor;
		push @RESOLVED, $_;
		shift @FAILED;
	}
    $me->_unlock('r');
	
	return $cursor;
}

=head3 reverse

    @list=$node->reverse()

Returns all paths from the root to the current node.  The return value is an
arrayref of names.  (If called on the root node, it returns a single empty 
arrayref, which is probably the most accurate depiction of the situation.)
If called in scalar context, it will return the number of paths from the root to
the current node.

If reverse() encounters a circular reference while attempting to find the parents,
it will return an empty list and set $! to ELOOP.

The results of this function are undefined if the relevant parts of the tree are
modified while it's being executed.  It is an exceedingly good idea to specify the
C<lock> and C<unlock> hooks if you intend to use this method.

Note: This function disregards the contents of the C<id> parameter given to C<new>; 
it considers the root to simply be the parentless node at the top of the tree.  
Thus, it may "break out" of a particular subtree.

=cut

{
our %seen;
my %memo;
sub reverse {
    %seen=();
    %memo=();
    $_[0]->_lock('r');
    my @ret;
    eval {
        @ret=&_reverse;
    };
    $_[0]->_unlock('r');
    if($@) {
       if($@ =~ /Circular reference encountered during DBIx::Path->reverse()/) {
            require POSIX;
            $!=POSIX::ELOOP();
            return;
	    }
        else {
            die;
        }
    }
    return @ret;
}

sub _reverse {
    my($me)=@_;
    my @ret;

    local %seen=%seen;
    die "Circular reference encountered during DBIx::Path->reverse()" if $seen{$me->id};
    $seen{$me->id}++;

    return @{$memo{$me->id}} if $memo{$me->id};

    my %parents=$me->parents;
    return [] unless %parents;

    for my $pid(keys %parents) {
        my $parent=$me->new(%$me, id => $pid);
        my @parent_ret=$parent->_reverse();
        for my $name(@{ $parents{$pid} }) {
			 for my $ancestors(@parent_ret) {
                 push @ret, [@$ancestors, $name];
             }
        }
    }
    $memo{$me->id}=\@ret;
    return @ret;
}
}


=head3 list

    @nodes=$node->list()

Returns an unordered list of nodes which are children of the current node.

This method does not operate recursively; the DBIx::Tree module would be more
appropriate for that purpose.

=cut

sub list {
	my($me)=@_;
	my @ret;
	local $_;
	
    $me->_lock('r');
	$me->{sth}{list}->execute($me->{id});
    $me->_unlock('r');
	push @ret, $me->_row_to_obj($_) while $_ = $me->{sth}{list}->fetchrow_arrayref;
	return @ret;
}

=head2 Accessors

=head3 id

    $id = $node->id()

Returns the ID of the current node.

=head3 pid

    $pid = $node->pid()

Returns the parent ID used to resolve the current node.  Returns C<undef> for
the root node.

=head3 name

    $name = $node->name()

Returns the name used to resolve the current node.  Returns C<undef> for the
root node.

=cut

for my $field qw(id pid name) {
	no strict 'refs';
	*{$field}=sub { $_[0]->{$field} }
}

{
    my $locked=0;
    sub _lock {
        my($me, $type)=@_;
        $locked++;
        if($locked == 1 and $me->{hooks}{lock}) {
            $me->{hooks}{lock}->($me->{dbh}, $type);
 	    }
    }
    sub _unlock {
        my($me, $type)=@_;
        if($locked == 1) {
            $me->{hooks}{unlock}->($me->{dbh}, $type) if $me->{hooks}{unlock};
		}
        elsif($locked == 0) {
            croak "DBIx::Path: PANIC: Key won't fit in lock";
		}
        $locked--;
    }
    END {
	    if($locked) {
            warn "DBIx::Path: WARNING: Program may have exited with lock(s) still held";
		}
    }
}

sub _row_to_obj {
	my($id, $pid, $name)=@{$_[1]};
	(ref $_[0])->new(%{$_[0]}, id => $id, pid => $pid, name => $name);
}

=head2 Diagnostics

DBIx::Path primarily communicates errors to the caller by returning C<undef>
and setting $! to an appropriate value.  However, it does throw a few
exceptions.

=over 4

=item C<Invalid or missing %s>

One of the required parameters to C<new> (either the database handle
or the table name) was omitted, or something that clearly wasn't a handle or
table name (such as an C<undef> value) was passed.  Please check your code.

=item C<< DBIx::Path->new: Couldn't prepare '%s' statement: %s >>

C<new> prepares several SQL statements which are used by the other
methods.  This message indicates that the indicated statement was invalid.
This could indicate a bad table name or invalid I<whatever>_column settings;
it could also mean that the SQL used by DBIx::Path isn't recognized by your
DBD.

Check the parameters you're passing to DBIx::Path->new, then make sure the
SQL at the indicated line number is valid for your server.  The text after
the second colon is the DBI error message.

=item C<DBIx::Path: PANIC: Key won't fit in lock>

Internal error indicating that DBIx::Path wanted to call your unlock hook,
but somehow forgot to call your lock hook in the first place.  This shouldn't
happen.

=item C<DBIx::Path: WARNING: Program may have exited with lock(s) still held>

DBIx::Path has an internal variable tracking how deeply nested locks currently
are; it uses this to ensure that your lock/unlock hooks are only called once
per method.  This message will be printed to STDERR if that variable has a 
non-zero value when Perl exits; it indicates that you should check to make sure
your database hasn't become wedged.

This message is most often seen when an error occurs within DBIx::Path itself;
it may also be displayed for particularly nasty sorts of bugs within DBIx::Path
or if your process is hit by a signal while DBIx::Path is querying your 
database.  It's never good news.

=back 4

=head1 BUGS AND ENHANCEMENTS

There are no known bugs at this time; however, I'm not that experienced
with the DBI, so God only knows if I've missed something important.

The following methods may be vulneurable to race conditions or other time-sensitive
bugs unless locking hooks are provided:

=over 4

=item * C<set>

=item * C<resolve>

=item * C<reverse>

=back 4

Some enhancements I'm considering are:

=over 4

=item * Hooks on the basic operations (C<get>, C<add>, C<del>, possibly C<set>
and C<list>).  Subclassing may make this unnecessary, however.

=item * Methods that select all descendents of the current node and return them
in various useful forms.  (These would have to not curl up into a ball and cry
in the face of circular references.)

=back 4

Patches to implement these, or to fix bugs, are much appreciated; send them to
<brentdax@cpan.org> and start the subject line with something like
"[PATCH DBIx::Path]".

=head1 SEE ALSO

L<DBI>, DBD::*, L<DBIx::Tree>, L<File::Path>

=head1 AUTHOR

Brent 'Dax' Royal-Gordon, <brentdax@cpan.org>

=head1 COPYRIGHT

Copyright 2005 Brent 'Dax' Royal-Gordon.  All rights reserved.

This library is free software; it may be used, redistributed, and/or modified 
under the same terms as Perl itself.

=cut

1;
