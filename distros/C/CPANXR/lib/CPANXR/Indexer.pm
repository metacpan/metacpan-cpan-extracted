# $Id: Indexer.pm,v 1.20 2003/10/07 19:53:18 clajac Exp $

package CPANXR::Indexer;

use CPANXR::Database;
use CPANXR::Parser;
use CPANXR::Config;
use Carp qw(carp croak);
use File::Find::Rule;
use File::Spec::Functions qw(catdir abs2rel rel2abs splitpath splitdir);

use strict;

use constant VALID_TYPES => qw(*.pm *.xs);

sub index {
  my ($self, $dist, %args) = @_;

  # Don't index development versions
  if($dist =~ /\_[A-Za-z0-9]$/) {
    # Looks like a development version, skip that
    print STDERR "$dist looks like a development release and will be skipped\n";
    return;
  }
  
  # Index distribution
  my $dist_rel_path = (splitdir($dist))[-1];
  
  # Check if distribution is already indexed
  my $dist_id = CPANXR::Database->indexed(distribution => $dist_rel_path);
  return if($dist_id);
  
  # Check version number
  my ($dist_no_version, $version_num) = $dist_rel_path =~ /^(.*)-([0-9\.]+)$/;

  my $pre = CPANXR::Database->indexed(like_distribution => "${dist_no_version}-\%");

  if($pre) {
    my ($pre_dist_id, $pre_dist) = @$pre;
    my ($pre_version_num) = $pre_dist =~ /^.*-([0-9\.]+)$/;
    if($version_num > $pre_version_num) {
      CPANXR::Database->delete_distribution(dist_id => $pre_dist_id);
    } else {
      print STDERR "$dist is older than the one that is already indexed\n";
      return;
    }
  }

  # Insert distribution
  $dist_id = CPANXR::Database->insert_path(distribution => $dist_rel_path);

  # Find files
  my @files = File::Find::Rule->file()->name(VALID_TYPES)->in($dist);

  for my $file_abs_path (@files) {
    my $file_rel_path = $self->file_path($file_abs_path);
    my $file_id = CPANXR::Database->indexed(file => $file_rel_path);
    next if($file_id);

    my $type = CPANXR::Parser->understands($file_rel_path);
    if ($type) {
      my $file = (splitpath($file_rel_path))[-1];
      my $sym_id = CPANXR::Database->insert_symbol($file);
      $file_id = CPANXR::Database->insert_path(file => $file_rel_path, $dist_id, $sym_id, $type);
      my $lines = CPANXR::Parser->parse($file_abs_path, dist_id => $dist_id, file_id => $file_id);
      CPANXR::Database->set_loc($file_id, $lines);
    }
  }
}

my $base_path = catdir(CPANXR::Config->get("XrRoot"));

sub file_path {
  my ($pkg, $file) = @_;
  $file = abs2rel($file, $base_path);
  return $file;
}

1;
