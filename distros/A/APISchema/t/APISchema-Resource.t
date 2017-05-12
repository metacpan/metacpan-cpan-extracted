package t::APISchema::Resource;
use t::test;

sub _require : Test(startup => 1) {
    my ($self) = @_;

    use_ok 'APISchema::Resource';
}

sub instantiate : Tests {
    my $resource = APISchema::Resource->new(
        title => 'Human',
        definition => {
            type => 'object',
            properties => {
                name  => { type => 'string'  },
                age => { type => 'integer' },
            },
            required => ['name', 'age'],
        },
    );
    cmp_deeply $resource, isa('APISchema::Resource') & methods(
        title => 'Human',
        definition => {
            type => 'object',
            properties => {
                name  => { type => 'string'  },
                age => { type => 'integer' },
            },
            required => ['name', 'age'],
        },
    );
}
