package t::APISchema;
use t::test;

sub _require : Test(startup => 1) {
    my ($self) = @_;

    use_ok 'APISchema';
}

sub version : Tests {
    cmp_ok $APISchema::VERSION, '>', 0, 'has positive version';
}
