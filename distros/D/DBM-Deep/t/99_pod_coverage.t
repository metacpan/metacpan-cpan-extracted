# Only DBM::Deep has any POD to test. All the other classes are private
# classes. Hence, they have no POD outside of DBM::Deep::Internals

use strict;

use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

plan tests => 1;

# I don't know why TYPE_ARRAY isn't being caught and TYPE_HASH is.
my @private_methods = qw(
    TYPE_ARRAY
);

# These are method names that have been commented out, for now
# max_of total_of
# begin_page end_page

my $private_regex = do {
    local $"='|';
    qr/^(?:@private_methods)$/
};

pod_coverage_ok( 'DBM::Deep' => {
    also_private => [ $private_regex ],
});
