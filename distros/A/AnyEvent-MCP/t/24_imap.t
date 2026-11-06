use common::sense;
use Test::More;
use MIME::Base64 ();
use JSON::XS ();

BEGIN {
   eval { require Mail::IMAPTalk; require IO::Socket::SSL; 1 }
      or plan skip_all => "IMAP test dependencies unavailable";
}

use lib "lib";
require AnyEvent::MCP::Worker::IMAP;

{
   package IMAPMock;
   our (%seen, %cap, $uidnext);
   $uidnext = 3001;

   sub new { bless {}, shift }
   sub login { 1 }
   sub uid { 1 }
   sub parse_mode { 1 }
   sub is_open { 1 }
   sub capability { \%cap }
   sub get_last_error { "mock IMAP error" }
   sub get_response_code {
      $_[1] eq "uidvalidity" ? 123 : $_[1] eq "uidnext" ? 3001 : undef
   }
   sub select {
      $seen{select} = [@_];
      1
   }
   sub list {
      my $mailboxes = [ ["", "/", "INBOX"], ["", "/", "Archive"] ];
      wantarray ? @$mailboxes : $mailboxes
   }
   sub lsub {
      my $mailboxes = [ ["", "/", "INBOX"] ];
      wantarray ? @$mailboxes : $mailboxes
   }
   sub status { $seen{status}++; { uidnext => $uidnext, uidvalidity => 123 } }
   sub search {
      my ($self, $range, @criteria) = @_;
      $seen{search} = [$range, @criteria];
      my ($lo, $hi) = split /:/, $range;
      my $uids = [grep $_ >= $lo && $_ <= $hi, (20, 1001, 2200, 2900, 3200)];
      wantarray ? @$uids : $uids
   }
   sub fetch {
      my ($self, $uids, $items) = @_;
      $seen{fetch} = [$uids, $items];
      my @uid = ref $uids ? @$uids : ($uids);
      my %out;
      for my $uid (@uid) {
         $out{$uid} = {
            envelope => { Subject => "test $uid", From => "sender\@example.org", Date => "date" },
            flags => ["\\Seen"], "rfc822.size" => 250,
            internaldate => "date",
            bodystructure => {
               "MIME-Type" => "text", "MIME-TxtType" => "text/plain",
               "IMAP-Partnum" => "1", "Content-Transfer-Encoding" => "QUOTED-PRINTABLE",
               "Content-Type" => { charset => "utf-8" },
            },
         };
         $out{$uid}{body} = "H=C3=A4llo" if $items =~ /body\.peek\[1\]/i;
         $out{$uid}{body} = "From: a\r\n\r\nhello" if $items =~ /body\.peek\[\]/i;
         $out{$uid}{headers} = { "x-test" => ["yes"] } if $items =~ /header\.fields/i;
      }
      \%out
   }
   sub store { $seen{store} = [@_]; 1 }
   sub copy { $seen{copy} = [@_]; 1 }
   sub move { $seen{move} = [@_]; 1 }
   sub append { $seen{append} = [@_]; wantarray ? () : 1 }
   sub expunge { ++$seen{expunge}; 1 }
   sub uidexpunge { $seen{uidexpunge} = [@_]; 1 }
   sub create { $seen{create} = [@_]; 1 }
   sub logout { 1 }
}

{
   no warnings "redefine";
   local *Mail::IMAPTalk::new = sub { IMAPMock->new };
   local %IMAPMock::cap = (move => 1, uidplus => 1);

   my ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("connect", {
      server => "example.org", port => 993, tls => "ssl", user => "a", password => "secret",
   });
   ok $ok, "connected with mock Mail::IMAPTalk";
   is $result->{connected}, 1, "authenticated";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("mailboxes", {});
   ok $ok, "list";
   is scalar @{$result->{mailboxes}}, 2, "two mailboxes";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("lsub", {});
   ok $ok, "lsub";
   is_deeply $result->{mailboxes}, [["", "/", "INBOX"]], "only subscribed mailboxes returned";

   my $nodes = 0;
   my @criteria = AnyEvent::MCP::Worker::IMAP::search_filter ({
      since => "1-Nov-2026",
      any => [
         { from => "alice\@example.org" },
         { subject => "invoice", body => "overdue" },
         { text => "last chance" },
      ],
      not => { flagged => JSON::XS::true },
      all => [
         { header => { "X-Test" => "(UNSEEN)" }, larger => 512 },
         { sent_before => "5-Nov-2026", cc => "jane\@example.org" },
      ],
   }, 0, \$nodes);
   is_deeply \@criteria, [
      ["HEADER", "X-Test", { Quote => "(UNSEEN)" }, "LARGER", 512],
      ["CC", { Quote => "jane\@example.org" }, "SENTBEFORE", "5-Nov-2026"],
      "OR", ["FROM", { Quote => "alice\@example.org" }],
      ["OR", ["BODY", { Quote => "overdue" }, "SUBJECT", { Quote => "invoice" }],
         ["TEXT", { Quote => "last chance" }]],
      "NOT", ["FLAGGED"], "SINCE", "1-Nov-2026",
   ], "recursive AND, OR, NOT compile to grouped IMAP SEARCH arguments";

   my $wire = Mail::IMAPTalk::_send_data (bless ({}, "Mail::IMAPTalk"), {}, "", @criteria);
   like $wire, qr/HEADER X-Test "\Q(UNSEEN)\E"/, "SEARCH parentheses are quoted as a value";
   like $wire, qr/OR \(FROM "alice\@example\.org"\) \(OR /, "multiple OR alternatives are grouped";
   like $wire, qr/NOT \(FLAGGED\)/, "NOT scopes its operand";

   for my $bad (
      { any => [] }, { all => [ {} ] }, { not => {} },
      { any => [ { subject => "x" }, { bogus => 1 } ] },
      { header => { "X) OR ALL" => "injection" } },
      { header => { "X-Test" => [] } },
      { larger => "123x" }, { sent_since => "yesterday" }, { unseen => [] },
   ) {
      my $nodes = 0;
      my $ok = eval { AnyEvent::MCP::Worker::IMAP::search_filter ($bad, 0, \$nodes); 1 };
      ok !$ok && $@, "invalid SEARCH filter rejected";
   }
   {
      my $nested = { subject => "x" };
      $nested = { not => $nested } for 1 .. 15;
      my $nodes = 0;
      my $ok = eval { AnyEvent::MCP::Worker::IMAP::search_filter ($nested, 0, \$nodes); 1 };
      ok !$ok && $@ =~ /too complex/, "SEARCH nesting depth bounded";
   }
   {
      my $nodes = 0;
      is_deeply [AnyEvent::MCP::Worker::IMAP::search_filter ({ unseen => JSON::XS::false }, 0, \$nodes)], [],
         "false flag preserves existing no-filter behavior";
   }

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("messages", {
      mailbox => "INBOX", limit => 2, fields => [qw(subject flags)],
      filter => { subject => "test" },
   });
   ok $ok, "page";
   is_deeply [map $_->{uid}, @{$result->{messages}}], [2900, 2200], "newest UIDs";
   is $result->{next_cursor}{before_uid}, 2200, "cursor anchored after returned messages";
   like $IMAPMock::seen{search}[0], qr/^\d+:\d+$/, "bounded search window";
   like $IMAPMock::seen{fetch}[1], qr/envelope/, "only requested summaries fetched";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("messages", {
      mailbox => "INBOX", limit => 2, cursor => $result->{next_cursor},
   });
   is_deeply [map $_->{uid}, @{$result->{messages}}], [1001, 20], "cursor resumes lower UIDs";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("messages", {
      mailbox => "INBOX", limit => 2,
      filter => { any => [{ from => "alice" }, { subject => "invoice" }], not => { deleted => 1 } },
   });
   ok $ok, "Boolean SEARCH integrated with message pagination";
   is_deeply [@{$IMAPMock::seen{search}}[1 .. 5]],
      ["OR", ["FROM", { Quote => "alice" }], ["SUBJECT", { Quote => "invoice" }], "NOT", ["DELETED"]],
      "pagination sends grouped SEARCH terms to IMAP";

   {
      local $IMAPMock::uidnext = 3501;
      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("messages", {
         mailbox => "INBOX", limit => 1,
      });
      is $result->{messages}[0]{uid}, 3200, "newly arrived mail visible despite cached SELECT";
      ok $IMAPMock::seen{status}, "UIDNEXT refreshed using STATUS";
   }

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("messages", {
      mailbox => "INBOX", cursor => { uidvalidity => 124, before_uid => 200 },
   });
   ok !$ok && $result =~ /stale|invalid/i, "stale cursor rejected";

   my %id = (mailbox => "INBOX", uidvalidity => "123", uid => 2900);

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("message", \%id);
   ok $ok && $result->{bodystructure}, "read MIME bodystructure";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("part", { %id, part => "1", decode_text => 1 });
   is $result->{text}, "H\x{e4}llo", "MIME QP and UTF-8 decoded";
   like $IMAPMock::seen{fetch}[1], qr/bodystructure/, "part fetch uses MIME structure";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("raw", \%id);
   is MIME::Base64::decode_base64 ($result->{data_base64}), "From: a\r\n\r\nhello", "raw message returned";
   is $result->{truncated}, 0, "raw not truncated";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("flags", {
      mailbox => "INBOX", uidvalidity => 123, uids => [2900],
      operation => "add", flags => ["\\Deleted"],
   });
   ok $ok, "mark deleted";
   is $IMAPMock::seen{expunge} || 0, 0, "mark deleted does not expunge";
   is $IMAPMock::seen{store}[2], "+flags.silent", "silent flag update";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("flags", {
      mailbox => "INBOX", uidvalidity => 123, uids => [2900],
      operation => "EXPUNGE", flags => ["\\Deleted"],
   });
   ok !$ok, "invalid flag operation rejected";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("mailbox", {
      mailbox => "INBOX", operation => "close",
   });
   ok !$ok && $result =~ /invalid mailbox operation/i, "arbitrary method invocation rejected";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("move", {
      mailbox => "INBOX", uidvalidity => 123, uids => [2900], destination => "Archive",
   });
   ok $ok && $IMAPMock::seen{move}, "MOVE used when advertised";

   {
      local $IMAPMock::cap{move} = 0;
      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("move", {
         mailbox => "INBOX", uidvalidity => 123, uids => [2900], destination => "Archive",
      });
      ok !$ok && $result =~ /MOVE/, "no multi-step MOVE emulation";
   }

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("append", {
      mailbox => "INBOX", data_base64 => MIME::Base64::encode_base64 ("From: a\r\n\r\nhello", ""),
   });
   ok $ok && $IMAPMock::seen{append}, "APPEND raw RFC 5322";

   my $head = "From: alice\@example.org\r\nSubject: sample\r\n\r\n";
   for my $case (
      ["ordinary prose",      "From home we returned\r\n",                1],
      ["no date clue",        "From sender some words\r\n",              1],
      ["two-digit number",    "From sender 25\r\n",                      0, 4],
      ["four-digit year",     "From sender 2026\r\n",                    0, 4],
      ["weekday",             "From sender Sat\r\n",                     0, 4],
      ["month",               "From sender Oct\r\n",                     0, 4],
      ["ctime separator",     "hello\r\nFrom someone Sat Oct 24 20:05:09 2026\r\n", 0, 5],
      ["tab spacing",         "From\tsender\t2026\r\n",                 0, 4],
      ["LF after delimiter",  "hello\nFrom sender 12\n",                 0, 5],
      ["mboxo escaping",      ">From sender Sat Oct 24 20:05:09 2026\r\n", 1],
      ["header with From:",  "From: mailbox header\r\n",               1],
   ) {
      my ($label, $body, $allowed, $line) = @$case;
      undef $IMAPMock::seen{append};
      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("append", {
         mailbox => "INBOX", data_base64 => MIME::Base64::encode_base64 ($head . $body, ""),
      });
      is !!$ok, !!$allowed, "APPEND $label " . ($allowed ? "allowed" : "blocked");
      is !!$IMAPMock::seen{append}, !!$allowed, "APPEND $label: no unexpected server write";
      if (!$allowed) {
         like $result, qr/raw message line $line\b/, "APPEND $label: exact raw line number";
         like $result, qr/mboxo From_ separator.*new message boundary/s, "APPEND $label: explains mboxo corruption risk";
      }
   }

   my %login = (server => "example.org", port => 993, tls => "ssl", user => "a", password => "secret");
   ($ok) = AnyEvent::MCP::Worker::IMAP::run ("connect", { %login, allow_mbox_from => 1 });
   ok $ok, "override enabled by connection settings";
   ($ok) = AnyEvent::MCP::Worker::IMAP::run ("append", {
      mailbox => "INBOX", data_base64 => MIME::Base64::encode_base64 ($head . "From sender Sat Oct 24 20:05:09 2026\r\n", ""),
   });
   ok $ok, "operator override permits otherwise rejected message";

   ($ok) = AnyEvent::MCP::Worker::IMAP::run ("connect", \%login);
   ok $ok, "default safety restored on reconnect";
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("append", {
      mailbox => "INBOX", data_base64 => MIME::Base64::encode_base64 ($head . "From sender Sat Oct 24 20:05:09 2026\r\n", ""),
      allow_mbox_from => 1,
   });
   ok !$ok && $result =~ /--allow-mbox-from/, "APPEND arguments cannot override server safety setting";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("append", {
      mailbox => "INBOX", data_base64 => MIME::Base64::encode_base64 (
         "From sender Sat Oct 24 20:05:09 2026\r\nFrom: alice\@example.org\r\n\r\nhello", ""),
   });
   ok !$ok, "suspicious From_ line rejected even before RFC 5322 headers";
   like $result, qr/raw message line 1\b/, "diagnostic points to first raw line";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("append", {
      mailbox => "INBOX", data_base64 => "ignored!garbage",
   });
   ok !$ok, "invalid Base64 rejected";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("expunge", {
      mailbox => "INBOX", uidvalidity => 123, uids => [2900],
   });
   ok $ok && $IMAPMock::seen{uidexpunge}, "UID EXPUNGE";

   {
      local $IMAPMock::cap{uidplus} = 0;
      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("expunge", {
         mailbox => "INBOX", uidvalidity => 123, uids => [2900],
      });
      ok !$ok && $result =~ /UIDPLUS/, "no dangerous UID EXPUNGE fallback";
   }

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("expunge", {
      mailbox => "INBOX", uidvalidity => 123,
   });
   ok $ok && $IMAPMock::seen{expunge} == 1, "whole-mailbox EXPUNGE only when explicitly asked";
}

SKIP: {
   skip "socketpair/fork unavailable", 2 if $^O eq "MSWin32";

   require Socket;
   socketpair (my $client, my $server,
      Socket::AF_UNIX (), Socket::SOCK_STREAM (), Socket::PF_UNSPEC ())
      or die "socketpair: $!";
   my $pid = fork;
   defined $pid or die "fork: $!";

   unless ($pid) {
      close $client;
      my $old = select $server;
      $| = 1;
      select $old;

      for (1..2) {
         my $line = <$server> or last;
         my ($tag) = split /\s+/, $line;
         my $header = $line =~ /header\.fields/i;
         my $body = $header ? "Subject: yep\r\n\r\n" : "hello";
         my $section = $header ? "BODY[HEADER.FIELDS (SUBJECT)]" : "BODY[1]<0>";
         print {$server} "* 1 FETCH (UID 42 $section {" . length ($body)
            . "}\r\n$body)\r\n$tag OK FETCH done\r\n";
      }
      exit;
   }

   close $server;
   my $imap = Mail::IMAPTalk->new (
      Socket => $client, State => Mail::IMAPTalk::Authenticated,
      Uid => 1, UseBlocking => 1, PreserveINBOX => 1,
   );
   my $body = $imap->fetch (42, "body.peek[1]<0.5>");
   is $body->{42}{body}, "hello", "real Mail::IMAPTalk partial BODY.PEEK uses body key";
   my $head = $imap->fetch (42, "body.peek[header.fields (SUBJECT)]");
   is_deeply $head->{42}{headers}{subject}, ["yep"], "real header field PEEK returns parsed headers";
   $imap->release_socket;
   close $client;
   waitpid $pid, 0;
}

done_testing;
