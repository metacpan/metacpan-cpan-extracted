
use strict;
use warnings;

use Test::More tests => 47;

{
    package Dummy;
    use Abstract::Meta::Class ':all'; storage_type 'Array';
    has '$.x';
}

my $dummy = Dummy->new;
isa_ok($dummy, 'Dummy', 'should have a Dummy instance');
ok($dummy->can('x'), 'should have an accessor for x attribute');
ok($dummy->can('set_x'), 'should have a mutator for x attribute');
is($dummy->set_x(101), $dummy, 'should set a value');
is($dummy->x(101), '101', 'should get the value');


{
    package Dummy::Required;
    use Abstract::Meta::Class ':all'; storage_type 'Array';
    has '$.x' => (required => 1);
}

eval { Dummy::Required->new; };
like($@, qr/x is required/, 'should catch x is required attribute');
my $required = Dummy::Required->new(x => 1);
isa_ok($required, 'Dummy::Required', 'should have a Dummy::Required instance');

{
    package Dummy::Hash;
    use Abstract::Meta::Class ':all'; storage_type 'Array';
    has '%.xs' => (item_accessor => 'x', required => 1);
}

my $hash = Dummy::Hash->new(xs => {key1 => 1, key2 => 2});
isa_ok($hash, 'Dummy::Hash', 'should have a Dummy::Hash instance');
is($hash->x('key1'), 1, 'should have key1 value');
is($hash->x('key2'), 2, 'should have key2 value');


{
  package Dummy::Array;
  use Abstract::Meta::Class ':all'; storage_type 'Array';
  has '@.xs' => (item_accessor => 'x');
}

my $array = Dummy::Array->new(xs => [3, 2, 1]);
isa_ok($array, 'Dummy::Array', 'should have a Dummy::Array instance');
my $array_ref = $array->xs; # scalar context
is_deeply($array_ref, [3, 2, 1], 'should have xs attribute');
my @array = $array->xs; #list contect
is(@array, 3, 'should have 3 items');
is($array->x(0), 3, 'should have [0] value');
is($array->x(1), 2, 'should have [1] value');

is($array->count_xs, 3, 'should count');
is($array->push_xs(0,7), 5, 'should extent array by push');
is($array->x(4), 7, 'should have the last extended item');
is($array->pop_xs, 7, 'should pop item');
is($array->unshift_xs(5, 6), 6, 'should extent array by unshift');
is($array->x(0), 5, 'should have the first extended item');
is($array->shift_xs, 5, 'should shit item');
  

{
    package Dummy::Default;
    use Abstract::Meta::Class ':all'; storage_type 'Array';
    has '$.z' => (default => 0);
    has '$.x' => (default => 'x');
    has '%.h' => (default => {a => 1});
    has '@.a' => (default => [1, 2, 3], required => 1);
    has '&.c' => (required => 1);
    has '$.d' => (default => sub { 'stuff' } , required => 1);
}

my $default = Dummy::Default->new(c => sub {123});
isa_ok($default, 'Dummy::Default');

is($default->x, 'x', 'should have default for the x attribute');
is_deeply({$default->h}, {a => 1}, 'should have default for the h attribute');
is_deeply([$default->a], [1, 2, 3], 'should have default for the a attribute');
is($default->d, 'stuff', 'should have default for the x attribute');
is($default->z, 0, 'should have 0 as default value');
is($default->c->(), '123', 'should have code value');


{
    package Dummy::OnChange;
    use Abstract::Meta::Class ':all'; storage_type 'Array';

    has '$.a' => (
        on_change => sub {
            my ($self, $attribute, $scope, $value_ref) = @_;
            # validate
            # does not change anything if return false
            return !! 0;
        },
    );

    my $x_value;
    my $x_attribute;
    my $x_scope;

    my $x_attr = has '$.x' => (
        on_change => sub {
            my ($self, $attribute, $scope, $value_ref) = @_;
            $x_value = $$value_ref;
            $x_attribute = $attribute;
            $x_scope = $scope;
            $self;
        },
    );

    my $y_value;
    my $y_attribute;
    my $y_scope;
    my $y_index;
    my $y_attr = has '@.y' => (
        on_change => sub {
            my ($self, $attribute, $scope, $value_ref, $index) = @_;
            $y_value = $$value_ref;
            $y_attribute = $attribute;
            $y_scope = $scope;
            $y_index = $index;
            $self;
        },
        item_accessor => 'y_item'
    );

    my $z_value;
    my $z_attribute;
    my $z_scope;
    my $z_key;
    my $z_attr = has '%.z' => (
        on_change => sub {
            my ($self, $attribute, $scope, $value, $key) = @_;
            $z_value = $$value;
            $z_attribute = $attribute;
            $z_scope = $scope;
            $z_key = $key;
            $self;
        },
        item_accessor => 'z_value'
    );
    
    my $on_change = Dummy::OnChange->new;
    ::isa_ok($on_change, 'Dummy::OnChange', 'should have a Dummy::OnChange instance');
    $on_change->x(100);
    ::is_deeply([100, 'mutator', $x_attr], [$x_value, $x_scope, $x_attribute], 'should trigger on change for scalar');

    $on_change->y(['1', '2', '3']);
    ::is_deeply([['1', '2', '3'], 'mutator', $y_attr], [$y_value, $y_scope, $y_attribute], 'should trigger on change for array');

    $on_change->y_item(1, 20);
    ::is_deeply([20, 'item_accessor', $y_attr, 1], [$y_value, $y_scope, $y_attribute, $y_index], 'should trigger on change for array by item accessor');

    $on_change->z({ a => '1'});
    ::is_deeply([{ a => '1'}, 'mutator', $z_attr], [$z_value, $z_scope, $z_attribute], 'should trigger on change for hash');

    $on_change->z_value( b => '10');
    ::is_deeply([10, 'item_accessor', $z_attr, 'b'], [$z_value, $z_scope, $z_attribute, $z_key], 'should trigger on change for hash');
    ::is_deeply({ a => '1', b => 10}, {$on_change->z}, 'should have modyfied hash');
    
    $on_change->set_a('100');
    ::ok(! $on_change->a, 'should not change a attribute');
}



{
    package Transistent;
    use Abstract::Meta::Class ':all'; storage_type 'Array';
    has '$.x' => (required => 1);
    has '$.t' => (transistent => 3);
    has '%.th' => (transistent => 1, item_accessor => 'item_t');
    has '@.ta' => (transistent => 1);
    
    my $obj = Transistent->new(x => 1, t => 2, th => {a => 1, b => 2}, ta => [1,2]);
    ::ok(@$obj == 1, 'should have only x stored in object');
    ::is($obj->t, 2, 'should have value for t');
    
    ::is($obj->item_t('a'), '1', 'should have 1');
    ::is($obj->item_t('b'), '2', 'should have 2');
    
    $obj->cleanup;
    ::is($obj->t, undef, 'should not have value for t after cleanup method was called');

}   



{
    package DynamicInterceptor;
    use Abstract::Meta::Class ':all'; storage_type 'Array';

    my %access_log;
    has '%.attrs' => (
        on_read => sub {
            my ($self, $attribute, $scope, $key) = @_;
            my $values = $attribute->get_value($self);
            $access_log{$scope}++;
            
            if ($scope eq 'accessor') {
                return $values;
            } else {
                return $values->{$key};
            }
        },
        item_accessor => 'attr'
    );
    
    my $attr = DynamicInterceptor->meta->attribute('attrs'); 
    my $code_ref = $attr->on_read;
    my $obj = DynamicInterceptor->new(attrs => {a => 1, b => 2});
    
    my $a = $obj->attr('a');
 
    my %hook_access_log;
    my $ncode_ref = sub {
        my ($self, $attribute, $scope, $key) = @_;
        $hook_access_log{$scope}++;
        #do some stuff
        $code_ref->($self, $attribute, $scope, $key);
    };
    
    
    $attr->set_on_read($ncode_ref);
    
    my $b = $obj->attr('b');
    ::is_deeply(\%access_log, {item_accessor => 2, accessor => 2}, 'should have updated access log');
    ::is_deeply(\%hook_access_log, {item_accessor => 1, accessor => 1}, 'should have updated hook_access_log');
}


{
    package StorageKey;
    use Abstract::Meta::Class ':all'; storage_type 'Array';
    has '$.x' => (required => 1, storage_key => 'x');
    has '@.y' => (required => 1, storage_key => 'y');
    
    my $obj = StorageKey->new(x => 1, y => [1,2]);
    ::is_deeply($obj, [1, [1,2]], 'should have storage key');
}

{
    package Validate;
    use Abstract::Meta::Class ':all'; storage_type 'Array';
    my $attr = has '$.x' => (on_validate => sub {
        
    });
    $attr->set_on_validate(
        sub {
            my ($self, $attribute, $scope, $value) = @_;
            die 'invalid value' if($$value ne 1);
        }
    );
    eval {
        Validate->new(x => 2);
    };
    ::like($@, qr{invalid value}, 'should validate');
    ::isa_ok(Validate->new(x => 1), 'Validate');
}