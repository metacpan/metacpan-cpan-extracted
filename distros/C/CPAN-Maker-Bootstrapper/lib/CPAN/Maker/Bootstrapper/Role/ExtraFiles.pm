package CPAN::Maker::Bootstrapper::Role::ExtraFiles;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use Data::Dumper;
use English qw(-no_match_vars);
use Scalar::Util qw(reftype);

use Role::Tiny;

########################################################################
sub cmd_extra_files {
########################################################################
  my ($self) = @_;

  my ( $path, @extra_files ) = $self->get_args;

  foreach (@extra_files) {
    die "ERROR: file not found - make sure '$_' exists before adding to buildspec.yml\n"
      if !-e $_;
  }

  die "ERROR: usage cmb extra-files path file...\n"
    if !$path || !@extra_files;

  require YAML::Tiny;

  my $buildspec = YAML::Tiny::LoadFile('buildspec.yml');

  my $extra = $buildspec->{'extra-files'} // [];

  if ( $path eq '.' ) {
    push @{$extra}, @extra_files;
  }
  else {
    my ($existing_path) = grep { ref $_ && reftype($_) eq 'HASH' && ( keys %{$_} )[0] eq $path } @{$extra};
    push @{ $existing_path->{$path} }, @extra_files;
  }

  rename 'buildspec.yml', 'buildspec.yml.bak';

  eval { YAML::Tiny::DumpFile( 'buildspec.yml', $buildspec ); } or do {
    rename 'buildspec.yml.bak', 'buildspec.yml';
  };

  return $SUCCESS;
}

1;
