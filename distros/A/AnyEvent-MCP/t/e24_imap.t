use common::sense;
use Test::More;
BEGIN {
   plan skip_all => "extended imap test (PERL_ANYEVENT_MCP_TESTS=1)"
      unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;
}

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
   our (%seen, %cap, $uidnext, $messages, @fetches);
   $uidnext = 3001;
   $messages = 0;

   sub new { bless {}, shift }
   sub login { 1 }
   sub uid { 1 }
   sub parse_mode { 1 }
   sub is_open { 1 }
   sub state { $_[0]{state} = $_[1] if @_ > 1; $_[0]{state} }
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
   sub status {
      $seen{status}++;
      $seen{status_args} = [@_];
      { uidnext => $uidnext, uidvalidity => 123, messages => $messages }
   }
   sub search {
      my ($self, $range, @criteria) = @_;
      $seen{search} = [$range, @criteria];
      my ($lo, $hi) = split /:/, $range;
      my $uids = [grep $_ >= $lo && $_ <= $hi, (20, 1001, 2200, 2900, 3200)];
      wantarray ? @$uids : $uids
   }
   sub fetch {
      my ($self, $uids, $items) = @_;
      push @fetches, [$uids, $items];
      $seen{fetch} = [$uids, $items];
      my @uid = ref $uids ? @$uids : ($uids);
      my %out;
      for my $uid (@uid) {
         next if $uid == 9999;
         $out{$uid} = {
            envelope => { Subject => "test $uid", From => "sender\@example.org", Date => "date" },
            flags => ["\\Seen"], "rfc822.size" => 250,
            internaldate => "date",
            bodystructure => {
               "MIME-Type" => "text", "MIME-Subtype" => "plain", "MIME-TxtType" => "text/plain",
               "IMAP-Partnum" => "1", "Content-Transfer-Encoding" => "QUOTED-PRINTABLE",
               "Content-Type" => { charset => "utf-8" },
            },
         };
         if ($uid == 3200) {
            $out{$uid}{envelope}{Subject} = "=?UTF-8?B?5pel5pys6Kqe?=";
            $out{$uid}{envelope}{From} = '"=?ISO-8859-1?Q?Andr=E9?=" <andre@example.org>';
            $out{$uid}{bodystructure} = {
               "MIME-Type" => "multipart", "MIME-Subtype" => "alternative",
               "MIME-Subparts" => [
                  {
                     "MIME-Type" => "text", "MIME-Subtype" => "plain",
                     "IMAP-Partnum" => "1", "Content-Transfer-Encoding" => "7BIT",
                     "Content-Type" => { charset => "utf-8" },
                  },
                  {
                     "MIME-Type" => "text", "MIME-Subtype" => "html",
                     "IMAP-Partnum" => "2", "Content-Transfer-Encoding" => "QUOTED-PRINTABLE",
                     "Content-Type" => { charset => "utf-8" },
                  },
               ],
            };
            $out{$uid}{bodystructure} = {
               "MIME-Type" => "multipart", "MIME-Subtype" => "mixed",
               "MIME-Subparts" => [
                  $out{$uid}{bodystructure},
                  {
                     "MIME-Type" => "image", "MIME-Subtype" => "jpeg",
                     "MIME-TxtType" => "image/jpeg", "IMAP-Partnum" => "3",
                     "Disposition-Type" => "attachment",
                     "Content-Disposition" => { filename => "IMG_3593.jpg" },
                     "Size" => 3496802,
                  },
               ],
            };
         } elsif ($uid == 2200) {
            $out{$uid}{bodystructure} = {
               "MIME-Type" => "text", "MIME-Subtype" => "html",
               "IMAP-Partnum" => "1", "Content-Transfer-Encoding" => "7BIT",
               "Content-Type" => { charset => "utf-8" },
            };
         }
         $out{$uid}{body} = "H=C3=A4llo" if $items =~ /body\.peek\[1\]/i;
         $out{$uid}{body} = "View this message on the web." if $uid == 3200 && $items =~ /body\.peek\[1\]/i;
         $out{$uid}{body} = '<html><head><script>ignore()</script></head><body><p>Actual message: <a href="https://example.invalid/login">click here</a> for details and the full report.</p></body></html>'
            if $uid == 2200 && $items =~ /body\.peek\[1\]/i;
         $out{$uid}{body} = '<html><body><p>Important bug details: <a href=3D"https://example.invalid/issue">click here</a> to read the complete reproducer, complete with relevant metadata.</p></body></html>'
            if $uid == 3200 && $items =~ /body\.peek\[2\]/i;
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
   sub delete { $seen{delete} = [@_]; 1 }
   sub logout { 1 }
}

{
   no warnings "redefine";
   local *Mail::IMAPTalk::new = sub { IMAPMock->new };
   local %IMAPMock::cap = (move => 1, uidplus => 1);

   my ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("connect", {
      server => "example.org", port => 993, tls => "connect", user => "a", password => "secret",
   });
   ok $ok, "connected with mock Mail::IMAPTalk";
   is $result->{connected}, 1, "authenticated";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("mailboxes", {});
   ok $ok, "list";
   is scalar @{$result->{mailboxes}}, 2, "two mailboxes";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("lsub", {});
   ok $ok, "lsub";
   is_deeply $result->{mailboxes}, [["", "/", "INBOX"]], "only subscribed mailboxes returned";

   {
      local $IMAPMock::messages = 3;
      delete $IMAPMock::seen{delete};
      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("mailbox",
         { operation => "delete", mailbox => "Archive" });
      ok !$ok && $result =~ /contains 3 messages; use force/, "nonempty mailbox deletion refused";
      ok !$IMAPMock::seen{delete}, "refused deletion never sends DELETE";
      is_deeply [@{$IMAPMock::seen{status_args}}[1, 2]], ["Archive", "(MESSAGES)"],
         "delete checks STATUS MESSAGES on the target mailbox";

      my $checks = $IMAPMock::seen{status};
      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("mailbox",
         { operation => "delete", mailbox => "Archive", force => JSON::XS::true });
      ok $ok && $result->{ok}, "force allows deleting nonempty mailbox";
      is $IMAPMock::seen{delete}->[1], "Archive", "forced deletion sends DELETE";
      is $IMAPMock::seen{status}, $checks, "force bypasses STATUS";
   }

   {
      local $IMAPMock::messages = 0;
      delete $IMAPMock::seen{delete};
      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("mailbox",
         { operation => "delete", mailbox => "Empty" });
      ok $ok && $result->{ok}, "empty mailbox can be deleted without force";
      is $IMAPMock::seen{delete}->[1], "Empty", "empty deletion sends DELETE";
   }

   {
      local $IMAPMock::messages;
      delete $IMAPMock::seen{delete};
      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("mailbox",
         { operation => "delete", mailbox => "Unknown" });
      ok !$ok && $result =~ /did not report mailbox message count/, "missing STATUS count refuses deletion";
      ok !$IMAPMock::seen{delete}, "missing STATUS count never sends DELETE";
   }

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
      is $result->{messages}[0]{subject}, "\x{65e5}\x{672c}\x{8a9e}", "RFC2047 subject decoded in messages";
      is $result->{messages}[0]{from}, '"Andr' . "\x{e9}" . '" <andre@example.org>',
         "RFC2047 display name decoded in messages";
      ok $IMAPMock::seen{status}, "UIDNEXT refreshed using STATUS";
   }

   {
      local $IMAPMock::uidnext = 25001;
      my $filter = { subject => "test" };

      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("messages", {
         mailbox => "INBOX", limit => 2, filter => $filter,
      });
      ok $ok && !@{$result->{messages}}, "sparse UID scan returns an empty page";
      ok $result->{incomplete} && $result->{more}, "empty, incomplete page reports more work";
      is $result->{next_cursor}{before_uid}, 5001, "empty page continues beyond 20000 UID scan budget";

      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("messages", {
         mailbox => "INBOX", limit => 2, filter => $filter, cursor => $result->{next_cursor},
      });
      is_deeply [map $_->{uid}, @{$result->{messages}}], [3200, 2900],
         "continuation reaches matches in older sparse UID interval";
      ok $result->{more} && !$result->{incomplete} && $result->{next_cursor},
         "ordinary full page has matching continuation";

      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("messages", {
         mailbox => "INBOX", limit => 100, filter => $filter, cursor => { uidvalidity => 123, before_uid => 5001 },
      });
      is_deeply [map $_->{uid}, @{$result->{messages}}], [3200, 2900, 2200, 1001, 20],
         "final sparse UID page yields all remaining matches";
      ok !$result->{more} && !$result->{incomplete} && !$result->{next_cursor},
         "more is false only when search is exhausted";
   }

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("messages", {
      mailbox => "INBOX", cursor => { uidvalidity => 124, before_uid => 200 },
   });
   ok !$ok && $result =~ /stale|invalid/i, "stale cursor rejected";

   delete $IMAPMock::seen{search};
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("messages", {
      mailbox => "INBOX", uidvalidity => 123,
      uids => [2200, 9999, 2900], fields => ["subject"],
   });
   ok $ok, "explicit UID summary batch";
   is_deeply [map $_->{uid}, @{$result->{messages}}], [2200, 2900],
      "targeted summary order preserved, vanished UID omitted";
   is_deeply $result->{missing_uids}, [9999], "missing UIDs reported";
   ok !exists $IMAPMock::seen{search} && !$result->{next_cursor},
      "explicit UID summaries skip SEARCH and cursor";

   {
      no warnings "redefine";
      local $IMAPMock::uidnext = 2001;
      local *IMAPMock::search = sub {
         my ($self, $range) = @_;
         my ($lo, $hi) = split /:/, $range;
         [grep $_ >= $lo && $_ <= $hi, 1 .. 1200]
      };

      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("messages", {
         mailbox => "INBOX", fields => ["uid"],
      });
      ok $ok && @{$result->{messages}} == 100, "default messages page has 100 summaries";
      is $result->{messages}[0]{uid}, 1200, "default page starts with newest UID";

      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("messages", {
         mailbox => "INBOX", limit => 1000, fields => ["uid"],
      });
      ok $ok && @{$result->{messages}} == 1000, "messages accepts 1000-summary page";
      is $result->{messages}[-1]{uid}, 201, "1000-summary page preserves UID order";
      ok $result->{more} && $result->{next_cursor}{before_uid} == 201,
         "1000-summary page exposes continuation";

      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("messages", {
         mailbox => "INBOX", limit => 1001,
      });
      ok !$ok && $result =~ /limit must be 1\.\.1000/, "1001-summary page is rejected";
   }

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("messages", {
      mailbox => "INBOX", uidvalidity => 123, uids => [1 .. 1000], fields => ["uid"],
   });
   ok $ok && @{$result->{messages}} == 1000, "1000 explicit UIDs accepted";
   is $result->{messages}[0]{uid}, 1, "explicit UID batch retains requested order";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("messages", {
      mailbox => "INBOX", uidvalidity => 123, uids => [1 .. 1001],
   });
   ok !$ok && $result =~ /uids must contain 1\.\.1000/, "1001 explicit UIDs rejected";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("messages", {
      mailbox => "INBOX", uidvalidity => 124, uids => [2900],
   });
   ok !$ok && $result =~ /UIDVALIDITY mismatch/, "targeted summary batch rejects stale UIDVALIDITY";
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("messages", {
      mailbox => "INBOX", uidvalidity => 123, uids => [2900], cursor => {},
   });
   ok !$ok && $result =~ /cannot be combined/, "targeted summaries reject cursor combination";

   SKIP: {
      skip "HTML::Parser unavailable for HTML preview test", 9
         unless eval { require HTML::Parser; 1 };
      @IMAPMock::fetches = ();
      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("previews", {
         mailbox => "INBOX", uidvalidity => 123, uids => [3200, 2200, 2900, 9999],
         max_bytes => 512,
      });
      ok $ok, "read-only MIME preview batch";
      is scalar @IMAPMock::fetches, 3, "batched MIME preview uses three UID FETCH commands, not one per mail";
      is_deeply [map $_->{uid}, @{$result->{previews}}], [3200, 2200, 2900, 9999],
         "preview order matches requested UIDs";
      is $result->{previews}[0]{content_type}, "text/html", "stub plain text replaced by HTML";
      like $result->{previews}[0]{text}, qr{https://example\.invalid/issue},
         "HTML alternative preserves link target";
      is_deeply $result->{previews}[0]{attachments}, [{
         part => "3", type => "image/jpeg", name => "IMG_3593.jpg",
         size => 3496802, disposition => "attachment",
      }], "attachment synopsis available without fetching the image";
      ok !exists $result->{previews}[1]{attachments}, "no attachment metadata for ordinary text mail";
      unlike $result->{previews}[1]{text}, qr/ignore\(\)/, "HTML-only preview omits script contents";
      like $result->{previews}[1]{text}, qr{https://example\.invalid/login},
         "HTML-only preview preserves embedded link";
      is $result->{previews}[2]{text}, "H\x{e4}llo", "batch preview decodes quoted-printable UTF-8";
      like $result->{previews}[3]{error}, qr/vanished/, "vanished UID reported individually";
   }

   my $base64_part = {
      "MIME-Subtype" => "plain", "Content-Transfer-Encoding" => "BASE64",
      "Content-Type" => { charset => "utf-8" }, "IMAP-Partnum" => "1",
   };
   my $partial = AnyEvent::MCP::Worker::IMAP::preview_decode ($base64_part,
      MIME::Base64::encode_base64 ("Hello world", ""), 7);
   is $partial->{text}, "Hel", "incomplete trailing Base64 group discarded";
   ok $partial->{truncated}, "partial Base64 preview explicitly marked truncated";
   $partial = AnyEvent::MCP::Worker::IMAP::preview_decode ({
      %$base64_part, "Content-Transfer-Encoding" => "8BIT",
   }, "A\xc3\xa4llo", 2);
   is $partial->{text}, "A", "partial UTF-8 sequence excluded from preview";
   ok $partial->{truncated}, "incomplete UTF-8 marks truncated preview";

   SKIP: {
      skip "optional Encode::HanExtra is unavailable", 2
         unless Encode::find_encoding ("GB18030");
      my $chinese = "\x{4e2d}\x{6587}";
      my $bytes = MIME::QuotedPrint::encode_qp (Encode::encode ("GB18030", $chinese));
      my $node = {
         "MIME-Type" => "text", "MIME-Subtype" => "plain",
         "MIME-TxtType" => "text/plain", "IMAP-Partnum" => "1",
         "Content-Transfer-Encoding" => "QUOTED-PRINTABLE",
         "Content-Type" => { charset => "GB18030" },
      };
      ok Encode::find_encoding ("GB18030"), "optional GB18030 encoding registered by IMAP worker";
      is AnyEvent::MCP::Worker::IMAP::preview_decode ($node, $bytes, 1000)->{text},
         $chinese, "preview decodes GB18030 quoted-printable text";
   }

   my %id = (mailbox => "INBOX", uidvalidity => "123", uid => 2900);

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("message", \%id);
   ok $ok && $result->{bodystructure}, "read MIME bodystructure";
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("message", { %id, uid => 3200 });
   is $result->{envelope}{Subject}, "\x{65e5}\x{672c}\x{8a9e}", "RFC2047 subject decoded in message detail";
   is $result->{envelope}{From}, '"Andr' . "\x{e9}" . '" <andre@example.org>',
      "RFC2047 display name decoded in message detail";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("part", { %id, part => "1", decode_text => 1 });
   is $result->{text}, "H\x{e4}llo", "MIME QP and UTF-8 decoded";
   like $IMAPMock::seen{fetch}[1], qr/bodystructure/, "part fetch uses MIME structure";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("raw", \%id);
   is MIME::Base64::decode_base64 ($result->{data_base64}), "From: a\r\n\r\nhello", "raw message returned";
   is $result->{truncated}, 0, "raw not truncated";
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("raw", { %id, max_bytes => 4 });
   ok $ok && $result->{truncated}, "partial raw FETCH reports truncation";
   is MIME::Base64::decode_base64 ($result->{data_base64}), "From",
      "partial raw FETCH actually truncates to max_bytes";

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

   my %login = (server => "example.org", port => 993, tls => "connect", user => "a", password => "secret");
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

{
   no warnings "redefine";
   my (%args, $upgrades, $handshakes, $mock);
   local *Mail::IMAPTalk::new = sub {
      my ($class, %options) = @_;
      %args = %options;
      $mock = IMAPMock->new;
   };
   local *IMAPMock::_imap_cmd = sub { ++$upgrades; 1 };
   local *IO::Socket::SSL::start_SSL = sub { ++$handshakes; 1 };
   my %login = (server => "localhost", user => "alice", password => "secret");

   my ($ok) = AnyEvent::MCP::Worker::IMAP::run ("connect",
      { %login, port => 143, tls => "none" });
   ok $ok && !$args{UseSSL} && !$upgrades && !$handshakes,
      "tls none authenticates over cleartext without STARTTLS or TLS";
   ok $mock->{UseBlocking}, "cleartext IMAP worker uses blocking socket operations";

   ($ok) = AnyEvent::MCP::Worker::IMAP::run ("connect",
      { %login, port => 993, tls => "connect" });
   ok $ok && $args{UseSSL} && !$upgrades && !$handshakes,
      "tls connect uses TLS immediately";

   my ($success, $error) = AnyEvent::MCP::Worker::IMAP::run ("connect",
      { %login, port => 993, tls => "ssl" });
   ok !$success && $error =~ /Invalid IMAP TLS mode/,
      "old ssl mode is rejected instead of silently disabling TLS";

   ($ok) = AnyEvent::MCP::Worker::IMAP::run ("connect",
      { %login, port => 143, tls => "starttls" });
   ok $ok && !$args{UseSSL} && $upgrades == 1 && $handshakes == 1,
      "tls starttls performs explicit upgrade before authentication";
}

{
   no warnings "redefine";
   my $logins;
   local *Mail::IMAPTalk::new = sub { IMAPMock->new };
   local *IMAPMock::login = sub { ++$logins; 1 };
   local %IMAPMock::cap = (logindisabled => 1);
   my %login = (server => "localhost", user => "root", password => "secret",
                port => 143, tls => "none");

   my ($ok, $error) = AnyEvent::MCP::Worker::IMAP::run ("connect", \%login);
   ok !$ok && $error =~ /LOGINDISABLED.*no supported AUTH mechanism/,
      "cleartext server that refuses LOGIN and offers no usable SASL reports the cause";
   is $logins || 0, 0, "no attempt to authenticate with an empty SASL mechanism list";

   $IMAPMock::cap{"auth=plain"} = 1;
   ($ok) = AnyEvent::MCP::Worker::IMAP::run ("connect", \%login);
   ok $ok && $logins == 1, "server-advertised AUTH PLAIN is not rejected";

   delete $IMAPMock::cap{"auth=plain"};
   delete $IMAPMock::cap{logindisabled};
   ($ok, $error) = AnyEvent::MCP::Worker::IMAP::run ("connect",
      { %login, password => "p\x{e4}ssword" });
   ok !$ok && $error =~ /non-ASCII password/,
      "non-ASCII password requiring SASL reports absent AUTH mechanisms";
}

{
   no warnings "redefine";
   my ($connections, $noops) = (0, 0);
   my $open = 1;
   local *Mail::IMAPTalk::new = sub { ++$connections; IMAPMock->new };
   local *IMAPMock::is_open = sub { $open };
   local *IMAPMock::noop = sub { ++$noops; 1 };
   local %IMAPMock::cap;
   my %login = (server => "localhost", port => 143, tls => "none", user => "root", password => "secret");

   my ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("connect", \%login);
   ok $ok && $connections == 1, "initial worker IMAP connection";
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("ping", {});
   ok $ok && $noops == 1, "keepalive sends NOOP on live session";
   is $connections, 1, "successful keepalive does not reconnect";

   $open = 0;
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("ping", {});
   ok !$ok && $result =~ /closed during keepalive/, "dead keepalive reports failure";
   is $connections, 1, "failed keepalive does not reconnect";

   $open = 1;
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("mailboxes", {});
   ok $ok && @{$result->{mailboxes}} == 2, "next tool succeeds after reconnect";
   is $connections, 2, "regular tool reconnects after failed ping";
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("ping", {});
   ok $ok && $noops == 2, "keepalive resumes on new session";

   {
      local *IMAPMock::noop = sub { ++$noops; undef };
      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("ping", {});
      ok !$ok && $result =~ /NOOP/, "NOOP refusal is reported";
   }
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("mailboxes", {});
   ok $ok && $connections == 3, "failed NOOP discards session even when socket appears open";

   {
      my ($ok, $error, $alive) = AnyEvent::MCP::Worker::IMAP::run ("mailbox",
         { mailbox => "INBOX", operation => "bad" });
      ok !$ok && $error =~ /Invalid mailbox operation/ && $alive,
         "application error keeps the IMAP connection alive for future keepalives";
   }

   {
      local *IMAPMock::list = sub { $open = 0; die "simulated disconnected LIST\n" };
      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("mailboxes", {});
      ok !$ok && $result =~ /simulated disconnected LIST/, "failure during operation reported, not retried";
      is $connections, 3, "failed read not silently retried";
   }
   $open = 1;
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("mailboxes", {});
   ok $ok && $connections == 4, "next read reconnects after in-operation failure";

   {
      my $warnings = "";
      local *STDERR;
      open STDERR, ">", \$warnings or die $!;
      local *IMAPMock::noop = sub {
         warn "unrelated IMAP warning\n";
         warn "IMAP keepalive timed out\n"; # IMAPTalk warns before rethrowing
         die "IMAP keepalive timed out\n";
      };
      my ($ok, $error) = AnyEvent::MCP::Worker::IMAP::run ("ping", {});
      ok !$ok && $error eq "IMAP keepalive timed out\n", "timeout still fails keepalive";
      is $warnings, "unrelated IMAP warning\n",
         "expected IMAPTalk timeout warning suppressed, other warnings preserved";
   }
}

{
   no warnings "redefine";
   my (@thread_args, $thread_calls);
   local *Mail::IMAPTalk::new = sub { IMAPMock->new };
   local %IMAPMock::cap = ("thread=orderedsubject" => 1);
   local *IMAPMock::thread = sub {
      @thread_args = @_;
      ++$thread_calls;
      [[100, 102, 111], [101], [104, 106]];
   };
   my %login = (server => "localhost", port => 143, tls => "none", user => "root", password => "secret");
   my ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("connect", \%login);
   ok $ok, "threading mock connected";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("threads", {
      mailbox => "INBOX", uid_range => "100:200", uidvalidity => 123,
      filter => { not => { deleted => 1 }, subject => "x(quoted)" },
   });
   ok $ok, "UID THREAD ORDEREDSUBJECT succeeds";
   is_deeply $result->{threads}, [[100, 102, 111], [101], [104, 106]],
      "nested UID threads retained in server order";
   is $result->{uidvalidity}, 123, "thread result includes mailbox UIDVALIDITY";
   is_deeply [@thread_args[1 .. $#thread_args]],
      ["ORDEREDSUBJECT", "UTF-8", "UID", "100:200", "NOT", ["DELETED"], "SUBJECT", { Quote => "x(quoted)" }],
      "bounded UID THREAD is sent with securely quoted SEARCH parameters";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("threads", {
      mailbox => "INBOX", filter => { before => "1-Feb-2021", undeleted => 1 },
   });
   ok $ok && !exists $result->{uid_range}, "threading works without uid_range";
   is_deeply [@thread_args[1 .. $#thread_args]],
      ["ORDEREDSUBJECT", "UTF-8", "BEFORE", "1-Feb-2021", "UNDELETED"],
      "thread SEARCH criteria select candidates without a UID range";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("threads", { mailbox => "INBOX" });
   ok $ok, "unrestricted threading succeeds";
   is_deeply [@thread_args[1 .. $#thread_args]], ["ORDEREDSUBJECT", "UTF-8", "ALL"],
      "unrestricted UID THREAD uses ALL";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("threads",
      { mailbox => "INBOX", uid_range => "1:300000" });
   ok $ok && $result->{uid_range} eq "1:300000", "wide UID interval allowed";
   is_deeply [@thread_args[1 .. $#thread_args]], ["ORDEREDSUBJECT", "UTF-8", "UID", "1:300000"],
      "optional wide UID interval sent to IMAP";

   for my $range ("0:100", "100:99", "1:*", "1:2 OR ALL", "1:99999999999", "4294967296:4294967297") {
      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("threads",
         { mailbox => "INBOX", uid_range => $range });
      ok !$ok && $result =~ /uid_range/, "invalid thread range rejected: $range";
   }
   is $thread_calls, 4, "invalid thread ranges never reach IMAP";
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("threads",
      { mailbox => "INBOX", uid_range => "1:300", uidvalidity => 124 });
   ok !$ok && $result =~ /UIDVALIDITY mismatch/, "threading checks supplied UIDVALIDITY";
   {
      local %IMAPMock::cap;
      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("threads",
         { mailbox => "INBOX", uid_range => "1:100" });
      ok !$ok && $result =~ /THREAD=ORDEREDSUBJECT/, "unsupported threading rejected";
   }
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("threads",
      { mailbox => "INBOX", uid_range => "1:100", filter => { bogus => 1 } });
   ok !$ok && $result =~ /Unknown SEARCH filter/, "threading uses validated SEARCH filters";
   is $thread_calls, 4, "invalid filtering never reaches server";
}

{
   no warnings "redefine";
   my ($sort_calls, @sort_args, $fail_sort) = (0);
   my $sort_size = 205;
   local *Mail::IMAPTalk::new = sub { IMAPMock->new };
   local %IMAPMock::cap = (sort => 1);
   local *IMAPMock::sort = sub {
      @sort_args = @_;
      ++$sort_calls;
      return if $fail_sort;
      [1001 .. 1000 + $sort_size];
   };
   my %login = (server => "localhost", port => 143, tls => "none", user => "root", password => "secret");
   my ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("connect", \%login);
   ok $ok, "SORT snapshot mock connected";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("sort_create", {
      mailbox => "INBOX", filter => { before => "1-Feb-2021", undeleted => 1 },
   });
   ok $ok, "create SORT snapshot with SEARCH filter";
   is_deeply [@sort_args[1 .. $#sort_args]],
      ["(SUBJECT DATE)", "UTF-8", "BEFORE", "1-Feb-2021", "UNDELETED"],
      "SORT uses subject/date and selected search criteria";
   is $result->{count}, 205, "snapshot contains all sorted UIDs";
   is_deeply $result->{uids}, [1001 .. 1100], "first page contains 100 UIDs";
   is $result->{next_offset}, 100, "first page exposes continuation offset";
   is $result->{uidvalidity}, 123, "snapshot accompanies UIDVALIDITY";
   my $id = $result->{snapshot_id};
   like $id, qr/\A[0-9a-f]{32}\z/, "snapshot ID is opaque and random";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("sort_page", {
      mailbox => "INBOX", snapshot_id => $id, offset => 100, limit => 100,
   });
   is_deeply $result->{uids}, [1101 .. 1200], "second page from cached sorted UIDs";
   is $result->{next_offset}, 200, "third page available";
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("sort_page", {
      mailbox => "INBOX", snapshot_id => $id, offset => 200,
   });
   is_deeply $result->{uids}, [1201 .. 1205], "short final page preserved";
   ok !defined $result->{next_offset}, "last page has no cursor";
   is $sort_calls, 1, "paging never repeats SORT";

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("sort_page", {
      mailbox => "INBOX", snapshot_id => $id, offset => 206,
   });
   ok !$ok && $result =~ /offset beyond/, "out-of-range page refused";
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("sort_page", {
      mailbox => "INBOX", snapshot_id => $id, offset => 205,
   });
   ok $ok && !@{$result->{uids}} && !defined $result->{next_offset}, "end offset is empty";

   $fail_sort = 1;
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("sort_create", { mailbox => "INBOX" });
   ok !$ok && $result =~ /UID SORT/, "failed sort reported";
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("sort_page", {
      mailbox => "INBOX", snapshot_id => $id,
   });
   ok $ok, "failed sort does not replace existing snapshot";
   $fail_sort = 0;

   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("sort_create", { mailbox => "INBOX", limit => 2 });
   ok $ok, "unrestricted snapshot created";
   is_deeply [@sort_args[1 .. $#sort_args]], ["(SUBJECT DATE)", "UTF-8", "ALL"],
      "unrestricted UID SORT uses ALL";
   is_deeply $result->{uids}, [1001, 1002], "custom page size used";
   my $new_id = $result->{snapshot_id};
   isnt $new_id, $id, "successful new sort replaces snapshot";
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("sort_page", {
      mailbox => "INBOX", snapshot_id => $id,
   });
   ok !$ok && $result =~ /stale/, "replaced snapshot ID rejected";
   {
      local *IMAPMock::get_response_code = sub { $_[1] eq "uidvalidity" ? 124 : undef };
      ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("sort_page", {
         mailbox => "INBOX", snapshot_id => $new_id,
      });
      ok !$ok && $result =~ /UIDVALIDITY/, "snapshot detects mailbox UIDVALIDITY changes";
   }
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("sort_discard", {
      mailbox => "INBOX", snapshot_id => $new_id,
   });
   ok $ok && $result->{ok}, "discard snapshot explicitly";
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("sort_page", {
      mailbox => "INBOX", snapshot_id => $new_id,
   });
   ok !$ok && $result =~ /No SORT snapshot/, "discarded snapshot cannot be reused";
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("sort_create", { mailbox => "INBOX", limit => 1001 });
   ok !$ok && $result =~ /limit/, "invalid limit rejected before SORT";
   is $sort_calls, 3, "invalid creation never reaches SORT";

   $sort_size = 1205;
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("sort_create", {
      mailbox => "INBOX", limit => 1000,
   });
   ok $ok, "SORT snapshot allows 1000 UIDs on first page";
   is_deeply $result->{uids}, [1001 .. 2000], "large first page preserves ordered UID list";
   is $result->{next_offset}, 1000, "large page has correct continuation offset";
   is $result->{count}, 1205, "large-page snapshot contains all matching UIDs";
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("sort_page", {
      mailbox => "INBOX", snapshot_id => $result->{snapshot_id},
      offset => 1000, limit => 1000,
   });
   ok $ok, "SORT page accepts 1000 UID limit";
   is_deeply $result->{uids}, [2001 .. 2205], "large page retrieves remaining sorted UIDs";
   ok !defined $result->{next_offset}, "large page ends at snapshot boundary";
   ($ok, $result) = AnyEvent::MCP::Worker::IMAP::run ("sort_page", {
      mailbox => "INBOX", snapshot_id => $result->{snapshot_id}, limit => 1001,
   });
   ok !$ok && $result =~ /limit/, "page rejects limits exceeding 1000";
   is $sort_calls, 4, "large page reuse does not repeat SORT";
}

SKIP: {
   skip "socketpair/fork unavailable", 4 if $^O eq "MSWin32";

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
      for my $pattern (
         qr/\A\S+ UID THREAD ORDEREDSUBJECT UTF-8 UID 100:200\r\n\z/i,
         qr/\A\S+ UID THREAD ORDEREDSUBJECT UTF-8 ALL\r\n\z/i,
         qr/\A\S+ UID THREAD ORDEREDSUBJECT UTF-8 BEFORE 1-Feb-2021 UNDELETED\r\n\z/i,
      ) {
         my $line = <$server>;
         exit 1 unless $line && $line =~ $pattern;
         my ($tag) = split /\s+/, $line;
         print {$server} "* THREAD (100 (102 111))(101)(104 (106))\r\n$tag OK THREAD done\r\n";
      }
      exit 0;
   }
   close $server;
   my $imap = Mail::IMAPTalk->new (
      Socket => $client, State => Mail::IMAPTalk::Authenticated,
      Uid => 1, UseBlocking => 1, PreserveINBOX => 1,
   );
   my $tree = $imap->thread ("ORDEREDSUBJECT", "UTF-8", "UID", "100:200");
   is_deeply $tree, [[100, [102, 111]], [101], [104, [106]]],
      "real Mail::IMAPTalk parses nested UID THREAD response";
   $tree = $imap->thread ("ORDEREDSUBJECT", "UTF-8", "ALL");
   is_deeply $tree, [[100, [102, 111]], [101], [104, [106]]],
      "real Mail::IMAPTalk sends UID THREAD with ALL";
   $tree = $imap->thread ("ORDEREDSUBJECT", "UTF-8", "BEFORE", "1-Feb-2021", "UNDELETED");
   is_deeply $tree, [[100, [102, 111]], [101], [104, [106]]],
      "real Mail::IMAPTalk sends UID THREAD with SEARCH criteria only";
   $imap->release_socket;
   close $client;
   waitpid $pid, 0;
   is $? >> 8, 0, "real UID THREAD commands use bounded, ALL and filtered SEARCH syntax";
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
      my $line = <$server>;
      my ($tag) = split /\s+/, $line;
      print {$server} "* SORT 42 7 99\r\n$tag OK SORT done\r\n";
      exit ($line =~ /\A\S+ UID SORT \(SUBJECT DATE\) UTF-8 BEFORE 1-Feb-2021 UNDELETED\r\n\z/i ? 0 : 1);
   }
   close $server;
   my $imap = Mail::IMAPTalk->new (
      Socket => $client, State => Mail::IMAPTalk::Authenticated,
      Uid => 1, UseBlocking => 1, PreserveINBOX => 1,
   );
   my $uids = $imap->sort ("(SUBJECT DATE)", "UTF-8", "BEFORE", "1-Feb-2021", "UNDELETED");
   is_deeply $uids, [42, 7, 99], "real Mail::IMAPTalk preserves SORT UID order";
   $imap->release_socket;
   close $client;
   waitpid $pid, 0;
   is $? >> 8, 0, "real UID SORT uses normalized subject, sent date, and SEARCH criteria";
}

done_testing;
