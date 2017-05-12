package Test4;
use Catalyst $ENV{TEST_VERBOSE} ? qw(-Debug) : ();

__PACKAGE__->config({
    setup_components => {
        search_extra => [ '::Foo' ],
    }
});

__PACKAGE__->setup();

1;
