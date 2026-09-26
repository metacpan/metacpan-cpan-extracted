package CPAN::Maker::Bootstrapper::Role::ExtraFiles;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use Data::Dumper;
use English qw(-no_match_vars);
use List::Util qw(any none);
use Scalar::Util qw(reftype);

use Role::Tiny;

our $VERSION = '2.3.3';

########################################################################
sub cmd_extra_files {
########################################################################
  my ($self) = @_;

  my ( $path, @extra_files ) = $self->get_args;

  require YAML::Tiny;

  my $buildspec = YAML::Tiny::LoadFile('buildspec.yml');
  my $extra     = $buildspec->{'extra-files'} // [];

  ######################################################################
  # With no arguments, emit the source files represented by
  # buildspec.yml. This form is used by make to regenerate extra-files.
  ######################################################################
  if ( !defined $path ) {
    foreach my $entry ( @{$extra} ) {
      if ( !ref $entry ) {
        print "$entry\n";
        next;
      }

      next
        if reftype($entry) ne 'HASH';

      foreach my $section ( keys %{$entry} ) {
        my $files = $entry->{$section};

        if ( !ref $files ) {
          print "$files\n"
            if defined $files && $files ne q{};
          next;
        }

        next
          if reftype($files) ne 'ARRAY';

        foreach my $file ( @{$files} ) {
          print "$file\n"
            if defined $file && !ref $file && $file ne q{};
        }
      }
    }

    return $SUCCESS;
  }

  die "ERROR: path must root, '.' or share\n"
    if none { $path eq $_ } qw(root . share);

  die "ERROR: usage cmb extra-files [path file...]\n"
    if !@extra_files;

  $path = q{.}
    if $path eq 'root';

  ######################################################################
  # Additions must exist. Removals are idempotent and need not exist on
  # disk.
  ######################################################################
  foreach my $file (@extra_files) {
    next
      if $file =~ /^-/xsm;

    die "ERROR: file not found - make sure '$file' exists before adding to buildspec.yml\n"
      if !-f $file;
  }

  if ( $path eq q{.} ) {
    my @updated;

    foreach my $entry ( @{$extra} ) {
      if ( ref $entry ) {
        push @updated, $entry;
        next;
      }

      my $remove = any {
        my $file = $_;
        $file =~ s/^-//xsm;
        $_    =~ /^-/xsm && $file eq $entry;
      } @extra_files;

      push @updated, $entry
        if !$remove;
    }

    foreach my $file (@extra_files) {
      next
        if $file =~ /^-/xsm;

      next
        if any { !ref $_ && $_ eq $file } @updated;

      push @updated, $file;
    }

    $extra = \@updated;
  }
  else {
    my @updated;
    my @share_files;
    my $share_seen = $FALSE;

    ####################################################################
    # Fold any duplicate share sections into one while preserving all
    # other extra-files sections unchanged.
    ####################################################################
    foreach my $entry ( @{$extra} ) {
      if ( ref $entry
        && reftype($entry) eq 'HASH'
        && exists $entry->{share} ) {
        my $files = $entry->{share};

        if ( ref $files && reftype($files) eq 'ARRAY' ) {
          foreach my $file ( @{$files} ) {
            push @share_files, $file
              if !any { $_ eq $file } @share_files;
          }
        }

        next
          if $share_seen;

        $share_seen = $TRUE;
        next;
      }

      push @updated, $entry;
    }

    foreach my $arg (@extra_files) {
      if ( $arg =~ /^-(.+)$/xsm ) {
        my $remove = $1;
        my @kept;

        foreach my $file (@share_files) {
          push @kept, $file
            if $file ne $remove;
        }

        @share_files = @kept;
        next;
      }

      push @share_files, $arg
        if !any { $_ eq $arg } @share_files;
    }

    push @updated, { share => \@share_files }
      if @share_files;

    $extra = \@updated;
  }

  $buildspec->{'extra-files'} = $extra;

  rename 'buildspec.yml', 'buildspec.yml.bak'
    or die "ERROR: could not back up buildspec.yml\n$OS_ERROR";

  eval {
    YAML::Tiny::DumpFile( 'buildspec.yml', $buildspec );
    return 1;
  } or do {
    my $error = $EVAL_ERROR;

    rename 'buildspec.yml.bak', 'buildspec.yml'
      or die "ERROR: could not restore buildspec.yml\n$OS_ERROR";

    die $error;
  };

  return $SUCCESS;
}

1;
