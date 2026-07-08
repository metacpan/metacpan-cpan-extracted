use Test2::V0 '!meta', '!pass';

# Argument-classification loops must not terminate early when an argument
# stringifies false (e.g. the literal '0'). index() is the cleanest window onto
# this class of loop: a falsy index name must not swallow the column list that
# follows it. The other DSL builders (plugins, autoskip, table class-path,
# column, link) use the same corrected loop form.

{
    package My::Falsy;
    use DBIx::QuickORM;
}

my $b = My::Falsy->builder;

my $idx = $b->index('0' => ['x', 'y'], {unique => 1});

is($idx->{name}, '0', "a falsy index name is captured, not treated as end-of-args");
is($idx->{columns}, ['x', 'y'], "the column list following a falsy name is not dropped");
is($idx->{unique}, 1, "trailing option hash is still applied after a falsy name");

# Sanity: a normal (truthy) name still works.
my $idx2 = $b->index('by_email' => ['email']);
is($idx2->{name}, 'by_email', "a normal index name still works");
is($idx2->{columns}, ['email'], "a normal index column list still works");

done_testing;
