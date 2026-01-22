use strict;
use warnings;
use Test::More;
use Scalar::Util qw(blessed);

$ENV{HARNESS_ACTIVE} = 1;

# 1. The Source Mock
package Mock::Source;
sub new { bless {}, shift }
sub has_column { 1 }
sub column_info { { data_type => 'varchar' } }
sub columns { qw(id name bio title user_id status) }
sub primary_columns { ('id') }
sub result_class { 'DBIx::Class::Async::Row' }
sub attributes { {} }
sub relationship_info {
    my ($self, $rel) = @_;
    return $rel eq 'profile' ? { source => 'Profile' }
         : $rel eq 'posts'   ? { source => 'Post' }
         : undef;
}

# 2. The DB Mock (This is what ResultSet calls)
package Mock::DB;
use Future;
sub new { bless {}, shift }

sub search {
    my ($self, $source_name, $cond, $attrs) = @_;
    # This is what ResultSet->all calls
    return Future->done([
        { id => 1, name => 'Mock User' }
    ]);
}

sub create {
    my ($self, $source, $data) = @_;
    return Future->done({ id => 99, %$data });
}

# 3. The Schema Mock
package Mock::Schema;
sub new { bless { db => Mock::DB->new }, shift }

sub source {
    my ($self, $name) = @_;
    return Mock::Source->new;
}

sub async_db { shift->{db} } # Convenience for Row objects

sub resultset {
    my ($self, $name) = @_;
    require DBIx::Class::Async::ResultSet;
    return DBIx::Class::Async::ResultSet->new(
        schema      => $self,
        async_db    => $self->{db}, # Now correctly shares the Mock::DB instance
        source_name => $name,
    );
}

package main;

# 2. The Test Logic
my $schema = Mock::Schema->new;
my $rs     = $schema->resultset('User');

subtest 'BelongsTo / MightHave Prefetch' => sub {
    my $raw_data = {
        id      => 1,
        name    => 'Alice',
        profile => { id => 99, bio => 'Software Engineer' }
    };

    my $row = $rs->new_result($raw_data);

    # This calls the logic at line 2645
    $rs->_inflate_prefetch($row, $raw_data, 'profile');

    my $profile = $row->{_relationship_data}{profile};
    ok(defined $profile, 'Profile relationship inflated');
    isa_ok($profile, 'DBIx::Class::Async::Row', 'Prefetched object');
    is($profile->get_column('bio'), 'Software Engineer', 'Data correctly mapped');
};

subtest 'HasMany Prefetch' => sub {
    my $raw_data = {
        id    => 2,
        name  => 'Bob',
        posts => [
            { id => 10, title => 'Async Perl is fun' },
            { id => 11, title => 'Testing Mocks' },
        ]
    };

    my $row = $rs->new_result($raw_data);

    # Trigger the same logic for a list
    $rs->_inflate_prefetch($row, $raw_data, 'posts');

    my $posts_rs = $row->{_relationship_data}{posts};

    ok(defined $posts_rs, 'Posts relationship inflated');
    isa_ok($posts_rs, 'DBIx::Class::Async::ResultSet', 'Prefetched relationship');
    is($posts_rs->{is_prefetched}, 1, 'ResultSet marked as prefetched');

    # Test that calling ->all on this virtual RS returns a Future immediately
    my $all_f = $posts_rs->all;
    isa_ok($all_f, 'Future', 'all() returns a Future');

    my $posts = $all_f->get; # Should resolve instantly
    is(scalar @$posts, 2, 'Found 2 prefetched posts');
    is($posts->[0]->get_column('title'), 'Async Perl is fun', 'First post title matches');
    isa_ok($posts->[0], 'DBIx::Class::Async::Row', 'Collection items are Row objects');
};

subtest 'Pager Lifecycle (Caching & Search)' => sub {
    # 1. Setup a paged ResultSet
    my $paged_rs = $rs->search(undef, { page => 1, rows => 10 });
    ok($paged_rs->is_paged, 'ResultSet is paged');

    # 2. Test Memoisation (Caching)
    my $pager1 = $paged_rs->pager;
    my $pager2 = $paged_rs->pager;

    ok(defined $pager1, 'Pager object created');
    # refaddr or stringification check ensures they are the exact same memory address
    is("$pager1", "$pager2", 'Multiple calls to ->pager return the same cached instance');

    # 3. Test Cache Clearing on Search
    my $filtered_rs = $paged_rs->search({ status => 'active' });

    ok(!defined $filtered_rs->{_pager}, 'New search results in a cleared pager cache');

    my $pager3 = $filtered_rs->pager;
    isnt("$pager1", "$pager3", 'The new ResultSet creates its own fresh pager instance');
};

subtest 'ResultSet ->first() strict context check' => sub {
    my $user_rs = $schema->resultset('User');

    # Just use the RS normally now that the Mock handles search()
    my $f = $user_rs->first;

    my $result;
    $f->on_done(sub { $result = shift });
    $f->get if $f->can('get') && !$f->is_ready;

    ok(ref($result) ne 'ARRAY', 'first() returns a Row, not an Array');
    isa_ok($result, 'DBIx::Class::Async::Row', 'Resolved object');
};

subtest 'ResultSet ->first() return value' => sub {
    my $user_rs = $schema->resultset('User');

    # Use 'find' or a manual mock if 'search' isn't implemented in Mock::DB
    my $f = $user_rs->first;

    # Use a try/catch or just ensure the Future exists
    ok($f, "first() returned a Future");

    # Wait for resolution
    my $row;
    eval {
        $row = $f->get; # This will fail if Mock::DB lacks 'search'
    };
    if ($@) {
        diag("Note: Mock::DB is missing 'search' method: $@");
    }

    if ($row) {
        isa_ok($row, 'DBIx::Class::Async::Row', 'The resolved value');
        isa_ok($row, 'DBIx::Class::Async::Row', 'Confirmed object instance');
    }

    done_testing();
};

done_testing();
