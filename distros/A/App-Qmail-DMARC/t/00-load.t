#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'MailX::Qmail::Queue::Message' ) || print "Bail out!\n";
}

diag( "Testing MailX::Qmail::Queue::Message $MailX::Qmail::Queue::Message::VERSION, Perl $], $^X" );
