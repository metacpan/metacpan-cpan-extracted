use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

choose

=usage

  choose('class');

=description

The choose function returns the configuration (plans) based on the argument passed.

=signature

choose(Str $arg1) : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'choose';

ok !Data::Object::Config::choose();

ok !Data::Object::Config::choose('Core');
ok !Data::Object::Config::choose('core');

ok !Data::Object::Config::choose(':Core');
ok !Data::Object::Config::choose(':core');

is_deeply Data::Object::Config::choose(':Class'), 'config_class';
is_deeply Data::Object::Config::choose(':Cli'), 'config_cli';
is_deeply Data::Object::Config::choose(':Role'), 'config_role';
is_deeply Data::Object::Config::choose(':Rule'), 'config_rule';
is_deeply Data::Object::Config::choose(':class'), 'config_class';
is_deeply Data::Object::Config::choose(':cli'), 'config_cli';
is_deeply Data::Object::Config::choose(':role'), 'config_role';
is_deeply Data::Object::Config::choose(':rule'), 'config_rule';

is_deeply Data::Object::Config::choose('Class'), 'config_class';
is_deeply Data::Object::Config::choose('Cli'), 'config_cli';
is_deeply Data::Object::Config::choose('Role'), 'config_role';
is_deeply Data::Object::Config::choose('Rule'), 'config_rule';
is_deeply Data::Object::Config::choose('class'), 'config_class';
is_deeply Data::Object::Config::choose('cli'), 'config_cli';
is_deeply Data::Object::Config::choose('role'), 'config_role';
is_deeply Data::Object::Config::choose('rule'), 'config_rule';

is_deeply Data::Object::Config::choose(':pl'), 'config_cli';
is_deeply Data::Object::Config::choose(':pm'), 'config_class';
is_deeply Data::Object::Config::choose('PL'), 'config_cli';
is_deeply Data::Object::Config::choose('PM'), 'config_class';
is_deeply Data::Object::Config::choose('pl'), 'config_cli';
is_deeply Data::Object::Config::choose('pm'), 'config_class';

ok 1 and done_testing;
