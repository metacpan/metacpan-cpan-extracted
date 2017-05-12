use strict;
use warnings;
use utf8;
use Test::More;
use Mail::IMAP::Envelope;

my $envelope = Mail::IMAP::Envelope->new(['Thu, 2 Aug 2012 01:56:00 +0200','PAUSE indexer report TOKUHIROM/Amon2-3.38.tar.gz',[['PAUSE',undef,'upload','pause.perl.org']],[['PAUSE',undef,'upload','pause.perl.org']],[['PAUSE',undef,'upload','pause.perl.org']],[[undef,undef,'tokuhirom','gmail.com'],[undef,undef,'andreas.koenig.gmwojprw+pause','franz.ak.mind.de']],undef,undef,undef,'<201208012356.q71Nu0xp024264@pause.fiz-chemie.de>']);
is($envelope->date, 'Thu, 2 Aug 2012 01:56:00 +0200');
is($envelope->subject, 'PAUSE indexer report TOKUHIROM/Amon2-3.38.tar.gz');
is(join(',', map { $_->as_string } @{$envelope->from}), 'PAUSE <upload@pause.perl.org>');
is(join(',', map { $_->as_string } @{$envelope->sender}), 'PAUSE <upload@pause.perl.org>');
is(join(',', map { $_->as_string } @{$envelope->reply_to}), 'PAUSE <upload@pause.perl.org>');
is(join(',', map { $_->as_string } @{$envelope->to}), 'tokuhirom@gmail.com,andreas.koenig.gmwojprw+pause@franz.ak.mind.de');
is(join(',', map { $_->as_string } @{$envelope->cc}), '');
is(join(',', map { $_->as_string } @{$envelope->bcc}), '');

done_testing;

