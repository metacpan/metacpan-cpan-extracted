#!perl
use Test2::V0;
use Test2::Tools::Command;
local @Test2::Tools::Command::command = ( $^X, '--', './bin/atonal-util' );

# these may just confirm existing bad behavior, or duplicate tests from
# Music::AtonalUtil, or probably are otherwise incomplete
command {
    args   => [qw(--sd=16 adjacent_interval_content 0 3 6 10 12)],
    stdout => "01220000\n",
};
command {
    args   => [qw(bark 69)],    # 440 Hz, a'
    stdout => "4.39\n",
};
command {
    args   => [qw(basic 0 4 7)],
    stdout => "0,3,7\n001110\n3-11\tMajor and minor triad\n0,4,7\thalf_prime\n",
};
command {
    args   => [qw(basic c e g)],
    stdout => "0,3,7\n001110\n3-11\tMajor and minor triad\n0,4,7\thalf_prime\n",
};
command {
    args   => [qw(basic --ly --tension=cope 0 1 2)],
    stdout => "c,cis,d\n210000\n3-1\n1.800  0.800  1.000\n",
};
command {
    args   => [qw(--rs=_ basic c e g)],
    stdout => "0_3_7\n001110\n3-11\tMajor and minor triad\n0_4_7\thalf_prime\n",
};
command {
    args   => [qw(beats2set --scaledegrees=16 x..x ..x. ..x. x...)],
    stdout => "0,3,6,10,12\n",
};
command {
    args   => [qw(circular_permute 0 1 2)],
    stdout => "0 1 2\n1 2 0\n2 0 1\n",
};
command {
    args   => [qw(combos 440 880)],
    stdout =>
      "440.00+880.00 = 1320.00\t(88 error -1.49)\n880.00-440.00 = 440.00\t(69 error 0.00)\n",
};
command {
    args   => [qw(combos c g)],
    stdout =>
      "130.81+196.00 = 326.81\t(64 error 2.82)\n196.00-130.81 = 65.18\t(36 error 0.22)\n",
};
command {
    args   => [ 'complement', '0,1,2,3,4,5,7,8,9,10,11' ],
    stdout => "6\n",
};
command {
    args   => [qw(equivs 0 1 2 3 4 5 6 7 8 9 10 11)],
    stdout => "0 1 2 3 4 5 6 7 8 9 10 11\n",
};
command {
    args   => [qw(findall --fn=5 --root=0 c e g b a)],
    stdout => "5-27\tTi(0)\t0,11,9,7,4\n",
};
command {
    args   => [qw(findin --pitchset=4-23 --root=2 0 2 7 9)],
    stdout => "-\tTi(2)\t2,0,9,7\n",
};
command {
    args   => [qw(forte2pcs 9-3)],
    stdout => "0,1,2,3,4,5,6,8,9\n",
};
command {
    args   => [qw(freq2pitch 440)],
    stdout => "440.00\t69\t+0.00\t0.00%\n",
};
command {
    args   => [qw(freq2pitch --cf=422.5 440)],
    stdout => "440.00\t70\t-7.62\t1.70%\n",
};
command {
    args   => [qw(half_prime_form c b g)],
    stdout => "0,4,5\n",
};
command {
    args   => [qw(interval_class_content c fis b)],
    stdout => "100011\n",
};
command {
    args   => [qw(intervals2pcs --pitch=2 3 4 7)],
    stdout => "2,5,9,4\n",
};
command {
    args   => [qw(invariance_matrix 0 2 4)],
    stdout => "0,2,4\n2,4,6\n4,6,8\n",
};
command {
    args   => [qw(invert 1 2 3)],
    stdout => "11,10,9\n",
};
command {
    args   => [qw(ly2pitch c')],
    stdout => "60\n",
};
command {
    args   => [qw(ly2struct --tempo=120 --relative=c c4 r8)],
    stdout => "\t{ 131, 500 },\t/* c4 */\n\t{ 0, 250 },\t/* r8 */\n",

};
command {
    args   => [qw(multiply --factor=2 1 2 3)],
    stdout => "2 4 6\n",
};
command {
    args   => [qw(normal_form e g c)],
    stdout => "0,4,7\n",
};
command {
    args   => [qw(notes2time 1)],
    stdout => "4s\n",
};
command {
    args   => [qw(notes2time --ms --tempo=120 1)],
    stdout => "2000\n",
};
command {
    args   => [qw(notes2time --ms --tempo=160 c4*2/3 c c)],
    stdout => "250\n250\n250\n= 750\n",
};
command {
    args   => [qw(notes2time --fraction=2/3 c4. d8 e4)],
    stdout => "1s\n333ms\n666ms\n= 2s\n",
};
command {
    args   => [qw(pcs2forte 4 6 3 7)],
    stdout => "4-3\n",
};
command {
    args   => [qw(pcs2intervals 3 4 7)],
    stdout => "1,3\n",
};
command {
    args   => [qw(pitch2freq 60)],
    stdout => "60\t261.63\n",
};
# TODO need to check these numbers manually
command {
    args   => [qw(pitch2freq --cf=422.5 a)],
    stdout => "57\t211.25\n",
};
command {
    args   => [qw(pitch2intervalclass 4)],
    stdout => "4\n",
};
command {
    args   => [qw(pitch2intervalclass 8)],
    stdout => "4\n",
};
command {
    args   => [qw(pitch2ly 72)],
    stdout => "c''\n",
};
command {
    args   => [qw(prime_form 0 4 7)],
    stdout => "0,3,7\n",
};
command {
    args   => [qw(recipe --file=t/rules 0 11 3)],
    stdout => "4,8,7\n",
};
command {
    args   => [qw(retrograde 1 2 3)],
    stdout => "3,2,1\n",
};
command {
    args   => [qw(rotate --rotate=3 1 2 3 4)],
    stdout => "2,3,4,1\n",
};
command {
    args   => [qw(set2beats --scaledegrees=16 4-z15)],
    stdout => "xx..x.x.........\n",
};
command {
    args   => [qw(set_complex 0 2 7)],
    stdout => "0,2,7\n10,0,5\n5,7,0\n",
};
command {
    args => [qw(subsets 3-1)],
    # NOTE might false alarm if permutation module changes ordering; if
    # so, sort the output?
    stdout => "0,1\n0,2\n1,2\n",
};
command {
    args   => [qw(tcs 7-4)],
    stdout => "7 5 4 4 3 3 4 3 3 4 4 5\n",
};
command {
    args   => [qw(tcis 7-4)],
    stdout => "2 4 4 4 5 4 5 6 5 4 4 2\n",
};
command {
    args   => [qw(tension g b d f)],
    stdout => "1.000  0.100  0.700\t0.2,0.1,0.7\n",
};
command {
    args   => [qw(time2notes 1234)],
    stdout => "c4*123/100\n",
};
command {
    args   => [qw(transpose --transpose=7 0 6 11)],
    stdout => "7,1,6\n",
};
command {
    args   => [qw(transpose_invert --transpose=3 1 2 3)],
    stdout => "2,1,0\n",
};
command {
    args   => [qw(whatscalesfit c d e f g a b)],
    stdout =>
      "C  Major                     c     d     e     f     g     a     b\nD  Dorian                    d     e     f     g     a     b     c\nE  Phrygian                  e     f     g     a     b     c     d\nF  Lydian                    f     g     a     b     c     d     e\nG  Mixolydian                g     a     b     c     d     e     f\nA  Aeolian                   a     b     c     d     e     f     g\nB  Locrian                   b     c     d     e     f     g     a\nA  Melodic minor     DSC     g     f     e     d     c     b     a\n",
};

# custom tests that the old Test::Cmd code had trouble with

my ( $result, $status, $stdout, $stderr ) =
  command { args => [qw(fnums)], stdout => qr/^3-1\s+0,1,2\s+210000/ };
my $lines = 0;
$lines++ while $$stdout =~ m/^[3-9]-[1-9Z]/gm;
is( $lines, 208, 'forte numbers count' );

command {
    args   => [qw(--help)],
    stderr => qr/Usage: atonal-util/,
    status => 64,
};

command {
    args   => [qw(invariants 3-9)],
    stdout => qr/^T\(0\)\s+\[ 0,2,7\s+\] ivars \[ 0,2,7\s+\] 3-9/,
    stderr => qr/^\[0,2,7\] icc 010020/,
};

command {
    args   => [qw(variances)],
    stdin  => "5-1\n0 1 2 3 5\n",
    stdout => "0,1,2,3\n4,5\n0,1,2,3,4,5\n"
};

command {
    args   => [qw(zrelation)],
    stdin  => "8-z15\n0,1,2,3,5,6,7,9\n",
    stdout => "1\n"
};

command {
    args   => [qw(zrelation)],
    stdin  => "9-2\n0 1 2 3 4 5 6 8 9\n",
    stdout => "0\n"
};

done_testing 173
