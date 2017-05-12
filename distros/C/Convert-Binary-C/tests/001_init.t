################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test::More tests => 29;

use constant SUCCEED => 1;
use constant FAIL    => 0;

#===================================================================
# try to require the modules (2 tests)
#===================================================================
require_ok('Convert::Binary::C');
require_ok('Convert::Binary::C::Cached');

#===================================================================
# check if we build the right object (4 tests)
#===================================================================
eval { $p = new Convert::Binary::C };
is($@, '', "create Convert::Binary::C object");
is(ref $p, 'Convert::Binary::C',
   "blessed Convert::Binary::C reference");

eval { $p = new Convert::Binary::C::Cached };
is($@, '', "create Convert::Binary::C::Cached object");
is(ref $p, 'Convert::Binary::C::Cached',
   "blessed Convert::Binary::C::Cached reference");

#===================================================================
# check initialization during construction (4 tests)
#===================================================================
eval {
  $p = new Convert::Binary::C PointerSize => 4,
                              EnumSize    => 4,
                              IntSize     => 4,
                              Alignment   => 2,
                              ByteOrder   => 'BigEndian',
                              EnumType    => 'Both';
};
is($@, '', "create Convert::Binary::C object with arguments");
is(ref $p, 'Convert::Binary::C',
   "blessed Convert::Binary::C reference");

@warn = ();
eval {
  local $SIG{__WARN__} = sub { push @warn, $_[0] };
  $p = new Convert::Binary::C::Cached Cache       => 'tests/cache.cbc',
                                      PointerSize => 4,
                                      EnumSize    => 4,
                                      IntSize     => 4,
                                      Alignment   => 2,
                                      ByteOrder   => 'BigEndian',
                                      EnumType    => 'Both';
};
is($@, '', "create Convert::Binary::C::Cached object with arguments");
is(ref $p, 'Convert::Binary::C::Cached',
   "blessed Convert::Binary::C::Cached reference");

if (@warn) {
  my $ok = 1;
  printf "# %d warning(s) issued:\n", scalar @warn;
  for (@warn) {
    diag($_);
    /Cannot load (?:Data::Dumper|IO::File), disabling cache at $0/
      or $ok = 0;
  }
  ok($ok, 'warnings');
}
else { pass('warnings') }

#===================================================================
# check unknown options in constructor (2 tests)
#===================================================================
eval {
  $p = new Convert::Binary::C FOO => 123, ByteOrder => 'BigEndian', BAR => ['abc'];
};
like($@, qr/Invalid option 'FOO' at \Q$0/);

eval {
  $p = new Convert::Binary::C::Cached FOO => 123, ByteOrder => 'BigEndian', BAR => ['abc'];
};
like($@, qr/Invalid option 'FOO' at \Q$0/);

#===================================================================
# check invalid construction (2 tests)
#===================================================================
eval {
  $p = new Convert::Binary::C FOO;
};
like($@, qr/Number of configuration arguments to new must be even at \Q$0/);

eval {
  $p = new Convert::Binary::C::Cached FOO;
};
like($@, qr/Number of configuration arguments to new must be even at \Q$0/);

#===================================================================
# check invalid construction (2 tests)
#===================================================================
eval {
  $p = new Convert::Binary::C ByteOrder => 'FOO';
};
like($@, qr/ByteOrder must be.*not 'FOO' at \Q$0/);

eval {
  $p = new Convert::Binary::C::Cached ByteOrder => 'FOO';
};
like($@, qr/ByteOrder must be.*not 'FOO' at \Q$0/);

#===================================================================
# check undefined feature (2 tests)
#===================================================================
eval {
  $p = Convert::Binary::C::feature('foobar');
};
is($@, '');
ok(not defined $p);

#===================================================================
# check calling feature as method (2 tests)
#===================================================================
eval {
  $p = new Convert::Binary::C;
  $p = $p->feature('debug');
};
is($@, '');
ok(defined $p);

#===================================================================
# check object corruption (8 tests)
#===================================================================
for my $class (qw(Convert::Binary::C Convert::Binary::C::Cached)) {
  eval { $p = $class->new };
  is($@, '');

  eval { $p->{''} = 0 };
  like($@, qr/^Modification of a read-only value attempted/);

  $tmp = delete $p->{''};

  eval { $p->clean };
  like($@, qr/THIS is corrupt/);

  $p->{''} = $tmp;

  $e = {'' => $tmp};
  bless $e, ref $p;

  eval { $e->clean };
  like($@, qr/THIS->hv is corrupt/);

  # don't forget to rebless to avoid warnings during cleanup
  bless $e, 'main';
}
