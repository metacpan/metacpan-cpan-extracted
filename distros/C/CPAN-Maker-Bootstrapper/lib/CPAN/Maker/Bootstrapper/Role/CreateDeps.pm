package CPAN::Maker::Bootstrapper::Role::CreateDeps;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use Data::Dumper;
use File::Find;
use List::Util qw(none);
use Role::Tiny;

########################################################################
sub find_modules {
########################################################################
  my ($self);

  my @modules;

  find(
    sub {
      return if !/[.]p[ml][.]in$/xsm;
      return if /^[.]?[#]/xsm;  # ignore temp files

      push @modules, $File::Find::name;
    },
    q{.}
  );

  return @modules;
}

########################################################################
sub find_package_name {
########################################################################
  my ( $self, $path ) = @_;

  my $module = slurp($path);
  my @package_names;

  while ( $module =~ /^package\s+([^;]+);/gxsm ) {
    push @package_names, $1;
  }

  return [ $path, \@package_names ];
}

########################################################################
sub find_deps {
########################################################################
  my ( $self, $modules ) = @_;

  my %requires;

  require Module::ScanDeps::Static;

  foreach my $m ( @{$modules} ) {
    my $scanner = Module::ScanDeps::Static->new( { path => $m } );
    $scanner->parse;
    $requires{$m} = [ keys %{ $scanner->get_require } ];
  }

  return \%requires;
}

########################################################################
sub cmd_create_deps {
########################################################################
  my ($self) = @_;

  my @output_modules = $self->get_args;

  my @modules = $self->find_modules();

  my @internal_packages;
  my %lookup;
  my $fh = \*STDOUT;

  foreach my $m (@modules) {
    my @p = @{ $self->find_package_name($m) };
    push @internal_packages, @{ $p[1] };
    $lookup{$_} = $m for @{ $p[1] };
  }

  my $packages = $self->find_deps( \@modules );

  foreach my $p ( sort keys %{$packages} ) {
    next if @output_modules && none { $p eq "./$_" } @output_modules;

    my $generated_p = $p;
    $generated_p =~ s/[.](p[ml])[.]in/.$1/xsm;

    my @deps;

    foreach my $m ( sort @{ $packages->{$p} } ) {
      next if none { $m eq $_ } @internal_packages;
      next if $p eq $lookup{$m};

      push @deps, $lookup{$m};
    }

    if (@deps) {
      print {$fh} sprintf "# %s\n%s: \\\n", $p, $generated_p;

      foreach ( sort @deps ) {
        s/\.in$//;
      }
      print {$fh} sprintf "    %s\n\n", join " \\\n    ", @deps;
    }
  }

  return $SUCCESS;
}

1;
