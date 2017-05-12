# mamgal - a program for creating static image galleries
# Copyright 2007-2012 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
# The directory encapsulating class
package App::MaMGal::Entry::Dir;
use strict;
use warnings;
use base 'App::MaMGal::Entry';
use Carp;
use App::MaMGal::Entry::Picture;
use App::MaMGal::DirIcon;
use Image::Magick;
use App::MaMGal::Exceptions;

sub child            { $_[0]->{path_name}.'/'.$_[1]     }
sub page_path        { $_[0]->{base_name}.'/index.html' }
sub thumbnail_path   { $_[0]->{base_name}.'/.mamgal-index.png'  }

sub init
{
	my $self = shift;
	$self->SUPER::init(@_);
	if ($self->{dir_name} eq '/' and ($self->{base_name} eq '/' or $self->{base_name} eq '.')) {
		$self->{path_name} = '/';
		$self->{base_name} = '/';
		$self->{is_root} = 1;
	} elsif (-e $self->child('.mamgal-root')) {
		$self->{is_root} = 1;
	}
}

sub set_root
{
	my $self = shift;
	my $was_root = $self->is_root;
	my $is_root = $self->{is_root} = shift; 

	return if $is_root == $was_root;

	if ($is_root) {
		$self->_write_contents_to(sub {''}, '.mamgal-root');
	} else {
		unlink($self->child('.mamgal-root')) or App::MaMGal::SystemException->throw(message => '%s: unlink failed: %s', objects => [$self->child(".mamgal-root"), $!]);
	}
}

sub is_root
{
	my $self = shift;
	return $self->{is_root} || 0;
}

sub make
{
	my $self = shift;
	my $tools = $self->tools or croak "Tools were not injected";
	my $formatter = $tools->{formatter} or croak "Formatter required";
	ref $formatter and $formatter->isa('App::MaMGal::Formatter') or croak "[$formatter] is not a formatter";

	my $deleted_css = $self->_write_stylesheet;
	# Force a rewrite of all html pages if the stylesheet was removed, as they now need to point to a different place
	my @active_files = map { $_->make(force_slide => $deleted_css) } $self->elements;
	my $pruned_count = $self->_prune_inactive_files(\@active_files);
	$self->_write_montage($pruned_count);
	$self->_write_index($deleted_css or $pruned_count);
	return ()
}

sub _write_index
{
	my $self = shift;
	my $force = shift;
	my $formatter = $self->tools->{formatter};
	$self->_write_contents_to(sub { $formatter->format($self) }, 'index.html') unless ($self->fresher_than_me($self->child('index.html')) and not $force);
}

sub _write_stylesheet
{
	my $self = shift;
	if ($self->is_root) {
		my $formatter = $self->tools->{formatter};
		$self->_write_contents_to(sub { $formatter->stylesheet    }, '.mamgal-style.css');
	} else {
		# Delete legacy stylesheet files in directories other than root.
		# TODO: remove this code a few releases from 1.2
		my $path = $self->child('.mamgal-style.css');
		return unless -e $path;
		unlink($path) or App::MaMGal::SystemException->throw(message => '%s: unlink failed: %s', objects => [$path, $!]);
		return 1;
	}
}

sub ensure_subdir_exists
{
	my $self = shift;
	my $basename = shift;
	my $dir = $self->child($basename);
	mkdir $dir or App::MaMGal::SystemException->throw(message => '%s: mkdir failed: %s', objects => [$dir, $!]) unless -w $dir;
}

# get _picture_ neighbours of given picture
sub neighbours_of_index
{
	my $self = shift;
	my $idx  = shift;
	croak "neighbours_of_index must run in array context" unless wantarray;
	my @elements = $self->elements;
	$idx >= 0 or croak "Pic index must be at least 0";
	$idx < scalar @elements or croak "Pic index out of bounds for this dir";

	my ($prev, $next);
	my $i = $idx - 1;
	while ($i >= 0) {
		$prev = $elements[$i], last if $elements[$i]->isa('App::MaMGal::Entry::Picture');
		$i--;
	}
	$i = $idx + 1;
	while ($i < scalar @elements) {
		$next = $elements[$i], last if $elements[$i]->isa('App::MaMGal::Entry::Picture');
		$i++;
	}
	return $prev, $next;
}


sub _write_contents_to
{
	my $self = shift;
	my $code = shift;
	my $suffix = shift;
	# TODO: this will be an issue when mamgal goes multi-threaded
	my $tmp_name = $self->child('.mamgal-tmp');
	my $full_name = $self->child($suffix);
	$self->SUPER::_write_contents_to($code, $tmp_name, $full_name);
}

sub _side_length
{
	my $self = shift;
	my $picture_count = shift;

	# The montage is a visual clue that the object is a container.
	# Therefore ensure we do not get a 1x1 montage, because it would be
	# indistinguishable from a single image.
	my $sqrt = sqrt($picture_count);
	my $int = int($sqrt);
	my $side = $int == $sqrt ? $int : $int + 1;
	$side = 2 if $side < 2;
	return $side;
}

sub _write_montage
{
	my $self = shift;
	my $pruned_files = shift;

	my @images = $self->_all_interesting_elements;

	unless (@images) {
		$self->_write_contents_to(sub { App::MaMGal::DirIcon->img }, '.mamgal-index.png');
		return;
	}

	my $montage_path = $self->child('.mamgal-index.png');
	# Return early if the montage is fresh
	return if $self->fresher_than_me($montage_path, consider_interesting_only => 1) and $pruned_files == 0;

	# Get just a bunch of images, not all of them.
	my $montage_count = scalar @images > 36 ? 36 : scalar @images;
	# Stack them all together
	my $stack = Image::Magick->new;
	push @$stack, map {
		my $img = Image::Magick->new;
		my $rr;
		$rr = $img->Read($_->tile_path) and App::MaMGal::SystemException->throw(message => '%s: %s', objects => [$_->tile_path, $rr]);
		$img->[0] or $img } @images[0..($montage_count-1)];

	my $side = $self->_side_length($montage_count);

	my ($m_x, $m_y) = (200, 150);

	my ($montage, $r);
	# Do the magick, scale and write.
	$r = $montage = $stack->Montage(tile => $side.'x'.$side, geometry => $m_x.'x'.$m_y, border => 2);
	ref($r)                                                            or  App::MaMGal::SystemException->throw(message => '%s: montage failed: %s',         objects => [$montage_path, $r]);
	$r = App::MaMGal::Entry::Picture->scale_into($montage, $m_x, $m_y) and App::MaMGal::SystemException->throw(message => '%s: scaling failed: %s',         objects => [$montage_path, $r]);
	$r = $montage->Write($montage_path)                                and App::MaMGal::SystemException->throw(message => '%s: writing montage failed: %s', objects => [$montage_path, $r]);
}

sub _ignorable_name($)
{
	my $self = shift;
	my $name = shift;
	# ignore hidden files
	return 1 if substr($_, 0, 1) eq '.';
	# TODO: optimize out contants calls, keeping in mind that they are not really constant (eg. tests change them when testing slides/miniatures generation)
	return 1 if grep { $_ eq $name } (qw(lost+found index.html .mamgal-index.png .mamgal-style.css), $self->slides_dir, $self->thumbnails_dir, $self->medium_dir);
	return 0;
}

sub _prune_inactive_files
{
	my $self = shift;
	my $active_files = shift;
	# delete old temporary file, if any
	unlink $self->child('.mamgal-tmp') if (-e $self->child('.mamgal-tmp'));
	my @known_subdirs = ($self->slides_dir, $self->thumbnails_dir, $self->medium_dir);
	# first, sanity check so we know if we start creating files outside the known subdirs
	foreach my $f (@$active_files) {
		confess "internal error: [$f] has an unknown prefix" unless
			substr($f, 0, length($known_subdirs[0]) + 1) eq $known_subdirs[0].'/' or
			substr($f, 0, length($known_subdirs[1]) + 1) eq $known_subdirs[1].'/' or
			substr($f, 0, length($known_subdirs[2]) + 1) eq $known_subdirs[2].'/';
	}
	my %active = map { $_ => 1 } @$active_files;
	my $base = $self->{path_name};
	my $pruned_count = 0;
	foreach my $dir (@known_subdirs) {
		# If the directory is not there, we have nothing to do about it
		next unless -d $base.'/'.$dir;
		# Read the names from the dir
		opendir DIR, $base.'/'.$dir or App::MaMGal::SystemException->throw(message => '%s: opendir failed: %s',  objects => ["$base/$dir", $!]);
		my @entries = grep { $_ ne '.' and $_ ne '..' } readdir DIR;
		closedir DIR                or App::MaMGal::SystemException->throw(message => '%s: closedir failed: %s', objects => ["$base/$dir", $!]);
		# Delete the files which are not "active"
		my $at_start = scalar @entries;
		my $deleted = 0;
		foreach my $entry (@entries) {
			next if $active{$dir.'/'.$entry};
			# Before unlinking, update touch self so that if we crash between unlinking and updating thumbnail, it will be done on subsequent invocation.
			utime(undef, undef, $base);
			unlink($base.'/'.$dir.'/'.$entry) or App::MaMGal::SystemException->throw(message => '%s: unlink failed: %s', objects => ["$base/$dir/$entry", $!]);
			$deleted++;
		}
		$pruned_count += $deleted;
		rmdir($base.'/'.$dir) or App::MaMGal::SystemException->throw(message => '%s: rmdir failed: %s', objects => ["$base/$dir", $!]) if $at_start == $deleted;
	}
	return $pruned_count;
}

sub elements
{
	my $self = shift;
	# Lookup the cache
	return @{$self->{elements}} if exists $self->{elements};

	# Get entry factory
	my $tools = $self->tools or croak "Tools were not injected";
	my $entry_factory = $tools->{entry_factory} or croak "Entry factory required";
	ref $entry_factory and $entry_factory->isa('App::MaMGal::EntryFactory') or croak "[$entry_factory] is not an entry factory";

	# Read the names from the dir
	my $path = $self->{path_name};
	opendir DIR, $path or App::MaMGal::SystemException->throw(message => '%s: opendir failed: %s',  objects => [$path, $!]);
	my @entries = sort { $a cmp $b } grep { ! $self->_ignorable_name($_) } readdir DIR;
	closedir DIR       or App::MaMGal::SystemException->throw(message => '%s: closedir failed: %s', objects => [$path, $!]);

	my $i = 0;
	# Instantiate objects and cache them
	$self->{elements} = [ map {
			$_ = $path.'/'.$_ ;
			my $e = $entry_factory->create_entry_for($_);
			$e->set_element_index($i++);
			$e->set_container($self);
			$e
		} @entries
	];
	return @{$self->{elements}};
}

sub containers
{
	my $self = shift;
	return if $self->is_root;
	return $self->SUPER::containers(@_);
}

sub creation_time
{
	my $self = shift;

	my $spaces = join('', map { " " } $self->containers);

	my @elements = $self->elements;
	if (scalar @elements == 1) {
		return $elements[0]->creation_time;
	} elsif (scalar @elements > 1) {
		# Lookup cache
		return wantarray ? @{$self->{cct}} : $self->{cct}->[1] if exists $self->{cct};
		my ($oldest, $youngest) = (undef, undef);
		foreach my $t (map { $_->creation_time } @elements) {
			$oldest   = $t if not defined $oldest   or $oldest   > $t;
			$youngest = $t if not defined $youngest or $youngest < $t;
		}
		$self->{cct} = [$oldest, $youngest];
		return ($oldest, $youngest) if wantarray;
		return $youngest;
	}
	return $self->SUPER::creation_time;
}

# Returns the most recent of:
# - this directory inode's modification time
# - all of interesting elements' content modification time
sub content_modification_time
{
	my $self = shift;
	my %opts = @_;
	my $own = $self->SUPER::content_modification_time;
	return $own if $opts{only_own};
	my @elements;
	if ($opts{consider_interesting_only}) {
		@elements = $self->_all_interesting_elements;
	} else {
		@elements = $self->elements;
	}
	foreach my $i (@elements) {
		# Prevent doing a deep tree walk
		my $that = $i->content_modification_time(only_own => 1);
		$own = $that if $that > $own;
	}
	return $own;
}

sub is_interesting
{
	my $self = shift;
	defined $self->_first_interesting_element ? 1 : 0
}

sub tile_path
{
	my $self = shift;
	# TODO: choice of the first element is arbitrary, there might be a better heuristic
	$self->_first_interesting_element->tile_path
}

sub _first_interesting_element
{
	my $self = shift;
	foreach ($self->elements) { return $_ if $_->is_interesting }
	return undef;
}

sub _all_interesting_elements
{
	my $self = shift;
	grep { $_->is_interesting } $self->elements
}

1;
