use Test::More;
use Test::Alien 0.05;
use Alien::gperf;
use Env (@PATH);

alien_ok 'Alien::gperf';

unshift @PATH, Alien::gperf->bin_dir;
my $prefix = Alien::gperf->bin_dir.'/' if Alien::gperf->bin_dir;
diag "${prefix}gperf --version";
my $out = qx/${prefix}gperf --version/;
is $?, 0, "Calling gperf --version doesn't fail";
like ($out, qr/Free Software Foundation/, "Check if --version gives familiar content");
diag $out;

done_testing;
