use Test::More;
use Test::Alien 0.05;
use Alien::lshw;
use Env (@PATH);

alien_ok 'Alien::lshw';

unshift @PATH, Alien::lshw->bin_dir;
my $prefix = Alien::lshw->bin_dir.'/' if Alien::lshw->bin_dir;
diag "${prefix}lshw -version";
my $out = qx/${prefix}lshw -version 2>&1/;
is $?, 0, "Calling lshw -version doesn't fail";
like ($out, qr/[.]/, "Check if -version has a dot in it!");
diag $out;

done_testing;
