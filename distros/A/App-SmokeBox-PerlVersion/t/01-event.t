use strict;
use warnings;
use Config;
use Test::More 'no_plan';
use POE;
use_ok('App::SmokeBox::PerlVersion');

diag("Using Perl $^X\n");
my $output = `$^X -v`;
diag($output);

POE::Session->create(
  package_states => [
    main => [qw(_start _stop _result)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  App::SmokeBox::PerlVersion->version(
    event => '_result',
    context => 'fubar',
  );
  return;
}

sub _stop {
  pass('Finished');
  return;
}

sub _result {
  my $href = $_[ARG0];
  pass('Response');
  is( $href->{exitcode}, 0, 'Exitcode is okay' );
  is( $href->{context}, 'fubar', 'Context is okay' );
  is( $href->{version}, $Config::Config{version}, 'Version is ' . $Config::Config{version} );
  is( $href->{archname}, $Config::Config{archname}, 'ArchName is ' . $Config::Config{archname} );
  is( $href->{osvers}, $Config::Config{osvers}, 'OSVers is ' . $Config::Config{osvers} );
  return;
}
