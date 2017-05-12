use strict;
use warnings;
use AnyEvent;
use AnyEvent::FTP::Client;

my $client = AnyEvent::FTP::Client->new;

my $cv = AnyEvent->condvar;

# connect to CPAN ftp server
$client->connect('ftp://ftp.cpan.org/pub/CPAN/src')->cb(sub {

  # execute LIST command and print results to stdout
  $client->list->cb(sub {
    my $list = shift->recv;
    print "$_\n" for @$list;
    $cv->send;
  });

});

$cv->recv;
