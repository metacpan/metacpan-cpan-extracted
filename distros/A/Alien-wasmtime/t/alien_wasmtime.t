use Test2::V0 -no_srand => 1;
use FFI::Platypus 1.00;
use Test::Alien 1.90;
use Test::Alien::Diag;
use File::Which qw( which );
use Alien::wasmtime;

if($^O eq 'linux')
{
  if(which 'bash')
  {
    # call ulimit via bash in case
    # the user's shell is not bash.
    my($vm) = grep /virtual memory/, `bash -c 'ulimit -a'`;
    if(defined $vm)
    {
      chomp $vm;
      if($vm !~ /unlimited/)
      {
        diag " !! WARNING !! WARNING !!";
        diag " !! WARNING !! WARNING !!";
        diag " ";
        diag " ";
        diag "You seem to have a virtual address limit set.  This can cause";
        diag "problems with software like Wasmtime which use `PROT_NONE` pages";
        diag "for memory OOB checks or allocation";
        diag "Please see";
        diag "https://github.com/perlwasm/Wasm/issues/22";
        diag " ";
        diag " ";
        diag " !! WARNING !! WARNING !!";
        diag " !! WARNING !! WARNING !!";
      }
    }
    else
    {
      diag "unable to find virtual memory limit";
      diag "https://github.com/perlwasm/Wasm/issues/22";
    }
  }
  else
  {
    diag "unable to find bash, not checking virtual memory limits";
    diag "https://github.com/perlwasm/Wasm/issues/22";
  }
}


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


