use strict;
use warnings;
use Test::More tests => 14;

eval {
  package Client;

  use Moo;

  with 'AnyEvent::FTP::Client::Role::ResponseBuffer';
};
diag $@ if $@;

my $client = eval { Client->new };
diag $@ if $@;
isa_ok $client, 'Client';

my $count1 = 0;
$client->on_each_response(sub {
  $count1++;
  isa_ok shift, 'AnyEvent::FTP::Response';
});

my $count2 = 0;
$client->on_next_response(sub {
  $count2++;
  my $res = shift;
  is $res->code, 220, 'code = 220';
  is join("\n", @{ $res->message }), 'ProFTPD 1.3.3a Server (Debian) [::ffff:10.10.16.1]', 'message = ProFTPD 1.3.3a Server (Debian) [::ffff:10.10.16.1]';
});

$client->process_message_line("220 ProFTPD 1.3.3a Server (Debian) [::ffff:10.10.16.1]\015\012");

my $count3 = 0;

$client->on_next_response(sub {
  $count3++;
  my $res = shift;
  is $res->code, 214, 'code = 214';
  is scalar(@{ $res->message }), 3, 'line count = 3';
});

$client->process_message_line("214-The following commands are recognized (* =>\'s unimplemented):\015\012");
$client->process_message_line("214-CWD     XCWD    CDUP    XCUP    SMNT*   QUIT    PORT    PASV\015\012");
$client->process_message_line("214 Direct comments to root\@web01.sydney.wdlabs.com\015\012");

my $count4 = 0;

$client->on_next_response(sub {
  $count4++;
  my $res = shift;
  is $res->code, 214, 'code = 214';
  is scalar(@{ $res->message }), 6, 'line count = 6';
});

$client->process_message_line("214-The following commands are recognized:\015\012");
$client->process_message_line("   USER    TYPE    RETR    RNFR    NLST    PWD     ALLO    EPSV\015\012");
$client->process_message_line("   PASS    STRU    STOR    RNTO    CWD     CDUP    SYST    QUIT\015\012");
$client->process_message_line("   SITE    PORT    STOU    DELE    MKD     NOOP    STAT    HELP\015\012");
$client->process_message_line("   MODE    EPRT    APPE    LIST    RMD     ABOR    PASV\015\012");
$client->process_message_line("214 End of Help.\015\012");
            
is $count1, 3, 'total = 3';
is $count2, 1, 'single = 1';
is $count3, 1, 'single = 1';
is $count4, 1, 'single = 1';
