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
    require Config;
    ($installbindir) = Config::config_re(qr/installsitebin/xsm);
    ($installbindir) = $installbindir =~ /=\'([^\']+)/xsm;
  }

  $installbindir = abs_path($installbindir);

  die "ERROR: no such directory ($installbindir) or inaccessible\n"
    if !-d $installbindir;

  local $RS = undef;

  my $script = <DATA>;

  # remove pod
  $script =~ s/\A(.*)^=pod.*\z/$1/xsm;

  # customize
  $script =~ s/[@]MODULINO_WRAPPER[@]/$alias/xsm;
  $script =~ s/[@]PERL_MODULE_NAME[@]/$module_name/xsm;

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

MODULINO_WRAPPER=@MODULINO_WRAPPER@
MODULE_NAME=@PERL_MODULE_NAME@
MODULE_PATH=$(MODULE_PATH="${MODULE_NAME//:://}.pm" perl -M$MODULE_NAME -e 'print $INC{$ENV{MODULE_PATH}};')

MODULINO_WRAPPER=$MODULINO_WRAPPER perl $MODULE_PATH "$@"

=pod

=head1 NAME

CLI::Simple::Modulino - Create CLI wrapper around a modulino

=head1 SYNOPSIS

 # create $RealBin/my-app
 create-modulino -m My::App

 # create /usr/local/bin/my-app
 create-modulino -i /usr/local/bin -m My::App

 # create /usr/local/bin app
 create-modulino -a app -i /usr/local/bin -m My::App

=head2 Options

 -h, --help            help
 -a, --alias           name of the modulino (default: lower cased snake cased module name)
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
