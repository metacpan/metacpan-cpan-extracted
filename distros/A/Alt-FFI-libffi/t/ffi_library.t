use strict;
use warnings;
use Test::More;
use FFI::Library;
use FFI::CheckLib qw( find_lib_or_die );

my $testlibfile = find_lib_or_die( lib => "test", libpath => "t/ffi/_build" );

subtest 'bad input' => sub {

  eval { FFI::Library->new };
  is $@, '', 'this... strangely... works.';

  my $usage = 'Usage: $lib = FFI::Library->new($filename [, $flags ])';
  eval { FFI::Library->new(1,2,3) };
  like $@, qr/\Q$usage\E/, 'usage with no dll';

  is( FFI::Library->new('bogus.so'), undef, 'returns undef with bogus dll' );

  done_testing;
};

subtest 'basic' => sub {
  my $lib = FFI::Library->new($testlibfile);
  isa_ok $lib, 'FFI::Library';

  is $lib->address('f1'), undef, 'address of bad symbol is undef';

  eval { $lib->function('f1', 'cCC') };
  like $@, qr/Unknown function f1/, 'error for unknown function';

  isnt $lib->address('f0'), undef, 'address of good symbol is not undef';

  my $f0 = $lib->function('f0', 'cCC');
  ok($0, "f0 is defined");

  is($f0->(42), 42, "f0(42) = 42");

  done_testing;
};

subtest 'call exe functions' => sub {
  my $lib = FFI::Library->new(\$0);
  isa_ok $lib, 'FFI::Library';

  eval { $lib->function('bogus', 'cCC') };
  like $@, qr/Unknown function bogus/;

  my $strlen = $lib->function('strlen', 'cIp');
  ok($strlen, "strlen is defined");

  is($strlen->("foo"), 3, "strlen of foo is 3");

  done_testing;
};

done_testing;
