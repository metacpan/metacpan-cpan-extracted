#!perl
use Test2::V0;
use Test2::Tools::Command;
local @Test2::Tools::Command::command = ( $^X, '--', './bin/vov' );

command {
    args   => [qw(I)],
    stdout => "c e g\n",
};
command {
    args   => [qw(I6)],
    stdout => "e g c\n",
};
command {
    args   => [qw(I64)],
    stdout => "g c e\n",
};
command {
    args   => [qw(--raw I)],
    stdout => "0 4 7\n",
};
command {
    args   => [qw(II)],
    stdout => "d fis a\n",
};
command {
    args   => [qw(--flats bII6)],
    stdout => "f aes des\n",
};
command {
    args   => [qw(--natural II)],
    stdout => "d f a\n",
};
command {
    args   => [qw(--minor --natural I)],
    stdout => "c dis g\n",
};
command {
    args   => [qw(--flats III)],
    stdout => "e aes b\n",
};
command {
    args   => [qw(V7)],
    stdout => "g b d f\n",
};
command {
    args   => [qw(V65)],
    stdout => "b d f g\n",
};
command {
    args   => [qw(V43)],
    stdout => "d f g b\n",
};
command {
    args   => [qw(V2)],
    stdout => "f g b d\n",
};
command {
    args   => [qw(--natural vii)],
    stdout => "b d f\n",
};
# XXX VII is tricky; this is what I intuit should happen without the
# --natural flag involved, though it does break out of the mode.
# XXX also must test inversions of VII and whatnot
command {
    args   => [qw(vii*)],
    stdout => "b d f\n",
};
#   args vii
#   stdout b d fis
#   args VII
#   stdout b dis fis
# XXX oh also bvii is bad, that diminishes itself, which I would only
# expect to happen to bvii*

# and now transpositions
command {
    args   => [qw(--transpose=g I)],
    stdout => "g b d\n",
};
command {
    args   => [qw(--transpose=7 I)],
    stdout => "g b d\n",
};
command {
    args   => [qw(--flats --transpose=g i)],
    stdout => "g bes d\n",
};
command {
    args   => [qw(--transpose=b --mode=locrian i)],
    stdout => "b d f\n",
};
command {
    args   => [qw(--transpose=b --mode=locrian II)],
    stdout => "c e g\n",
};
command {
    args   => [qw(--transpose=b --mode=locrian Vb)],
    stdout => "a c f\n",
};
command {
    args   => [qw(I V7/IV IV V)],
    stdout => "c e g\nc e g b\nf a c\ng b d\n",
};
command {
    args   => [qw(--factor=7 IV)],
    stdout => "f a c e\n",
};
command {
    args   => [qw(--outputtmpl=%{vov} I)],
    stdout => "I\n",
};
command {
    args   => [qw(--outputtmpl=x%{chord}x I13g)],
    stdout => "xa c e g b d fx\n",
};
command {
    args   => [qw(--flats i7**)],
    stdout => "c ees g bes\n",
};
command {
    args   => [qw(I+)],
    stdout => "c e gis\n",
};
command {
    args   => [qw(i*)],
    stdout => "c dis fis\n",
};

# XXX think about what I* would mean...major 3rd but dim 5th? or throw
# exception for unknown chord?

done_testing 84
