package Alien::Build::MB;

use strict;
use warnings;
use Path::Tiny ();
use Alien::Build;
use base qw( Module::Build );

# ABSTRACT: Alien::Build installer class for Module::Build
our $VERSION = '0.06'; # VERSION


sub new
{
  my($class, %args) = @_;
  
  if(! -f 'alienfile')
  {
    die "unable to find alienfile";
  }
  else
  {
    my $build = Alien::Build->load('alienfile', root => '_alien');
    $build->load_requires('configure');
    $build->root;
    $build->checkpoint;
  }
  
  my $self = $class->SUPER::new(%args);
  
  my $build = $self->alien_build(1);

  $self->_add_prereq( "${_}_requires", 'Module::Build'    => '0.36' ) for qw( configure build );
  $self->_add_prereq( "${_}_requires", 'Alien::Build::MB' => '0.01' ) for qw( configure build );
  $self->add_to_cleanup("_alien");

  foreach my $hook_name (qw( test_ffi test_share test_system ))
  {
    if($build->meta->has_hook($hook_name))
    {
      $self->_add_prereq( "configure_requires", 'Alien::Build::MB' => '0.05');
      last;
    }
  }

  my %config_requires = %{ $build->requires('configure') };
  foreach my $module (keys %config_requires)
  {
    my $version = $config_requires{$module};
    $self->_add_prereq( 'configure_requires', $module => $version );
  }
  
  unless($build->install_type =~ /^(share|system)$/)
  {
    die "unknown install type: @{[ $build->install_type ]}";
  }

  my %build_requires = %{ $build->requires($build->install_type) };
  foreach my $module (keys %build_requires)
  {
    my $version = $build_requires{$module};
    $self->_add_prereq( 'build_requires', $module => $version );
  }
  
  my $final_dest = $self->install_destination($build->meta_prop->{arch} ? 'arch' : 'lib');

  my $prefix = Path::Tiny->new($final_dest)
                         ->child("auto/share/dist")
                         ->child($self->dist_name)
                         ->absolute;
  my $stage  = Path::Tiny->new("blib/lib/auto/share/dist")
                         ->child($self->dist_name)
                         ->absolute;
  
  $build->set_stage ($stage->stringify );
  $build->set_prefix($prefix->stringify);
  $build->runtime_prop->{perl_module_version} = $self->dist_version;
  
  $build->checkpoint;

  if($self->alien_alienfile_meta)
  {
    $self->meta_merge->{x_alienfile} = {
      generated_by => "@{[ __PACKAGE__ ]} version @{[ __PACKAGE__->VERSION || 'dev' ]}",
      requires => {
        map {
          my %reqs = %{ $build->requires($_) };
          $reqs{$_} = "$reqs{$_}" for keys %reqs;
          $_ => \%reqs;
        } qw( share system )
      },
    };
  }

  $self;
}


__PACKAGE__->add_property( alien_alienfile_meta => 1 );


sub alien_build
{
  my($self, $noload) = @_;
  my $build = Alien::Build->resume('alienfile', '_alien');
  $build->load_requires('configure');
  $build->load_requires($build->install_type) unless $noload;
  $build;
}

sub _alien_already_done ($)
{
  my($name) = @_; 
  my $path = Path::Tiny->new("_alien/mb/$name");
  return -f $path;
}

sub _alien_touch ($)
{
  my($name) = @_;
  my $path = Path::Tiny->new("_alien/mb/$name");
  $path->parent->mkpath;
  $path->touch;
}


sub ACTION_alien_download
{
  my($self) = @_;
  return $self if _alien_already_done 'download';
  my $build = $self->alien_build;
  $build->download;
  $build->checkpoint;
  _alien_touch 'download';
  $self;
}


sub ACTION_alien_build
{
  my($self) = @_;
  return $self if _alien_already_done 'build';
  $self->depends_on('alien_download');

  my $build = $self->alien_build;
  $build->build;
  
  if($build->meta_prop->{arch})
  {
    my $archdir = Path::Tiny->new("./blib/arch/auto/@{[ join '/', split /-/, $self->dist_name ]}");
    $archdir->mkpath;
    my $archfile = $archdir->child($archdir->basename . ".txt");
    $archfile->spew('Alien based distribution with architecture specific file in share');
  }
  
  $build->checkpoint;
  
  _alien_touch 'build';
  $self;
}


sub ACTION_alien_test
{
  my($self) = @_;
  $self->depends_on('alien_build');
  
  my $build = $self->alien_build;
  if($build->can('test'))
  {
    $build->test;
    $build->checkpoint;
  }
  $self;  
}

sub ACTION_test
{
  my($self) = @_;
  $self->depends_on('alien_test');
  $self->SUPER::ACTION_test;
}

sub ACTION_code
{
  my($self) = @_;
  $self->depends_on('alien_build');
  $self->SUPER::ACTION_code;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::MB - Alien::Build installer class for Module::Build

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In your Build.PL:

 use Alien::Build::MB;
 
 Alien::Build::MB->new(
   module_name => 'Alien::MyLibrary',
   ...
 );

=head1 DESCRIPTION

This is a L<Module::Build> subclass that uses L<Alien::Build> to
help create L<Alien> distributions.  The author recommends
L<Alien::Build::MM>, which uses L<ExtUtils::MakeMaker> instead.
The primary rationale for this class, is to prove independence
from any particular installer, so that other installers may be
added in the future if they become available.  If you really do
prefer to work with L<Module::Build> though, this may be the 
installer for you!

=head1 CONSTRUCTOR

=head2 new

 my $abmb = Alien::Build::MB->new(%args);

Takes the usual L<Module::Build> arguments.

=head1 PROPERTIES

All L<Alien::Build::MB> specific properties have a C<alien_> prefix.

=head2 alien_alienfile_meta

If true (the default), then extra meta will be stored in C<x_alienfile> which includes
the C<share> and C<system> prereqs.

=head1 METHODS

=head2 alien_build

 my $build = $abmb->alien_build;

Returns a freshly deserialized instance of L<Alien::Build>.  If you make
any changes to this object's C<install_prop> or C<runtime_prop> properties
be sure that you also call C<< $build->checkpoint >>!

=head1 ACTIONS

These actions should automatically be called during the normal install
process.  For debugging you may want to call them separately.

=head2 ACTION_alien_download

 ./Build alien_download

Downloads the package from the internet.  For a system install this does
not do anything.

=head2 ACTION_alien_build

 ./Build alien_build

Build the package from source.

=head2 ACTION_alien_test

 ./Build alien_test

Run the package tests, if there are any.

=head1 SEE ALSO

L<Alien::Build>, L<Alien::Build::MM>, L<Alien::Base::ModuleBuild>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
