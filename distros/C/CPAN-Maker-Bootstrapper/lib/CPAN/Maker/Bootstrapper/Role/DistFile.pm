package CPAN::Maker::Bootstrapper::Role::DistFile;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use Data::Dumper;
use English qw(-no_match_vars);
use File::ShareDir qw(dist_dir);

use Role::Tiny;

########################################################################
sub cmd_dist_file {
########################################################################
  my ($self) = @_;

  my ( $distribution, $file ) = $self->get_args;

  if ( !$file ) {
    $file         = $distribution;
    $distribution = 'CPAN-Maker-Bootstrapper';
  }

  die "usage: dist-file [--path-only] distribution file\n"
    if !$file;

  my ( $path, $content ) = eval {
    my $dist_dir = dist_dir($distribution);

    my ($path) = grep { -e $_ } ( "$dist_dir/$file", "$dist_dir/share/$file" );

    die "$file not found in $distribution\n"
      if !$path;

    return ( $path, !$self->get_path_only ? slurp($path) : q{} );
  };

  die "ERROR: could not fetch $file from $distribution\n$EVAL_ERROR"
    if !$path || $EVAL_ERROR;

  print {*STDOUT} $self->get_path_only ? $path : $content;

  return $SUCCESS;
}

1;
