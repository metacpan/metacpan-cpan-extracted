use v5.32;
use warnings;
use Object::Pad 0.73;

class Archive::SCS::GameDir 1.00;

use builtin 'trim';
use stable 0.031 'isa';
no warnings 'experimental::builtin';

use Archive::SCS;
use Carp 'croak';
use List::Util 1.33 qw(any first none);
use Path::Tiny 0.017 ();

our @LOAD_ORDER = qw(
  version.scs
  effect.scs
  base.scs
  base_map.scs
  base_vehicle.scs
  base_share.scs
  def.scs
  core.scs
  locale.scs
  base_cfg.scs
);

our @LIBRARY_PATHS = (
  '~/.steam/steam',
  '~/.local/share/Steam',
  '~/.var/app/com.valvesoftware.Steam/.steam/steam',
  '~/Library/Application Support/Steam',
  eval {
    require Archive::SCS::GameDir::Steam;
    @Archive::SCS::GameDir::Steam::library_paths
  },
  (split /:/, $ENV{STEAM_LIBRARY} // ''),
);

our %GAMES = (
  ATS  => 'American Truck Simulator',
  ETS2 => 'Euro Truck Simulator 2',
);

field $game :param = undef;

field $path;

field @library_paths = @LIBRARY_PATHS;

ADJUST {
  $self->find($game);
}


method game () {
  $game
}


method game_short () {
  no warnings 'uninitialized';
  return first { $game eq $GAMES{$_} } keys %GAMES;
}


method path () {
  $path
}


method find ($name = '') {
  $name //= '';
  if ( length $name ) {
    my $dir = Path::Tiny::path $name;
    if ($dir->child('base.scs')->exists) {
      $game = ($path = $dir)->basename;
      return $self;
    }
  }

  my @games = map { $GAMES{$_} } sort keys %GAMES;
  length $name and @games = $GAMES{ uc $name } // $name;

  my @paths;
  for my $fullname ( @games ) {
    push @paths, map { Path::Tiny::path "$_/steamapps/common/$fullname" } @library_paths;
  }

  $path = first { $_->child('base.scs')->exists } @paths;
  $game = defined $path ? $path->basename : undef;
  return $self;
}


method library_paths () {
  @library_paths
}


method set_library_paths (@paths) {
  @library_paths = @paths;
  return $self;
}


method archives () {
  $path or croak 'Game dir not found; cannot list archives';

  my @files = grep { $path->child($_)->exists } @LOAD_ORDER;
  push @files, sort
    grep { my $file = $_; none { $file eq $_ } @files }
    grep /\.scs$/, map { $_->basename } $path->children;
  return @files;
}


method mounted (@files) {
  $path or croak 'Game dir not found; cannot mount';

  @files or @files = $self->archives;
  @files = map {
    $_ =~ /\//
    ? Path::Tiny::path($_)
    : Path::Tiny::path($_)->absolute($path)
  } @files;

  my $scs = Archive::SCS->new;
  $scs->mount($_) for @files;
  return $scs;
}


method version () {
  $path or croak 'Game dir not found; cannot determine version';

  if ( any { 'version.scs' eq $_ } $self->archives ) {  # >= 1.50
    my $scs = $self->mounted('version.scs');
    return eval { $scs->read_entry('version.sii') =~ m/version:\s*"([^"]*)"/; $1 };
  }
  else {  # < 1.50
    my $scs = $self->mounted('base.scs');
    return eval { trim $scs->read_entry('version.txt') };
  }
}

1;


=head1 NAME

Archive::SCS::GameDir - Find the game dir and mount its archives

=head1 SYNOPSIS

  my $scs = Archive::SCS::GameDir->new->mounted;
  # $scs isa Archive::SCS

  my $path = Archive::SCS::GameDir->new(game => 'ATS')->path;
  # $path isa Path:Tiny

  my $gd = Archive::SCS::GameDir->new;
  my @files = grep !/^dlc_/, $gd->archives;
  my $scs = $gd->mounted( @files, 'dlc_ks.scs', 'dlc_ok.scs' );

  # Custom paths
  $gd->set_library_paths( @steam_library_paths );
  my $path = $gd->find('ATS')->path;
  my $scs = $gd->find('/path/to/gamedir')->mounted;

=head1 DESCRIPTION

Finds the game install directory inside your home directory.

A number of default locations for the Steam library will be
searched first. If your Steam library is in a non-standard
location, there are four different ways in which you can
supply additional paths to search:

=over

=item *

Specify the list of search paths for an individual GameDir
object using the C<set_library_paths()> object method.
Call C<find()> afterwards.

=item *

Manipulate the existing default list of search paths in the
C<@Archive::SCS::GameDir::LIBRARY_PATHS> global variable.

=item *

Install a custom C<Archive::SCS::GameDir::Steam> module that
sets the global variable C<@library_paths>.

=item *

Set the C<STEAM_LIBRARY> environment variable.

=back

=head1 METHODS

=head2 archives

  @files = $gamedir->archives;

Returns the list of filenames found in the game directory.

=head2 find

  $gamedir = $gamedir->find;
  $gamedir = $gamedir->find('ATS');
  $gamedir = $gamedir->find('/path/to/gamedir');

Tries to find the game directory for the given game in the
current Steam library paths. Will modify the object state.
Use C<game()> / C<game_short()> / C<path()> to read the result.

If there are multiple game directories in the paths, the search
stops at the first one found.

=head2 game

  $full_name = $gamedir->game;

Returns the full name of the game directory, or C<undef>
if the search was unsuccessful.

=head2 game_short

  $abbreviation = $gamedir->game_short;

Returns an abbreviation for the game name (like C<ATS>),
or C<undef> if the search was unsuccessful.

=head2 mounted

  $scs = $gamedir->mounted;
  $scs = $gamedir->mounted(@files);

Returns a new L<Archive::SCS> object with all files found in
the game directory already mounted. If a list of filenames is
given, only those files will be mounted.

=head2 new

  $gamedir = Archive::SCS::GameDir->new;
  $gamedir = Archive::SCS::GameDir->new(game => 'ATS');
  $gamedir = Archive::SCS::GameDir->new(game => '/path/to/gamedir');

Creates a new L<Archive::SCS::GameDir> object.
Will call C<find()> with the given game as argument.

=head2 path

  $path_tiny = $gamedir->path;

Returns a L<Path::Tiny> object for the game directory,
or C<undef> if the search was unsuccessful.

=head2 library_paths

  @steam_paths = $gamedir->library_paths;

Returns the current list of paths to search for the Steam library.

=head2 set_library_paths

  $gamedir = $gamedir->set_library_paths(@steam_paths);

Sets the list of paths to search for the Steam library. The Steam
library is the directory containing the C<steamapps> directory.

=head2 version

  $installed_version = $gamedir->version;

Reads the game directory and reports the installed game version.

=head1 AUTHOR

L<nautofon|https://github.com/nautofon>

=head1 COPYRIGHT

This software is copyright (c) 2024 by nautofon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
