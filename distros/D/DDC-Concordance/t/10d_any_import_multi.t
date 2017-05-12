##-*- Mode: CPerl -*-
use Test::More;
use DDC::Any qw(:none);
#use lib qw(blib/lib);
no warnings 'once';

if (!DDC::Any->have_xs()) {
  plan skip_all => 'DDC::XS '.($DDC::XS::VERSION ? "v$DDC::XS::VERSION is too old" : 'not available');
} else {
  plan tests => 4;
}

##-- +1: import none
is(DDC::Any->import(':none'), undef, 'import :none -> undef');

##-- +1: import xs
is(DDC::Any->import(':xs'), 'DDC::XS', 'import :xs -> DDC::XS');

##-- +1: import pp (+warning)
{
  my ($import_pp_rc,$import_pp_warning);
  local $SIG{__WARN__} = sub { $import_pp_warning=$_[0]; };
  eval { $import_pp_rc=DDC::Any->import(':pp'); };

  is($import_pp_rc, 'DDC::XS', 'import :pp -> DDC::XS');
  like($import_pp_warning, qr/ignoring user request/, 'import :pp - warning');
}
