package App::perlminlint::Plugin::LintPL;
# -*- coding: utf-8 -*-
use strict;
use warnings FATAL => qw/all/;

use App::perlminlint::Plugin -as_base
  , [priority => 0], -is_generic;

sub handle_match {
  (my MY $plugin, my $fn) = @_;
  $fn =~ m{\.(pl|t)\z}
    and $plugin;
}

sub handle_test {
  (my MY $plugin, my $fn) = @_;

  my @opts = $plugin->gather_opts($fn);

  $plugin->app->run_perl(@opts, -wc => $fn)
    and ""; # Empty message.
}

sub gather_opts {
  (my MY $plugin, my $fn) = @_;

  $plugin->app->read_shbang_opts($fn);
}

1;
