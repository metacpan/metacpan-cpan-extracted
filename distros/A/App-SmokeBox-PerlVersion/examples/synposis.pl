use strict;
use warnings;
use POE;
use App::SmokeBox::PerlVersion;

my $perl = shift || $^X;

POE::Session->create(
  package_states => [
    main => [qw(_start _result)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  App::SmokeBox::PerlVersion->version(
    perl => $perl,
    event => '_result',
  );
  return;
}

sub _result {
  my $href = $_[ARG0];
  print "Perl version: ", $href->{version}, "\n";
  print "Built for:    ", $href->{archname}, "\n";
  return;
}
