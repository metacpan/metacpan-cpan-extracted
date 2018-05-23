use strict;
use warnings;

no indirect 'fatal';

use Test::More;

use Try::Tiny;

subtest 'Long class name' => sub {
    package Very::Long::Prefix::For::Schema::Result::FooBar;

    use Test::More;

    require DBIx::Class::Relationship::Abbreviate;
    DBIx::Class::Relationship::Abbreviate->import(qw/ result /);

    is(result('Baz'), 'Very::Long::Prefix::For::Schema::Result::Baz', 'Very long package names work');
};

subtest 'Short class name' => sub {
    package Some::Schema::Result::FooBar;

    use Test::More;

    require DBIx::Class::Relationship::Abbreviate;
    DBIx::Class::Relationship::Abbreviate->import(qw/ result /);

    is(result('Baz'), 'Some::Schema::Result::Baz', 'Very long package names work');
};

subtest 'Invalid class name' => sub {
    package Some::Other::Class::FooBar;

    use Test::More;
    use Test::Fatal qw/ exception /;

    require DBIx::Class::Relationship::Abbreviate;

    my $ex = exception { DBIx::Class::Relationship::Abbreviate->import(qw/ result /) };
    like($ex, qr/Cannot find result namespace in 'Some::Other::Class::FooBar'/);
};

done_testing();
