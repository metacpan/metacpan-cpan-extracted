#!/usr/bin/perl
use Test::More tests => 16;
use strict;
use warnings;
BEGIN {
use_ok 'Data::Hierarchy';
}

my $tree = Data::Hierarchy->new();
$tree->store ('/', {access => 'all'});
$tree->store ('/private', {access => 'auth', type => 'pam'});
$tree->store ('/private/fnord', {otherinfo => 'fnord',
				 '.sticky' => 'this is private fnord'});
$tree->store ('/blahblah', {access => {fnord => 'bzz'}});

# Tree is:
# / [access: all]
# /private [access: auth, type: pam]
# /private/fnord [otherinfo: fnord, .sticky: this is private fnord]
# /blahblah [access: {fnord => bzz}]

is_deeply (scalar $tree->get ('/private/somewhere/deep'), {access => 'auth',
                                                           type => 'pam'});

is_deeply (scalar $tree->get ('/private'), {access => 'auth',
                                            type => 'pam'});

is_deeply (scalar $tree->get ('/private/fnord'), {access => 'auth',
                                                  otherinfo => 'fnord',
                                                  '.sticky' => 'this is private fnord',
                                                  type => 'pam'});

is_deeply (scalar $tree->get ('/private/fnord/blah'), {access => 'auth',
                                                       otherinfo => 'fnord',
                                                       type => 'pam'});

is_deeply (scalar $tree->get ('/private/fnordofu'), {access => 'auth',
                                                     type => 'pam'});

is (($tree->get ('/private/somewhere/deep'))[-1], '/private');
is (($tree->get ('/public'))[-1], '');

is_deeply ([$tree->find ('/', {access => qr/.*/})],
           ['','/blahblah','/private']);

$tree->store ('/private', {type => undef});

# Tree is:
# / [access: all]
# /private [access: auth]
# /private/fnord [otherinfo: fnord, .sticky: this is private fnord]
# /blahblah [access: {fnord => bzz}]

is_deeply (scalar $tree->get ('/private'), { access => 'auth' });
is_deeply (scalar $tree->get ('/private/nothing'), { access => 'auth' });
is_deeply (scalar $tree->get ('/private/fnord'), { access => 'auth',
                                                   otherinfo => 'fnord',
                                                   '.sticky' => 'this is private fnord' });

$tree->store ('/', {access => 'all', type => 'null'}, {override_sticky_descendents => 1});

# Tree is:
# / [access: all, type: null]
# /private/fnord [otherinfo: fnord, .sticky: this is private fnord]

is_deeply ([$tree->get ('/private/fnord/somewhere/deep')],
	   [{access => 'all',
	     otherinfo => 'fnord',
	     type => 'null', }, '','/private/fnord']);

my $tree2 = Data::Hierarchy->new();
$tree2->store ('/private/blah', {access => 'no', type => 'pam', giggle => 'haha'});
$tree2->store ('/private', {access => 'auth', type => 'pam', blah => 'fnord'}, {override_sticky_descendents => 1});

# Tree2 is:
# /private [access: auth, type: pam, blah: fnord]
# /private/blah [giggle: haha]

is_deeply (scalar $tree2->get ('/private/blah'), { access => 'auth',
                                                   type => 'pam',
                                                   blah => 'fnord',
                                                   giggle => 'haha'});

$tree2->merge ($tree, '/private');

# Tree2 is:
# /private [access: all, type: null]
# /private/fnord [otherinfo: fnord, .sticky: this is private fnord]

is_deeply (scalar $tree2->get ('/private/fnord'), {access => 'all',
                                                   otherinfo => 'fnord',
                                                   '.sticky' => 'this is private fnord',
                                                   type => 'null'});

is_deeply (scalar $tree2->get ('/private/blah'), { access => 'all',
                                                   type => 'null'});
