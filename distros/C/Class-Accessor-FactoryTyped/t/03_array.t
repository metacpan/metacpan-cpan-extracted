#!/usr/bin/env perl
use warnings;
use strict;
use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'lib');
use Person;
use Test::More tests => 4;
my $person = Person->new;

my $make_friend = sub { MyFactory->make_object_for_type('person_name', fullname => shift) };
$person->push_friends($make_friend->('Foo Bar'), $make_friend->('Baz'));
is($person->friends_count, 2, 'person has two friends');
is(join(' ' => map { $_->fullname } $person->friends), 'Foo Bar Baz', 'map');
is($person->friends_index(0)->fullname, 'Foo Bar', "first friend's name");
is($person->pop_friends->fullname, 'Baz', 'pop the second friend');
