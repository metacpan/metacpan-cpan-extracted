package CPAN::Maker::Bootstrapper::Role::PerlCritic;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use English qw(-no_match_vars);
use Role::Tiny;

use Readonly;
Readonly::Scalar our $DEFAULT_SEVERITY => 5;

########################################################################
sub cmd_perlcritic {
########################################################################
  my ($self) = @_;

  my $has_perl_critic = eval {
    require Perl::Critic;
    1;
  };

  die "ERROR: perlcritic command requires Perl::Critic\n"
    if !$has_perl_critic || $EVAL_ERROR;

  my ( $source, $arg_severity ) = $self->get_args;

  my $file_list = $self->get_file_list;
  my $severity  = $self->get_severity;
  my $profile   = $self->get_profile;
  my $theme     = $self->get_theme;

  die "ERROR: source-file and --file-list are mutually exclusive\n"
    if $source && $file_list;

  die
    "ERROR: usage: cmb perlcritic [--file-list file-list] [--severity 1-5] [--profile file] [--theme theme] [source-file [severity]]\n"
    if !$source && !$file_list;

  $severity //= $arg_severity;
  $severity //= $DEFAULT_SEVERITY;

  die "ERROR: severity must be an integer between 1 and 5\n"
    if $severity !~ /\A[1-5]\z/xsm;

  die "ERROR: $profile not found or not readable\n"
    if $profile && ( !-f $profile || !-r $profile );

  my @files = $self->_perlcritic_files( $source, $file_list );

  my %critic_args = ( -severity => $severity, );

  $critic_args{-profile} = $profile
    if $profile;

  $critic_args{-theme} = $theme
    if $theme;

  my $critic = Perl::Critic->new(%critic_args);

  for my $file (@files) {
    my @violations = $critic->critique($file);
    my $report     = "$file.crit";

    open my $fh, '>', $report
      or die "ERROR: cannot write $report: $ERRNO\n";

    for my $violation (@violations) {
      print {$fh} $violation->to_string();
    }

    close $fh
      or die "ERROR: cannot close $report: $ERRNO\n";

    die "ERROR: $file fails perlcritic at severity $severity (see $file.crit)\n"
      if @violations;
  }

  return $SUCCESS;
}

########################################################################
sub _perlcritic_files {
########################################################################
  my ( $self, $source, $file_list ) = @_;

  my @files;

  if ($file_list) {
    die "ERROR: $file_list not found or not readable\n"
      if !-f $file_list || !-r $file_list;

    for my $file ( split /\n/xsm, slurp($file_list) ) {
      next if !$file;
      next if $file =~ /^[#]/xsm;

      push @files, $file;
    }
  }
  else {
    @files = ($source);
  }

  die "ERROR: no files to critique\n"
    if !@files;

  for my $file (@files) {
    die "ERROR: $file not found or not readable\n"
      if !-f $file || !-r $file;
  }

  return @files;
}

1;
