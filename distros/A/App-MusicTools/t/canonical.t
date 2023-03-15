#!perl
use Test2::V0;
use Test2::Tools::Command;
local @Test2::Tools::Command::command = ( $^X, '--', './bin/canonical' );

command {
    args   => [qw(--relative=c exact --transpose=7 0 4 7)],
    stdout => "g b d\n",
};
command {
    args   => [qw(exact --transpose=7 c e g)],
    stdout => "g b d'\n",
};
command {
    args   => [qw(exact --transpose=g c e g)],
    stdout => "g b d'\n",
};
command {
    args   => [qw(--raw exact --transpose=g c e g)],
    stdout => "55 59 62\n",
};
command {
    args   => [qw(--relative=c exact --contrary c f g e a c)],
    stdout => "c g f gis dis c\n",
};
command {
    args   => [qw(--raw exact --retrograde 1 2 3)],
    stdout => "3 2 1\n",
};
command {
    args   => [qw(--flats exact --transpose=1 c e g)],
    stdout => "des f aes\n",
};

# modal tests - mostly just copied from Music-Canon/t/Music-
# Canon.t cases.
command {
    args   => [qw(--relative=c modal --contrary  0 13)],
    stdout => "c x\n",
};
command {
    args   => [qw(--relative=c modal --contrary --undef=q 0 8)],
    stdout => "c q\n",
};
command {
    args => [qw(modal --contrary --retrograde --raw 0 2 4 5 7 9 11 12 14 16 17 19)],
    stdout => "-19 -17 -15 -13 -12 -10 -8 -7 -5 -3 -1 0\n",
};
command {
    args => [
        qw(--rel=c modal --flats --sp=c --ep=bes), "--output=1,4,1,4", qw(c cis d)
    ],
    stdout => "bes x b\n",
};
command {
    args => [
        qw(--rel=c modal --flats --sp=c --ep=aes), "--output=2,1,4,1", qw(c cis d)
    ],
    stdout => "aes a bes\n",
};
command {
    args =>
      [ qw(--rel=c modal --flats --sp=c --ep=b), "--output=4,1,4,2", qw(c cis d) ],
    stdout => "b des ees\n",
};
command {
    args => [
        qw(--rel=c modal --chrome=-1 --flats --sp=c --ep=b),
        "--output=4,1,4,2", qw(c cis d)
    ],
    stdout => "b c ees\n",
};
command {
    args => [
        qw(--rel=c modal --chrome=1 --flats --sp=c --ep=b),
        "--output=4,1,4,2", qw(c cis d)
    ],
    stdout => "b d ees\n",
};
# rhythmic foo
command {
    args => [
        qw(--rel=c modal --chrome=1 --flats --sp=c --ep=b),
        "--output=4,1,4,2", qw(c8.. cis32 d4)
    ],
    stdout => "b8.. d32 ees4\n",
};
command {
    args   => [qw(--relative=c modal --retrograde c16 d8. e4 f g)],
    stdout => "g4 f e d8. c16\n",
};
# transpositions tricky
command {
    args => [qw(modal --transpose=3 --flats --input=minor --output=minor g f ees)],
    stdout => "bes a g\n",
};

# only the first column is considered when the notes arrive via stdin
# (this allows the subsequent columns to bear other data, such as
# lyrics, cat photos, etc). multicolumn output will also be enabled if
# the --map flag is used

# either "no remaining arguments" or "ultimate argument is a -"
# should be supported
command {
    args =>
      [ qw(--rel=c modal --chrome=1 --flats --sp=c --ep=b), "--output=4,1,4,2" ],
    stdin  => join( "\n", qw{c cis d} ) . "\n",
    stdout => "b\nd\nees\n",
};
command {
    args => [
        qw(modal --rel=c --chrome=1 --flats --sp=c --ep=b),
        "--output=4,1,4,2", '-'
    ],
    stdin  => join( "\n", qw{c cis d} ) . "\n",
    stdout => "b\nd\nees\n",
};
# if multicolumn, not-first-column data should be unchanged
command {
    args   => [qw(exact --transpose=c)],
    stdin  => join( "\n", "0 4. f", "2 8 p", "4 4 ff" ) . "\n",
    stdout => "c 4. f\nd 8 p\ne 4 ff\n",
};
command {
    args   => [qw(exact --transpose=c --retrograde)],
    stdin  => join( "\n", "0 4. f", "2 8 p", "4 4 ff" ) . "\n",
    stdout => "e 4 ff\nd 8 p\nc 4. f\n",
};
# Hindemith overtone ordering in G for something more complicated
command {
    args  => [qw(--relative=g --contrary --retrograde exact)],
    stdin => join( "\n",
        "g", "d'", "c", "e", "b", "bes", "ees", "a,", "f'", "aes,", "fis'", "cis" )
      . "\n",
    stdout => "cis\ngis\nfis'\na,\nf'\nb,\ne\ndis\nais\nd\nc\ng'\n",
};
# and also rhythmic alterations!
command {
    args  => [qw(--relative=g --contrary --retrograde exact)],
    stdin => join( "\n",
        "g4",  "d'8.", "c16", "e4",   "b",    "bes",
        "ees", "a,",   "f'",  "aes,", "fis'", "cis" )
      . "\n",
    stdout => "cis4\ngis\nfis'\na,\nf'\nb,\ne\ndis\nais\nd16\nc8.\ng'4\n",
};
# Caught mapping
command {
    args =>
      [qw(--map modal --contrary --retrograde --raw 0 2 4 5 7 9 11 12 14 16 17 19)],
    stdout =>
      "0 -19\n2 -17\n4 -15\n5 -13\n7 -12\n9 -10\n11 -8\n12 -7\n14 -5\n16 -3\n17 -1\n19 0\n",
};

command {
    args   => [qw(--help)],
    stderr => qr/^Usage/,
    status => 64,
};
command {
    args   => [qw(exact --help)],
    stderr => qr/^Usage/,
    status => 64,
};
command {
    args   => [qw(modal --help)],
    stderr => qr/^Usage/,
    status => 64,
};
command {
    args   => [qw(exact)],
    stdin  => "\n",
    stderr => qr/no notes/,
    status => 65,
};
command {
    args   => [qw(modal)],
    stdin  => "\n",
    stderr => qr/no notes/,
    status => 65,
};

done_testing 90
