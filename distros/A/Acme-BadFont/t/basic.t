use strict;
use warnings;
use Test::More;

my @warnings;
{
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  eval '#line '.(__LINE__+1).' "'.__FILE__.q{"
    use Acme::BadFont;
    cmp_ok "1OO" + 1, '==', 0+"I0I";
    cmp_ok "I.S" * 2, '==', 0+"E";
    1;
  } or die $@;
}
is join('', @warnings), '', 'no warnings';

done_testing;
