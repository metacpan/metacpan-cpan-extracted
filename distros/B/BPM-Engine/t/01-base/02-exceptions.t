use strict;
use warnings;
use Test::More;
use Test::Exception;

use BPM::Engine::Types 'Exception';
use BPM::Engine::Exceptions ':all'; # qw/throw_runner throw_model/;

my $e;

eval { BPM::Engine::Exception::Engine->throw( error => 'I feel funny.' ) };

eval { throw error => 'Basic error' };
$e = $@;
ok(is_Exception($e));

eval { throw_engine(error => "Engine error"); };
ok(is_Exception($@));
is($@, 'Engine error');

eval { throw_runner(error => "Runner error"); };

eval { throw_store(error => "Store error"); };
$e = Exception::Class->caught('BPM::Engine::Exception::Database');
isa_ok($e, 'BPM::Engine::Exception::Database');
isa_ok(BPM::Engine::Exception::Database->caught(), 'BPM::Engine::Exception::Database');

eval { throw_plugin error => "No strawberry", plugin => "SomePlugin"; };
isa_ok($@, 'BPM::Engine::Exception::Plugin');
$e = Exception::Class->caught('BPM::Engine::Exception::Plugin');
isa_ok($e, 'BPM::Engine::Exception::Plugin');

eval { throw_param error => "Param error"; };
isa_ok(BPM::Engine::Exception::Parameter->caught(), 'BPM::Engine::Exception::Parameter');

eval { throw_io error => "IO error"; };
ok($e = Exception::Class->caught());
isa_ok($e, 'BPM::Engine::Exception::IO');

eval { throw_model error => "Model error"; };
isa_ok($@, 'BPM::Engine::Exception::Model');

eval { throw_install error => "Installation error"; };
$e = Exception::Class->caught();
isa_ok($e, 'BPM::Engine::Exception::Install');

eval { throw_abstract error => "Method not implemented"; };
$e = Exception::Class->caught();
isa_ok($e, 'BPM::Engine::Exception::NotImplemented');

eval { throw_expression error => "Expression evaluator error"; };
$e = Exception::Class->caught();
isa_ok($e, 'BPM::Engine::Exception::Expression');

eval { $e->rethrow; };
ok(is_Exception($@));
isa_ok($@, 'BPM::Engine::Exception::Expression');

done_testing;
