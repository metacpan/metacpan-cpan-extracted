package Foo;
use strict; use warnings;
use parent 'Class::Accessor::Lazy';

__PACKAGE__->follow_best_practice
    ->original_accessors
    ->mk_accessors('rw_accessor')
    ->mk_ro_accessors('ro_accessor')
    ->mk_wo_accessors('wo_accessor')
    ->mk_lazy_accessors('rw_accessor_lazy')
    ->mk_lazy_ro_accessors('ro_accessor_lazy');

sub _lazy_init_rw_accessor_lazy
{
    my $self = shift;
    $self->{'rw_accessor_lazy'} = 'rw lazy init';
}

sub _lazy_init_ro_accessor_lazy
{
    my $self = shift;
    $self->{'ro_accessor_lazy'} = 'ro lazy init';
}

package Bar;
use strict; use warnings;
use parent 'Class::Accessor::Lazy';

__PACKAGE__->follow_best_practice
    ->fast_accessors
    ->mk_accessors('rw_accessor')
    ->mk_ro_accessors('ro_accessor')
    ->mk_wo_accessors('wo_accessor')
    ->mk_lazy_accessors('rw_accessor_lazy')
    ->mk_lazy_ro_accessors('ro_accessor_lazy');

sub _lazy_init_rw_accessor_lazy
{
    my $self = shift;
    $self->{'rw_accessor_lazy'} = 'rw lazy init';
}

sub _lazy_init_ro_accessor_lazy
{
    my $self = shift;
    $self->{'ro_accessor_lazy'} = 'ro lazy init';
}

package main;
use strict;
use warnings;

use Test::More 'tests' => 5;
BEGIN { use_ok('Class::Accessor::Lazy') };

my $data = {
    'rw_accessor' => 'rw_ok',
    'ro_accessor' => 'ro_ok',
    'wo_accessor' => 'wo_ok',
    'rw_accessor_lazy' => 'rw_ok_lazy',
    'ro_accessor_lazy' => 'ro_ok_lazy',
};

my $foo = Foo->new($data);
subtest "Original accessors, first instance" => sub{ test_instance($foo); };
my $foo2 = Foo->new($data);
subtest "Original accessors, second instance" => sub{ test_instance($foo2); };
my $bar = Bar->new($data);
subtest "Fast accessors, first instance" => sub{ test_instance($bar); };
my $bar2 = Bar->new($data);
subtest "Fast accessors, second instance" => sub{ test_instance($bar2); };

#done_testing();

sub test_instance
{
    my $self = shift;
    
    my $var = int(rand(1000));
    is( $self->get_rw_accessor(), 'rw_ok', 'RW inited in constructor');
    is( $self->get_ro_accessor(), 'ro_ok', 'RO inited in constructor');

    eval{ my $var = $self->get_wo_accessor(); };
    ok( $@ =~ /can't locate object method/i, 'Reading protection on WO accessor');
    
    eval{ my $var = $self->set_ro_accessor(++$var); };
    ok( $@ =~ /can't locate object method/i, 'Writing protection on RO accessor');
    
    eval{ my $var = $self->set_ro_accessor_lazy(++$var); };
    ok( $@ =~ /can't locate object method/i, 'Writing protection on RO lazy accessor');
    
    $self->set_rw_accessor(++$var);
    is( $self->get_rw_accessor, $var, 'Setting and getting rw accessor');

    is( $self->get_rw_accessor_lazy(), 'rw lazy init', 'RW lazy accessor init');
    $self->set_rw_accessor_lazy(++$var);
    is( $self->get_rw_accessor_lazy(), $var, 'RW lazy accessor init pass on second access');

    is( $self->get_ro_accessor_lazy(), 'ro lazy init', 'RO lazy accessor init');
    $self->{'ro_accessor_lazy'} = ++$var;
    is( $self->get_ro_accessor_lazy(), $var, 'RO lazy accessor init pass on second access');
 
    $self->set_wo_accessor(++$var);
    is( $self->{'wo_accessor'}, $var, 'WO accessor mutator');
}