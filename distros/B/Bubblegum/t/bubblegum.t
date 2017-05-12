BEGIN {
    @ARGV = qw(føø bar bāz);
}

use Bubblegum;
use Test::More;

is_deeply \@ARGV, [qw(føø bar bāz)],
    'utf8::all effects observed';

ok $INC{'Bubblegum.pm'},
    'Bubblegum loaded';

ok $INC{'Bubblegum/Constraints.pm'},
    'Bubblegum::Constraints loaded';

ok $INC{'Bubblegum/Role.pm'},
    'Bubblegum::Role loaded';

ok $INC{'Bubblegum/Role/Configuration.pm'},
    'Bubblegum::Role::Configuration loaded';

ok $INC{'Bubblegum/Object/Number.pm'},
    'Bubblegum::Object::Number loaded';

ok $INC{'Bubblegum/Object/Scalar.pm'},
    'Bubblegum::Object::Scalar loaded';

ok $INC{'Bubblegum/Object/Instance.pm'},
    'Bubblegum::Object::Instance loaded';

ok $INC{'Bubblegum/Object/Hash.pm'},
    'Bubblegum::Object::Hash loaded';

ok $INC{'Bubblegum/Object/Array.pm'},
    'Bubblegum::Object::Array loaded';

ok $INC{'Bubblegum/Object/String.pm'},
    'Bubblegum::Object::String loaded';

ok $INC{'Bubblegum/Object/Integer.pm'},
    'Bubblegum::Object::Integer loaded';

ok $INC{'Bubblegum/Object/Universal.pm'},
    'Bubblegum::Object::Universal loaded';

ok $INC{'Bubblegum/Object/Float.pm'},
    'Bubblegum::Object::Float loaded';

ok $INC{'Bubblegum/Object/Code.pm'},
    'Bubblegum::Object::Code loaded';

ok $INC{'Bubblegum/Object/Undef.pm'},
    'Bubblegum::Object::Undef loaded';

ok $INC{'Bubblegum/Object/Role/Coercive.pm'},
    'Bubblegum::Object::Role::Coercive loaded';

ok $INC{'Bubblegum/Object/Role/Ref.pm'},
    'Bubblegum::Object::Role::Ref loaded';

ok $INC{'Bubblegum/Object/Role/List.pm'},
    'Bubblegum::Object::Role::List loaded';

ok $INC{'Bubblegum/Object/Role/Defined.pm'},
    'Bubblegum::Object::Role::Defined loaded';

ok $INC{'Bubblegum/Object/Role/Item.pm'},
    'Bubblegum::Object::Role::Item loaded';

ok $INC{'Bubblegum/Object/Role/Comparison.pm'},
    'Bubblegum::Object::Role::Comparison loaded';

ok $INC{'Bubblegum/Object/Role/Keyed.pm'},
    'Bubblegum::Object::Role::Keyed loaded';

ok $INC{'Bubblegum/Object/Role/Value.pm'},
    'Bubblegum::Object::Role::Value loaded';

ok $INC{'Bubblegum/Object/Role/Indexed.pm'},
    'Bubblegum::Object::Role::Indexed loaded';

ok $INC{'Bubblegum/Object/Role/Collection.pm'},
    'Bubblegum::Object::Role::Collection loaded';

ok !$INC{'Bubblegum/Wrapper/Digest.pm'},
    'Bubblegum::Wrapper::Digest is not loaded';

ok !$INC{'Bubblegum/Wrapper/Dumper.pm'},
    'Bubblegum::Wrapper::Dumper is not loaded';

ok !$INC{'Bubblegum/Wrapper/Encoder.pm'},
    'Bubblegum::Wrapper::Encoder is not loaded';

ok !$INC{'Bubblegum/Wrapper/Json.pm'},
    'Bubblegum::Wrapper::Json is not loaded';

ok !$INC{'Bubblegum/Wrapper/Yaml.pm'},
    'Bubblegum::Wrapper::Yaml is not loaded';

ok ''->digest,  'Bubblegum::Wrapper::Digest invoked';
ok []->dumper,  'Bubblegum::Wrapper::Dumper invoked';
ok ''->encoder, 'Bubblegum::Wrapper::Encoder invoked';
ok []->json,    'Bubblegum::Wrapper::Json invoked';
ok []->yaml,    'Bubblegum::Wrapper::Yaml invoked';

ok $INC{'Bubblegum/Wrapper/Digest.pm'},
    'Bubblegum::Wrapper::Digest is loaded';

ok $INC{'Bubblegum/Wrapper/Dumper.pm'},
    'Bubblegum::Wrapper::Dumper is loaded';

ok $INC{'Bubblegum/Wrapper/Encoder.pm'},
    'Bubblegum::Wrapper::Encoder is loaded';

ok $INC{'Bubblegum/Wrapper/Json.pm'},
    'Bubblegum::Wrapper::Json is loaded';

ok $INC{'Bubblegum/Wrapper/Yaml.pm'},
    'Bubblegum::Wrapper::Yaml is loaded';

ok ! main->can($_), "method ($_) not found"
    for qw(after around before has does extends meta requires with);

done_testing;
