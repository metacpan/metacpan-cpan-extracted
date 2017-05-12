use Test::More;
use Module::Pluggable::Object;

BEGIN{
    my $loader = Module::Pluggable::Object->new(
        search_path => [ 'DBIx::ObjectMapper' ],
        require     => 0,
    );

    my @classes = $loader->plugins;
    unshift @classes , 'DBIx::ObjectMapper';

    plan tests => scalar(@classes);
    require_ok($_) for sort @classes;
}
