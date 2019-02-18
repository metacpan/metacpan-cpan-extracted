use Test2::V0 -no_srand => 1;
use Alt::FFI::Raw::Platypus;
use FFI::Raw;

subtest 'do not allow extensions' => sub {

  eval { FFI::Raw->attach };
  like $@, qr/attach not available for FFI::Raw interface/;

  eval { FFI::Raw->platypus };
  like $@, qr/platypus not available for FFI::Raw interface/;

};

done_testing
