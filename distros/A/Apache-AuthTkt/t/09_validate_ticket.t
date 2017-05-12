# Test parse_ticket()

use File::Basename;
use Test::More tests => 48;
BEGIN { use_ok(Apache::AuthTkt) }
use strict;

# Testing against old TktUtil
my $TU = 0;
if ($TU) {
    require TktUtil;
}

# Load result strings
my $test = 't02';
my %result = ();
$test = "t/$test" if -d "t/$test";
die "missing data dir $test" unless -d $test;
opendir DATADIR, "$test" or die "can't open $test";
for my $f (readdir DATADIR) {
  next if $f =~ m/^\./;
  open FILE, "<$test/$f" or die "can't read $test/$f";
  {
      local $/ = undef;
      $result{$f} = <FILE>;
  }
  close FILE;
  chomp $result{$f};
}
close DATADIR;

# This allows you to specify a test to stop at, dumping the result
my $print = shift @ARGV || 0;
my $t = 4;
sub report {
  my ($data, $file, $inc) = @_;
  $inc ||= 1;
  if ($print == $t) {
    print STDERR "--> $file\n";
    print "$data\n";
    exit 0;
  }
  $t += $inc;
}

my ($at, $ticket, $tu, $different_at, $different_at_ip_ignore);
my $ts = 1108811260;
my $conf = dirname($0) . "/t01/mod_auth_tkt.conf";
$ENV{REMOTE_ADDR} = '192.168.0.1';

# Setup
if ($TU) {
  $TktUtil::SECRET_CONFIG_FILE = $conf;
  # Silence warning
  my $x = $TktUtil::SECRET_CONFIG_FILE;
}
ok($at = Apache::AuthTkt->new(conf => $conf),
    'conf constructor ok');
ok($different_at = Apache::AuthTkt->new( secret => "DifferentSecret" ), 'created new object with different secret');
is($at->secret, '0e1d79e1-c18b-43c5-bfd6-a396e13bf39c', 'secret() ok');
is($different_at->secret, "DifferentSecret", "Different secret to check MD5 hash" );
ok($different_at_ip_ignore = Apache::AuthTkt->new( secret => $at->secret(), ignore_ip => 1), 'created object with ignore_ip=1, same secret');

my $parsed;

# Default settings
print TktUtil::get_auth_ticket(ts => $ts, base64 => 0, uid => 'guest', ip_addr => $ENV{REMOTE_ADDR}) . "\n" if $TU;
$ticket = $at->ticket(ts => $ts, base64 => 0);
report $ticket, 'defaults';
is($ticket, $result{defaults}, 'ticket using defaults ok');
ok($parsed = $at->parse_ticket($ticket), 'parse ticket using defaults');
is($parsed->{uid}, 'guest', 'uid parsed');
is($parsed->{ts}, $ts, 'ts parsed');
is($parsed->{tokens}, '', "tokens ''");
is($parsed->{data}, '', "data ''");
is_deeply($at->validate_ticket( $ticket ), $parsed, "MD5 checked");
is($different_at->validate_ticket( $ticket ), undef, "Different secret so no data returned" );

# TKTAuthIgnoreIP tickets
print TktUtil::get_auth_ticket(ts => $ts, uid => 'guest', ip_addr => '0.0.0.0') . "\n" if $TU;
$ticket = $at->ticket(ts => $ts, ip_addr => 0);
report $ticket, 'ignore_ip';
is($ticket, $result{ignore_ip}, 'ticket ignore ip 1 ok');
ok($parsed = $at->parse_ticket($ticket), 'parse ticket ignore ip 1');
is($parsed->{uid}, 'guest', 'uid parsed');
is($parsed->{ts}, $ts, 'ts parsed');
is($parsed->{tokens}, '', "tokens ''");
is($parsed->{data}, '', "data ''");
is_deeply($at->validate_ticket( $ticket, ip_addr => '0.0.0.0' ), $parsed, "MD5 checked");
is_deeply($different_at_ip_ignore->validate_ticket( $ticket ), $parsed, "MD5 checked with ignore_ip set on constructor");
is($different_at->validate_ticket( $ticket ), undef, "Different secret so no data returned" );

$ticket = $at->ticket(ts => $ts, ip_addr => undef);
report $ticket, 'ignore_ip';
is($ticket, $result{ignore_ip}, 'ticket ignore ip 2 ok');
ok($parsed = $at->parse_ticket($ticket), 'parse ticket ignore ip 2');
is($parsed->{uid}, 'guest', 'uid parsed');
is($parsed->{ts}, $ts, 'ts parsed');
is($parsed->{tokens}, '', "tokens ''");
is($parsed->{data}, '', "data ''");
is_deeply($at->validate_ticket( $ticket, ip_addr => undef ), $parsed, "MD5 checked");
is_deeply($different_at_ip_ignore->validate_ticket( $ticket ), $parsed, "MD5 checked with ignore_ip set on constructor");
is($different_at->validate_ticket( $ticket ), undef, "Different secret so no data returned" );

# Complex tickets
print TktUtil::get_auth_ticket(ts => $ts, base64 => 0, uid => 'gavin', ip_addr => $ENV{REMOTE_ADDR}, tokens => 'finance,admin,it', data => 'Mary had a little lamb') . "\n" if $TU;
$ticket = $at->ticket(ts => $ts, base64 => 0, uid => 'gavin', tokens => 'finance, admin, it', data => 'Mary had a little lamb');
report $ticket, 'complex1';
is($ticket, $result{complex1}, 'ticket complex 1 ok');
ok($parsed = $at->parse_ticket($ticket), 'parse ticket complex 1');
is($parsed->{uid}, 'gavin', 'uid parsed');
is($parsed->{ts}, $ts, 'ts parsed');
is($parsed->{tokens}, 'finance,admin,it', 'tokens parsed');
is($parsed->{data}, 'Mary had a little lamb', 'data parsed');
is_deeply($at->validate_ticket( $ticket ), $parsed, "MD5 checked");
is($different_at->validate_ticket( $ticket ), undef, "Different secret so no data returned" );

print TktUtil::get_auth_ticket(ts => $ts, base64 => 1, uid => 'freddy', ip_addr => $ENV{REMOTE_ADDR}, data => $ENV{REMOTE_ADDR}) . "\n" if $TU;
$ticket = $at->ticket(ts => $ts, base64 => 1, uid => 'freddy', data => $ENV{REMOTE_ADDR});
report $ticket, 'complex2';
is($ticket, $result{complex2}, 'ticket complex 2 ok');
ok($parsed = $at->parse_ticket($ticket), 'parse ticket complex 2');
is($parsed->{uid}, 'freddy', 'uid parsed');
is($parsed->{ts}, $ts, 'ts parsed');
is($parsed->{tokens}, '', "tokens ''");
is($parsed->{data}, $ENV{REMOTE_ADDR}, 'data parsed');
is_deeply($at->validate_ticket( $ticket ), $parsed, "MD5 checked");
is($different_at->validate_ticket( $ticket ), undef, "Different secret so no data returned" );


# vim:ft=perl
