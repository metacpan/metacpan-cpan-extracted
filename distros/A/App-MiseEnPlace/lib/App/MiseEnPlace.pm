package App::MiseEnPlace;
our $AUTHORITY = 'cpan:GENEHACK';
$App::MiseEnPlace::VERSION = '0.170';
# ABSTRACT: A place for everything and everything in its place


use strict;
use warnings;
use 5.010;

use base 'App::Cmd::Simple';
use autodie;
use Carp;
use File::HomeDir;
use Path::Tiny;
use Term::ANSIColor;
use Try::Tiny;
use Types::Standard -types;
use YAML qw/ LoadFile /;

use Moo;
use MooX::HandlesVia;

has bindir => (
  is      => 'rw' ,
  isa     => Str ,
  lazy    => 1 ,
  default => sub { path( File::HomeDir->my_home , 'bin' )->stringify } ,
);

has config_file => (
  is      => 'rw' ,
  isa     => Str ,
  lazy    => 1 ,
  default => sub { path( File::HomeDir->my_home() , '.mise' )->stringify() } ,
);

has 'directories' => (
  is          => 'rw' ,
  isa         => ArrayRef[Str] ,
  handles_via => 'Array' ,
  handles     => { all_directories => 'elements' } ,
);

has 'homedir' => (
  is      => 'rw' ,
  isa     => Str ,
  lazy    => 1 ,
  default => sub { path( File::HomeDir->my_home )->stringify() } ,
);

has 'links' => (
  is          => 'rw' ,
  isa         => ArrayRef[ArrayRef[Str]] ,
  handles_via => 'Array' ,
  handles     => { all_links => 'elements' } ,
);

has 'verbose' => (
  is      => 'rw' ,
  isa     => Bool ,
  default => 0 ,
);

sub opt_spec {
  return (
    [ 'config|C=s'         => 'config file location (default = ~/.mise)' ] ,
    [ 'remove-bin-links|R' => 'remove all links from ~/bin at beginning of run' ] ,
    [ 'verbose|v'          => 'be verbose' ] ,
    [ 'version|V'          => 'show version' ] ,
  );
}

sub validate_args {
  my( $self , $opt , $args ) = @_;

  $self->usage_error( "No args needed" ) if @$args;

  if ( $opt->{version} ) {
    say $App::MiseEnPlace::VERSION;
    exit;
  }

  $self->config_file( $opt->{config} ) if $opt->{config};
  $self->verbose( $opt->{verbose} )    if $opt->{verbose};
}

sub execute {
  my( $self , $opt , $args ) = @_;

  # set up colored output if we page thru less
  # also exit pager immediately if <1 page of output
  $ENV{LESS} = 'RFX';

  # don't catch any errors here; if this fails we just output stuff like
  # normal and nobody is the wiser.
  eval 'use IO::Page';

  $self->_load_configs();

  $self->_remove_bin_links($opt)
    if $opt->{remove_bin_links} and -e -d $self->bindir();

  $self->_create_dir( $_ ) for $self->all_directories();

  $self->_create_link( $_ ) for $self->all_links();
}

sub _create_dir {
  my( $self , $dir ) = @_;

  my $msg;

  if( -e -d $dir ) {
    $msg = colored('exists ','green') if $self->verbose();
  }
  elsif( -e $dir and ! -l $dir ) {
    $msg = colored('ERROR: blocked by non-dirctory','bold white on_red');
  }
  else {
    path( $dir )->mkpath();
    $msg = colored('created','bold black on_green');
  }

  my $home = $self->homedir();
  if ( $msg ) {
    $dir =~ s/^$home/~/;
    say "[ DIR] $msg $dir";
  }
}

sub _create_link {
  my( $self , $linkpair ) = @_;

  my( $src , $target ) = @$linkpair;

  my $msg;

  if ( ! -e $src ) {
    $msg = colored( 'ERROR:  src does not exist' , 'bold white on_red' )
  }
  elsif( -e -l $target ) {
    if ( readlink $target eq $src ) {
      $msg = colored('exists ','green') if $self->verbose;
    }
    else {
      unlink $target;
      symlink $src , $target;
      $msg = colored( 'fixed' , 'bold black on_yellow' ) . '  ';
    }
  }
  elsif ( -e $target ) {
    $msg = colored( 'ERROR:  blocked by existing file' , 'bold white on_red' );
  }
  else {
    symlink $src , $target;
    $msg = colored( 'created' , 'bold black on_green' );
  }

  my $home = $self->homedir();
  if ( $msg ) {
    $src    =~ s/^$home/~/;
    $target =~ s/^$home/~/;
    say "[LINK] $msg $src -> $target";
  }
}

sub _load_configs {
  my( $self ) = shift;

  unless ( -e $self->config_file() ) {
    say "Whoops, it looks like you don't have a " . $self->config_file() . " file yet.";
    say "Please review the documentation, create one, and try again.";
    exit;
  }

  my $base_config = _load_config_file( $self->config_file() );

  my @links = map { _parse_linkpair( $_ , $self->homedir() ) } @{ $base_config->{create}{links} };

  my @dirs = map { _prepend_dir( $_ , $self->homedir() ) } @{ $base_config->{create}{directories} };

  my @managed_dirs = map { glob _prepend_dir( $_ , $self->homedir() ) } @{ $base_config->{manage} };

  for my $managed_dir ( @managed_dirs ) {
    my $mise_file = path( $managed_dir , '.mise' )->stringify();

    if ( -e -r $mise_file ) {
      my $config = _load_config_file( $mise_file );

      for ( @{ $config->{create}{directories} } ) {
        push @dirs , _prepend_dir( $_ , $managed_dir );
      }

      for ( @{ $config->{create}{links} } ) {
        push @links , _parse_linkpair( $_ , $managed_dir );
      }
    }
  }

  $self->directories( \@dirs );

  $self->links( $self->_parse_create_links( \@links ) );
}

sub _load_config_file {
  my $file = shift;

  my $config;

  try { $config = LoadFile( glob($file) ) }
  catch {
    say "Failed to parse config file $file:\n\t$_";
    exit;
  };

  return $config;
}

sub _parse_create_links {
  my( $self, $link_array ) = @_;

  my( %link_targets , @links );

  for my $link_pair ( @$link_array ) {
    my( $src , $target ) = ( %$link_pair );

    my $src_base = path( $src )->basename();

    $target = $self->bindir() if $target =~ m'BIN$';
    $target = path($target, $src_base)->stringify()
      if path($target)->is_dir() and ! path( $src )->is_dir();

    if (exists $link_targets{$target} ) {
      say "ERROR: Attempting to create multiple links to the same target:";
      printf "%s -> %s\n%s -> %s\n" ,
        $link_targets{$target} , $target , $src , $target;
    }

    $link_targets{$target} = $src;

    push @links , [ $src , $target ];
  }

  return \@links;
}

sub _parse_linkpair {
  confess "BAD ARGS" unless
    my( $linkpair , $dir ) = @_;

  confess "BAD LINKPAIR" unless
    my( $src , $target ) = ( %$linkpair );

  # this lets 'DIR' turn into enclosing directory
  $src = '' if $src eq 'DIR';

  $src    = _prepend_dir( $src , $dir );
  $target = _prepend_dir( $target , $dir ) unless $target eq 'BIN';

  return { $src => $target };
}

sub _prepend_dir {
  confess "BAD ARGS" unless
    my( $base , $dir ) = @_;

  return path( $base )->stringify()        if $base =~ m|^~|;
  return path( $dir )->stringify( )        unless $base;
  return path( $dir , $base )->stringify() unless $base =~ m|^/|;
  return path( $base )->stringify();
}

sub _remove_bin_links {
  my( $self , $opt ) = @_;

  my $bin = $self->bindir();

  opendir( my $dh , $bin );
  while ( readdir $dh ) {
    my $path = path( $bin , $_ );

    next unless -l $path;

    $path->remove();

    say colored('UNLINK' , 'bright_red' ) , " ~/bin/$_"
      if $opt->{verbose};
  }

  closedir( $dh );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MiseEnPlace - A place for everything and everything in its place

=head1 VERSION

version 0.170

=head1 SYNOPSIS

See 'pod mise' for usage details.

=head1 AUTHOR

John SJ Anderson <john@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
