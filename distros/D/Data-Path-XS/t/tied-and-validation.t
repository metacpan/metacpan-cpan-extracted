use strict;
use warnings;
use Test::More;
use Data::Path::XS qw(
    path_get path_set path_delete path_exists
    patha_get patha_set patha_delete patha_exists
    path_compile pathc_get pathc_set pathc_delete pathc_exists
);
use Data::Path::XS ':keywords';

# H1: tied container errors should be informative, not generic.
# H2: VALIDATE_COMPILED_PATH should not emit Perl warnings on bad input.

package T::Hash {
    sub TIEHASH { bless { d => {} }, shift }
    sub FETCH   { $_[0]->{d}{$_[1]} }
    sub STORE   { $_[0]->{d}{$_[1]} = $_[2] }
    sub EXISTS  { exists $_[0]->{d}{$_[1]} }
    sub DELETE  { delete $_[0]->{d}{$_[1]} }
    sub FIRSTKEY { keys %{$_[0]->{d}}; each %{$_[0]->{d}} }
    sub NEXTKEY  { each %{$_[0]->{d}} }
}

package T::Array {
    sub TIEARRAY  { bless { d => [] }, shift }
    sub FETCH     { $_[0]->{d}[$_[1]] }
    sub STORE     { $_[0]->{d}[$_[1]] = $_[2] }
    sub FETCHSIZE { scalar @{$_[0]->{d}} }
    sub STORESIZE { $#{$_[0]->{d}} = $_[1]-1 }
    sub EXISTS    { exists $_[0]->{d}[$_[1]] }
    sub DELETE    { delete $_[0]->{d}[$_[1]] }
}

package main;

subtest 'H1: tied hash set gives informative error' => sub {
    tie my %th, 'T::Hash';
    my $r = \%th;

    eval { path_set($r, '/foo', 1) };
    like($@, qr/tied|magical/i, 'path_set: tied hash error mentions tied/magical');

    eval { patha_set($r, ['foo'], 1) };
    like($@, qr/tied|magical/i, 'patha_set: tied hash error mentions tied/magical');

    eval { pathc_set($r, path_compile('/foo'), 1) };
    like($@, qr/tied|magical/i, 'pathc_set: tied hash error mentions tied/magical');

    my $sub = sub { my ($d,$p,$v) = @_; pathset $d, $p, $v };
    eval { $sub->($r, '/foo', 1) };
    like($@, qr/tied|magical/i, 'kw pathset dyn: tied hash error mentions tied/magical');
};

subtest 'H1: tied array set gives informative error' => sub {
    tie my @ta, 'T::Array';
    my $r = \@ta;

    eval { path_set($r, '/0', 1) };
    like($@, qr/tied|magical/i, 'path_set: tied array error mentions tied/magical');
};

subtest 'H1: tied intermediate (multi-level) gives informative error' => sub {
    tie my %th, 'T::Hash';
    my $root = { mid => \%th };

    eval { path_set($root, '/mid/foo', 1) };
    like($@, qr/tied|magical/i, 'path_set: tied intermediate hash');

    eval { patha_set($root, ['mid', 'foo'], 1) };
    like($@, qr/tied|magical/i, 'patha_set: tied intermediate hash');

    eval { pathc_set($root, path_compile('/mid/foo'), 1) };
    like($@, qr/tied|magical/i, 'pathc_set: tied intermediate hash');

    my $sub = sub { my ($d, $p, $v) = @_; pathset $d, $p, $v };
    eval { $sub->($root, '/mid/foo', 1) };
    like($@, qr/tied|magical/i, 'kw pathset dyn: tied intermediate hash');

    # tied intermediate that already holds a non-ref scalar; the next
    # autoviv step in pp_pathset_dynamic should croak with tied msg
    tie my %th2, 'T::Hash';
    $th2{x} = 'scalar';  # populate the slot
    my $root2 = { mid => \%th2 };
    eval { $sub->($root2, '/mid/x/y', 1) };
    like($@, qr/tied|magical/i, 'kw pathset dyn: tied autoviv replaces scalar');
};

subtest 'H1: tied array at intermediate depth' => sub {
    tie my @ta, 'T::Array';
    my $root = { mid => \@ta };

    eval { path_set($root, '/mid/0/x', 1) };
    like($@, qr/tied|magical/i, 'path_set: tied array intermediate');

    eval { patha_set($root, ['mid', 0, 'x'], 1) };
    like($@, qr/tied|magical/i, 'patha_set: tied array intermediate');

    eval { pathc_set($root, path_compile('/mid/0/x'), 1) };
    like($@, qr/tied|magical/i, 'pathc_set: tied array intermediate');

    my $sub = sub { my ($d, $p, $v) = @_; pathset $d, $p, $v };
    eval { $sub->($root, '/mid/0/x', 1) };
    like($@, qr/tied|magical/i, 'kw pathset dyn: tied array intermediate');
};

subtest 'tied containers still work for read' => sub {
    tie my %th, 'T::Hash';
    $th{x} = 'value';     # native assignment goes through STORE
    my $r = \%th;
    is(path_get($r, '/x'), 'value', 'path_get on tied hash works');
    ok(path_exists($r, '/x'),       'path_exists on tied hash works');
    is(path_delete($r, '/x'), 'value', 'path_delete on tied hash works');
    ok(!exists $th{x}, 'delete actually fired DELETE');
};

subtest 'H2: VALIDATE_COMPILED_PATH no warnings on bad input' => sub {
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };

    # Hash ref blessed as our class
    my $fake_hv = bless { not => 'real' }, 'Data::Path::XS::Compiled';
    eval { pathc_get({a => 1}, $fake_hv) };
    like($@, qr/Not a compiled path/, 'fake (HV bless): croaks');

    # Array ref blessed as our class
    my $fake_av = bless [1,2,3], 'Data::Path::XS::Compiled';
    eval { pathc_get({a => 1}, $fake_av) };
    like($@, qr/Not a compiled path/, 'fake (AV bless): croaks');

    # Plain non-ref scalar
    eval { pathc_get({a => 1}, "not a ref") };
    like($@, qr/Not a compiled path/, 'non-ref: croaks');

    # Scalar ref not pointing at IV
    my $s = "garbage";
    my $fake_sv = bless \$s, 'Data::Path::XS::Compiled';
    eval { pathc_get({a => 1}, $fake_sv) };
    like($@, qr/Not a compiled path/, 'fake (SV bless): croaks');

    is(scalar @warns, 0, 'no warnings emitted during validation')
        or diag("warnings: @warns");
};

subtest 'compiled path methods all reject bad input' => sub {
    my $fake = bless [], 'Data::Path::XS::Compiled';
    for my $sub ([\&pathc_get,    'pathc_get'],
                 [\&pathc_exists, 'pathc_exists'],
                 [\&pathc_delete, 'pathc_delete']) {
        my @warns;
        local $SIG{__WARN__} = sub { push @warns, $_[0] };
        eval { $sub->[0]->({a=>1}, $fake) };
        like($@, qr/Not a compiled path/, "$sub->[1] rejects");
        is(scalar @warns, 0, "$sub->[1] no warnings");
    }
    {
        my @warns;
        local $SIG{__WARN__} = sub { push @warns, $_[0] };
        eval { pathc_set({a=>1}, $fake, 'v') };
        like($@, qr/Not a compiled path/, 'pathc_set rejects');
        is(scalar @warns, 0, 'pathc_set no warnings');
    }
};

done_testing;
