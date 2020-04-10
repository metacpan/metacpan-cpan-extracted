use Test2::V0 -no_srand => 1;
use FFI::Platypus 1.00;
use Test::Alien 1.90;
use Test::Alien::Diag;
use Alien::wasmtime;

alien_ok 'Alien::wasmtime';
alien_diag 'Alien::wasmtime';

my @dll = Alien::wasmtime->dynamic_libs;
ok scalar(@dll), 'at least one dynamic library found';

ffi_ok
  {
    symbols => [ qw( wasm_engine_new wasm_engine_delete ) ],
    api => 1,
  },
  with_subtest {
    my($ffi) = @_;
    my $engine = $ffi->function( wasm_engine_new => [] => 'opaque' )->call;
    ok $engine;
    note "engine = $engine";
    $ffi->function( wasm_engine_delete => ['opaque'] => 'void' )->call($engine);
    ok 1;
  }
;

done_testing;


