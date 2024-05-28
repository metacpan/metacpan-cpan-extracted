#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Data::Message::Board::Example;

my $obj = Test::Shared::Fixture::Data::Message::Board::Example->new;

# Print out.
print 'Author name: '.$obj->author->name."\n";
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
# Author name: John Wick
# Date: 2024-05-25T17:53:20
# Id: 7
# Message: How to install Perl?
# Comments:
#         Author name: Gregor Herrmann
#         Date: 2024-05-25T17:53:27
#         Id: 1
#         Comment: apt-get update; apt-get install perl;
# 
#         Author name: Emmanuel Seyman
#         Date: 2024-05-25T17:53:37
#         Id: 2
#         Comment: dnf update; dnf install perl-intepreter;
# 