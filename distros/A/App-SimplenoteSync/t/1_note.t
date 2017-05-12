#!/usr/bin/env perl -w

use Test::More tests => 6;

use App::SimplenoteSync::Note;
use DateTime;
use Path::Class;
use JSON;

my $date = DateTime->new(
    year  => 2012,
    month => 1,
    day   => 1,
);

my $notes_dir = Path::Class::Dir->new('.');

my $note = App::SimplenoteSync::Note->new(
    createdate => $date->epoch,
    modifydate => $date->epoch,
    notes_dir  => $notes_dir,
    content    => "# Some Content #\n This is a test",
);

ok(defined $note,                           'new() returns something');
ok($note->isa('App::SimplenoteSync::Note'), '... the correct class');

cmp_ok($note->title, 'eq', 'Some Content', 'Title is correct');

ok(my $json_str       = $note->serialise,      'Serialise note to JSON');
ok(my $note_from_json = decode_json $json_str, '...JSON is valid');
ok(my $note_thawed = App::SimplenoteSync::Note->new($json_str),
    '...can deserialise');
