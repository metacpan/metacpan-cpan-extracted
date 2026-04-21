#!/usr/bin/env perl
# ABSTRACT: Unit tests for the filesystem MCP tools

use strict;
use warnings;
use Test2::Bundle::More;
use File::Temp qw( tempdir );
use Path::Tiny;

use App::Raider::FileTools qw( build_file_tools_server );

my $dir = tempdir(CLEANUP => 1);
path($dir)->child('a.txt')->spew_utf8("hello\n");
path($dir)->child('sub')->mkpath;
path($dir)->child('sub/b.txt')->spew_utf8("world\n");

my $server = build_file_tools_server(root => $dir);

sub call_tool {
  my ($name, $args) = @_;
  my ($tool) = grep { $_->name eq $name } @{ $server->tools };
  die "no tool $name" unless $tool;
  return $tool->code->($tool, $args);
}

subtest list_files => sub {
  my $res = call_tool('list_files', { path => '.' });
  like($res->{content}[0]{text}, qr/a\.txt/, 'lists a.txt');
  like($res->{content}[0]{text}, qr{sub/},   'lists sub dir with slash');
};

subtest read_file => sub {
  my $res = call_tool('read_file', { path => 'a.txt' });
  like($res->{content}[0]{text}, qr/hello/, 'reads a.txt');
};

subtest write_and_edit => sub {
  call_tool('write_file', { path => 'new.txt', content => "one\ntwo\n" });
  ok(-f path($dir, 'new.txt'), 'new.txt created');

  my $edit = call_tool('edit_file', {
    path => 'new.txt', old_string => 'two', new_string => 'TWO',
  });
  like($edit->{content}[0]{text}, qr/Edited/, 'edit reports success');
  is(path($dir, 'new.txt')->slurp_utf8, "one\nTWO\n", 'content edited');

  my $miss = call_tool('edit_file', {
    path => 'new.txt', old_string => 'nope', new_string => 'x',
  });
  ok($miss->{isError}, 'missing old_string is an error');
};

subtest root_escape => sub {
  my $res = call_tool('read_file', { path => '../outside' });
  ok($res->{isError}, 'path escape rejected');
};

done_testing;
