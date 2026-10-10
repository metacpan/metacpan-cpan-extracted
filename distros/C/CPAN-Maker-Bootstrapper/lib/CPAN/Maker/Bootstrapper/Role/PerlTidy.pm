package CPAN::Maker::Bootstrapper::Role::PerlTidy;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use English qw(-no_match_vars);
use Role::Tiny;

########################################################################
sub cmd_perltidy {
########################################################################
  my ($self) = @_;

  my $has_perl_tidy = eval {
    require Perl::Tidy;
    1;
  };

  die "ERROR: perltidy command requires Perl::Tidy\n"
    if !$has_perl_tidy || $EVAL_ERROR;

  my ($source) = $self->get_args;

  my $file_list = $self->get_file_list;
  my $profile   = $self->get_profile;

  die "ERROR: source-file and --file-list are mutually exclusive\n"
    if $source && $file_list;

  die "ERROR: usage: cmb perltidy [--file-list file-list] [--profile file] [source-file]\n"
    if !$source && !$file_list;

  die "ERROR: $profile not found or not readable\n"
    if $profile && ( !-f $profile || !-r $profile );

  my @files = $self->_perltidy_files( $source, $file_list );

  for my $file (@files) {
    my $source_text = slurp($file);
    my $tidied_text = q{};
    my $stderr      = q{};
    my $errorfile   = q{};

    my %tidy_args = (
      source      => \$source_text,
      destination => \$tidied_text,
      stderr      => \$stderr,
      errorfile   => \$errorfile,
    );

    $tidy_args{perltidyrc} = $profile
      if $profile;

    my $error = Perl::Tidy::perltidy(%tidy_args);

    if ($error) {
      print {*STDERR} $stderr
        if $stderr;

      print {*STDERR} $errorfile
        if $errorfile;

      die "ERROR: perltidy failed for $file\n";
    }

    die "ERROR: $file is not tidy - run: make tidy\n"
      if $source_text ne $tidied_text;

    my $sentinel = "$file.tdy";

    open my $fh, '>', $sentinel
      or die "ERROR: cannot write $sentinel: $ERRNO\n";

    close $fh
      or die "ERROR: cannot close $sentinel: $ERRNO\n";
  }

  return $SUCCESS;
}

########################################################################
sub _perltidy_files {
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

  die "ERROR: no files to tidy\n"
    if !@files;

  for my $file (@files) {
    die "ERROR: $file not found or not readable\n"
      if !-f $file || !-r $file;
  }

  return @files;
}

1;
