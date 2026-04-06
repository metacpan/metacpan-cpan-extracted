#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('Chandra::Store');

my $dir = tempdir(CLEANUP => 1);
sub store_path { "$dir/$_[0].json" }

# ---- Construction ----

{
    my $s = Chandra::Store->new(path => store_path('basic'));
    isa_ok($s, 'Chandra::Store', 'new returns object');
    is($s->path, store_path('basic'), 'path() accessor');
    is($s->auto_save, 1, 'auto_save defaults to 1');
}

{
    my $s = Chandra::Store->new(path => store_path('nosave'), auto_save => 0);
    is($s->auto_save, 0, 'auto_save => 0 respected');
}

{
    eval { Chandra::Store->new() };
    like($@, qr/name.*path|path.*name/i, 'dies without name or path');
}

# ---- Basic get/set ----

{
    my $s = Chandra::Store->new(path => store_path('getset'));

    is($s->get('missing'),           undef, 'get missing key returns undef');
    is($s->get('missing', 'fallbk'), 'fallbk', 'get missing key returns default');

    $s->set('theme', 'dark');
    is($s->get('theme'), 'dark', 'get after set');

    $s->set('count', 42);
    is($s->get('count'), 42, 'numeric value');

    $s->set('flag', 0);
    is($s->get('flag'), 0, 'falsy value stored correctly');

    $s->set('empty', '');
    is($s->get('empty'), '', 'empty string stored correctly');
}

# ---- has / delete ----

{
    my $s = Chandra::Store->new(path => store_path('hasdel'));

    is($s->has('x'), 0, 'has returns 0 for missing');
    $s->set('x', 1);
    is($s->has('x'), 1, 'has returns 1 after set');

    $s->delete('x');
    is($s->has('x'), 0, 'has returns 0 after delete');
    is($s->get('x'), undef, 'get returns undef after delete');

    # delete non-existent key is a no-op
    my $ret = $s->delete('nonexistent');
    isa_ok($ret, 'Chandra::Store', 'delete returns self');
}

# ---- Dot notation ----

{
    my $s = Chandra::Store->new(path => store_path('dot'));

    $s->set('window.width',  800);
    $s->set('window.height', 600);

    is($s->get('window.width'),  800, 'dot get leaf');
    is($s->get('window.height'), 600, 'dot get second leaf');

    my $window = $s->get('window');
    is(ref $window, 'HASH', 'dot get returns subtree hashref');
    is($window->{width},  800, 'subtree width');
    is($window->{height}, 600, 'subtree height');

    is($s->has('window.width'),  1, 'has with dot notation - present');
    is($s->has('window.depth'),  0, 'has with dot notation - absent');

    $s->set('a.b.c.d', 'deep');
    is($s->get('a.b.c.d'), 'deep', 'deep dot notation set/get');

    $s->delete('window.width');
    is($s->has('window.width'), 0, 'dot delete leaf');
    is($s->has('window'), 1, 'parent survives leaf delete');
    is($s->has('window.height'), 1, 'sibling survives leaf delete');
}

# ---- Arrays as values ----

{
    my $s = Chandra::Store->new(path => store_path('arrays'));
    $s->set('files', ['/a', '/b', '/c']);
    my $files = $s->get('files');
    is(ref $files, 'ARRAY', 'array value stored');
    is_deeply($files, ['/a', '/b', '/c'], 'array round-trips correctly');
}

# ---- set_many ----

{
    my $s = Chandra::Store->new(path => store_path('many'));
    $s->set_many({
        'ui.font_size' => 14,
        'ui.sidebar'   => 1,
        'theme'        => 'light',
        'files'        => ['/x', '/y'],
    });
    is($s->get('ui.font_size'), 14,      'set_many dot key');
    is($s->get('ui.sidebar'),   1,       'set_many second dot key');
    is($s->get('theme'),        'light', 'set_many simple key');
    is_deeply($s->get('files'), ['/x', '/y'], 'set_many array');

    # set_many returns self
    my $ret = $s->set_many({ a => 1 });
    isa_ok($ret, 'Chandra::Store', 'set_many returns self');
}

# ---- all / clear ----

{
    my $s = Chandra::Store->new(path => store_path('allclear'));
    $s->set('a', 1);
    $s->set('b', 2);

    my $all = $s->all;
    is(ref $all, 'HASH', 'all returns hashref');
    is($all->{a}, 1, 'all contains a');
    is($all->{b}, 2, 'all contains b');

    $s->clear;
    my $empty = $s->all;
    is_deeply($empty, {}, 'all empty after clear');
    is(-f $s->path, 1, 'file still exists after clear');
}

# ---- Persistence: save / reload ----

{
    my $path = store_path('persist');

    {
        my $s = Chandra::Store->new(path => $path);
        $s->set('saved', 'yes');
        $s->set('num', 99);
    }

    # Reopen — data should persist
    my $s2 = Chandra::Store->new(path => $path);
    is($s2->get('saved'), 'yes', 'data persists across instances');
    is($s2->get('num'),   99,    'numeric persists');
}

{
    # Manual save mode
    my $path = store_path('manual');
    my $s = Chandra::Store->new(path => $path, auto_save => 0);
    $s->set('x', 'unsaved');

    my $s2 = Chandra::Store->new(path => $path);
    is($s2->get('x'), undef, 'auto_save=>0: data not on disk before save');

    $s->save;

    my $s3 = Chandra::Store->new(path => $path);
    is($s3->get('x'), 'unsaved', 'data on disk after explicit save');
}

{
    # reload picks up external changes
    my $path = store_path('reload');
    my $s = Chandra::Store->new(path => $path);
    $s->set('v', 1);

    # Write externally
    open(my $fh, '>', $path) or die $!;
    print $fh '{"v":42}';
    close $fh;

    $s->reload;
    is($s->get('v'), 42, 'reload picks up external change');
}

# ---- auto_save accessor ----

{
    my $s = Chandra::Store->new(path => store_path('autosacc'));
    $s->auto_save(0);
    is($s->auto_save, 0, 'auto_save setter/getter');
    $s->auto_save(1);
    is($s->auto_save, 1, 'auto_save re-enable');
}

# ---- set returns self (chaining) ----

{
    my $s = Chandra::Store->new(path => store_path('chain'));
    my $ret = $s->set('a', 1);
    isa_ok($ret, 'Chandra::Store', 'set returns self');
    $s->set('a', 1)->set('b', 2)->set('c', 3);
    is($s->get('b'), 2, 'chained set');
}

# ---- App integration ----

{
    # Mock a minimal Chandra::App-like object to test the store() method
    package MockApp;
    sub new { bless { title => 'Test App' }, shift }
    sub title { $_[0]->{title} }

    package main;

    require Chandra::App;

    # store() is a Perl method on Chandra::App — test it via direct bless trick
    my $app = bless { title => 'My App' }, 'Chandra::App';
    can_ok('Chandra::App', 'store');
}

done_testing();
