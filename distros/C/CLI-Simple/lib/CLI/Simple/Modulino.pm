package CLI::Simple::Modulino;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use Cwd qw(abs_path);
use English qw(-no_match_vars);

use parent qw(CLI::Simple);

caller or exit __PACKAGE__->main;

########################################################################
sub cmd_create_modulino {
########################################################################
  my ($self) = @_;

  my $module_name = $self->get_module;

  my $alias = $self->get_alias;

  if ( !$alias ) {
    $alias = $module_name;
    $alias =~ s/::/-/xsmg;
    $alias = lc $alias;
  }

  my $installbindir = $self->get_installbindir;

  if ( !$installbindir ) {
    if ( defined $ENV{PERL_LOCAL_LIB_ROOT} ) {
      $installbindir = "$ENV{PERL_LOCAL_LIB_ROOT}/bin";
    }
    else {
      require Config;
      ($installbindir) = Config::config_re(qr/installsitebin/xsm);
      ($installbindir) = $installbindir =~ /=\'([^\']+)/xsm;
    }
  }

  $installbindir = abs_path($installbindir);

  die "ERROR: no such directory ($installbindir) or inaccessible\n"
    if !-d $installbindir;

  local $RS = undef;

  my $script = <DATA>;

  # remove pod
  $script =~ s/\A(.*)^=pod.*\z/$1/xsm;

  # customize
  $script =~ s/[@]modulino_wrapper[@]/$alias/xsm;
  $script =~ s/[@]perl_module_name[@]/$module_name/xsm;

  my $modulino = sprintf '%s/%s', $installbindir, $alias;

  open my $fh, '>', $modulino
    or die "ERROR: could not open $installbindir for writing:\n$OS_ERROR\n";

  print {$fh} $script;

  close $fh
    or die "ERROR: could not close handle for $modulino\n:$OS_ERROR\n";

  chmod 0755, $modulino;

  print "$alias installed as $modulino\n";

  return $SUCCESS;
}

########################################################################
sub main {
########################################################################
  my $option_specs = [
    qw(
      alias|a=s
      help|h
      installbindir|i=s
      module|m=s
    )
  ];

  my $commands = {
    'create-modulino' => \&cmd_create_modulino,
    default           => \&cmd_create_modulino,
  };

  return __PACKAGE__->new(
    commands     => $commands,
    option_specs => $option_specs
  )->run;
}

1;

__DATA__
#!/usr/bin/env bash
#-*- mode: sh; -*-
# modulino invocation

MODULINO_WRAPPER=@modulino_wrapper@
MODULINO_MODULE_NAME=@perl_module_name@

MODULINO_WRAPPER="$MODULINO_WRAPPER" \
MODULINO_MODULE_NAME="$MODULINO_MODULE_NAME" \
  perl -M"$MODULINO_MODULE_NAME" \
  -e 'exit $ENV{MODULINO_MODULE_NAME}->main' \
  -- "$@"

=pod

=head1 NAME

CLI::Simple::Modulino - Create CLI wrapper around a modulino

=head1 SYNOPSIS

  # create my-app in the default installation directory
  create-modulino -m My::App

  # create /usr/local/bin/my-app
  create-modulino -i /usr/local/bin -m My::App

  # create /usr/local/bin app
  create-modulino -a app -i /usr/local/bin -m My::App

=head2 Options

  -h, --help            help
  -a, --alias           wrapper name (default: lowercase module name with :: replaced by -)
  -m, --module          module name - Perl module implementing the modulino
  -i, --installbindir   executable directory

Example:

 create-modulino -i /usr/local/bin -a find-requires -m Module::ScanDeps::FindRequires

=head1 DESCRIPTION

Creates a so called wrapper for a so-called "modulino". Modulinos are
Perl modules that use the pattern:

 caller or exit __PACKAGE__->main

...to flexibly use a Perl module as a script.

See L<CLI::Simple> for more information about modulinos.

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=head1 SEE ALSO 

L<CLI::Simple>
