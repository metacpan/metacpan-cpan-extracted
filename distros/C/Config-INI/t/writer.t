#!perl

use strict;

use Test::More tests => 20;

my $R = 'Config::INI::Reader';
my $W = 'Config::INI::Writer';

use_ok($_) for $R, $W;

my $data = {
  _ => {
    a => 1,
    b => 2,
    c => 3,
  },
  foo => {
    bar  => 'baz',
    baz  => 'bar',
  },
};

is_deeply(
  $R->read_string($W->write_string($data)),
  $data,
  'we can round-trip hashy data',
);

is_deeply(
  $R->read_string($W->new->write_string($data)),
  $data,
  'we can round-trip hashy data, object method',
);

my $starting_first = [
  _ => [
    a => 1,
    b => 2,
    c => 3,
  ],
  foo => [
    bar  => 'baz',
    baz  => 'bar',
    quux => undef,
  ],
];

my $expected = <<'END_INI';
a = 1
b = 2
c = 3

[foo]
bar = baz
baz = bar
END_INI

is(
  $W->write_string($starting_first),
  $expected,
  'stringifying AOA, _ first',
);

is(
  $W->new->write_string($starting_first),
  $expected,
  'stringifying AOA, _ first, object method',
);

{
  my $expected = <<'END_INI';
[foo]
bar = baz
baz = bar

[_]
a = 1
b = 2
c = 3

[foo]
fer = agin
END_INI

  my $starting_later = [
    foo => [
      bar  => 'baz',
      baz  => 'bar',
      quux => undef,
    ],
    _ => [
      a => 1,
      b => 2,
      c => 3,
    ],
    foo => [
      fer => 'agin',
    ],
  ];

  is(
    $W->write_string($starting_later),
    $expected,
    'stringifying AOA, _ later',
  );

  is(
    $W->new->write_string($starting_later),
    $expected,
    'stringifying AOA, _ later, object method',
  );
}

{
  my @possibilities = (
    [ a => [ b => 1 ] ],
    [ a => { b => 1 } ],
    { a => { b => 1 } },
    { a => [ b => 1 ] },
  );

  my $reference = $W->write_string(shift @possibilities);
  my $failures  = 0;
  $failures++ unless $W->write_string(shift @possibilities) eq $reference;

  ok(!$failures, "all array/hash combinations seem miscible");
}

eval { $W->write_string([ A => [ B => 1 ], A => [ B => 2 ] ]); };
like($@, qr/multiple/, "you can't set property B in section A more than once");

SKIP: {
  eval "require File::Temp;" or skip "File::Temp not availabe", 3;

  # This could probably be limited to being required for Cygwin.
  eval "require filetest;"   or skip "filetest.pm not available", 3;
  filetest->import('access');

  my ($fh, $fn) = File::Temp::tempfile('tempXXXXX', UNLINK => 1);
  close $fh;
  unlink $fn;

  $W->write_file($data, $fn);

  is_deeply(
    $R->read_file($fn),
    $data,
    "round-trip data->file->data",
  );

  my $new_data = { foo => { a => 1, b => 69101 } };
  $W->write_file($new_data, $fn);

  is_deeply(
    $R->read_file($fn),
    $new_data,
    "round-trip data->file->data, clobbering file",
  );

  chmod 0444, $fn;
  
  if (-w $fn) {
    chmod 0666, $fh;
    skip "chmoding file 0444 left it -w", 1;
  }

  eval { Config::INI::Writer->write_file($data, $fn); };
  like($@, qr/couldn't write/, "can't clobber an unwriteable file");

  chmod 0666, $fh;
}

eval { $W->write_file($data); };
like($@, qr/no filename/, "you can't set write to a file without a filename");

eval { $W->write_file($data, 't'); };
like($@, qr/not a plain file/, "you can't write to a file that's -e -d");

eval { $W->write_string(sub { 1 }) };
like($@, qr/can't output CODE/, "you can't write out non-ARRAY/HASH data");

eval { $W->write_string({ "[=]" => { a => 1 } }) };
is($@, '', "a stupid section header ([=]) is allowed");

eval { $W->write_string({ "[\n]" => { a => 1 } }) };
like($@, qr/illegal/, "...but an impossible to parse one is not");

eval { $W->write_string({ "[foo ;bar]" => { a => 1 } }) };
like($@, qr/illegal/, "...we also can't emit things that would be comments");

eval { $W->write_string({ "[foo;bar]" => { a => 1 } }) };
is($@, '', "...but things -almost- like comments are okay");
