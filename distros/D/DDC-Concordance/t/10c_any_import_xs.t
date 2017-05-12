##-*- Mode: CPerl -*-
use Test::More;
use DDC::Any qw(:none);
#use lib qw(blib/lib);
no warnings 'once';

if (!DDC::Any->have_xs()) {
  plan skip_all => 'DDC::XS '.($DDC::XS::VERSION ? "v$DDC::XS::VERSION is too old" : 'not available');
} else {
  plan tests => 8;
}

##-- +8: xs
ok(DDC::Any->import(':xs'), 'import :xs');
my $qstr = 'Haus';
my ($q);
is($DDC::Any::WHICH, 'DDC::XS', 'import :xs - WHICH');
like(DDC::Any::library_version(), qr/^DDC::XS/, 'import :xs - library_version');
is(DDC::Any->can('NoSort'), DDC::XS->can('NoSort'), 'import :xs - NoSort coderef');
is(*DDC::Any::HitSortEnum, *DDC::XS::HitSortEnum, 'import :xs - HitSortEnum glob');
ok(defined($q=DDC::Any->parse($qstr)), 'import :xs - parse');
isa_ok($q, 'DDC::XS::CQuery',  'import :xs - $q');
isa_ok($q, 'DDC::Any::CQuery', 'import :xs - $q');
