package App::perlminlint::Plugin::LintYATTRC;
use strict;
use warnings FATAL => qw/all/;
use autodie;
use File::Basename qw/dirname/;

use App::perlminlint::Plugin -as_base, [priority => 10];

sub handle_match {
  my ($plugin, $fn) = @_;

  $fn =~ m{\.htyattrc\.pl\z}
    and do { eval {require YATT::Lite::Factory} }
    and $plugin->find_linter
    and $plugin;
}

sub handle_test {
  my ($plugin, $fn) = @_;

  defined (my $linter = $plugin->find_linter)
    or die "Can't find linter for $fn\n";

  $plugin->app->run_perl($linter, $fn)
    and "$fn is OK";
}

sub find_linter {
  my ($plugin) = @_;
  my $modfn = $INC{"YATT/Lite/Factory.pm"}
    or return undef;
  my $scriptdir = dirname(dirname($plugin->rel2abs($modfn))) . "/scripts";
  -x (my $script = "$scriptdir/yatt.lintrc")
    or return undef;
  $script;
}

1;
