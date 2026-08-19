package CPAN::Maker::Bootstrapper::Role::ExtraFiles;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use Data::Dumper;
use English qw(-no_match_vars);
use List::Util qw(uniq none any);
use Scalar::Util qw(reftype);

use Role::Tiny;

########################################################################
sub cmd_extra_files {
########################################################################
  my ($self) = @_;

  my ( $path, @extra_files ) = $self->get_args;

  die "ERROR: path must root, '.' or share\n"
    if none { $path eq $_ } qw(root . share);

  foreach (@extra_files) {
    die "ERROR: file not found - make sure '$_' exists before adding to buildspec.yml\n"
      if !-f $_;
  }

  die "ERROR: usage cmb extra-files path file...\n"
    if !$path || !@extra_files;

  require YAML::Tiny;

  my $buildspec = YAML::Tiny::LoadFile('buildspec.yml');

  my $extra = $buildspec->{'extra-files'} // [];
  $path = $path eq 'root' ? q{.} : $path;

  if ( $path eq q{.} ) {

    foreach my $f (@extra_files) {
      next if any { $f eq $_ } @{$extra};
      push @{$extra}, $f;
    }
  }
  else {
    my ($share) = grep { ref $_ && ( keys %{$_} )[0] eq 'share' } @{$extra};

    my $files = $share->{share} // [];

    foreach my $f (@extra_files) {
      next if any { $f eq $_ } @{$files};
      push @{$files}, $f;
    }

    push @{$extra}, { share => $files };
  }

  $buildspec->{'extra-files'} = $extra;

  rename 'buildspec.yml', 'buildspec.yml.bak';

  eval { YAML::Tiny::DumpFile( 'buildspec.yml', $buildspec ); } or do {
    rename 'buildspec.yml.bak', 'buildspec.yml';
  };

  return $SUCCESS;
}

1;
