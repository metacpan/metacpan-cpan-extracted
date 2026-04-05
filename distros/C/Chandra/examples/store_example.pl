#!/usr/bin/env perl
use strict;
use warnings;
use Chandra::Store;

# ---- Basic usage ----

my $store = Chandra::Store->new(name => 'myapp');

$store->set('theme', 'dark');
printf "theme: %s\n", $store->get('theme');

my $missing = $store->get('nonexistent', 'default_value');
printf "missing: %s\n", $missing;

# ---- Dot notation for nested structures ----

$store->set('window.width',  800);
$store->set('window.height', 600);
$store->set('window.x',      100);
$store->set('window.y',      50);

printf "width:  %s\n", $store->get('window.width');
printf "window: %s\n", join(', ', map { "$_=$store->get(\"window.$_\")" }
    qw(width height x y));

my $window = $store->get('window');
printf "window subtree: width=%s height=%s\n",
    $window->{width}, $window->{height};

# ---- Check existence ----

printf "has theme:   %s\n", $store->has('theme')   ? 'yes' : 'no';
printf "has missing: %s\n", $store->has('missing') ? 'yes' : 'no';

# ---- Delete ----

$store->delete('theme');
printf "after delete, has theme: %s\n", $store->has('theme') ? 'yes' : 'no';

# ---- Bulk set ----

$store->set_many({
    'ui.font_size'  => 14,
    'ui.sidebar'    => 1,
    'recent_files'  => ['/home/user/doc.txt', '/home/user/notes.md'],
    'last_opened'   => time(),
});

printf "font_size:    %s\n", $store->get('ui.font_size');
printf "recent_files: %s\n", join(', ', @{ $store->get('recent_files') });

# ---- All keys ----

my $all = $store->all;
printf "top-level keys: %s\n", join(', ', sort keys %$all);

# ---- Manual save mode ----

my $s2 = Chandra::Store->new(name => 'myapp_batch', auto_save => 0);
$s2->set('a', 1);
$s2->set('b', 2);
$s2->set('c', 3);
$s2->save;   # single write for all three changes
printf "batch saved: a=%s b=%s c=%s\n",
    $s2->get('a'), $s2->get('b'), $s2->get('c');

# ---- Reload from disk ----

my $s3 = Chandra::Store->new(name => 'myapp_batch');
printf "reloaded: a=%s\n", $s3->get('a');

# ---- Clear ----

$store->clear;
printf "after clear, all empty: %s\n",
    keys(%{ $store->all }) == 0 ? 'yes' : 'no';

printf "\nDone. Store path: %s\n", $store->path;
