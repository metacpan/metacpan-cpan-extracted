use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::Meson;
use Data::Dumper;

alien_diag 'Alien::Meson';
diag "Alien::Meson {style} : ", Alien::Meson->runtime_prop->{'style'};
alien_ok 'Alien::Meson';

diag "Alien::Meson->runtime_prop ", Dumper( [ Alien::Meson->runtime_prop ] );

diag "Alien::Meson->exe: ", Dumper( [ Alien::Meson->exe ] );

like warning {
  helper_ok 'meson';
  interpolate_template_is '%{meson}', join " ", Alien::Meson->exe;
}, qr/deprecated/, 'helper is deprecated';

run_ok([ Alien::Meson->exe, qw(--version) ])
  ->success
  ->out_like(qr/[0-9\.]+/);

done_testing;
