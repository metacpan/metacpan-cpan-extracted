##-*- Mode: CPerl -*-
use Test::More tests=>8;
use DDC::Any ':none';
no warnings 'once';

##-- +8: pp
ok(DDC::Any->import(':pp'), 'import :pp');
my $qstr = 'Haus';
my ($q);
is($DDC::Any::WHICH, 'DDC::PP', 'import :pp - WHICH');
like(DDC::Any::library_version(), qr/^DDC::PP/, 'import :pp - library_version');
is(DDC::Any->can('NoSort'), DDC::PP->can('NoSort'), 'import :pp - NoSort coderef');
is(*DDC::Any::HitSortEnum, *DDC::PP::HitSortEnum, 'import :pp - HitSortEnum glob');
ok(defined($q=DDC::Any->parse($qstr)), 'import :pp - parse');
isa_ok($q, 'DDC::PP::CQuery',  'import :pp - $q');
isa_ok($q, 'DDC::Any::CQuery', 'import :pp - $q');
