use strict;
use Test::More tests => 32;
use Test::Exception;
use Mock::Quick;

BEGIN {
   (my $subdir = __FILE__) =~ s{t$}{d}mxs;
   unshift @INC, $subdir;
}

use UA;

my @ua_posts;
my $ua_control = qclass(
   -implement => 'Mojo::UserAgent',
   -with_new  => 1,
   post       => sub { shift; push @ua_posts, [@_] },
);

my $running_flag = 0;
my $loop_control = qclass(
   -implement => 'Mojo::IOLoop',
   start      => sub { $running_flag++ },
   is_running => sub { return !!$running_flag }
);

my $ua;
lives_ok { $ua = UA->new } 'default constructor lives';
ok !$ua->has_callback, 'no callback by default';

ok !$ua->start_loop, 'loop does not start by itself';

$running_flag = 0;
lives_ok { $ua->may_start_loop } 'may_start_loop lives (1)';
ok !$running_flag, 'loop was not started';

$running_flag = 0;
lives_ok { $ua->may_start_loop(start_loop => 1) }
'may_start_loop lives (2)';
ok $running_flag, 'loop was started';

$running_flag = 0;
lives_ok { $ua->start_loop(1) } 'set start_loop to 1 lives';
lives_ok { $ua->may_start_loop } 'may_start_loop lives (3)';
ok $running_flag, 'loop was started';

$running_flag = 0;
lives_ok { $ua->may_start_loop(start_loop => 0) }
'may_start_loop lives (4)';
ok !$running_flag, 'loop was not started';

@ua_posts = ();
$running_flag = 0;
lives_ok { $ua->ua_request('post', ua_args => [1..3], start_loop => 1) }
  'ua_request lives';
ok !$running_flag, 'loop was not started (no callback)';
is scalar(@ua_posts), 1, 'one post was sent';
is_deeply $ua_posts[0], [1..3], 'post parameters';

@ua_posts = ();
$running_flag = 0;
my $some_sub = sub { return 'some' };
lives_ok { $ua->ua_request('post', ua_args => [$some_sub]) }
  'ua_request lives';
ok $running_flag, 'loop was started (callback in ua_args)';
is scalar(@ua_posts), 1, 'one post was sent';
isa_ok $ua_posts[0][0], 'CODE', 'post parameters';
is $ua_posts[0][0]->(), 'some', 'right callback';

@ua_posts = ();
$running_flag = 0;
my $other_sub = sub { return 'other' };
lives_ok { $ua->callback($other_sub) } 'callback (setter) lives';
lives_ok { $ua->ua_request('post', ua_args => []) }
  'ua_request lives';
ok $running_flag, 'loop was started (callback in object)';
is scalar(@ua_posts), 1, 'one post was sent';
isa_ok $ua_posts[0][0], 'CODE', 'post parameters';
is $ua_posts[0][0]->(), 'other', 'right callback';

@ua_posts = ();
$running_flag = 0;
my $some_sub = sub { return 'some' };
lives_ok { $ua->ua_request('post', ua_args => [$some_sub]) }
  'ua_request lives';
ok $running_flag, 'loop was started (callback in ua_args)';
is scalar(@ua_posts), 1, 'one post was sent';
isa_ok $ua_posts[0][0], 'CODE', 'post parameters';
is $ua_posts[0][0]->(), 'some', 'right callback (ua_args wins)';

done_testing();
