package Data::Hierarchy;
$VERSION = '0.34';
use strict;
use Storable qw(dclone);
# XXX consider using Moose

=head1 NAME

Data::Hierarchy - Handle data in a hierarchical structure

=head1 SYNOPSIS

    my $tree = Data::Hierarchy->new();
    $tree->store ('/', {access => 'all'});
    $tree->store ('/private', {access => 'auth',
                               '.note' => 'this is private});

    $info = $tree->get ('/private/somewhere/deep');

    # return actual data points in list context
    ($info, @fromwhere) = $tree->get ('/private/somewhere/deep');

    my @items = $tree->find ('/', {access => qr/.*/});

    # override all children
    $tree->store ('/', {'.note' => undef}, {override_sticky_descendents => 1});

=head1 DESCRIPTION

L<Data::Hierarchy> provides a simple interface for manipulating
inheritable data attached to a hierarchical environment (like
a filesystem).

One use of L<Data::Hierarchy> is to allow an application to annotate
paths in a real filesystem in a single compact data
structure. However, the hierarchy does not actually need to correspond
to an actual filesystem.

Paths in a hierarchy are referred to in a Unix-like syntax; C<"/"> is
the root "directory". (You can specify a different separator character
than the slash when you construct a Data::Hierarchy object.)  With the
exception of the root path, paths should never contain trailing
slashes. You can associate properties, which are arbitrary name/value
pairs, with any path.  (Properties cannot contain the undefined value.)
By default, properties are inherited by child
paths: thus, if you store some data at C</some/path>:

    $tree->store('/some/path', {color => 'red'});

you can fetch it again at a C</some/path/below/that>:

    print $tree->get('/some/path/below/that')->{'color'};
    # prints red

On the other hand, properties whose names begin with dots are
uninherited, or "sticky":

    $tree->store('/some/path', {'.color' => 'blue'});
    print $tree->get('/some/path')->{'.color'};            # prints blue
    print $tree->get('/some/path/below/that')->{'.color'}; # undefined

Note that you do not need to (and in fact, cannot) explicitly add
"files" or "directories" to the hierarchy; you simply add and delete
properties to paths.

=cut

=head1 CONSTRUCTOR

Creates a new hierarchy object.  Takes the following options:

=over

=item sep

The string used as a separator between path levels. Defaults to '/'.

=back

=cut

sub new {
    my $class = shift;
    my %args = (
                sep => '/',
                @_);

    my $self = bless {}, $class;
    $self->{sep} = $args{sep};
    $self->{hash} = {};
    $self->{sticky} = {};
    return $self;
}

=head1 METHODS

=head2 Instance Methods

=over

=cut

=item C<store $path, $properties, {%options}>

Given a path and a hash reference of properties, stores the properties
at the path.

Unless the C<override_descendents> option is given with a false value,
it eliminates any non-sticky property in a descendent of C<$path> with
the same name.

If the C<override_sticky_descendents> option is given with a true
value, it eliminates any sticky property in a descendent of C<$path>
with the same name.  override it.

A value of undef removes that value; note, though, that
if an ancestor of C<$path> defines that property, the ancestor's value
will be inherited there; that is, with:

    $t->store('/a',   {k => 'top'});
    $t->store('/a/b', {k => 'bottom'});
    $t->store('/a/b', {k => undef});
    print $t->get('/a/b')->{'k'};

it will print 'top'.

=cut

sub store {
    my $self = shift;
    $self->_store_no_cleanup(@_);
    $self->_remove_redundant_properties_and_undefs($_[0]);
}

# Internal method.
#
# Does everything that store does, except for the cleanup at the
# end (appropriate for use in e.g. merge, which calls this a bunch of
# times and then does cleanup at the end).

sub _store_no_cleanup {
    my $self = shift;
    my $path = shift;
    my $props = shift;
    my $opts = shift || {};

    $self->_path_safe ($path);

    my %args = (
               override_descendents => 1,
               override_sticky_descendents => 0,
                %$opts);

    $self->_remove_matching_properties_recursively($path, $props, $self->{hash})
      if $args{override_descendents};
    $self->_remove_matching_properties_recursively($path, $props, $self->{sticky})
      if $args{override_sticky_descendents};
    $self->_store ($path, $props);
}

=item C<get $path, [$dont_clone]>

Given a path, looks up all of the properteies (sticky and not) and
returns them in a hash reference.  The values are clones, unless you
pass a true value for C<$dont_clone>.

If called in list context, returns that hash reference followed by all
of the ancestral paths of C<$path> which contain non-sticky properties
(possibly including itself).

=cut

sub get {
    my ($self, $path, $dont_clone) = @_;
    $self->_path_safe ($path);
    my $value = {};

    my @datapoints = $self->_ancestors($self->{hash}, $path);

    for (@datapoints) {
	my $newv = $self->{hash}{$_};
	$newv = dclone $newv unless $dont_clone;
	$value = {%$value, %$newv};
    }
    if (exists $self->{sticky}{$path}) {
	my $newv = $self->{sticky}{$path};
	$newv = dclone $newv unless $dont_clone;
	$value = {%$value, %$newv}
    }
    return wantarray ? ($value, @datapoints) : $value;
}

=item C<find $path, $property_regexps>

Given a path and a hash reference of name/regular expression pairs,
returns a list of all paths which are descendents of C<$path>
(including itself) and define B<at that path itself> (not inherited)
all of the properties in the hash with values matching the given
regular expressions.  (You may want to use C<qr/.*/> to merely see if
it has any value defined there.)  Properties can be sticky or not.

=cut

sub find {
    my ($self, $path, $prop_regexps) = @_;
    $self->_path_safe ($path);
    my @items;
    my @datapoints = $self->_all_descendents($path);

    for my $subpath (@datapoints) {
	my $matched = 1;
	for (keys %$prop_regexps) {
	    my $lookat = (index($_, '.') == 0) ?
		$self->{sticky}{$subpath} : $self->{hash}{$subpath};
	    $matched = 0
		unless exists $lookat->{$_}
			&& $lookat->{$_} =~ m/$prop_regexps->{$_}/;
	    last unless $matched;
	}
	push @items, $subpath
	    if $matched;
    }
    return @items;
}

=item C<merge $other_hierarchy, $path>

Given a second L<Data::Hierarchy> object and a path, copies all the
properties from the other object at C<$path> or below into the
corresponding paths in the object this method is invoked on.  All
properties from the object this is invoked on at C<$path> or below are
erased first.

=cut

sub merge {
    my ($self, $other, $path) = @_;
    $self->_path_safe ($path);

    my %datapoints = map {$_ => 1} ($self->_all_descendents ($path),
				    $other->_all_descendents ($path));
    for my $datapoint (sort keys %datapoints) {
	my $my_props = $self->get ($datapoint, 1);
	my $other_props = $other->get ($datapoint);
	for (keys %$my_props) {
	    $other_props->{$_} = undef
		unless defined $other_props->{$_};
	}
	$self->_store_no_cleanup ($datapoint, $other_props);
    }

    $self->_remove_redundant_properties_and_undefs;
}

=item C<to_relative $base_path>

Given a path which B<every> element of the hierarchy must be contained
in, returns a special Data::Hierarchy::Relative object which
represents the hierarchy relative that path. The B<only> thing you can
do with a Data::Hierarchy::Relative object is call
C<to_absolute($new_base_path)> on it, which returns a new
L<Data::Hierarchy> object at that base path. For example, if
everything in the hierarchy is rooted at C</home/super_project> and it
needs to be moved to C</home/awesome_project>, you can do

    $hierarchy = $hierarchy->to_relative('/home/super_project')->to_absolute('/home/awesome_project');

(Data::Hierarchy::Relative objects may be a more convenient
serialization format than Data::Hierarchy objects, if they are
tracking the state of some relocatable resource.)

=cut

sub to_relative {
    my $self = shift;
    my $base_path = shift;

    return Data::Hierarchy::Relative->new($base_path, %$self);
}

# Internal method.
#
# Dies if the given path has a trailing slash and is not the root.  If it is root,
# destructively changes the path given as argument to the empty string.

sub _path_safe {
    # Have to do this explicitly on the elements of @_ in order to be destructive
    if ($_[1] eq $_[0]->{sep}) {
        $_[1] = '';
        return;
    }

    my $self = shift;
    my $path = shift;

    my $location_of_last_separator = rindex($path, $self->{sep});
    return if $location_of_last_separator == -1;

    my $potential_location_of_trailing_separator = (length $path) - (length $self->{sep});

    return unless $location_of_last_separator == $potential_location_of_trailing_separator;

    require Carp;
    Carp::confess('non-root path has a trailing slash!');
}

# Internal method.
#
# Actually does property updates (to hash or sticky, depending on name).

sub _store {
    my ($self, $path, $new_props) = @_;

    my $old_props = exists $self->{hash}{$path} ? $self->{hash}{$path} : undef;
    my $merged_props = {%{$old_props||{}}, %$new_props};
    for (keys %$merged_props) {
	if (index($_, '.') == 0) {
	    defined $merged_props->{$_} ?
		$self->{sticky}{$path}{$_} = $merged_props->{$_} :
		delete $self->{sticky}{$path}{$_};
	    delete $merged_props->{$_};
	}
	else {
	    delete $merged_props->{$_}
		unless defined $merged_props->{$_};
	}
    }

    $self->{hash}{$path} = $merged_props;
}

# Internal method.
#
# Given a hash (probably $self->{hash}, $self->{sticky}, or their union),
# returns a sorted list of the paths with data that are ancestors of the given
# path (including it itself).

sub _ancestors {
    my ($self, $hash, $path) = @_;

    my @ancestors;
    push @ancestors, '' if exists $hash->{''};

    # Special case the root.
    return @ancestors if $path eq '';

    my @parts = split m{\Q$self->{sep}}, $path;
    # Remove empty string at the front.
    my $current = '';
    unless (length $parts[0]) {
	shift @parts;
	$current .= $self->{sep};
    }

    for my $part (@parts) {
        $current .= $part;
        push @ancestors, $current if exists $hash->{$current};
        $current .= $self->{sep};
    }

    # XXX: could build cached pointer for fast traversal
    return @ancestors;
}

# Internal method.
#
# Given a hash (probably $self->{hash}, $self->{sticky}, or their union),
# returns a sorted list of the paths with data that are descendents of the given
# path (including it itself).

sub _descendents {
    my ($self, $hash, $path) = @_;

    # If finding for everything, don't bother grepping
    return sort keys %$hash unless length($path);

    return sort grep {index($_.$self->{sep}, $path.$self->{sep}) == 0}
	keys %$hash;
}

# Internal method.
#
# Returns a sorted list of all of the paths which currently have any
# properties (sticky or not) that are descendents of the given path
# (including it itself).
#
# (Note that an arg of "/f" can return entries "/f" and "/f/g" but not
# "/foo".)

sub _all_descendents {
    my ($self, $path) = @_;
    $self->_path_safe ($path);

    my $both = {%{$self->{hash}}, %{$self->{sticky} || {}}};

    return $self->_descendents($both, $path);
}

# Internal method.
#
# Given a path, a hash reference of properties, and a hash reference
# (presumably {hash} or {sticky}), removes all properties from the
# hash at the path or its descendents with the same name as a name in
# the given property hash. (The values in the property hash are
# ignored.)

sub _remove_matching_properties_recursively {
    my ($self, $path, $remove_props, $hash) = @_;

    my @datapoints = $self->_descendents ($hash, $path);

    for my $datapoint (@datapoints) {
	delete $hash->{$datapoint}{$_} for keys %$remove_props;
	delete $hash->{$datapoint} unless %{$hash->{$datapoint}};
    }
}

# Internal method.
#
# Returns the parent of a path; this is a purely textual operation, and is not necessarily a datapoint.
# Do not pass in the root.

sub _parent {
    my $self = shift;
    my $path = shift;

    return if $path eq q{} or $path eq $self->{sep};

    # For example, say $path is "/foo/bar/baz";
    # then $last_separator is 8.
    my $last_separator = rindex($path, $self->{sep});

    # This happens if a path is passed in without a leading
    # slash. This is really a bug, but old version of
    # SVK::Editor::Status did this, and we might as well make it not
    # throw unintialized value errors, since it works otherwise. At
    # some point in the future this should be changed to a plain
    # "return" or an exception.
    return '' if $last_separator == -1;

    return substr($path, 0, $last_separator);
}

# Internal method.
#
# Cleans up the hash and sticky by removing redundant properties,
# undef properties, and empty property hashes.

sub _remove_redundant_properties_and_undefs {
    my $self = shift;
    my $prefix = shift;
    # This is not necessarily the most efficient way to implement this
    # cleanup, but that can be fixed later.

    # By sorting the keys, we guarantee that we never get to a path
    # before we've dealt with all of its ancestors.
    for my $path (sort keys %{$self->{hash}}) {
        next if $prefix && index($prefix.$self->{sep}, $path.$self->{sep}) != 0;
        my $props = $self->{hash}{$path};

        # First check for undefs.
        for my $name (keys %$props) {
            if (not defined $props->{$name}) {
                delete $props->{$name};
            }
        }

        # Now check for redundancy.

        # The root can't be redundant.
        if (length $path) {
            my $parent = $self->_parent($path);

            my $parent_props = $self->get($parent, 1);

            for my $name (keys %$props) {
                # We've already dealt with undefs in $props, so we
                # don't need to check that for defined.
                if (defined $parent_props->{$name} and
                    $props->{$name} eq $parent_props->{$name}) {
                    delete $props->{$name};
                }
            }
        }

        # Clean up empty property hashes.
        delete $self->{hash}{$path} unless %{ $self->{hash}{$path} };
    }

    for my $path (sort keys %{$self->{sticky}}) {
        # We only have to remove undefs from sticky, since there is no
        # inheritance.
        my $props = $self->{sticky}{$path};

        for my $name (keys %$props) {
            if (not defined $props->{$name}) {
                delete $props->{$name};
            }
        }

        # Clean up empty property hashes.
        delete $self->{sticky}{$path} unless %{ $self->{sticky}{$path} };
    }
}

# These are for backwards compatibility only.

sub store_recursively { my $self = shift; $self->store(@_, {override_sticky_descendents => 1}); }
sub store_fast        { my $self = shift; $self->store(@_, {override_descendents => 0}); }
sub store_override    { my $self = shift; $self->store(@_, {override_descendents => 0}); }

package Data::Hierarchy::Relative;

sub new {
    my $class = shift;
    my $base_path = shift;

    my %args = @_;

    my $self = bless { sep => $args{sep} }, $class;

    my $base_length = length $base_path;

    for my $item (qw/hash sticky/) {
        my $original = $args{$item};
        my $result = {};

        for my $path (sort keys %$original) {
            unless ($path eq $base_path or index($path, $base_path . $self->{sep}) == 0) {
                require Carp;
                Carp::confess("$path is not a child of $base_path");
            }
            my $relative_path = substr($path, $base_length);
            $result->{$relative_path} = $original->{$path};
        }

        $self->{$item} = $result;
    }

    return $self;
}

sub to_absolute {
    my $self = shift;
    my $base_path = shift;

    my $tree = { sep => $self->{sep} };

    for my $item (qw/hash sticky/) {
        my $original = $self->{$item};
        my $result = {};

        for my $path (keys %$original) {
            $result->{$base_path . $path} = $original->{$path};
        }

        $tree->{$item} = $result;
    }

    bless $tree, 'Data::Hierarchy';

    return $tree;
}

1;

=back

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>
David Glasser E<lt>glasser@mit.eduE<gt>

=head1 COPYRIGHT

Copyright 2003-2006 by Chia-liang Kao E<lt>clkao@clkao.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
