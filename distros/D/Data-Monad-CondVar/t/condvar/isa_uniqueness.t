use strict;
use warnings;
use AnyEvent;
use Test::More;

sub is_unique(@) {
    my %isnt_unique;
    $isnt_unique{$_}++ && do {diag "duplicated: $_"; return} for @_;
    return 1;
}

{
    local $SIG{__WARN__} = sub {}; # suppress worning
    require Data::Monad::CondVar;
    delete $INC{"Data/Monad/CondVar.pm"};
    require Data::Monad::CondVar;
}

ok is_unique @AnyEvent::CondVar::ISA;

done_testing;
