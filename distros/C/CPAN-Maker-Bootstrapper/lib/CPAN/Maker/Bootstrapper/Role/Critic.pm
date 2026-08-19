package CPAN::Maker::Bootstrapper::Role::Critic;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use Data::Dumper;
use English qw(-no_match_vars);
use File::Find;
use List::Util qw(none);

use Role::Tiny;

use Readonly;

Readonly::Scalar our $DEFAULT_THEME    => 'pbp';
Readonly::Scalar our $DEFAULT_SEVERITY => 5;

########################################################################
sub cmd_critique {
########################################################################
  my ($self) = @_;

  my $file_list = eval {
    if ( my $manifest = $self->get_file_list ) {
      my $list = slurp($manifest);
      return [ split /\n/xsm, $list ];
    }

    return [ ( $self->get_args ) ];
  };

  die "ERROR: no files to critique\n$OS_ERROR"
    if !$file_list || !@{$file_list};

  eval { require Perl::Critic; 1; };

  die "ERROR: Perl::Critic is not installed!\n"
    if $EVAL_ERROR;

  my $theme    = $ENV{PERLCRITIC_THEME}    || $DEFAULT_THEME;
  my $severity = $ENV{PERLCRITIC_SEVERITY} || $DEFAULT_SEVERITY;

  my %options = (
    $ENV{PERLCRITICRC} ? ( '-profile' => $ENV{PERLCRITICRC} ) : (),
    '-theme'    => $theme,
    '-severity' => $severity,
  );

  my $critic = Perl::Critic->new(%options);

  open my $old_stderr, '>&', \*STDERR
    or die $OS_ERROR;

  my %has_violations;

  foreach my $file ( @{$file_list} ) {
    my ($base_file) = $file =~ /^(.*?)[.]p[ml](?:[.]in)?$/xsm;

    die "ERROR: $base_file not found.\n"
      if !-e "$base_file.pm";

    open STDERR, '|-', 'tee', $base_file . '.crit'
      or die "ERROR: could not open pipe to tee for $base_file.crit: $OS_ERROR\n";

    my @violations = $critic->critique( $base_file . '.pm' );

    foreach my $v (@violations) {
      my $severity = $v->severity;
      $has_violations{$severity}++;

      my $level = {
        1 => 'info',
        2 => 'info',
        3 => 'warn',
        4 => 'warn',
        5 => 'error',
      }->{$severity};

      my $violation_msg = $v->to_string;
      chomp $violation_msg;
      $violation_msg = "$violation_msg (Severity $severity)";
      $self->get_logger->$level($violation_msg);  # one write -> tee -> terminal AND .crit
    }

    close STDERR
      or die "ERROR: could not close pipe for $base_file.crit: $OS_ERROR\n";
  }

  open STDERR, '>&', $old_stderr
    or die $OS_ERROR;

  open STDERR, '>&', $old_stderr
    or die $OS_ERROR;

  if ( keys %has_violations ) {
    $self->get_logger->error( sprintf 'Total Violations: %s',
      join q{, }, map { sprintf "%s: [%s]", $_, ( $has_violations{$_} // '0' ) } ( 1 .. 5 ) );
  }

  return keys %has_violations ? $FAILURE : $SUCCESS;
}

1;
