package App::perlminlint::Plugin::LintT;
# -*- coding: utf-8 -*-
use strict;
use warnings FATAL => qw/all/;
use App::perlminlint::Plugin::LintPL
  (-as_base, [priority => 1], [is_generic => 0]);

sub handle_match {
  (my MY $plugin, my $fn) = @_;
  $fn =~ m{\.t\z}i
    and $plugin;
}

sub gather_opts {
  (my MY $plugin, my $fn) = @_;

  my @opts = $plugin->SUPER::gather_opts($fn);

  #
  # Add -Ilib if $fn looks like t/.../*.t
  #
  if (my ($basedir) = $fn =~ m{^(.*/|)t/}) {
    my $libdir = $basedir . "lib";
    push @opts, "-I$libdir" if -d $libdir;
  }

  @opts;
}

1;
