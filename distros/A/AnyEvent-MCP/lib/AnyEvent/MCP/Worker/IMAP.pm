package AnyEvent::MCP::Worker::IMAP;

use common::sense;
use Mail::IMAPTalk ();
use IO::Socket::SSL ();
use MIME::Base64 ();
use MIME::QuotedPrint ();
use Encode ();
use JSON::XS ();

# mboxo stores raw messages without reliably escaping From_ lines.
# check the original bytes, not decoded MIME parts; never rewrite the message.
sub mbox_from {
   my ($bytes) = @_;
   $bytes =~ /^From[ \t]+\S+[ \t]+[^\r\n]*
             (?: [0-9]{2}
                | \b(?i:Mon|Tue|Wed|Thu|Fri|Sat|Sun
                       |Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\b
             )/mx or return;

   1 + ((substr $bytes, 0, $-[0]) =~ tr/\n//)
}

my ($imap, $config);

sub imap_connect {
   my ($settings) = @_;

   $config = $settings;
   undef $imap;

   my %tls = (
      SSL_verify_mode     => IO::Socket::SSL::SSL_VERIFY_PEER (),
      SSL_verifycn_name   => $config->{server},
      SSL_verifycn_scheme => "http", # DNS names and IP addresses, not a web protocol
   );

   if ($config->{tls} eq "ssl") {
      $imap = Mail::IMAPTalk->new (
         Server => $config->{server}, Port => $config->{port},
         UseSSL => 1, UseBlocking => 1, PreserveINBOX => 1, %tls,
      );
   } else {
      $imap = Mail::IMAPTalk->new (
         Server => $config->{server}, Port => $config->{port}, PreserveINBOX => 1,
      );

      $imap or die "IMAP connection failed: $@\n";
      $imap->_imap_cmd ("starttls", 0, "")
         or die "IMAP STARTTLS rejected: " . $imap->get_last_error . "\n";
      IO::Socket::SSL->start_SSL ($imap->{Socket}, %tls)
         or die "IMAP TLS handshake failed: " . IO::Socket::SSL::errstr () . "\n";
      $imap->{UseBlocking} = 1;
      delete $imap->{Cache}{capability}; # TLS changes advertised mechanisms
   }

   $imap or die "IMAP connection failed: $@\n";
   if (($config->{method} || "password") eq "oauth2") {
      require AnyEvent::MCP::IMAP::OAuth2;
      require Authen::SASL;
      my $mechanism = uc ($config->{oauth}{"oauth-sasl"} || "xoauth2");
      $imap->capability->{"auth=" . lc $mechanism}
         or die "IMAP server does not advertise AUTH=$mechanism\n";
      my $token = $config->{access_token}
         || AnyEvent::MCP::IMAP::OAuth2::refresh ($config->{account_file}, $config->{oauth});
      my $sasl = Authen::SASL->new (
         mechanism => $mechanism,
         callback => { user => $config->{user}, pass => $token },
      );
      $imap->authenticate ($sasl)
         or die "IMAP OAuth authentication failed: " . $imap->get_last_error . "\n";
   } else {
      $imap->login ($config->{user}, $config->{password})
         or die "IMAP authentication failed: " . $imap->get_last_error . "\n";
   }

   $imap->uid (1);
   $imap->parse_mode (DecodeUTF8 => 1);

   +{ connected => JSON::XS::true, capabilities => [sort keys %{$imap->capability}] }
}

sub checked ($$) {
   my ($result, $what) = @_;

   defined $result && $result
      or die "$what: " . ($imap->get_last_error || $@ || "IMAP command failed") . "\n";

   $result
}

sub mailbox {
   my ($name, $writable) = @_;

   checked ($imap->select ($name, ReadOnly => !$writable), "Select $name");
   my $validity = $imap->get_response_code ("uidvalidity");
   defined $validity or die "UIDVALIDITY not supplied for $name\n";

   $validity
}

sub same_validity {
   my ($args, $writable) = @_;

   my $validity = mailbox ($args->{mailbox}, $writable);
   defined $args->{uidvalidity} && "$args->{uidvalidity}" eq "$validity"
      or die "UIDVALIDITY mismatch (current $validity); refresh message references\n";

   $validity
}

sub uids {
   my ($args) = @_;

   ref $args->{uids} eq "ARRAY" && @{$args->{uids}} && @{$args->{uids}} <= 100
      or die "uids must contain 1..100 message UIDs\n";
   for (@{$args->{uids}}) {
      defined $_ && !ref $_ && /\A[1-9][0-9]*\z/
         or die "Invalid UID\n";
   }

   join ",", @{$args->{uids}}
}

sub message {
   my ($args) = @_;

   my $validity = same_validity ($args, 0);
   my $uid = $args->{uid};
   my $f = checked ($imap->fetch ($uid, "(envelope flags internaldate rfc822.size bodystructure)"), "Fetch $uid")->{$uid}
      or die "Message $uid vanished\n";

   +{ uid => 0 + $uid, uidvalidity => $validity, %$f }
}

sub search_filter {
   my ($filter, $depth, $nodes) = @_;

   ref $filter eq "HASH" && (!$depth || keys %$filter)
      or die "Invalid SEARCH filter group\n";
   ++$$nodes <= 100 && $depth <= 12 or die "SEARCH filter too complex\n";

   my @criteria;
   for my $key (sort keys %$filter) {
      my $value = $filter->{$key};

      if ($key eq "all" || $key eq "any") {
         ref $value eq "ARRAY" && @$value && @$value <= 100
            or die "SEARCH $key requires a nonempty array of filters\n";
         my @groups = map [search_filter ($_, $depth + 1, $nodes)], @$value;
         if ($key eq "all") {
            push @criteria, @groups;
         } else {
            my $or = pop @groups;
            $or = ["OR", pop @groups, $or] while @groups;
            push @criteria, @$or;
         }
      } elsif ($key eq "not") {
         push @criteria, "NOT", [search_filter ($value, $depth + 1, $nodes)];
      } elsif ($key eq "header") {
         ref $value eq "HASH" && keys %$value && keys %$value <= 20
            or die "SEARCH header requires 1..20 header names\n";
         for my $name (sort keys %$value) {
            $name =~ /\A[A-Za-z0-9][A-Za-z0-9-]{0,62}\z/
               or die "Invalid SEARCH header name\n";
            my $text = $value->{$name};
            defined $text && !ref $text && length $text <= 500
               or die "Invalid SEARCH header value\n";
            push @criteria, "HEADER", $name, { Quote => $text };
         }
      } elsif ($key =~ /\A(?:from|to|cc|bcc|subject|body|text)\z/) {
         defined $value && !ref $value && length $value <= 500
            or die "Invalid SEARCH $key value\n";
         push @criteria, uc $key, { Quote => $value };
      } elsif ($key =~ /\A(?:since|before|on|sent_since|sent_before|sent_on)\z/) {
         defined $value && !ref $value && $value =~ /\A[0-9]{1,2}-[A-Za-z]{3}-[0-9]{4}\z/
            or die "Invalid SEARCH $key date (D-Mon-YYYY)\n";
         (my $command = uc $key) =~ tr/_//d;
         push @criteria, $command, $value;
      } elsif ($key eq "larger" || $key eq "smaller") {
         defined $value && !ref $value && $value =~ /\A[0-9]{1,10}\z/ && $value <= 4294967295
            or die "Invalid SEARCH $key size\n";
         push @criteria, uc $key, $value;
      } elsif ($key =~ /\A(?:seen|unseen|answered|unanswered|flagged|unflagged|deleted|undeleted|draft|undraft|recent|old|new)\z/) {
         defined $value && "$value" =~ /\A[01]\z/
            or die "Invalid SEARCH $key boolean\n";
         push @criteria, uc $key if $value;
      } else {
         die "Unknown SEARCH filter: $key\n";
      }
   }

   @criteria or !$depth or die "Empty SEARCH filter group\n";
   @criteria
}

sub messages {
   my ($args) = @_;

   my $validity = mailbox ($args->{mailbox}, 0);
   my $limit = $args->{limit} || 25;
   $limit =~ /\A[1-9][0-9]*\z/ && $limit <= 100 or die "limit must be 1..100\n";

   my $cursor = $args->{cursor};
   if (defined $cursor) {
      ref $cursor eq "HASH" && defined $cursor->{uidvalidity}
         && "$cursor->{uidvalidity}" eq "$validity"
         && defined $cursor->{before_uid} && $cursor->{before_uid} =~ /\A[1-9][0-9]*\z/
         or die "Stale or invalid UID cursor\n";
   }

   my $nodes = 0;
   my @criteria = search_filter ($args->{filter} // {}, 0, \$nodes);

   my @fields = @{$args->{fields} || [qw(subject from date flags size)]};
   my %valid = map +($_ => 1), qw(uid from to subject date cc reply-to message-id flags size internaldate);
   $valid{$_} or die "Invalid summary field: $_\n" for @fields;
   my @headers = @{$args->{headers} || []};
   @headers <= 20 or die "Too many headers\n";
   for (@headers) {
      /\A[A-Za-z0-9][A-Za-z0-9-]{0,62}\z/ or die "Invalid header name: $_\n";
   }

   # search in descending UID windows: ordinary UID SEARCH can otherwise return
   # millions of matches even when only one summary page was requested.
   # Mail::IMAPTalk caches SELECT, so UIDNEXT from that SELECT becomes stale.
   my $status = checked ($imap->status ($args->{mailbox}, "(UIDNEXT UIDVALIDITY)"), "STATUS");
   "$status->{uidvalidity}" eq "$validity"
      or die "Mailbox UIDVALIDITY changed; restart mcp-imap\n";
   my $uidnext = $status->{uidnext};
   defined $uidnext && $uidnext =~ /\A[1-9][0-9]*\z/
      or die "Server did not provide UIDNEXT\n";
   my $hi = $cursor ? $cursor->{before_uid} - 1 : $uidnext - 1;
   my @found;
   my $scanned = 0;
   while ($hi > 0 && $scanned < 20000 && @found <= $limit) {
      my $lo = $hi > 999 ? $hi - 999 : 1;
      my $matches = checked ($imap->search ("$lo:$hi", @criteria), "UID SEARCH");
      push @found, sort { $b <=> $a } @$matches;
      $scanned += $hi - $lo + 1;
      $hi = $lo - 1;
   }

   my $more = @found > $limit;
   splice @found, $limit if $more;
   my $incomplete = $hi > 0 && !$more;
   my %selected = map +($_ => 1), @fields;
   my @items = ("uid");
   push @items, "envelope" if grep $selected{$_}, qw(from to subject date cc reply-to message-id);
   push @items, "flags" if $selected{flags};
   push @items, "rfc822.size" if $selected{size};
   push @items, "internaldate" if $selected{internaldate};
   if (@headers) {
      push @items, "body.peek[header.fields (" . (join " ", @headers) . ")]";
   }

   my $data = @found
      ? checked ($imap->fetch (\@found, "(" . join (" ", @items) . ")"), "Fetch summaries")
      : {};
   my %env = (
      (map +($_ => ucfirst $_), qw(from to subject date cc)),
      "reply-to" => "Reply-To",
      "message-id" => "Message-ID",
   );
   my @messages;
   for my $uid (@found) {
      my $item = $data->{$uid} or next;
      my %row = (uid => 0 + $uid);
      for my $field (@fields) {
         next if $field eq "uid";
         my $key = $env{$field};
         $row{$field} = $key ? $item->{envelope}{$key}
                      : $field eq "size" ? $item->{"rfc822.size"} : $item->{$field};
      }
      if (@headers) {
         $row{headers} = $item->{headers} || {};
         length (JSON::XS->new->utf8->encode ($row{headers})) <= 65536
            or die "Selected headers exceed 64 KiB\n";
      }
      push @messages, \%row;
   }

   my $before = $incomplete ? $hi + 1 : @found ? $found[-1] : undef;

   +{
      uidvalidity => $validity,
      messages    => \@messages,
      more        => $more ? JSON::XS::true : JSON::XS::false,
      incomplete  => $incomplete ? JSON::XS::true : JSON::XS::false,
      next_cursor => ($more || $incomplete) && $before
         ? { uidvalidity => $validity, before_uid => $before } : undef,
   }
}

sub part {
   my ($args, $raw_message) = @_;

   my $validity = same_validity ($args, 0);
   my $uid = $args->{uid};
   my $part = $raw_message ? "" : $args->{part};
   defined $part && $part =~ /\A(?:[1-9][0-9]*(?:\.[1-9][0-9]*)*)?\z/
      or die "Invalid MIME part number\n";
   my $max = $args->{max_bytes} || 65536;
   $max =~ /\A[1-9][0-9]*\z/ && $max <= 262144
      or die "max_bytes must be 1..262144\n";

   my $f = checked ($imap->fetch ($uid, "body.peek[$part]<0." . ($max + 1) . ">"), "Fetch part $uid");
   my $item = $f->{$uid} or die "Message $uid vanished\n";
   my $bytes = $item->{body};
   defined $bytes && !ref $bytes or die "Invalid part data\n";
   my $truncated = length $bytes > $max;
   substr $bytes, $max, "" if $truncated;
   my $result = {
      uid => 0 + $uid, uidvalidity => $validity, part => $part,
      data_base64 => MIME::Base64::encode_base64 ($bytes, ""),
      truncated => $truncated ? JSON::XS::true : JSON::XS::false,
   };

   if ($args->{decode_text} && !$truncated && !$raw_message) {
      my $bs = checked ($imap->fetch ($uid, "bodystructure"), "Fetch MIME structure")->{$uid}{bodystructure};
      my @pending = ($bs);
      my $node;
      while (@pending) {
         my $candidate = shift @pending;
         if (($candidate->{"IMAP-Partnum"} // "") eq $part && $candidate->{"MIME-Type"} eq "text") {
            $node = $candidate;
            last;
         }
         push @pending, @{$candidate->{"MIME-Subparts"} || []};
      }
      $node or die "Part is not a text MIME leaf\n";
      my $encoding = uc ($node->{"Content-Transfer-Encoding"} || "");
      $bytes = MIME::Base64::decode_base64 ($bytes) if $encoding eq "BASE64";
      $bytes = MIME::QuotedPrint::decode_qp ($bytes) if $encoding eq "QUOTED-PRINTABLE";
      my $charset = $node->{"Content-Type"}{charset} || "us-ascii";
      $result->{text} = Encode::decode ($charset, $bytes, Encode::FB_CROAK ());
      $result->{content_type} = $node->{"MIME-TxtType"};
   }

   $result
}

sub run {
   my ($cmd, $args) = @_;

   my $result = eval {
      if ($cmd eq "connect") {
         return (1, imap_connect ($args));
      }

      $imap && $imap->is_open or die "IMAP connection closed; restart mcp-imap\n";

      if ($cmd eq "mailboxes" || $cmd eq "lsub") {
         my $method = $cmd eq "lsub" ? "lsub" : "list";
         return (1, { mailboxes => checked ($imap->$method ("", "*"), uc $method) });
      } elsif ($cmd eq "messages") {
         return (1, messages ($args));
      } elsif ($cmd eq "message") {
         return (1, message ($args));
      } elsif ($cmd eq "part" || $cmd eq "raw") {
         return (1, part ($args, $cmd eq "raw"));
      } elsif ($cmd eq "flags") {
         my $validity = same_validity ($args, 1);
         my $uidset = uids ($args);
         $args->{operation} =~ /\A(?:add|remove)\z/
            or die "Invalid flag operation\n";
         my $flags = $args->{flags};
         ref $flags eq "ARRAY" && @$flags && @$flags <= 20
            or die "flags must be an array of 1..20 flags\n";
         for (@$flags) {
            /\A(?:\\(?:Seen|Flagged|Answered|Deleted|Draft)|[A-Za-z][A-Za-z0-9_-]{0,63})\z/i
               or die "Invalid IMAP flag\n";
         }
         checked ($imap->store ($uidset, ($args->{operation} eq "add" ? "+" : "-") . "flags.silent",
            "(" . join (" ", @$flags) . ")"), "STORE");
         return (1, { ok => JSON::XS::true, uidvalidity => $validity, uids => $args->{uids} });
      } elsif ($cmd eq "copy" || $cmd eq "move") {
         my $validity = same_validity ($args, 1);
         my $uidset = uids ($args);
         $cmd ne "move" || $imap->capability->{move}
            or die "Server does not advertise MOVE; refusing unsafe fallback\n";
         checked ($imap->$cmd ($uidset, $args->{destination}), uc $cmd);
         return (1, { ok => JSON::XS::true, uidvalidity => $validity, uids => $args->{uids} });
      } elsif ($cmd eq "append") {
         defined $args->{data_base64} && !ref $args->{data_base64}
            && length $args->{data_base64} <= 1398112
            && $args->{data_base64} =~ /\A(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?\z/
            or die "Invalid or oversized Base64 message\n";
         my $bytes = MIME::Base64::decode_base64 ($args->{data_base64});
         length $bytes <= 1048576 or die "APPEND limited to 1 MiB\n";
         $bytes =~ /\r\n/ or die "APPEND expects an RFC 5322 message with CRLF line endings\n";

         unless ($config->{allow_mbox_from}) {
            my $line = mbox_from ($bytes);
            die "APPEND refused: raw message line $line resembles an unescaped mboxo From_ separator "
              . "(starts with 'From ' and has date-like text). Some mbox servers may mistake it "
              . "for a new message boundary. No APPEND attempted. Escape the line, or ask the "
              . "server operator to use --allow-mbox-from.\n"
               if $line;
         }

         ref $args->{flags} eq "ARRAY" || !defined $args->{flags}
            or die "Invalid flags\n";
         for (@{$args->{flags} || []}) {
            defined $_ && !ref $_ && /\A(?:\\(?:Seen|Flagged|Answered|Deleted|Draft)|[A-Za-z][A-Za-z0-9_-]{0,63})\z/i
               or die "Invalid IMAP flag\n";
         }
         my @extra = $args->{flags} && @{$args->{flags}}
            ? ("(" . (join " ", @{$args->{flags}}) . ")") : ();
         checked ($imap->append ($args->{mailbox}, @extra, { Literal => $bytes }), "APPEND");
         return (1, { ok => JSON::XS::true });
      } elsif ($cmd eq "expunge") {
         my $validity = same_validity ($args, 1);
         if ($args->{uids}) {
            $imap->capability->{uidplus}
               or die "Server lacks UIDPLUS; refusing whole-mailbox fallback\n";
            checked ($imap->uidexpunge (uids ($args)), "UID EXPUNGE");
         } else {
            checked ($imap->expunge, "EXPUNGE");
         }
         return (1, { ok => JSON::XS::true, uidvalidity => $validity });
      } elsif ($cmd eq "mailbox") {
         my $op = $args->{operation};
         defined $op && $op =~ /\A(?:create|rename|delete|subscribe|unsubscribe)\z/
            or die "Invalid mailbox operation\n";
         my @params = $op eq "rename" ? @{$args}{qw(mailbox destination)} : ($args->{mailbox});
         checked ($imap->$op (@params), uc $op);
         return (1, { ok => JSON::XS::true });
      }

      die "Unknown IMAP operation\n";
   };
   my $error = $@;
   $result ? (1, $result) : (0, $error || "IMAP operation failed\n")
}

1;
