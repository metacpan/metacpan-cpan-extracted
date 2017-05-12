use strict;
use warnings;
use Fennec::Declare class => 'DSL::HTML::Rendering';

BEGIN { use_ok $CLASS }
use DSL::HTML;

ok(!$CLASS->current, "not in a template");
template foo {
    ok($CLASS->current, "in a template");
}

isa_ok( $CLASS->new(), $CLASS );

# TODO: Flesh this out more

done_testing;
