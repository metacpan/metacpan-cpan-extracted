# -*- mode: perl -*-
use strict;
use warnings;

use Apache::Test qw{:withtestmore};
use Test::More;
use Apache::TestUtil;
use Apache::TestUtil qw/t_write_file t_client_log_error_is_expected
                        t_start_error_log_watch t_finish_error_log_watch
			t_read_file_watch
                        t_mkdir t_catfile t_write_file/;
use Apache::TestRequest qw{GET_BODY GET};

sub t_grep_file_watch ($;$$) {
  use Time::HiRes ();
  my $re=shift;
  my $timeout=10;
  $timeout=shift if @_;
  my $line;
  eval {
    local $SIG{ALRM}=sub { warn "alarm; alarm";die \42};
    Time::HiRes::alarm $timeout;
    eval {
    OUTER: while() {
	while( defined (my $l=t_read_file_watch @_?$_[0]:()) ) {
	  if( $l=~$re ) {
	    $line=$l;
	    last OUTER;
	  }
	}
	select undef, undef, undef, 0.1;
      }
    };
    Time::HiRes::alarm 0;
  };
  Time::HiRes::alarm 0;
  return $line;
}

BEGIN {
  #plan 'no_plan';
  plan tests=>26;

  use_ok('Apache2::ScoreBoardFile');
}

my $t_dir=Apache::Test::vars('t_dir');
#t_debug "@{[keys %{Apache::Test::vars()}]}";
my $pidfile=Apache::Test::vars('t_pid_file');
my $indexfile=t_catfile Apache::Test::vars('documentroot'), 'index.html';
t_debug "indexfile=$indexfile";

Apache::TestRequest::user_agent(reset => 1,
				requests_redirectable => 0);

$!=0;
my $obj=Apache2::ScoreBoardFile->new('.');
ok $!, "errno: $!";
ok !defined($obj), 'object creation (undef)';

my $sb="$t_dir/scoreboard.sb";

{
 open my $fd, '<', $sb or die;
 is ref(Apache2::ScoreBoardFile->new($fd)), 'Apache2::ScoreBoardFile',
        'object creation from fd';
 is +(stat $fd)[9], +(stat $sb)[9], 'fd is still open';
}

$obj=Apache2::ScoreBoardFile->new($sb);
is ref($obj), 'Apache2::ScoreBoardFile', 'object creation by name';

is $obj->shmsize, (stat $sb)[7], 'shmsize=size(sbfile)';

t_debug $obj->restart_time." >= ".((stat $pidfile)[9]-1);
ok $obj->restart_time>=(stat $pidfile)[9]-1, 'restart_time >= mtime(pidfile)-1';

my $gen=$obj->generation;
cmp_ok $gen, '>=', 0, 'current generation>=0';
is $obj->type, 2, 'type=SB_SHARED';

is $obj->server_limit, 16, "ServerLimit 16 (extra.conf.in)";

for (qw/shmsize server_limit thread_limit type generation
	restart_time lb_limit/) {
  t_debug "$_: ".$obj->$_;
}

t_start_error_log_watch;
{
  local $/;
  local @ARGV=($pidfile);
  my $pid=0+<>;
  t_debug "httpd pid=$pid";
  kill 'HUP', $pid;
}
warn "ERROR: Cannot restart apache"
  unless t_grep_file_watch qr/resuming normal operations/;
t_finish_error_log_watch;

is $obj->generation, $gen+1, "current generation=$gen+1 after restart";
$gen++;

my $count=0;			# StartServers 2
t_debug "pids: ".join ", ", map {$obj->process($_)->pid} 0..15;
for( my $i=0; $i<16; $i++ ) {
  $count++ if $obj->process($i)->pid;
}

is $count, 3, 'StartServers 3 - found '.$count;

ok !defined($obj->process(17)), 'process(17) - undef (out of range)';
ok !defined($obj->process(-1)), 'process(-1) - undef (out of range)';

$count=0;
for( my $i=0; $i<16; $i++ ) {
  $count+=$obj->worker($i)->thread_num;
}
is $count, 3, 'sum(thread_num)==3';

$count=join "", map {$obj->worker($_)->status} 0..15;
t_debug "status: $count";
is $count=~tr/_//, 3, '3 ready worker (status _)';

t_debug "access_count: ".join ", ", map {$obj->worker($_)->access_count} 0..15;
$count=0;
for( my $i=0; $i<16; $i++ ) {
  $count+=$obj->worker($i)->access_count;
}
is $count, 0, 'sum(access_count)==0';

GET '/index.html' for (1..3);
Apache::TestRequest::module 'h2';
GET '/';

t_debug "access_count: ".join ", ", map {$obj->worker($_)->access_count} 0..15;
$count=0;
for( my $i=0; $i<16; $i++ ) {
  $count+=$obj->worker($i)->access_count;
}
is $count, 4, 'sum(access_count)==4';

$count=join ", ", map {$obj->worker($_)->request} 0..15;
t_debug "request: ".$count;
like $count, qr!GET /index\.html HTTP/1\.\d!, 'GET /index.html';
like $count, qr!GET / HTTP/1\.\d!, 'GET /';

$count=join ", ", map {$obj->worker($_)->vhost} 0..15;
t_debug "vhost: ".$count;
like $count, qr!fritz!, 'Main Server = fritz';
like $count, qr!hugo!, 'vhost = hugo';

$count=join ", ", map {$obj->worker($_)->client} 0..15;
t_debug "client: ".$count;

ok !defined($obj->worker(17)), 'worker(17) - undef (out of range)';
ok !defined($obj->worker(-1)), 'worker(-1) - undef (out of range)';

my %summary;
my @keys=qw/. _ S R W K L D C G I bw iw cw nr nb/;
@summary{@keys}=$obj->summary(@keys);

use Data::Dumper;
t_debug Dumper \%summary;

is_deeply \%summary, {
		      '.' => '13',
		      'C' => '0',
		      'D' => '0',
		      'G' => '0',
		      'I' => '0',
		      'K' => '0',
		      'L' => '0',
		      'R' => '0',
		      'S' => '0',
		      'W' => '0',
		      '_' => '3',
		      'bw' => '0',
		      'cw' => '3',
		      'iw' => '3',
		      'nb' => 4*(-s $indexfile),
		      'nr' => '4'
		     }, 'summary';
