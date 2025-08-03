#!/usr/bin/env perl

use strict;
use warnings;

use Data::Message::Board::Comment;
use Data::Person;
use DateTime;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

my $obj = Data::Message::Board::Comment->new(
        'author' => Data::Person->new(
                'email' => 'skim@cpan.org',
                'name' => decode_utf8('Michal Josef Špaček'),
        ),
        'date' => DateTime->now,
        'id' => 7,
        'message' => 'I am fine.',
);

# Print out.
print 'Author name: '.encode_utf8($obj->author->name)."\n";
print 'Author email: '.$obj->author->email."\n";
print 'Date: '.$obj->date."\n";
print 'Id: '.$obj->id."\n";
print 'Comment message: '.$obj->message."\n";

# Output:
# Author name: Michal Josef Špaček
# Author email: skim@cpan.org
# Date: 2024-05-27T09:54:28
# Id: 7
# Comment message: I am fine.