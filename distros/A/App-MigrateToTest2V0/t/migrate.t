use strict;
use warnings;
use App::MigrateToTest2V0;
use PPI;
use Test::Base::Less;

sub migrate {
    my ($source) = @_;
    my $doc = PPI::Document->new(\$source);
    my $migrated_doc = App::MigrateToTest2V0->apply($doc);
    return $migrated_doc->content;
}

filters {
    input    => ['trim', \&migrate],
    expected => ['trim'],
};

run {
    my $block = shift;
    is $block->input, $block->expected;
};

done_testing;

__DATA__

=== use Test::More -> use Test2::V0
--- input
use Test::More;

--- expected
use Test2::V0;

=== use Test::More with planing
--- input
use Test::More tests => 10;

--- expected
use Test2::V0;
plan tests => 10;

=== use Test::More skip_all
--- input
use Test::More skip_all => 'reason';

--- expected
use Test2::V0;
skip_all 'reason';

=== is_deeply -> is
--- input
is_deeply [], [], 'message';

--- expected
is [], [], 'message';

=== isa_ok normal instance
--- input
isa_ok $foo, 'Foo', '$foo is an instance of Foo';

--- expected
isa_ok $foo, ['Foo'], '$foo is an instance of Foo';

=== isa_ok normal instance (with paren)
--- input
isa_ok($foo, 'Foo', '$foo is an instance of Foo');

--- expected
isa_ok($foo, ['Foo'], '$foo is an instance of Foo');

=== isa_ok ARRAY -> ref_ok
--- input
isa_ok [], 'ARRAY';

--- expected
ref_ok [], 'ARRAY';

=== isa_ok HASH -> ref_ok
--- input
isa_ok +{}, 'HASH';

--- expected
ref_ok +{}, 'HASH';

=== use Test::Deep
--- input
use Test::Deep;

--- expected
use Test::Deep ();

=== Test::Deep::bag
--- input
use Test::Deep;
cmp_deeply [], bag();

--- expected
use Test::Deep ();
Test::Deep::cmp_deeply [], Test::Deep::bag();

=== This is not Test::Deep::bag
--- input
use Test::Deep;
$foo->bag;

--- expected
use Test::Deep ();
$foo->bag;

=== not replace subroutine definition
--- input
use Test::Deep;
sub bag {}

--- expected;
use Test::Deep ();
sub bag {}
