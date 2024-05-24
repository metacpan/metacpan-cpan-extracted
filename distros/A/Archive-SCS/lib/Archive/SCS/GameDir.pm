use v5.38;
use feature 'class';
no warnings 'experimental::builtin';
no warnings 'experimental::class';

class Archive::SCS::GameDir 0.03;

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


method find ($name //= '') {
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
    return eval { builtin::trim $scs->read_entry('version.txt') };
  }
}


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

=head2 find

  $gamedir = $gamedir->find;
  $gamedir = $gamedir->find('ATS');
  $gamedir = $gamedir->find('/path/to/gamedir');

=head2 game

  $full_name = $gamedir->game;

=head2 game_short

  $abbreviation = $gamedir->game_short;

=head2 mounted

  $scs = $gamedir->mounted;
  $scs = $gamedir->mounted(@files);

=head2 new

  $gamedir = Archive::SCS::GameDir->new;
  $gamedir = Archive::SCS::GameDir->new(game => 'ATS');
  $gamedir = Archive::SCS::GameDir->new(game => '/path/to/gamedir');

=head2 path

  $path_tiny = $gamedir->path;

=head2 library_paths

  @steam_paths = $gamedir->library_paths;

=head2 set_library_paths

  $gamedir = $gamedir->set_library_paths(@steam_paths);

=head2 version

  $installed_version = $gamedir->version;

=head1 AUTHOR

L<nautofon|https://github.com/nautofon>

=head1 COPYRIGHT

This software is copyright (c) 2024 by nautofon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
