#!perl
use strict;
use Test::More (tests => 26);
use Data::FormValidator;

BEGIN
{
    use_ok("Data::FormValidator::Constraints::Japanese");
}


my @ok_imode = (
    'foo@docomo.ne.jp',
);

my @ok_vodafone = (
    'foo@jp-d.ne.jp',
    'foo@d.vodafone.ne.jp',
);

my @ok_ezweb = (
    'foo@ezweb.ne.jp',
    'foo@hoge.ezweb.ne.jp',
);

my @ok = (
    @ok_imode,
    @ok_vodafone,
    @ok_ezweb,
    'foo@mnx.ne.jp',
    'foo@bar.mnx.ne.jp',
    'foo@dct.dion.ne.jp',
    'foo@sky.tu-ka.ne.jp',
    'foo@bar.sky.tkc.ne.jp',
    'foo@em.nttpnet.ne.jp',
    'foo@bar.em.nttpnet.ne.jp',
    'foo@pdx.ne.jp',
    'foo@dx.pdx.ne.jp',
    'foo@phone.ne.jp',
    'foo@bar.mozio.ne.jp',
    'foo@p1.foomoon.com',
    'foo@x.i-get.ne.jp',
    'foo@ez1.ido.ne.jp',
    'foo@cmail.ido.ne.jp',
);

my @not = (
    'foo@example.com',
    'foo@dxx.pdx.ne.jp',
    'barabr',
    'foo@a.vodafone.ne.jp',
);

my $dfv = Data::FormValidator->new('t/profile.pl');

for (@ok_ezweb) {
    my $rv = $dfv->check({ ezweb => $_ }, 'mobile_jp');
    ok(! $rv->has_invalid && ! $rv->has_missing && ! $rv->has_unknown);
}

for (@ok_imode) {
    my $rv = $dfv->check({ imode => $_ }, 'mobile_jp');
    ok(! $rv->has_invalid && ! $rv->has_missing && ! $rv->has_unknown);
}

for (@ok_vodafone) {
    my $rv = $dfv->check({ vodafone => $_ }, 'mobile_jp');
    ok(! $rv->has_invalid && ! $rv->has_missing && ! $rv->has_unknown);
}

for (@ok) {
    my $rv = $dfv->check({ mobile_jp => $_ }, 'mobile_jp');
    ok(! $rv->has_invalid && ! $rv->has_missing && ! $rv->has_unknown);
}

