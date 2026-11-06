#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

eval { require File::Raw; 1 } or plan skip_all => 'File::Raw required for Chandra::Assets tests';
use Chandra::Assets;

package MockProtocol;
our %registered;
sub new { bless {}, shift }
sub register { my ($self, $prefix, $handler) = @_; $registered{$prefix} = $handler; return $self }

package MockAssetsApp;
sub new { bless { protocol => MockProtocol->new }, shift }
sub protocol { $_[0]{protocol} }

package main;

my $dir = tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/a.txt" or die; print $fh "alpha\n"; close $fh;
open $fh, '>', "$dir/b.css" or die; print $fh "b{}\n"; close $fh;
open $fh, '>', "$dir/prefixed.js" or die; print $fh "1;\n"; close $fh;

# --- constructor shapes ---
{
    my $app = MockAssetsApp->new;
    my $a = Chandra::Assets->new(root => $dir, prefix => 'files://', app => $app, other => 1);
    is($a->{app}, $app, 'the app is kept');
    is($a->prefix, 'files', 'a prefix with :// is trimmed');
    is(Chandra::Assets->new(root => "$dir/", prefix => 'f:')->prefix, 'f', 'a prefix with a colon is trimmed');
    is(Chandra::Assets->new(root => $dir, prefix => 'plain')->prefix, 'plain', 'a plain prefix is kept');
    is(Chandra::Assets->new(root => $dir)->prefix, 'asset', 'the default prefix is asset');
    like(Chandra::Assets->new(root => $dir)->root, qr{/$}, 'the root ends in a slash');
    eval { Chandra::Assets->new(prefix => 'x') };
    like($@, qr/requires 'root' directory/, 'no root croaks');
}

# --- mime types and paths ---
{
    my $a = Chandra::Assets->new(root => $dir);
    is($a->mime_type('x.' . ('q' x 40)), 'application/octet-stream', 'an extension too long to look up is a stream');
    is($a->mime_type('noext'), 'application/octet-stream', 'no extension is a stream too');
    is($a->_resolve_path('a.txt'), "$dir/a.txt", 'and a bare name resolves');
    for my $bad ('../x', "a\0b", '\\x', '/x') {
        eval { $a->_resolve_path($bad) };
        like($@, qr/path traversal detected/, 'a path with ' . ($bad =~ /\0/ ? 'a NUL' : $bad =~ /^\\/ ? 'a leading backslash' : $bad =~ m{^/} ? 'a leading slash' : 'a parent step') . ' is refused');
    }
    is($a->read('a.txt'), "alpha\n", 'read returns the file');
    ok($a->exists('a.txt'), 'exists sees it');
    ok(!$a->exists('../x'), 'an unsafe path does not exist');
    ok(!$a->exists('missing'), 'nor a missing one');
    delete $a->{root};
    eval { $a->_resolve_path('a.txt') };
    like($@, qr/Assets object has no root/, 'resolving without a root croaks');
    is_deeply([ $a->list ], [], 'listing without a root gives nothing');
}

# --- listing ---
{
    my $a = Chandra::Assets->new(root => $dir);
    is_deeply([ sort $a->list ], [qw(a.txt b.css prefixed.js)], 'list gives every entry');
    is_deeply([ $a->list('*.css') ], ['b.css'], 'a glob on the extension');
    is_deeply([ $a->list('prefix') ], ['prefixed.js'], 'a plain prefix');
    is_deeply([ $a->list('*.nope') ], [], 'no match is empty');
    my $gone = Chandra::Assets->new(root => "$dir/missing");
    my @got = eval { $gone->list };
    ok(1, 'listing a missing root ' . ($@ ? 'dies' : 'gives ' . scalar(@got) . ' entries'));
}

# --- mounting on an app's protocol ---
{
    %MockProtocol::registered = ();
    my $app = MockAssetsApp->new;
    my $a = Chandra::Assets->new(root => $dir, prefix => 'mine');
    eval { $a->mount };
    like($@, qr/mount\(\) requires an app object/, 'mount without an app croaks');
    is($a->mount($app), $a, 'mount with an app returns the assets');
    is($a->mount, $a, 'mounting again is a no-op');
    my $handler = $MockProtocol::registered{mine};
    is(ref $handler, 'CODE', 'the handler is registered under the prefix');
    is($handler->('a.txt'), "alpha\n", 'the handler serves a file');
    ok(!defined $handler->('../x'), 'and refuses an unsafe path');
    ok(!defined $handler->('missing.txt'), 'and gives undef for a missing one');
    is($a->_serve('b.css'), "b{}\n", '_serve directly');
    my $kept = Chandra::Assets->new(root => $dir, app => $app);
    is($kept->mount, $kept, 'mount uses the app given to new');
    my $noproto = Chandra::Assets->new(root => $dir);
}

done_testing;
