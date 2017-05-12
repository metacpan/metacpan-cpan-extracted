# mamgal - a program for creating static image galleries
# Copyright 2007-2010 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
# Any interesting entry (picture or subdirectory)
package App::MaMGal::Entry;
use strict;
use warnings;
use base 'App::MaMGal::Base';
use Carp;
use File::Basename;
use File::stat;

sub init
{
	my $self     = shift;
	my $dirname  = shift or croak "Need dir"; # the directory which contains this entry, relative to WD or absolute
	my $basename = shift or croak "Need basename"; # under $dirname
	confess "A basename of \".\" used when other would be possible (last component of $dirname)" if $basename eq '.' and not ($dirname eq '.' or $dirname eq '/');
	confess "Basename [$basename] contains a slash" if $basename =~ m{/};
	# We might not be able to get stat information (e.g. no execute permission on containing directory), so do not croak
	my $stat     = shift;
	confess "Third argument must be a File::stat, if provided" unless (not defined $stat) or (ref $stat and $stat->isa('File::stat'));
	confess "At most 3 args expected, got fourth: [$_[0]]" if @_;

	$self->{dir_name}  = $dirname;
	$self->{base_name} = $basename;
	$self->{stat}      = $stat;
	$self->{path_name} = $dirname.'/'.$basename;
	$self->{tools}     = {};
}

sub add_tools
{
	my $self = shift;
	my $tools = shift;
	foreach (keys %$tools) { $self->{tools}->{$_} = $tools->{$_} }
}

sub tools
{
	my $self = shift;
	return $self->{tools};
}

sub logger
{
	my $self = shift;
	return $self->tools->{logger};
}

# TODO: element should not have a need to know its index, container should be able to tell it simply given the object
sub element_index { $_[0]->{element_index}  }
sub set_element_index { $_[0]->{element_index} = $_[1]  }
sub name          { $_[0]->{base_name} }
sub description   { '' }
sub set_container { $_[0]->{container} = $_[1] }

sub container
{
	my $self = shift;
	unless (defined $self->{container}) {
		# TODO this will lead to creation of a strange split tree if it
		# is traversed again from container to this child
		$self->set_container($self->tools->{entry_factory}->create_entry_for($self->{dir_name}));
	}
	return $self->{container};
}

sub containers
{
	my $self = shift;
	return ($self->container->containers, $self->container);
}

sub neighbours
{
	my $self = shift;
	# TODO this should in theory use container method rather than the hash
	# element, but because this method needs element_index to be available
	# (which is only set in the entity if it is instantiated by its
	# container), then this will break in mysterious ways if the container
	# method has to instantiate the container object
	return (undef, undef) unless $self->{container};
	return $self->{container}->neighbours_of_index($self->element_index);
}

# Returns the best available approximation of creation time of this entry
sub creation_time
{
	my $self = shift;
	my $stat = $self->{stat};
	# We might not be able to get stat information (broken symlink, no permissions, ...)
	return undef unless $stat;
	# We need to use st_mtime, for lack of anything better
	return $stat->mtime;
}

sub content_modification_time
{
	my $self = shift;
	return $self->App::MaMGal::Entry::creation_time(@_);
}

sub fresher_than_me
{
	my $self = shift;
	my $path = shift;
	my %opts = @_;
	my $stat = stat($path) or return 0;
	return 1 if $stat->mtime >= $self->content_modification_time(%opts);
	return 0;
}

# Whether this entry should be shown in a directory contents montage
sub is_interesting { }

# Some constants
our $slides_dir = '.mamgal-slides';
sub slides_dir     { $slides_dir }
sub thumbnails_dir { '.mamgal-thumbnails' }
sub medium_dir     { '.mamgal-medium' }

#######################################################################################################################
# Abstract methods
# these two need to return the text of the link ...
sub page_path		{ croak(sprintf("INTERNAL ERROR: Class [%s] does not define page_path.",      ref(shift))) }
sub thumbnail_path	{ croak(sprintf("INTERNAL ERROR: Class [%s] does not define thumbnail_path.", ref(shift))) }

1;
