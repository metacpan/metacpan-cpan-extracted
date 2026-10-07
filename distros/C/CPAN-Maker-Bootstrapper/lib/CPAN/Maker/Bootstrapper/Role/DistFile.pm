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

  die "usage: dist-file distribution file\n"
    if !$distribution || !$file;

  my $content = eval {
    my $dist_dir = dist_dir($distribution);

    my ($path) = grep { -e "$dist_dir/$_" } ( $file, "share/$file" );

    die "$file not found in $distribution\n"
      if !$path;

    return slurp $path;
  };

  die "ERROR: could not fetch $file from $distribution\n$EVAL_ERROR"
    if !$content || $EVAL_ERROR;

  print {*STDOUT} $content;

  return $SUCCESS;
}

1;
