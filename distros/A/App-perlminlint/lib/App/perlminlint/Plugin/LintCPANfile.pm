package App::perlminlint::Plugin::LintCPANfile;
use strict;
use warnings FATAL => qw/all/;

use App::perlminlint::Plugin -as_base;

my $has_module_cpanfile;
BEGIN {
  local $@;
  eval {require Module::CPANfile};
  $has_module_cpanfile = ! $@;
}

sub handle_match {
  my ($plugin, $fn) = @_;
  $has_module_cpanfile
    and $fn =~ m{\bcpanfile\z}i
      and $plugin;
}

sub handle_test {
  my ($plugin, $fn) = @_;

  Module::CPANfile->load($fn)
    and "CPANfile $fn is OK";
}

1;
