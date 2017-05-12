#!perl
use common::sense;
use Test::More;
use AnyEvent::IRC::Util
   qw/parse_irc_msg mk_msg split_prefix rfc_code_to_name
      prefix_nick prefix_user prefix_host filter_colors/;

our @ircmsg_tests = (
   ['full message' =>
      ":nick!user\@host PRIVMSG #test :test message\015\012" => {
         prefix    => 'nick!user@host',
         prefix_ar => ['nick', 'user', 'host'],
         command   => 'PRIVMSG',
         params    => ['#test', 'test message'],
      }
   ],
   ['quoted colon' =>
      ":nick!user\@host PRIVMSG #test ::)\015\012" => {
         prefix    => 'nick!user@host',
         prefix_ar => ['nick', 'user', 'host'],
         command   => 'PRIVMSG',
         params    => ['#test', ':)'],
      }
   ],
   ['without prefix' =>
      "PART #test :i'm gone\015\012" => {
          prefix   => undef,
          command  => 'PART',
          params   => ['#test', 'i\'m gone'],
      }
   ],
   ['without params' =>
      "QUIT\015\012" => {
         prefix   => undef,
         command  => 'QUIT',
         params   => [],
      }
   ],
);

our @ircmodes = (
   [qw/461 ERR_NEEDMOREPARAMS/],
   [qw/491 ERR_NOOPERHOST/],
   [qw/324 RPL_CHANNELMODEIS/],
   [qw/209 RPL_TRACECLASS/],
   [qw/001 RPL_WELCOME/],
   [qw/502 ERR_USERSDONTMATCH/]
);

plan tests =>
   (4 * scalar @ircmsg_tests)
   + (6 * scalar grep { $_->[2]->{prefix} } @ircmsg_tests)
   + scalar @ircmodes
   + 3;

{
   sub undef_or_eq {
      my ($what, $it) = @_;
      if (not defined $what) {
         return not defined $it;
      } else {
         return 0 unless defined $it;
         return $what eq $it;
      }
   }
   sub cmp_msg {
      my ($name, $msg, $cmp) = @_;
      ok (undef_or_eq ($cmp->{prefix}, $msg->{prefix}),   "$name: message prefix");
      ok (undef_or_eq ($cmp->{command}, $msg->{command}), "$name: message command");

      my $params_ok = 1;

      if ($cmp->{params}) {
         my @msgp = @{$msg->{params}};
         for (@{$cmp->{params}}) {
            my $p = shift @msgp;
            unless (undef_or_eq ($_, $p)) {
               $params_ok = 0;
               last
            }
         }
      }

      ok ($params_ok, "$name: message params");
   }

   for (@ircmsg_tests) {
      my $msg = parse_irc_msg ($_->[1]);
      cmp_msg ($_->[0], $msg, $_->[2]);
   }
}

{
   for (@ircmsg_tests) {
      my $name = $_->[0];
      my $msg  = $_->[1];
      my $pmsg = parse_irc_msg ($msg);
      my @params = @{$pmsg->{params}};
      my $omsg =
         mk_msg ($pmsg->{prefix}, $pmsg->{command}, @params) . "\015\012";

      is ($omsg, $msg, "$name: message parse and making succeed");
   }
}

{
   for (@ircmsg_tests) {
      my $name = $_->[0];
      my $msg  = $_->[1];
      my $cmp  = $_->[2];

      if ($cmp->{prefix}) {
         $msg = parse_irc_msg ($msg);
         my @prfx = split_prefix ($msg->{prefix});
         for (0..2) {
            is ($prfx[$_], $cmp->{prefix_ar}->[$_], "'$name': prefix ($_)")
         }
         is (prefix_nick ($msg), $cmp->{prefix_ar}->[0], "$name: nick prefix");
         is (prefix_user ($msg), $cmp->{prefix_ar}->[1], "$name: user prefix");
         is (prefix_host ($msg), $cmp->{prefix_ar}->[2], "$name: host prefix");
      }
   }
}

for (@ircmodes) {
   is (rfc_code_to_name ($_->[0]), $_->[1], "rfc_code_to_name: $_->[0]");
}

is (filter_colors ('2007-06-30 12:14:36 +0200 | IRC RECV{cmd: 332, params: elmex, #Jav-Fans, 8,1::7[ 0JAVFANS 7]8:: 8:: 7( 8Recruiting 7)0'),
    '2007-06-30 12:14:36 +0200 | IRC RECV{cmd: 332, params: elmex, #Jav-Fans, ::[ JAVFANS ]:: :: ( Recruiting )',
    'mirc color filter ok');

is (filter_colors ('2007-08-04 22:01:04 +0200 | IRC RECV{cmd: PRIVMSG, params: #welcome, [A[A[Bcocommlymeca: what is the biggest contemporan brake to the evolution of humankind towards Communism?, prefix: anonymous!anonymous@psyced.org}'),
    '2007-08-04 22:01:04 +0200 | IRC RECV{cmd: PRIVMSG, params: #welcome, cocommlymeca: what is the biggest contemporan brake to the evolution of humankind towards Communism?, prefix: anonymous!anonymous@psyced.org}', 'filter ansi sequences');
is (filter_colors ('2007-08-07 19:15:27 +0200 | IRC RECV{cmd: PRIVMSG, params: #ccc, ~[5~[5~[5~[6~[6~[6~[5~[6~, prefix: schneider!~schneider@blinkenlichts.net}'),
    '2007-08-07 19:15:27 +0200 | IRC RECV{cmd: PRIVMSG, params: #ccc, ~, prefix: schneider!~schneider@blinkenlichts.net}',
    'filter ansi sequences 2');
