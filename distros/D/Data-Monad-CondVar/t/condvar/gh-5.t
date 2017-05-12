use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent;
use Test::More;

my $cv = cv_unit()->sleep(.05);
my @ret = AnyEvent::CondVar->all(
  $cv->map(sub { 1 }),
  $cv->map(sub { 2 }),
)->timeout(3)->recv;

is_deeply(\@ret, [[1], [2]], 'map 2 times');

$cv = cv_unit(1)->sleep(.05);
@ret = AnyEvent::CondVar->all(
  $cv->or(cv_unit(2)),
  $cv->or(cv_unit(2)),
)->timeout(3)->recv;

is_deeply(\@ret, [[1], [1]], 'or 2 times');

$cv = cv_unit()->sleep(.05)->flat_map(sub { cv_fail('Fail') });
@ret = AnyEvent::CondVar->all(
  $cv->catch(sub { cv_unit(2) }),
  $cv->catch(sub { cv_unit(2) }),
)->timeout(3)->recv;

is_deeply(\@ret, [[2], [2]], 'catch 2 times');

$cv = cv_unit("OK")->sleep(.05);
@ret = AnyEvent::CondVar->all(
    $cv->map(sub { $_[0] x 2 }),
    cv_unit()->flat_map(sub { $cv }),
)->recv;

is_deeply \@ret, [["OKOK"], ["OK"]], 'Call cb() 2 times on inner flat_map';

$cv = cv_unit("OK")->sleep(.05);
@ret = AnyEvent::CondVar->all(
    $cv->map(sub { $_[0] x 2 }),
    cv_fail()->or($cv),
)->recv;

is_deeply \@ret, [["OKOK"], ["OK"]], 'Call cb() 2 times on inner or';

$cv = cv_unit("OK")->sleep(.05);
@ret = AnyEvent::CondVar->all(
    $cv->map(sub { $_[0] x 2 }),
    cv_fail()->catch(sub { $cv }),
)->recv;

is_deeply \@ret, [["OKOK"], ["OK"]], 'Call cb() 2 times on inner catch';

done_testing;
