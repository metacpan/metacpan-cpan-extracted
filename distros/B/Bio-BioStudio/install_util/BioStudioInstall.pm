package BioStudioInstall;

use base 'Module::Build';
use File::Path qw(mkpath);
use File::Basename;
use IO::Socket::INET;
use File::Spec;
use IO::File;

use strict;
use warnings;

sub ACTION_install
{
  my $self = shift;
  $self->SUPER::ACTION_install;
  my $confpath = $self->config_data('conf_path');
  $confpath = $self->_endslash($confpath);
  my $command = "chmod -R 777 $confpath*";
  print $command, "\n";
  system $command;
  print "\n";
}

sub process_conf_files
{
  my $BSB = shift;
  my $files = shift;
  return unless $files;

  my $conf_dir = File::Spec->catdir($BSB->blib, 'BioStudio');
  File::Path::mkpath( $conf_dir );

  foreach my $file (@{$files})
  {
    my $result = $BSB->copy_if_modified($file, $conf_dir) or next;
    $BSB->fix_shebang_line($result) unless $BSB->is_vmsish;
  }
}

sub process_gbrowse_files
{
  my $BSB = shift;
  my $files = shift;
  return unless $files;

  my $gbrowse_dir = File::Spec->catdir($BSB->blib, 'gbrowse_plugins');
  File::Path::mkpath( $gbrowse_dir );

  foreach my $file (@{$files})
  {
    my $result = $BSB->copy_if_modified($file, $gbrowse_dir, 'flatten') or next;
    $BSB->fix_shebang_line($result) unless $BSB->is_vmsish;
    $BSB->make_executable($result);
  }
}

sub _endslash
{
  my ($self, $path) = @_;
  if ($path && substr($path, -1, 1) ne q{/})
  {
    $path .= q{/};
  }
  return $path;
}

1;