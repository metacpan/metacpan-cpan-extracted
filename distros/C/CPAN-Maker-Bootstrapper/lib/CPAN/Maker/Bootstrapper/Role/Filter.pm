package CPAN::Maker::Bootstrapper::Role::Filter;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use Data::Dumper;

use Role::Tiny;

########################################################################
sub _fetch_requires {
########################################################################
  my ( $self, $infile ) = @_;

  return {}
    if !-s $infile;

  my %requires;

  open my $fh, '<', $infile
    or die "ERROR: could not open $infile for reading\n";

  while (<$fh>) {
    chomp;
    my ( $m, $v ) = split q{ }, $_;
    $requires{$m} = $v // 0;
  }

  close $fh;

  return \%requires;
}

########################################################################
sub cmd_filter {
########################################################################
  my ($self) = @_;

  my ( $requires_new, $skip_file, $requires_old ) = $self->get_args;

  my %files = (
    skip => $self->_fetch_requires($skip_file),
    new  => $self->_fetch_requires($requires_new),
    old  => $self->_fetch_requires($requires_old),
  );

  my %new_requires;

  # copy preserved modules (ones preceded with '+')
  foreach my $m ( keys %{ $files{old} } ) {
    next if $m !~ /^\+/xsm;
    $new_requires{$m} = $files{old}->{$m};
  }

  foreach my $m ( keys %{ $files{new} } ) {
    # skip modules on skip list
    next if exists $files{skip}->{$m};
    next if exists $files{old}->{"+$m"};

    # keep modules from preserved list if versions differ (user must have specified specific version)
    if ( exists $files{old}->{$m} && $files{old}->{$m} ne $files{new}->{$m} ) {
      $new_requires{$m} = $files{old}->{$m};
    }
    else {
      $new_requires{$m} = $files{new}->{$m};
    }
  }

  print join q{}, map {"$_ $new_requires{$_}\n"} sort keys %new_requires;

  return $SUCCESS;
}

1;
