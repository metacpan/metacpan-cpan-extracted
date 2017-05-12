use strict;
use Test::More (tests => 13);

BEGIN
{
    use_ok("Data::ResourceSet");
}

{
    my $resources = Data::ResourceSet->new({
        resources => {
            fogbaz => {
                foo => bless {}, "SampleResource"
            },
            frobnitz => {
                bar => bless {}, "SampleResource"
            },
        }
    });

    ok($resources);
    isa_ok($resources, 'Data::ResourceSet');

    my $foo = $resources->resource('fogbaz', 'foo');
    ok($foo, 'type fogbaz, name foo');
    isa_ok($foo, 'SampleResource');
}

{
    my $resources = Data::ResourceSet->new({
        resources_config => {
            fogbaz => {
                foo => {
                    module => '+SampleResource',
                    args => { whee => 1 },
                }
            },
        }
    });

    ok($resources);
    isa_ok($resources, 'Data::ResourceSet');

    my $foo = $resources->resource('fogbaz', 'foo');
    ok($foo, 'type fogbaz, name foo');
    isa_ok($foo, 'SampleResource');
}

{
    my $resources = Data::ResourceSet->new({
        resources_config => {
            fogbaz => {
                foo => {
                    module => 'Adaptor',
                    args => {
                        args   => { whee => 1 },
                        class  => 'SampleResource',
                    }
                }
            },
        }
    });

    ok($resources);
    isa_ok($resources, 'Data::ResourceSet');

    my $foo = $resources->resource('fogbaz', 'foo');
    ok($foo, 'type fogbaz, name foo');
    isa_ok($foo, 'SampleResource');
}

package
    SampleResource;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors($_) for qw(whee);

1;
