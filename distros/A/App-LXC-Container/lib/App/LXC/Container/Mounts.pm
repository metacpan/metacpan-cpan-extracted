package App::LXC::Container::Mounts;

# Author, Copyright and License: see end of file

=head1 NAME

App::LXC::Container::Mounts - manage mount-points for LXC container configuration

=head1 SYNOPSIS

    use App::LXC::Container::Mounts;
    my $mounts = App::LXC::Container::Mounts->new();
    $mounts->mount_point($path, EXPLICIT);
    if ($mounts->mount_point($path) == IMPLICIT) { ... }
    $mounts->mount_point($path, REMOVE);

    $mounts->merge_mount_points(12);
    ... foreach $mounts->sub_directories($path);

    say $out $_  foreach  $mounts->implicit_mount_lines('/');
    $mounts->create_mount_points('/');

=head1 ABSTRACT

This module is used by L<App::LXC::Container::Update> to manage the
(possible) mount-points of a container that is updated.

=head1 DESCRIPTION

The module handles all kinds of mount-points of an LXC container
configuration created (and maybe destroyed again) during the update of an
LXC container.

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = "0.41";

use Cwd 'abs_path';

use App::LXC::Container::Texts;

#########################################################################

=head1 EXPORT

All access functions are exported by default as that's the point of this
module.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(REMOVE
		 UNDEFINED
		 IGNORE
		 NO_MERGE
		 EMPTY
		 COPY
		 EXPLICIT
		 IMPLICIT
		 IMPLICIT_LINK
	       );

# possible states of a possible mount-point or directory above it:
use constant REMOVE => -1;
use constant UNDEFINED => 0;
use constant IGNORE => 1;
use constant NO_MERGE => 2;
use constant EMPTY => 3;
use constant COPY => 4;
use constant EXPLICIT => 5;
use constant IMPLICIT => 6;
use constant IMPLICIT_LINK => 7; # an optional copy that may be merged away

#########################################################################
#
# internal constants and data:

our @CARP_NOT = (substr(__PACKAGE__, 0, rindex(__PACKAGE__, "::")));

#########################################################################
#########################################################################

=head1 MAIN METHODS

The module defines the following main methods which are used by
L<App::LXC::Container>:

=cut

#########################################################################

=head2 B<new> - create object to manage mount-points

    $mounts = App::LXC::Container::Mounts->new();

=head3 description:

This is the constructor for the object used to manage the possible
mount-poins and directories of an LXC application container.

=head3 returns:

the management object

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub new($)
{
    my $class = shift;
    $class eq __PACKAGE__  or  fatal 'bad_call_to__1', __PACKAGE__ . '->new';
    debug(2, __PACKAGE__, '::new()');

    my $object = {'/' => [NO_MERGE, {}]}; # [ state, sub-directory counters ]
    return bless $object, $class;
}

#########################################################################

=head2 B<implicit_mount_lines> - get list of implicit mount-lines for path

    say $out $_  foreach  $mounts->implicit_mount_lines('/');

=head3 parameters:

    $path               root path

=head3 description:

This method (recursively) returns a list of mount-lines for the LXC
configuration.  It returns all implicit mount-points below (including) the
given path.

=head3 returns:

list of implicit mount-lines for path

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub implicit_mount_lines($$)
{
    my ($self, $path) = @_;
    my @mount_lines = ();
    if ($self->mount_point($path) == IMPLICIT)
    {
	push @mount_lines,
	    'lxc.mount.entry = ' . $path . ' ' . substr($path, 1) .
	    ' none create=' . (-d $path ? 'dir' : 'file') . ',ro,bind 0 0';
    }
    local $_;
    foreach ($self->sub_directories($path))
    {	push @mount_lines, $self->implicit_mount_lines($_);   }
    return @mount_lines;
}

#########################################################################

=head2 B<merge_mount_points> - merge mount-points

    $mounts->merge_mount_points($limit2, $limit3, $limit4, $limit5);

=head3 parameters:

    $limitN             heuristic limit for depth N used for the merge decision

=head3 description:

This method merges all IMPLICIT mount-points gathered so far.  The heuristic
limits are the maximum number of children a directory of the corresponding
depth may have as separate mount-points.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub merge_mount_points($$$$$)
{
    my ($self, $limit2, $limit3, $limit4, $limit5) = @_;

    # merge child mount-points into one mount-point of parent, if reasonable:
    local $_;
    foreach (sort _depth_sort keys %{$self})
    {
	next if -f $_;		# Existing files can't have children!

	# Children of entries with these states never may be merged:
	my $state = $self->mount_point($_);
	next if $state == EXPLICIT  or  $state == IGNORE  or  $state == NO_MERGE;

	# Never merge single children:
	my @children = keys %{$self->{$_}[1]};
	my $childs = @children;
	next if $childs <= 1;

	# The nearer the root, the more children are needed to allow a merge:
	my $depth = _depth_of($_);
	next if $depth < 2;
	my $limit = ($depth == 2 ? $limit2 :
		     $depth == 3 ? $limit3 :
		     $depth == 4 ? $limit4 : $limit5);
	next unless $childs >= $limit;

	# Finally we only merge children of undefined entries:
	if ($state == UNDEFINED)
	{
	    debug(4, __PACKAGE__,
		  '::merge_mount_points: merging ', $childs, ' into ', $_);
	    $self->mount_point($_, IMPLICIT);
	    $self->{$_}[1] = {};
	    $self->mount_point($_, REMOVE) foreach @children;
	}
    }
}

#########################################################################

=head2 B<mount_point> - access child in specific new

    $state = $mounts->mount_point($path);
        or
    $mounts->mount_point($path, $state);

=head3 parameters:

    $path               the path to be checked or set
    $value              state to be set for path

=head3 description:

This method either sets the state for a path (including for each parent
directory) or determines its current state.  Note that the method does not
prevent every possible contradicting settings!

The state is one of the following values:

=over

=item UNDEFINED - not yet defined

=item IGNORE - completely ignored

=item NO_MERGE, EMPTY, COPY - special states from filters

=item EXPLICIT - explicit mount-point or filtered as not C<ignore>

=item IMPLICIT - will be used as implicit mount-point (or merged with others)

=item IMPLICIT_LINK - similar, but a copy instead of a mount-point

=item REMOVE - remove state for specific path

=back

=head3 returns:

state of the path

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub mount_point($$;$)
{
    my ($self, $path, $state) = @_;
    $path =~ s|(?<=.)/+$||;	# remove trailing / (just to be on the safe side)

    local $_ = $path;
    s|/+(?:[^/]+)$||;		# Don't resolve link of path itself!
    -e $_  and  $_ = abs_path($_);
    my @parents = ();
    while ($_)
    {
	push @parents, $_;
	s|/+(?:[^/]+)$||  or  last;
    }

    if (defined $state)
    {
	if ($state == REMOVE)
	{
	    # REMOVE is recursive:
	    $self->mount_point($_, REMOVE) foreach keys %{$self->{$path}[1]};
	    delete $self->{$path};
	    return $state;
	}
	my $may_change = 1;
	foreach ($path, @parents)
	{
	    if (defined $self->{$_}  and
		$self->{$_}[0] > NO_MERGE)
	    {
		if ($self->{$_}[0] != $state)
		{
		    error('_1_has_incompatible_state__2', $_, $path);
		    $state = $_ eq $path ? $self->{$_}[0] : IGNORE;
		}
		$may_change = 0;
	    }
	}
	if ($may_change)
	{
	    if ($state == COPY  or
		$state == EMPTY  or
		$state == EXPLICIT  or
		$state == NO_MERGE)
		# hopefully this now even covers all links correctly, even
		# the "Waterloo-link": /lib64/ld-linux-x86-64.so.2
	    {   $self->_set($path, $state, \@parents, NO_MERGE);   }
	    elsif ($state == IGNORE  or
		   $state == IMPLICIT  or
		   $state == IMPLICIT_LINK)
	    {
		$self->_set($path, $state, \@parents, UNDEFINED);
		# REMOVE any children:
		$self->mount_point($_, REMOVE) foreach keys %{$self->{$path}[1]};
		$self->{$path}[1] = {};
	    }
	    else
	    {
		$state = UNDEFINED;
		$self->_set($path, $state, \@parents, UNDEFINED);
	    }
	}
    }
    elsif (defined $self->{$path}  and  $self->{$path}[0] > UNDEFINED)
    {					# defined and not UNDEFINED
	$state = $self->{$path}[0];
    }
    else
    {
	$state = UNDEFINED;
	foreach ($path, @parents)
	{
	    if ($self->{$_}  and  $self->{$_}[0] != NO_MERGE)
	    {
		$state = $self->{$_}[0];
		last;
	    }
	}
    }
    return $state;
}

#########################################################################

=head2 B<sub_directories> - get sub-directories of a path

    foreach ($mounts->sub_directories($path)) { ... }

=head3 parameters:

    $path               parent path of sub-directories

=head3 description:

This method returns the alphabetically sorted list of all sub-directories of
the given path.

=head3 returns:

list of all sub-directories

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub sub_directories($$)
{
    my ($self, $path) = @_;
    $path =~ s|(?<=.)/+$||;	# remove trailing / (just to be on the safe side)

    return sort keys %{$self->{$path}[1]};
}


#########################################################################
#########################################################################

=head1 HELPER METHODS / FUNCTIONS

The following methods and functions should not be used outside of this
module itself:

=cut

#########################################################################

=head2 B<_depth_of> - return depth of path

    $depth = _depth_of($path);

=head3 parameters:

    $path               the path to be checked

=head3 description:

This method function returns the depth of a given path.

=head3 returns:

depth of path

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _depth_of($)
{
    local $_ = $_[0];
    return s|[^/]+||g;
}

#########################################################################

=head2 B<_depth_sort> - sort paths depth first

    $depth = _depth_sort($path);

=head3 parameters:

    $path1              1st path to be sorted
    $path2              2nd path to be sorted

=head3 description:

This method compares two paths for sorting them depth first followed by
alphabetic.

=head3 returns:

sort value

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _depth_sort($$)
{
    _depth_of($_[1]) <=> _depth_of($_[0])   ||   $_[0] cmp $_[1]
}

#########################################################################

=head2 B<_set> - set values for a specific path

    $self->_set($path, $state, \@parents, $parent_state);

=head3 parameters:

    $path               the path to be set
    $state              the state to be set for path itself
    $parents            reference to array of parent directories
    $parent_state       the state to be set for all parents of the path

=head3 description:

This method function sets the state for a path and its parents.  It also
creates the internal directory tree, if necessary.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _set($$$$$)
{
    my ($self, $path, $state, $parents, $parent_state) = @_;
    defined $self->{$path}  or  $self->{$path} = [undef, {}];
    $self->{$path}[0] = $state;
    my $child = $path;
    local $_;
    foreach (@$parents)
    {
	defined $self->{$_}  or  $self->{$_} = [UNDEFINED, {}];
	if ($self->{$_}[0] == UNDEFINED)
	{   $self->{$_}[0] = $parent_state;   }
	defined $self->{$_}[1]{$child}  or  $self->{$_}[1]{$child} = 0;
	$self->{$_}[1]{$child}++;
	$child = $_;
    }
    defined $self->{'/'}[1]{$child}  or  $self->{'/'}[1]{$child} = 0;
    $self->{'/'}[1]{$child}++;
}

#########################################################################

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

man pages C<lxc.container.conf>, C<lxc> and C<lxcfs>

LXC documentation on L<https://linuxcontainers.org>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=head2 Contributors

none so far

=cut
