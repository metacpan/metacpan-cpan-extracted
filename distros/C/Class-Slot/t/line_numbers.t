BEGIN{ $ENV{CLASS_SLOT_NO_XS} = 1 };

package Class_A;
use Class::Slot;
use Scalar::Util qw(looks_like_number);
slot 'x', def => sub{ my ($pkg, $file, $line) = caller; return [$line, $file] };
slot 'y' => \&looks_like_number, req => 1, rw => 1;
1;


package main;
use Test2::V0;
use Carp;

no warnings 'once';

subtest 'default function' => sub{
  local $Carp::Verbose = 1;
  my $obj = Class_A->new(y => 1);
  is $obj->x, [6, 't/line_numbers.t'], 'default function preserves line number';
};

subtest 'attempt to set protected field' => sub{
  local $Carp::Verbose = 1;
  my $err_line = __LINE__; eval{ Class_A->new(y => 1)->x(42) }; # croaks because slot x is read-only
  my $err = $@;

  like $err, qr{Class_A::x is protected at t/line_numbers\.t line 6}, 'stack trace contains location of slot def'
    or diag $err;

  like $err, qr{at t/line_numbers\.t line $err_line}, 'stack trace containers location of caller'
    or diag $err;
};

subtest 'missing required slot' => sub{
  local $Carp::Verbose = 1;
  my $err_line = __LINE__; eval{ Class_A->new };
  my $err = $@;

  like $err, qr{y is a required field at t/line_numbers\.t line 7}, 'stack trace contains location of slot def'
    or diag $err;

  like $err, qr{called at t/line_numbers\.t line $err_line}, 'stack trace contains location of caller'
    or diag $err;
};

subtest 'fails type check in ctor' => sub{
  local $Carp::Verbose = 1;
  my $err_line = __LINE__; eval{ Class_A->new(y => 'not a number') };
  my $err = $@;

  like $err, qr{Class_A::y did not pass validation as type \(anon code type\) at t/line_numbers\.t line 7}, 'stack trace contains location of slot def'
    or diag $err;

  like $err, qr{called at t/line_numbers\.t line $err_line}, 'stack trace contains location of caller'
    or diag $err;
};

subtest 'fails type check in setter' => sub{
  local $Carp::Verbose = 1;
  my $err_line = __LINE__; eval{ Class_A->new(y => 42)->y('not a number') };
  my $err = $@;

  like $err, qr{Class_A::y did not pass validation as type \(anon code type\) at t/line_numbers\.t line 7}, 'stack trace contains location of slot def'
    or diag $err;

  like $err, qr{called at t/line_numbers\.t line $err_line}, 'stack trace contains location of caller'
    or diag $err;

};

done_testing;
