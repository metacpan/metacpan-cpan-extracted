#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);

use Test::More;
use Encode qw(decode encode);
use constant PLAN => 14;

BEGIN {
    if (eval "require Mouse; 1") {
        plan tests => PLAN;
    } else {
        plan skip_all => 'Module "Mouse" is not found';
    }
    use_ok 'DR::DateTime::MouseType';
}

eval <<eof;

package Tst;
use Mouse;
use DR::DateTime::MouseType;


has dt  => is => 'ro', isa => 'DRDateTime', coerce => 1;
has mdt => is => 'ro', isa => 'MaybeDRDateTime', coerce => 1;

__PACKAGE__->meta->make_immutable;

eof
diag $@ if $@;
package main;

my $now = time;
for my $o (new Tst dt => $now) {
    isa_ok $o->dt, DR::DateTime::, 'coerced from timestamp';

    is $o->dt->strftime('%F %T%z'),
        DR::DateTime->new($now)->strftime('%F %T%z'),
        'strftime';
}

for my $o (new Tst dt => DR::DateTime->new($now)->strftime('%F %T%z')) {
    isa_ok $o->dt, DR::DateTime::, 'coerced from string';

    is $o->dt->strftime('%F %T%z'),
        DR::DateTime->new($now)->strftime('%F %T%z'),
        'strftime';
}

for my $o (new Tst mdt => $now) {
    isa_ok $o->mdt, DR::DateTime::, '[Maybe] coerced from timestamp';

    is $o->mdt->strftime('%F %T%z'),
        DR::DateTime->new($now)->strftime('%F %T%z'),
        'strftime';
}

for my $o (new Tst mdt => DR::DateTime->new($now)->strftime('%F %T%z')) {
    isa_ok $o->mdt, DR::DateTime::, '[Maybe] coerced from string';

    is $o->mdt->strftime('%F %T%z'),
        DR::DateTime->new($now)->strftime('%F %T%z'),
        'strftime';
}

for my $o (new Tst mdt => undef) {
    is $o->mdt, undef, 'Maybe == undef';
}

ok !eval { new Tst dt => 'abc' }, 'wrong str';
like $@ => qr{Can't parse datetime.*abc}, 'error message';

ok !eval { new Tst mdt => 'cde' }, 'wrong str';
like $@ => qr{Can't parse datetime.*cde}, 'error message';
