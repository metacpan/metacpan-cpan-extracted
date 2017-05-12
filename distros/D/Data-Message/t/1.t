#!/usr/bin/perl -w
use strict;
use Test::More tests => 10;

sub read_file { local $/; local *FH; open FH, shift or die $!; return <FH> }
use_ok("Data::Message");
# Very basic functionality test
my $mail_text = read_file("t/test-mails/josey-nofold");
my $mail = Data::Message->new($mail_text);
isa_ok($mail, "Data::Message");

like($mail->as_string, qr/From: Andrew/, "Andrew's in the header");

my $old_from;
is($old_from = $mail->header("From"), 
   'Andrew Josey <ajosey@rdg.opengroup.org>',  
    "We can get a header");
my $sc = 'Simon Cozens <simon@cpan.org>';
is($mail->header_set("From", $sc), $sc, "Setting returns new value");
is($mail->header("From"), $sc, "Which is consistently returned");

# Put andrew back:
$mail->header_set("From", $old_from);

my $body;
like($body = $mail->body, qr/Austin Group Chair/, "Body has sane stuff in it");
my $old_body;

my $hi = "Hi there!\n";
$mail->body_set($hi);
is($mail->body, $hi, "Body can be set properly");

$mail->body_set($body);
is($mail->as_string, $mail_text, "Good grief, it's round-trippable");
is(Data::Message->new($mail->as_string)->as_string, $mail_text, "Good grief, it's still round-trippable");
