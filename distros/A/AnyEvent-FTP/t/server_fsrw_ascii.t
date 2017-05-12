use strict;
use warnings;
use autodie;
use File::Spec;
use Test::More tests => 6;
use Test::AnyEventFTPServer;
use File::Temp qw( tempdir );

my $tmp      = tempdir( CLEANUP => 1);

note "chdir $tmp";
chdir $tmp;

if($^O eq 'MSWin32')
{
  (undef, $tmp) = File::Spec->splitpath($tmp,1);
  $tmp =~ s{\\}{/}g;
}

my $t = create_ftpserver_ok('FSRW');

my $ctx;
my $client;

subtest 'connect and set mode' => sub {
  plan tests => 6;

  $t->on_connect(sub { $ctx = shift->context });

  $t->command_ok(TYPE => 'A')
    ->code_is(200)
    ->message_like(qr{Type set to A});
    
  $t->command_ok(CWD => $tmp)
    ->code_is(250)
    ->message_like(qr{CWD command successful});;
    
  $client = $t->_client;
};

subtest 'store native (default)' => sub {
  plan tests => 12;

  my $payload_crlf = "one\015\012two\015\012three\015\012";

  is $client->stor('test1.txt', \$payload_crlf)->recv->code, 226, 'store okay';

  my $test1;
  is $client->retr('test1.txt', \$test1)->recv->code, 226, 'retr okay';
  is $test1, $payload_crlf, "payload response matches what we sent";

  open my $fh, '<', 'test1.txt';
  $test1 = do { local $/; <$fh> };
  close $fh;
  is $test1, "one\ntwo\nthree\n", "stored as native";
  
  xd('test1.txt');

  $test1 = '';
  is $client->appe('test1.txt', \$payload_crlf)->recv->code, 226, 'appe okay';
  is $client->retr('test1.txt', \$test1)->recv->code, 226, 'retr okay';
  is $test1, "$payload_crlf$payload_crlf", "payload response matches what we sent (append)";

  open $fh, '<', 'test1.txt';
  $test1 = do { local $/; <$fh> };
  close $fh;
  is $test1, "one\ntwo\nthree\none\ntwo\nthree\n", "stored as native (append)";

  xd('test1.txt');
  
  my $xfer = $client->stou(undef, \$payload_crlf);
  is $xfer->recv->code, 226, 'stou okay fn = ' . $xfer->remote_name;
 
  $test1 = ''; 
  is $client->retr($xfer->remote_name, \$test1)->recv->code, 226, 'retr okay';
  is $test1, $payload_crlf, "payload response matches what we sent (stou)";
  
  open $fh, '<', $xfer->remote_name;
  $test1 = do { local $/; <$fh> };
  close $fh;
  is $test1, "one\ntwo\nthree\n", "stored as native";
  
  xd($xfer->remote_name);
};

subtest 'store CRLF' => sub {
  plan skip_all => 'todo';
};

subtest 'store CR' => sub {
  plan skip_all => 'todo';
};

subtest 'store LF' => sub {
  plan skip_all => 'todo';
};

note "chdir " . File::Spec->rootdir;
chdir(File::Spec->rootdir);

sub xd
{
  my $fn = shift;
  if(eval { require Data::HexDump })
  {
    open my $fh, '<', $fn;
    my $data = <$fh>;
    close $fh;
    note "hex dump of $fn";
    note $_ for grep !/^$/, split /\n/, Data::HexDump::HexDump($data);
  }
}
