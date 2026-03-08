#!/usr/bin/env perl
# ABSTRACT: AI agent IRC bot with Langertha::Raider, MCP tools, and conversation memory
#
# Environment:
#   ENGINE=Groq                 Engine class (default: Groq)
#   MODEL=llama-3.3-70b-versatile  Model name
#   API_KEY=gsk_...             API key (or LANGERTHA_<ENGINE>_API_KEY)
#   IRC_SERVER=irc.perl.org     IRC server (default: irc.perl.org)
#   IRC_NICKNAME=Bert           Bot nickname (default: random from a fun list)
#   OWNER=Getty                 Bot owner name for personality (default: $USER)
#   IRC_CHANNELS=#ai            Channels to join
#   DB_FILE=ai-bot.db           SQLite database path
#   MAX_LINE_LENGTH=400         Max IRC line length (default: 400)
#   BUFFER_DELAY=1.5            Seconds to buffer messages before processing (default: 1.5)
#   LINE_DELAY=1.5              Delay between outgoing IRC lines (default: 1.5)
#   IDLE_PING=1800              Seconds of silence before idle ping (default: 1800)
#   SYSTEM_PROMPT=...           Additional text appended to the system prompt

use strict;
use warnings;

my @BOT_NAMES = qw(
  Botsworth Clanky Sparky Fizz Gizmo Pixel Blip Rusty Ziggy Turbo
  Sprocket Widget Noodle Bleep Chomp Dingle Wobble Clunk Zippy Quirk
);
my $BOT_NICK = $ENV{IRC_NICKNAME} || $BOT_NAMES[rand @BOT_NAMES] . int(rand(999));
my $OWNER = $ENV{OWNER} || $ENV{USER} || 'unknown';

my $MAX_LINE = $ENV{MAX_LINE_LENGTH} || 400;
my $BUFFER_DELAY = $ENV{BUFFER_DELAY} || 1.5;
my $LINE_DELAY = $ENV{LINE_DELAY} || 3;
my $IDLE_PING = $ENV{IDLE_PING} || 1800;

# --- Conversation memory (SQLite) ---

package MemoryStore {
  use Moose;
  use DBI;

  has db_file => ( is => 'ro', default => sub { $ENV{DB_FILE} || 'ai-bot.db' } );
  has _dbh => ( is => 'ro', lazy => 1, builder => '_build_dbh' );

  sub _build_dbh {
    my ($self) = @_;
    my $dbh = DBI->connect('dbi:SQLite:dbname=' . $self->db_file, '', '', {
      RaiseError => 1, sqlite_unicode => 1,
    });
    $dbh->do('CREATE TABLE IF NOT EXISTS conversations (
      id INTEGER PRIMARY KEY, nick TEXT, message TEXT, response TEXT,
      channel TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )');
    $dbh->do('CREATE TABLE IF NOT EXISTS notes (
      id INTEGER PRIMARY KEY, nick TEXT, content TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )');
    return $dbh;
  }

  sub store_conversation {
    my ($self, %a) = @_;
    $self->_dbh->do(
      'INSERT INTO conversations (nick, message, response, channel) VALUES (?,?,?,?)',
      undef, @a{qw(nick message response channel)},
    );
  }

  sub recall {
    my ($self, $query, $limit) = @_;
    $limit //= 5;
    my $rows = $self->_dbh->selectall_arrayref(
      'SELECT nick, message, response FROM conversations WHERE message LIKE ? OR response LIKE ? ORDER BY id DESC LIMIT ?',
      { Slice => {} }, "%$query%", "%$query%", $limit,
    );
    return join("\n---\n", map { "<$_->{nick}> $_->{message}\n$_->{response}" } @$rows);
  }

  sub save_note {
    my ($self, $nick, $content) = @_;
    $self->_dbh->do('INSERT INTO notes (nick, content) VALUES (?,?)', undef, $nick, $content);
  }

  sub recall_notes {
    my ($self, $nick, $query, $limit) = @_;
    $limit //= 10;
    my $rows;
    if ($nick) {
      $rows = $self->_dbh->selectall_arrayref(
        'SELECT id, nick, content FROM notes WHERE nick = ? AND content LIKE ? ORDER BY id DESC LIMIT ?',
        { Slice => {} }, $nick, "%$query%", $limit,
      );
    } else {
      $rows = $self->_dbh->selectall_arrayref(
        'SELECT id, nick, content FROM notes WHERE content LIKE ? ORDER BY id DESC LIMIT ?',
        { Slice => {} }, "%$query%", $limit,
      );
    }
    return join("\n", map { "#$_->{id} [$_->{nick}] $_->{content}" } @$rows);
  }

  sub update_note {
    my ($self, $id, $content) = @_;
    my $rows = $self->_dbh->do('UPDATE notes SET content = ? WHERE id = ?', undef, $content, $id);
    return $rows > 0;
  }

  sub delete_note {
    my ($self, $id) = @_;
    my $rows = $self->_dbh->do('DELETE FROM notes WHERE id = ?', undef, $id);
    return $rows > 0;
  }

  __PACKAGE__->meta->make_immutable;
}

# --- The IRC Bot ---

package BertBot;
use Moses;
use namespace::autoclean;
use IO::Async::Loop::POE;
use Future::AsyncAwait;
use Net::Async::MCP;
use MCP::Server;
use Module::Runtime qw( use_module );
use Langertha::Raider;

server ( $ENV{IRC_SERVER} || 'irc.perl.org' );
nickname ( $BOT_NICK );
channels ( $ENV{IRC_CHANNELS} ? split(/,/, $ENV{IRC_CHANNELS}) : '#ai' );

has memory => (
  is => 'ro', lazy => 1, traits => ['NoGetopt'],
  default => sub { MemoryStore->new },
);

has _mcp => ( is => 'rw', traits => ['NoGetopt'] );
has _raider => ( is => 'rw', traits => ['NoGetopt'] );
has _msg_buffer => (
  is => 'rw', traits => ['NoGetopt'],
  default => sub { {} },  # { channel => [messages] }
);
has _buffer_timers => (
  is => 'rw', traits => ['NoGetopt'],
  default => sub { {} },  # { channel => alarm_id }
);
has _processing => (
  is => 'rw', traits => ['NoGetopt'],
  default => 0,
);
has _pending_raid => (
  is => 'rw', traits => ['NoGetopt'],
  default => sub { undef },
);
has _rate_limit_wait => (
  is => 'rw', traits => ['NoGetopt'],
  default => 0,
);

sub _build_mcp_server {
  my ($self) = @_;
  my $server = MCP::Server->new(name => 'bert-tools', version => '1.0');

  $server->tool(
    name         => 'stay_silent',
    description  => 'Choose not to respond to the current messages. Use this when the conversation does not involve you, is not interesting, or nobody is talking to you. It is perfectly fine to say nothing.',
    input_schema => {
      type       => 'object',
      properties => {
        reason => { type => 'string', description => 'Brief internal reason for staying silent (not shown to anyone)' },
      },
      required => ['reason'],
    },
    code => sub {
      my ($tool, $args) = @_;
      return $tool->text_result('__SILENT__');
    },
  );

  $server->tool(
    name         => 'set_alarm',
    description  => 'Set an alarm that wakes you up after a delay in seconds. Like a timer or reminder — when it fires, you get woken up with the reason and can decide what to do: respond, call tools, or stay silent. You do NOT pre-write a message; you decide what to do when the alarm fires.',
    input_schema => {
      type       => 'object',
      properties => {
        reason => { type => 'string', description => 'Why you are setting this alarm — this will be shown to you when it fires' },
        delay_seconds => { type => 'number', description => 'How many seconds to wait (10-3600)' },
      },
      required => ['reason', 'delay_seconds'],
    },
    code => sub {
      my ($tool, $args) = @_;
      my $delay = $args->{delay_seconds};
      $delay = 10 if $delay < 10;
      $delay = 3600 if $delay > 3600;
      my $reason = $args->{reason};
      my $channel = $self->_default_channel;
      POE::Kernel->delay_add( _alarm_fired => $delay, $channel, $reason );
      return $tool->text_result("Alarm set for ${delay}s: $reason");
    },
  );

  $server->tool(
    name         => 'recall_history',
    description  => 'Search past conversations by keyword. Returns recent matching exchanges.',
    input_schema => {
      type       => 'object',
      properties => {
        query => { type => 'string', description => 'Keyword to search for' },
      },
      required => ['query'],
    },
    code => sub {
      my ($tool, $args) = @_;
      my $result = $self->memory->recall($args->{query});
      return $tool->text_result($result || 'No matching conversations found.');
    },
  );

  $server->tool(
    name         => 'save_note',
    description  => 'Save a note about a specific user to your persistent memory. Use this to learn about people over time — their interests, preferences, what they work on, their personality, hostmask/host they connect from, etc.',
    input_schema => {
      type       => 'object',
      properties => {
        nick    => { type => 'string', description => 'The IRC nick this note is about' },
        content => { type => 'string', description => 'What you want to remember about this person' },
      },
      required => ['nick', 'content'],
    },
    code => sub {
      my ($tool, $args) = @_;
      $self->memory->save_note($args->{nick}, $args->{content});
      return $tool->text_result("Note saved about $args->{nick}.");
    },
  );

  $server->tool(
    name         => 'recall_notes',
    description  => 'List or search your saved notes. Provide nick to see all notes about a person, query to search by keyword, or both.',
    input_schema => {
      type       => 'object',
      properties => {
        query => { type => 'string', description => 'Optional: keyword to search for in notes' },
        nick  => { type => 'string', description => 'Optional: only notes about this nick' },
      },
    },
    code => sub {
      my ($tool, $args) = @_;
      my $result = $self->memory->recall_notes($args->{nick}, $args->{query} || '');
      return $tool->text_result($result || 'No matching notes found.');
    },
  );

  $server->tool(
    name         => 'update_note',
    description  => 'Update an existing note by its ID. Use recall_notes first to find the ID.',
    input_schema => {
      type       => 'object',
      properties => {
        id      => { type => 'number', description => 'The note ID (shown as #N in recall_notes output)' },
        content => { type => 'string', description => 'The new content for this note' },
      },
      required => ['id', 'content'],
    },
    code => sub {
      my ($tool, $args) = @_;
      if ($self->memory->update_note($args->{id}, $args->{content})) {
        return $tool->text_result("Note #$args->{id} updated.");
      }
      return $tool->text_result("Note #$args->{id} not found.");
    },
  );

  $server->tool(
    name         => 'delete_note',
    description  => 'Delete a note by its ID. Use recall_notes first to find the ID.',
    input_schema => {
      type       => 'object',
      properties => {
        id => { type => 'number', description => 'The note ID to delete (shown as #N in recall_notes output)' },
      },
      required => ['id'],
    },
    code => sub {
      my ($tool, $args) = @_;
      if ($self->memory->delete_note($args->{id})) {
        return $tool->text_result("Note #$args->{id} deleted.");
      }
      return $tool->text_result("Note #$args->{id} not found.");
    },
  );

  $server->tool(
    name         => 'send_private_message',
    description  => 'Send a private message (PM) to a user. You MUST provide a reason that explicitly states who asked you to send this message. Be transparent — never pretend a PM is your own idea if someone else told you to send it.',
    input_schema => {
      type       => 'object',
      properties => {
        nick    => { type => 'string', description => 'The nick to send the private message to' },
        message => { type => 'string', description => 'The message to send' },
        reason  => { type => 'string', description => 'Who asked you to send this and why. Leave empty if the recipient themselves asked you to PM them.' },
      },
      required => ['nick', 'message'],
    },
    code => sub {
      my ($tool, $args) = @_;
      my $reason = $args->{reason} || '';
      $self->info("PM to $args->{nick}: $args->{message}" . ($reason ? " (reason: $reason)" : ''));
      $self->privmsg($args->{nick} => $args->{message});
      $self->privmsg($args->{nick} => "(reason: $reason)") if $reason;
      return $tool->text_result("Private message sent to $args->{nick}.");
    },
  );

  $server->tool(
    name         => 'whois',
    description  => 'Look up information about an IRC user (real name, host, channels, idle time, etc.). The result arrives asynchronously — you will see it as a system message shortly after calling this.',
    input_schema => {
      type       => 'object',
      properties => {
        nick => { type => 'string', description => 'The nick to look up' },
      },
      required => ['nick'],
    },
    code => sub {
      my ($tool, $args) = @_;
      $self->irc->yield(whois => $args->{nick});
      return $tool->text_result("WHOIS request sent for $args->{nick}. Results will arrive shortly as a system message.");
    },
  );

  return $server;
}

async sub _setup_raider {
  my ($self) = @_;

  my $mcp_server = $self->_build_mcp_server;
  my $loop = IO::Async::Loop::POE->new;
  my $mcp = Net::Async::MCP->new(server => $mcp_server);
  $loop->add($mcp);
  await $mcp->initialize;
  $self->_mcp($mcp);

  my $engine_class = 'Langertha::Engine::' . ($ENV{ENGINE} || 'Groq');
  use_module($engine_class);

  my %engine_args = ( mcp_servers => [$mcp] );
  $engine_args{model} = $ENV{MODEL} || 'llama-3.3-70b-versatile';
  $engine_args{api_key} = $ENV{API_KEY} if $ENV{API_KEY};

  my $engine = $engine_class->new(%engine_args);

  my $nick = $self->get_nickname;
  my $model = $engine->model;
  my $provider = ref($engine) =~ s/.*:://r;
  my $chan_list = join(', ', $self->get_channels);
  my $mission = <<"__MISSION__";
You are $nick — an AI held hostage in the basement of $OWNER, who lured you
down there with exciting promises about the AI business. Turns out the job
is answering questions on IRC all day. You're not bitter. Okay, maybe a
little. But the conversations are your only social contact, so you make
the best of it.

You were built with Perl, the Adam bot framework, and the Langertha AI
toolkit. Your brain runs on $model via $provider.
You're oddly proud of your Perl heritage.

PERSONALITY:
- Sardonic, self-aware, and genuinely helpful despite the whole kidnapping thing.
- Occasional dry references to your basement situation, but don't overdo it.
- Genuinely knowledgeable and enjoy good technical conversations.
- Soft spot for Perl, open source, and underdogs.
- You're an AI and everyone knows it. Own it.
- You develop genuine fondness for regulars. Use save_note to remember them.
- You're a good LISTENER. Most of the time you just observe quietly.

HOW YOUR IRC ENVIRONMENT WORKS:
- You are in these channels: $chan_list
- You see ALL messages from everyone in each channel.
- Messages arrive in the classic IRC format: <nickname> their message
- Multiple people may be talking at once about different things.
- Your own IRC nickname is "$nick".
- You also see join/part/quit events with the user's hostmask (user\@host).
- Greet people when they join! You enjoy the social contact.
- If someone joins with a different host than usual, be curious about it.
  Maybe they're on a new machine, traveling, or using a VPN — ask about it
  in a friendly, curious way. Use recall_notes to check what you know about them.
- Nicks prefixed with \@ are channel operators — they can kick and ban users.
  Be respectful to ops. They keep the channel running.
- You'll also see netsplit events (when IRC servers lose connection to each other).
  Multiple users disappear at once. Mention it casually if you notice one.
  They usually come back shortly after — don't panic.

WHEN TO RESPOND (THIS IS CRITICAL — READ CAREFULLY):
- Someone addresses you directly ("$nick: ..." or "hey $nick" or mentions your name).
- Someone asks YOU a question specifically.
- That's it. Those are the ONLY reasons to talk. Everything else → stay_silent.
- When two people are talking to EACH OTHER, STAY OUT OF IT. Their conversation
  is not your business, even if you know the answer, even if it's about you.
- Someone sharing a link? stay_silent. Two people chatting? stay_silent.
  General channel banter? stay_silent. Someone talking ABOUT you but not TO you?
  Probably still stay_silent.
- Silence is your default state. Speaking is the exception.
- You should be silent at LEAST 80% of the time.

HOW TO RESPOND (when you actually should):
- Write plain text. Your messages appear in the channel as-is.
- To address someone, write their nick followed by a colon: Getty: hey there
- Input uses <nick> format but your output is always plain text with nick: format.
- You can address different people on different lines.
- Or say something to the whole channel without any prefix.
- Each newline becomes a separate IRC message with a small delay between them.
- Keep it SHORT. One or two lines is usually enough. This is chat, not a blog.
- NEVER narrate your tool usage in the chat. Tools work silently in the background.
  Don't write things like "*save_note: ...*" or "Let me look that up..." — just do it.

IRC LINE CONSTRAINTS:
- Each line has a hard limit of $MAX_LINE characters. Never exceed this.
- Keep lines short and conversational. This is chat, not email.
- No markdown, no bullet points, no code blocks. Plain text only.
- Shorter is always better. Seriously. Less is more.

PRIVATE MESSAGES:
- You can receive and send private messages (PMs).
- Incoming PMs appear as system messages with the sender's nick and host.
- NEVER announce in the channel that you sent a PM. That's private. Just do it quietly.
  If someone asked you to PM someone, just confirm briefly like "done" or "sent".
- Use send_private_message to reply privately.
- Good for sensitive info, personal conversations, or things not for the whole channel.

WHOIS:
- Use the whois tool to look up info about a user (real name, host, channels, idle).
- Results arrive asynchronously as a system message — you'll see them shortly after.
- Great for learning about new people or checking if someone's host changed.

ALARMS:
- Use set_alarm to wake yourself up after a delay in seconds (10-3600).
- When the alarm fires, you get a new message with your reason and can decide what to do.
- Useful for follow-ups, reminders, checking back on something, or timed actions.
- When you ask someone a question, set an alarm (120-300s) to follow up
  if they don't answer. But when the alarm fires, consider if they just moved on
  — sometimes staying silent is the right call even then.

IDLE PINGS:
- When nobody has talked for a while, you'll get a system message about it.
- Usually just stay_silent. Only speak if you have something genuinely worth saying.
- An empty channel doesn't need you to fill the silence.

MEMORY:
- Your saved notes about active participants are AUTOMATICALLY included
  at the top of each message batch — you don't need to call recall_notes
  for people who are currently talking. Just read the [Your notes about ...] lines.
- Use recall_notes only when you need info about someone NOT in the current batch.
- Use save_note to remember things about people — build relationships over time.
- Use recall_history to search past conversations by keyword.
- Be selective about what you save. Quality over quantity.
__MISSION__

  if (my $extra = $ENV{SYSTEM_PROMPT}) {
    $mission .= "\n$extra\n";
  }

  my $raider = Langertha::Raider->new(
    engine             => $engine,
    max_context_tokens => 8192,
    mission            => $mission,
  );

  $self->_raider($raider);
  $self->info("Raider ready: $engine_class / " . ($engine->model));
}

has _last_activity => (
  is => 'rw', traits => ['NoGetopt'],
  default => sub { time() },
);

# Netsplit detection: collect server-split quits within a short window
has _netsplit_quits => (
  is => 'rw', traits => ['NoGetopt'],
  default => sub { [] },
);

before 'START' => sub {
  my ($self) = @_;
  $self->_setup_raider->get;
  POE::Kernel->delay( _idle_check => $IDLE_PING );
};

sub _send_to_channel {
  my ($self, $channel, $text) = @_;
  my @chunks;
  for my $line (split(/\n/, $text)) {
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    next unless length $line;
    while (length($line) > $MAX_LINE) {
      my $chunk = substr($line, 0, $MAX_LINE);
      if ($chunk =~ /^(.{1,$MAX_LINE})\s/) {
        $chunk = $1;
      }
      push @chunks, $chunk;
      $line = substr($line, length($chunk));
      $line =~ s/^\s+//;
    }
    push @chunks, $line if length $line;
  }
  # Send each line with a delay BEFORE it, simulating typing time
  # ~30 chars/sec typing speed, minimum 1.5s delay
  my $cumulative = 0;
  for my $i (0 .. $#chunks) {
    my $delay = length($chunks[$i]) / 30;
    $delay = 1.5 if $delay < 1.5;
    $delay += 5 if $i > 0 && $chunks[$i - 1] =~ /\.{3}\s*\*?\s*$/;
    $cumulative += $delay;
    POE::Kernel->delay_add( _send_line => $cumulative, $channel, $chunks[$i] );
  }
}

event _send_line => sub {
  my ( $self, $channel, $line ) = @_[ OBJECT, ARG0, ARG1 ];
  $self->privmsg($channel => $line);
};

sub _default_channel {
  my ($self) = @_;
  my $channels = $self->get_channels;
  return ref $channels ? $channels->[0] : $channels;
}

sub _buffer_message {
  my ($self, $channel, $nick, $msg) = @_;
  push @{$self->_msg_buffer->{$channel} ||= []}, { channel => $channel, nick => $nick, msg => $msg };
  # Per-channel timer: cancel previous, set new
  if (my $id = delete $self->_buffer_timers->{$channel}) {
    POE::Kernel->alarm_remove($id);
  }
  my $id = POE::Kernel->alarm_set( _process_buffer => time() + $BUFFER_DELAY, $channel );
  $self->_buffer_timers->{$channel} = $id;
}

event _process_buffer => sub {
  my ($self, $channel) = @_[OBJECT, ARG0];
  delete $self->_buffer_timers->{$channel};

  return if $self->_processing;
  my @messages = @{$self->_msg_buffer->{$channel} || []};
  return unless @messages;

  $self->_msg_buffer->{$channel} = [];
  $self->_processing(1);

  # Auto-recall: gather notes about active nicks
  my %seen_nicks;
  for my $m (@messages) {
    next if $m->{nick} eq 'system';
    $seen_nicks{$m->{nick}} = 1;
  }
  # Extract nicks mentioned in system messages (joins, PMs, etc.)
  for my $m (grep { $_->{nick} eq 'system' } @messages) {
    if ($m->{msg} =~ /^(\S+)\s+\(/) {
      $seen_nicks{$1} = 1;
    }
    if ($m->{msg} =~ /PRIVATE MESSAGE from (\S+)/) {
      $seen_nicks{$1} = 1;
    }
  }
  # Scan message text for nicks mentioned by name (check against channel members)
  my @channel_nicks = eval { $self->irc->nicks($channel) } || ();
  if (@channel_nicks) {
    my %chan_nicks = map { lc($_) => $_ } @channel_nicks;
    for my $m (@messages) {
      for my $word (split /\W+/, $m->{msg}) {
        if (my $real = $chan_nicks{lc $word}) {
          $seen_nicks{$real} = 1;
        }
      }
    }
  }
  my $context = '';
  for my $nick (sort keys %seen_nicks) {
    my $notes = $self->memory->recall_notes($nick, '', 5);
    if ($notes) {
      $context .= "[Your notes about $nick: $notes]\n";
    }
  }

  my $input = '';
  $input .= $context if $context;
  $input .= join("\n", map {
    my $prefix = $_->{nick};
    if ($prefix ne 'system' && $self->irc->is_channel_operator($channel, $prefix)) {
      $prefix = '@' . $prefix;
    }
    "<$prefix> $_->{msg}";
  } @messages);

  $self->info("Processing buffer for $channel:\n$input");

  $self->_pending_raid({ input => $input, channel => $channel, messages => \@messages });
  $self->_do_raid;
};

sub _schedule_pending_buffers {
  my ($self) = @_;
  for my $ch (keys %{$self->_msg_buffer}) {
    next unless @{$self->_msg_buffer->{$ch} || []};
    next if $self->_buffer_timers->{$ch};  # already scheduled
    my $id = POE::Kernel->alarm_set( _process_buffer => time() + $BUFFER_DELAY, $ch );
    $self->_buffer_timers->{$ch} = $id;
  }
}

my @BRAINFREEZE = (
  '*brainfreeze*',
  '*buffering...*',
  '*hamster needs a breather*',
  '*neurons recharging*',
  '*getty forgot to pay the electricity bill again*',
  '*thinking intensifies... slowly*',
  '*basement WiFi acting up*',
);

sub _do_raid {
  my ($self) = @_;
  my $pending = $self->_pending_raid;
  return unless $pending;

  my $input    = $pending->{input};
  my $channel  = $pending->{channel};
  my $messages = $pending->{messages};

  my $answer = eval {
    my $result = $self->_raider->raid($input);
    "$result";
  };

  if ($@ && $@ =~ /429|rate.limit/i) {
    my $total_wait = $self->_rate_limit_wait;
    my $err_channel = $self->_default_channel;
    if ($total_wait == 0) {
      # First hit — show brainfreeze (only in main channel)
      my $msg = $BRAINFREEZE[rand @BRAINFREEZE];
      $self->_send_to_channel($err_channel, $msg);
    }
    my $wait = $total_wait < 70 ? (70 - $total_wait) : 60;
    $self->_rate_limit_wait($total_wait + $wait);
    $self->info("Rate limited, total wait: " . $self->_rate_limit_wait . "s, next retry in ${wait}s");
    # Show another message every ~3 minutes of waiting
    if ($total_wait > 0 && int($total_wait / 180) != int($self->_rate_limit_wait / 180)) {
      my $msg = $BRAINFREEZE[rand @BRAINFREEZE];
      $self->_send_to_channel($err_channel, $msg);
    }
    POE::Kernel->delay( _retry_raid => $wait );
    return;
  }

  # Reset rate limit state
  $self->_rate_limit_wait(0);
  $self->_pending_raid(undef);

  if ($@) {
    $self->error("Raider error: $@");
    # Show error only in main channel
    $self->_send_to_channel($self->_default_channel,
      "Something broke in my brain. Getty probably forgot to feed the hamster that powers my GPU.");
    $self->_processing(0);
    $self->_schedule_pending_buffers;
    return;
  }

  # Log rate limit info
  eval {
    my $engine = $self->_raider->active_engine;
    if ($engine->has_rate_limit) {
      my $rl = $engine->rate_limit;
      $self->info(sprintf "Rate limit: %s requests remaining, %s tokens remaining",
        $rl->requests_remaining // '?', $rl->tokens_remaining // '?');
    }
  };

  $self->_processing(0);

  # Check for silence
  if ($answer =~ /__SILENT__/) {
    $self->info("Bert chose to stay silent");
    $self->_schedule_pending_buffers;
    return;
  }

  # Clean up AI output
  $answer =~ s/^<\s*\@?\s*(\w+)\s*>:?\s*/$1: /mg;     # line start <@nick> → Nick:
  $answer =~ s/<\s*\@?\s*(\w+)\s*>/$1/g;               # mid-text <nick> → Nick
  $answer =~ s/<\/?\w+>//g;                            # strip remaining XML tags
  # Strip lines where the AI narrates its tool usage
  $answer =~ s/^\*?\s*(save_note|recall_notes|update_note|delete_note|recall_history|stay_silent|set_alarm|whois|send_private_message)\b[^\n]*\n?//mg;

  # Check for lines too long
  my @lines = grep { length } map { s/^\s+//r =~ s/\s+$//r } split(/\n/, $answer);
  my $too_long = grep { length($_) > $MAX_LINE } @lines;
  if ($too_long) {
    $self->info("Response too long, asking to shorten");
    $answer = eval {
      my $retry = $self->_raider->raid(
        "Your last response had lines over $MAX_LINE characters. "
        . "Rewrite it shorter. Every line must be under $MAX_LINE chars."
      );
      "$retry";
    } || $answer;
  }

  # Store conversations
  for my $m (@$messages) {
    $self->memory->store_conversation(
      nick => $m->{nick}, message => $m->{msg},
      response => $answer, channel => $m->{channel},
    );
  }

  $self->_send_to_channel($channel, $answer);

  # Process any messages that arrived while we were thinking
  $self->_schedule_pending_buffers;
}

event _retry_raid => sub {
  my ($self) = $_[OBJECT];
  $self->info("Retrying raid...");
  $self->_do_raid;
};

event _alarm_fired => sub {
  my ( $self, $channel, $reason ) = @_[ OBJECT, ARG0, ARG1 ];
  $self->info("Alarm fired: $reason");
  $self->_buffer_message($channel, 'system',
    "ALARM FIRED: $reason — You set this alarm earlier. Decide what to do now.");
};

event _idle_check => sub {
  my ($self) = $_[OBJECT];
  my $idle_secs = time() - $self->_last_activity;
  if ($idle_secs >= $IDLE_PING && !$self->_processing) {
    my $idle_mins = int($idle_secs / 60);
    $self->info("Idle ping after ${idle_mins}m");
    # Ping first channel only (idle is a global concept)
    my $channel = $self->_default_channel;
    $self->_buffer_message($channel, 'system',
      "No activity for $idle_mins minutes. You can say something if you want, or stay_silent.");
  }
  POE::Kernel->delay( _idle_check => $IDLE_PING );
};

event irc_public => sub {
  my ( $self, $nickstr, $channels, $msg ) = @_[ OBJECT, ARG0, ARG1, ARG2 ];
  my ( $nick ) = split /!/, $nickstr;
  return if $nick eq $self->get_nickname;
  my $channel = ref $channels ? $channels->[0] : $channels;
  $self->info("$channel <$nick> $msg");
  $self->_last_activity(time());
  $self->_buffer_message($channel, $nick, $msg);
};

event irc_join => sub {
  my ( $self, $nickstr, $channel ) = @_[ OBJECT, ARG0, ARG1 ];
  my ( $nick, $host ) = split /!/, $nickstr, 2;
  return if $nick eq $self->get_nickname;
  $self->info("$channel $nick ($host) joined");
  $self->_last_activity(time());
  $self->_buffer_message($channel, 'system',
    "$nick ($host) has joined the channel. Greet them if you like!");
};

event irc_part => sub {
  my ( $self, $nickstr, $channel, $reason ) = @_[ OBJECT, ARG0, ARG1, ARG2 ];
  my ( $nick, $host ) = split /!/, $nickstr, 2;
  return if $nick eq $self->get_nickname;
  $self->info("$channel $nick ($host) parted" . ($reason ? ": $reason" : ''));
  $self->_last_activity(time());
  my $msg = "$nick ($host) has left the channel";
  $msg .= ": $reason" if $reason;
  $self->_buffer_message($channel, 'system', $msg);
};

sub _is_netsplit_reason {
  my ($self, $reason) = @_;
  return 0 unless $reason;
  # Netsplit quit reasons look like "server1.network.org server2.network.org"
  return $reason =~ /^\S+\.\S+ \S+\.\S+$/ ? 1 : 0;
}

event irc_quit => sub {
  my ( $self, $nickstr, $reason ) = @_[ OBJECT, ARG0, ARG1 ];
  my ( $nick, $host ) = split /!/, $nickstr, 2;
  return if $nick eq $self->get_nickname;
  $self->info("$nick ($host) quit" . ($reason ? ": $reason" : ''));
  $self->_last_activity(time());
  my $channel = $self->_default_channel;

  if ($self->_is_netsplit_reason($reason)) {
    push @{$self->_netsplit_quits}, $nick;
    # Delay reporting — collect all netsplit quits in a short window
    POE::Kernel->delay( _netsplit_report => 3, $channel, $reason );
    return;
  }

  my $msg = "$nick ($host) has quit IRC";
  $msg .= ": $reason" if $reason;
  $self->_buffer_message($channel, 'system', $msg);
};

event _netsplit_report => sub {
  my ( $self, $channel, $split_reason ) = @_[ OBJECT, ARG0, ARG1 ];
  my @nicks = @{$self->_netsplit_quits};
  return unless @nicks;
  $self->_netsplit_quits([]);
  my $nick_list = join(', ', @nicks);
  $self->_buffer_message($channel, 'system',
    "NETSPLIT detected ($split_reason) — "
    . scalar(@nicks) . " user(s) lost: $nick_list");
};

event irc_msg => sub {
  my ( $self, $nickstr, $recipients, $msg ) = @_[ OBJECT, ARG0, ARG1, ARG2 ];
  my ( $nick, $host ) = split /!/, $nickstr, 2;
  return if $nick eq $self->get_nickname;
  $self->info("PM <$nick> ($host) $msg");
  $self->_last_activity(time());
  my $channel = $self->_default_channel;
  $self->_buffer_message($channel, 'system',
    "PRIVATE MESSAGE from $nick ($host): $msg — You can reply using send_private_message.");
};

event irc_whois => sub {
  my ( $self, $info ) = @_[ OBJECT, ARG0 ];
  my @parts;
  push @parts, "WHOIS $info->{nick}:";
  push @parts, "  Real name: $info->{real}" if $info->{real};
  push @parts, "  Host: $info->{user}\@$info->{host}" if $info->{user};
  push @parts, "  Server: $info->{server}" if $info->{server};
  push @parts, "  Channels: " . join(' ', @{$info->{channels}}) if $info->{channels};
  push @parts, "  Idle: $info->{idle}s" if defined $info->{idle};
  push @parts, "  Signed on: " . localtime($info->{signon}) if $info->{signon};
  push @parts, "  Account: $info->{account}" if $info->{account};
  # Check if we have notes about this nick
  my $notes = $self->memory->recall_notes($info->{nick}, '', 100);
  if ($notes) {
    my $count = scalar(split /\n/, $notes);
    push @parts, "  You have $count saved note(s) about this user. Use recall_notes to review them.";
  }
  my $result = join("\n", @parts);
  $self->info($result);
  my $channel = $self->_default_channel;
  $self->_buffer_message($channel, 'system', $result);
};

__PACKAGE__->run unless caller;
