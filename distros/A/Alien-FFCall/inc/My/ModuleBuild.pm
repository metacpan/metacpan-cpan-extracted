package My::ModuleBuild;

use strict;
use warnings;
use parent 'Alien::Base::ModuleBuild';
use File::Spec;

sub alien_check_installed_version {
  my($self) = @_;

  my $b = $self->cbuilder;
  
  my $obj = eval {
    $b->compile(
      source => File::Spec->catfile(qw( inc My test.c )),
    );
  };
  
  return unless defined $obj;
  
  $self->add_to_cleanup($obj);
  
  my($exe, @rest) = eval {
    $b->link_executable(
      objects => [$obj],
    );
  };
  
  unlink $obj;
  
  return unless defined $exe;
  
  $self->add_to_cleanup($exe, @rest);

  if(`$exe` =~ /version=([0-9\.]+)/) {
    my $version = $1;
    unlink $exe, @rest;
    return $version;
  }  
  return;
}

1;
