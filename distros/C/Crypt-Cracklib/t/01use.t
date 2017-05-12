use Test::More tests => 22;

BEGIN { use_ok( 'Crypt::Cracklib' ); }

SKIP: {
    $username = getpwuid($<);
    skip "won't work unless username is longer", 1
    unless length($username) > 4;
    like(fascist_check($username.'1'), qr/username/, "username");
};

# it's WAY too short
like(fascist_check('bad'), qr/WAY/, "way too short");

# it is too short
ok(fascist_check('blah') eq 'it is too short', "too short");

# it does not contain enough DIFFERENT characters
like(fascist_check('aaaaaabb'), qr/DIFFERENT/, "not enough different");

# it is all whitespace
like(fascist_check(''), qr/whitespace/, "whitespace");

# it is too simplistic/systematic
like(fascist_check('abcdef'), qr/simplistic/, "simplistic");

# it is based on a dictionary word
like(fascist_check('dictionary'), qr/dictionary/, "dictionary");

# it is based on a (reversed) dictionary word
like(fascist_check('yranoitcid'), qr/dictionary/, "reversed dictionary");

# Ok
ok(fascist_check('Sil1ntBob') eq 'ok');
ok(fascist_check('N3veRGs$') eq 'ok');
ok(fascist_check('W1n$uckS') eq 'ok');
ok(fascist_check('PerL4eVr') eq 'ok');
ok(fascist_check('Neg@torY') eq 'ok');

# Ok - check wrapper
ok(!check('blah'));
ok(check('N3veRGs$'));
ok(!check('blather'));
ok(!check('begin'));
ok(check('Neg@torY'));

ok(bad_pass('bad'));
ok(bad_pass('') eq 'Password is all whitespace');
ok(bad_pass('Neg@torY') eq '');
