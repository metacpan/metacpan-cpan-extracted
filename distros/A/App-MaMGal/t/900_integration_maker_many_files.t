#!/usr/bin/perl
# mamgal - a program for creating static image galleries
# Copyright 2007-2010 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
use strict;
use warnings;
use Carp 'verbose';
use Test::More tests => 11;
use Test::Files;
use Test::HTML::Content;
use Test::Exception;
use lib 'testlib';
use App::MaMGal::TestHelper;

prepare_test_data;

dir_only_contains_ok('td/more', [qw(a.png b.png x.png subdir subdir/p.png subdir/p2.png subdir/lost+found),
                                 qw(subdir/uninteresting subdir/uninteresting/bar.txt),
                                 qw(subdir/interesting subdir/interesting/b.png),
                                 'zzz another subdir', 'zzz another subdir/p.png'], "not much exists initially");

use_ok('App::MaMGal');
# Get locale from environment so that you can see some representatative output in your language
my $M = App::MaMGal->new('');
ok($M->{logger});
ok($M->make_roots('td/more'), "maker returns success on an dir with some files");
dir_only_contains_ok('td/more', [qw(.mamgal-root
					index.html .mamgal-index.png .mamgal-style.css
					.mamgal-medium .mamgal-thumbnails .mamgal-slides
					a.png b.png x.png
					.mamgal-medium/a.png .mamgal-medium/b.png .mamgal-medium/x.png
					.mamgal-thumbnails/a.png .mamgal-thumbnails/b.png .mamgal-thumbnails/x.png
					.mamgal-slides/a.png.html .mamgal-slides/b.png.html .mamgal-slides/x.png.html
					subdir subdir/p.png subdir/p2.png subdir/lost+found
					subdir/index.html subdir/.mamgal-index.png
					subdir/.mamgal-medium subdir/.mamgal-medium/p.png subdir/.mamgal-medium/p2.png
					subdir/.mamgal-thumbnails subdir/.mamgal-thumbnails/p.png
					subdir/.mamgal-thumbnails/p2.png
					subdir/.mamgal-slides subdir/.mamgal-slides/p.png.html
					subdir/.mamgal-slides/p2.png.html
					subdir/uninteresting subdir/uninteresting/bar.txt subdir/interesting subdir/interesting/b.png
					subdir/interesting/.mamgal-index.png subdir/interesting/.mamgal-medium
					subdir/interesting/.mamgal-medium/b.png subdir/uninteresting/.mamgal-index.png
					subdir/uninteresting/index.html subdir/interesting/index.html subdir/interesting/.mamgal-thumbnails
					subdir/interesting/.mamgal-slides subdir/interesting/.mamgal-slides/b.png.html
					subdir/interesting/.mamgal-thumbnails/b.png),
					'zzz another subdir', 'zzz another subdir/.mamgal-index.png', 'zzz another subdir/index.html',
					'zzz another subdir/p.png', 'zzz another subdir/.mamgal-slides',
					'zzz another subdir/.mamgal-slides/p.png.html', 'zzz another subdir/.mamgal-thumbnails',
					'zzz another subdir/.mamgal-thumbnails/p.png', 'zzz another subdir/.mamgal-medium',
					'zzz another subdir/.mamgal-medium/p.png'
					],
						"maker created index.html, .mamgal-medium, .mamgal-thumbnails and .mamgal-slides, also for both subdirs");

# Test failures
my $ex = get_mock_exception 'App::MaMGal::SystemException';
$M->{maker} = Test::MockObject->new;
$M->{maker}->mock('make_roots', sub { die $ex });
$M->{maker}->mock('make_without_roots', sub { die $ex });
$M->{logger} = get_mock_logger;
lives_ok(sub { $M->make_roots('whatever') }, 'make_roots survives');
my ($method, $args) = $M->{logger}->next_call;
is($method, 'log_exception');
is($args->[1], $ex);
$M->{logger}->clear;

lives_ok(sub { $M->make_without_roots('whatever') }, 'make_without_roots survives');
($method, $args) = $M->{logger}->next_call;
is($method, 'log_exception');
is($args->[1], $ex);
$M->{logger}->clear;

