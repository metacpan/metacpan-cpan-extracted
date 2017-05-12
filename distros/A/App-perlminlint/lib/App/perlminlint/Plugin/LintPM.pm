package App::perlminlint::Plugin::LintPM;
use strict;
use warnings FATAL => qw/all/;
use autodie;

use App::perlminlint::Plugin -as_base, [priority => 0];

sub handle_match {
  my ($plugin, $fn) = @_;

  $fn =~ m{\.pm\z}
    and $plugin;
}

sub handle_test {
  my ($plugin, $fn) = @_;

  defined (my $modname = $plugin->find_module($fn))
    or die "Can't extract module name from $fn\n";

  my @inc_opt = $plugin->app->inc_opt($fn, $modname);

  $plugin->app->run_perl(@inc_opt, -we => "require $modname")
    and "Module $modname is OK";
}

sub find_module {
  my ($plugin, $fn) = @_;

  local $_ = $plugin->app->read_file($fn);

  while (/(?:^|\n) [\ \t]*     (?# line beginning + space)
	  package  [\n\ \t]+   (?# newline is allowed here)
	  ([\w:]+)             (?# module name)
	  \s* [;\{]            (?# statement or block)
	 /xsg) {
    my ($modname) = $1;

    # Tail of $modname should be equal to it's rootname.
    if (((split /::/, $modname)[-1])
	eq $plugin->app->rootname($plugin->app->basename($fn))) {
      return $modname;
    }
  }
  return;
}

1;
