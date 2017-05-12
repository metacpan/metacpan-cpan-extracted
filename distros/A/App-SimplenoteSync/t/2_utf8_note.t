#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;
use App::SimplenoteSync::Note;
use Path::Class qw//;
use Test::utf8;
use Test::More tests => 6;

my $notes_dir = Path::Class::Dir->new('t/');

my $note =
  App::SimplenoteSync::Note->new(file => $notes_dir->file('utf8_note.txt'),);

ok(defined $note,                           'new() returns something');
ok($note->isa('App::SimplenoteSync::Note'), '... the correct class');

ok($note->load_content, 'Loaded file content');

is_flagged_utf8($note->content, 'Flagged utf8');

is_valid_string($note->content, 'Valid string');

is_sane_utf8($note->content, 'Sane utf8');
