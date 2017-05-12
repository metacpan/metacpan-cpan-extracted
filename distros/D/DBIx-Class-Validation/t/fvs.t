#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use DBIC::Test tests => 17;
}

my $schema = DBIC::Test->init_schema;
my $row;

my $profile = [
	name => [ 'NOT_BLANK', ['LENGTH', 4, 10] ],
];

DBIC::Test::Schema::Test->validation_profile($profile);
Class::C3->reinitialize();

$row = eval{  $schema->resultset('Test')->create({name => ''}) };
isa_ok $@, 'FormValidator::Simple::Results', 'blank value not accepted';

$row = eval{ $schema->resultset('Test')->create({name => 'qwertyqwerty'}) };
isa_ok $@, 'FormValidator::Simple::Results', 'long string not accepted';

$row = eval{ $schema->resultset('Test')->create({name => 'qwerty'}) };
is $row->name, 'qwerty', 'valid data accepted';

# updates too
$row->name('food');
$row->update;
is $row->name, 'food', 'valid data accepted';

eval { $row->update({ name => "a" }) };
isa_ok $@, 'FormValidator::Simple::Results', '$row->update($fields) also goes through validation';

# without auto on update
$row->validation_auto(0);
$row->name('yo');
$row->update;
is $row->name, 'yo', 'validation is off';

## without auto on create
DBIC::Test::Schema::Test->validation_auto(0);
Class::C3->reinitialize();
$row = eval{ $schema->resultset('Test')->create({name => 'qwertyqwerty'}) };
is $row->name, 'qwertyqwerty', 'validation is off';

# validation changes all
DBIC::Test::Schema::Test->validation(
    module  => 'Validator',
    auto    => 2,
    filter => 3,
    profile => {name => 'NOT_BLANK'}
);
is(DBIC::Test::Schema::Test->validation_module, 'Validator');
is(DBIC::Test::Schema::Test->validation_auto, 2);
is(DBIC::Test::Schema::Test->validation_filter, 3);
is_deeply(DBIC::Test::Schema::Test->validation_profile, {name => 'NOT_BLANK'}), 

## things should stay the same
DBIC::Test::Schema::Test->validation();
is(DBIC::Test::Schema::Test->validation_module, 'Validator');
is(DBIC::Test::Schema::Test->validation_auto, 2);
is(DBIC::Test::Schema::Test->validation_filter, 3);
is_deeply(DBIC::Test::Schema::Test->validation_profile, {name => 'NOT_BLANK'}), 

eval {
    DBIC::Test::Schema::Test->validation_module('JunkFoo');
};
if ($@ && $@ =~ /unable to load the validation module/i) {
    pass;
} else {
    fail('throw exception when module fails to load');
};

eval {
    DBIC::Test::Schema::Test->validation_module('ValidatorWithoutCheck');
};
if ($@ && $@ =~ /does not support the check\(\) method/i) {
    pass;
} else {
    fail('throw exceptionb when module does not support check');
};
