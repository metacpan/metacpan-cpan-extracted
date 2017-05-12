return (
 [
  cpanmod => ['Linux::Only'],
  [os => 'linux',
   [package => 'libfoo-dev']]],

 [
  cpanmod => ['FreeBSD::Only'],
  [os => 'freebsd',
   [package => 'libfoo']]],

 [
  cpanmod => ['FreeBSD::Version'],
  [os => 'freebsd',
   [osvers => qr{^[123456789]\.},
    [package => 'gcc']],
   [osvers => qr{^10\.},
    [package => 'clang']]]],

 [
  cpanmod => 'Multi::Packages',
  [package => ['package-one', 'package-two']]],

);
