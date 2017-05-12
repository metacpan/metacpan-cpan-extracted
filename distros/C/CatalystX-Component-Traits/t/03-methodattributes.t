use strict;
use warnings;
use Test::More;

unless (
    eval { require version; require MooseX::MethodAttributes; MooseX::MethodAttributes->VERSION('0.15'); }
) {
    plan skip_all => 'Need MooseX::MethodAttributes 0.15 for this test';
    exit;
}

plan tests => 4;

{
    package My::Role;
    use MooseX::MethodAttributes ();
    use Moose::Role -traits => 'MethodAttributes';

    sub foo : Action {}
}

{
    package My::Controller;
    use Moose;
    BEGIN { extends 'Catalyst::Controller'; }
    with 'CatalystX::Component::Traits';
}

my $app = bless {}, 'MyApp';
my $i = eval { My::Controller->COMPONENT($app, { traits => '+My::Role' } ) };
ok $i;
ok !$@ or warn $@;
my $meta = $i->meta;
ok $meta->can('get_method_attributes');
my $attr = $meta->get_method_attributes( $i->can('foo') );
is_deeply $attr, ['Action'];

