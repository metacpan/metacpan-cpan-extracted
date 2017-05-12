#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('App::Lastmsg') };

{
	no warnings 'redefine';
	*App::Lastmsg::format_time = sub { shift };
}

chdir 't';
my $out = '';
open my $fh, '>', \$out or die "$!";
$App::Lastmsg::OUTPUT_FILEHANDLE = $fh;
$0 = 'lastmsg';
App::Lastmsg::run;

is $out, <<'EOF', 'output is correct';
user2 user2@example.org 1483182600
user1 user1@example.com 1483105440
user3                   NOT FOUND
EOF

$ENV{LASTMSG_DEBUG} = 1;
my $err = '';
close STDERR;
open STDERR, '>', \$err or die "$!";
App::Lastmsg::run;

is $err, <<'EOF', 'debug output is correct';
Scanning inbox (inbox)
Processing <mail1@example.com> from User 1 <user1@example.com> (Comment)
Processing <mail2@example.com> from user1@example.com
Processing <mail3@example.com> from user2@example.com
Scanning sent (sent)
Processing <33r32r32igf432g@localhost.localdomain> sent to Random User <rando@example.com> (Very random), User 2 <user2@example.org>
EOF
