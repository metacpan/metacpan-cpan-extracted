package CPAN::Maker::Bootstrapper::Role::ReconcileDeps;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);

use English qw(-no_match_vars);
use Role::Tiny;

use Role::Tiny::With;
with 'CPAN::Maker::Bootstrapper::Role::DepsFilter';

########################################################################
sub cmd_reconcile_deps {
########################################################################
  my ($self) = @_;

  my @types = $self->get_args;

  die "ERROR: usage: reconcile-deps dependency-type [...]\n"
    if !@types;

  my @mirrors = ('https://cpan.metacpan.org');

  if ( -e 'build-mirrors' ) {

    foreach my $mirror ( split /\n/xsm, slurp('build-mirrors') ) {
      next if !$mirror || $mirror =~ /^[#]/xsm;
      push @mirrors, $mirror;
    }

  }

  my $index = $self->fetch_index( \@mirrors );

  foreach my $type (@types) {
    my $requires = $self->_filter_requires( "$type.raw", "$type.skip", $type, );

    my %package_lines;

    foreach my $module ( keys %{$requires} ) {
      my $lookup = $module;
      $lookup =~ s/^[+]//xsm;

      $package_lines{$lookup} = sprintf '%s %s', $module, $requires->{$module};
    }

    my $filtered = $self->_filter_package_hash( $index, \%package_lines, );

    $self->_write_requires( $type, $filtered );
  }

  return $SUCCESS;
}

########################################################################
sub _write_requires {
########################################################################
  my ( $self, $filename, $requires ) = @_;

  my $output = q{};

  if ( %{$requires} ) {
    $output = join( "\n", sort values %{$requires} ) . "\n";
  }

  if ( !-e $filename || slurp($filename) ne $output ) {
    open my $fh, '>', $filename
      or die "ERROR: could not write $filename: $OS_ERROR\n";

    print {$fh} $output;

    close $fh
      or die "ERROR: could not close $filename: $OS_ERROR\n";
  }

  return;
}

1;
