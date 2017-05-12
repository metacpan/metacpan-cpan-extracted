#!/usr/bin/perl -w

use strict;
use Test::More tests => 52;

BEGIN { use_ok('Apache::FakeTable') }

# Test the failure to pass an Apache object to new().
eval { Apache::FakeTable->new };
ok( my $err = $@, "Catch exception" );
like( $err,
      qr/Usage: Apache::FakeTable::new\(pclass, r, nalloc=10\) at .* line 9/,
      "Check exception message"
    );

# Create a table object.
ok( my $table = Apache::FakeTable->new( bless {}, 'Apache'),
    "Create new FakeTable" );

# Test direct hash access.
ok( $table->{Location} = 'foo', "Assing to Location" );
is( $table->{Location}, 'foo', "Location if 'foo'" );

# Test case-insensitivity.
is( $table->{location}, 'foo', "location if 'foo'" );
is( delete $table->{Location}, 'foo', "Delete location" );

# Test add().
ok( $table->{Hey} = 1, "Set 'Hey' to 1" );
ok( $table->add('Hey', 2), "Add another value to 'Hey'" );

# Fetch both values at once.
is_deeply( [$table->get('Hey')], [1,2], "Get array for 'Hey'" );
is( scalar $table->get('Hey'), 1, "Get first 'Hey' value only" );
is( $table->{Hey}, 1, "Get first 'Hey' value via direct hash access" );

# Keys returns the same key twice;
is_deeply( [keys %$table], [qw(Hey Hey)], 'Check keys %$table' );

# Values returns the first value twice on newer perls. That's a pity.
my $two = $] < 5.006 ? 2 : 1;
is_deeply( [values %$table], [1, $two], 'Check values %$table' );

# Try each.
my $i;
while (my ($k, $v) = each %$table) {
    is( $k, 'Hey', "Check key in 'each'" );
    is( $v, ++$i, "Check value in 'each'" );
}

# Try do(). The code ref should be executed twice, once for each value
# in the 'Hey' array reference.
$i = 0;
$table->do( sub {
    my ($k, $v) = @_;
    is( $k, 'Hey', "Check key in 'do'" );
    is( $v, ++$i, "Check value in 'do'" );
});

# Try short-circutiting do(). The code ref should be executed only once,
# because it returns a false value.
$table->do( sub {
    my ($k, $v) = @_;
    is( $k, 'Hey', "Check key in short 'do'" );
    is( $v, 1, "Check value in short 'do'" );
    return;
});

# Test set() and get().
ok( $table->set('Hey', 'bar'), "Set 'Hey' to 'bar'" );
is( $table->{Hey}, 'bar', "Get 'Hey'" );
is( $table->get('Hey'), 'bar', "Get 'Hey' with get()" );

# Try merge().
ok( $table->merge(Hey => 'you'), "Add 'you' to 'Hey'" );
is( $table->{Hey}, 'bar, you', "Get 'Hey'" );
is( $table->get('Hey'), 'bar, you', "Get 'Hey' with get()" );

# Merge into multiple values merges only the first value with the new value.
ok( $table->add(Yo => 'one'), "Add 'one' to 'Yo'" );
ok( $table->add(Yo => 'another'), "Add 'another' to 'Yo'" );
ok( $table->merge(Yo => 'third'), "Merge 'third' into 'Yo'" );
is( $table->get('Yo'), 'one, third', "Check 'Yo' is 'one, third'" );

# Try unset().
ok( $table->unset('Hey'), "Unset 'Hey'" );
ok( ! exists $table->{Hey}, "Hey doesn't exist" );
is( $table->{Hey}, undef, 'Hey is undef' );

{
    my $rx = qr/Use of uninitialized value in null operation at .* line 98/;
    local $SIG{__WARN__} = sub {
        like( shift, $rx, "Check warning" );
    };

    # Setting the value to undef should actually issue a warning and set it to
    # the null string.
    ok( !$table->set('Hey', undef), "Set 'Hey' to undef");
    is( $table->{Hey}, '', "Get null string 'Hey'" );
    is( $table->get('Hey'), '', "Get null string 'Hey' with get()" );

    $rx = qr/Use of uninitialized value in null operation at .* line 103/;
    ok( !($table->{Hey} = undef), "Store 'Hey' as undef");
    is( $table->{Hey}, '', "Get null string 'Hey'" );
    is( $table->get('Hey'), '', "Get null string 'Hey' with get()" );

    # Adding undef also yields the warning.
    $rx = qr/Use of uninitialized value in null operation at .* line 109/;
    ok( $table->add('Hey', undef), "Add undef to 'Hey'");

    # Turning warnings off should work.
    $SIG{__WARN__} = sub {
        fail("No warnings");
    };
    local $^W;
    ok( $table->add('Hey', undef), "Add undef to 'Hey'");
}

# Try clear().
ok( $table->{Foo} = 'bar', "Add Foo value" );
$table->clear;
ok( ! exists $table->{Foo}, "Hey doesn't exist" );
is( $table->{Foo}, undef, 'Hey is undef' );

__END__
