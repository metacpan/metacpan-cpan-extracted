use Test2::V0 -no_srand => 1;
use Test::Alien 0.56;
use Alien::gmake ();

alien_ok 'Alien::gmake';
my $run = run_ok([Alien::gmake->exe, '--version'])
  ->exit_is(0);

$run->success ? $run->note : $run->diag;

ok(Alien::gmake->exe, 'exe method returns a "true" value');
note "Alien::gmake->exe = @{[ Alien::gmake->exe ]}";

helper_ok 'gmake';
interpolate_template_is '%{gmake}', Alien::gmake->exe;

done_testing;
