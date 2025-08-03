#!/usr/bin/env perl

use strict;
use warnings;

use Data::Message::Board;
use Data::Message::Board::Comment;
use Data::Person;
use DateTime;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

my $dt = DateTime->now;
my $dt_comment1 = $dt->clone->add('minutes' => 5);
my $dt_comment2 = $dt_comment1->clone->add('seconds' => 34);
my $obj = Data::Message::Board->new(
        'author' => Data::Person->new(
                'email' => 'skim@cpan.org',
                'name' => decode_utf8('Michal Josef Špaček'),
        ),
        'comments' => [
                Data::Message::Board::Comment->new(
                        'author' => Data::Person->new(
                                'email' => 'bar@example.com',
                                'name' => decode_utf8('St. John'),
                        ),
                        'date' => $dt_comment1,
                        'id' => 7,
                        'message' => 'I am fine.',
                ),
                Data::Message::Board::Comment->new(
                        'author' => Data::Person->new(
                                'email' => 'foo@example.com',
                                'name' => decode_utf8('John Wick'),
                        ),
                        'date' => $dt_comment2,
                        'id' => 6,
                        'message' => 'Not bad.',
                ),
        ],
        'date' => $dt,
        'id' => 1,
        'message' => 'How are you?',
);

# Print out.
print 'Author name: '.encode_utf8($obj->author->name)."\n";
print 'Author email: '.$obj->author->email."\n";
print 'Date: '.$obj->date."\n";
print 'Id: '.$obj->id."\n";
print 'Message: '.$obj->message."\n";
print "Comments:\n";
map {
        print "\tAuthor name: ".$_->author->name."\n";
        print "\tDate: ".$_->date."\n";
        print "\tId: ".$_->id."\n";
        print "\tComment: ".$_->message."\n\n";
} @{$obj->comments};

# Output:
# Author name: Michal Josef Špaček
# Author email: skim@cpan.org
# Date: 2024-05-27T18:10:55
# Id: 1
# Message: How are you?
# Comments:
#         Author name: St. John
#         Date: 2024-05-27T18:15:55
#         Id: 7
#         Comment: I am fine.
# 
#         Author name: John Wick
#         Date: 2024-05-27T18:16:29
#         Id: 6
#         Comment: Not bad.
# 