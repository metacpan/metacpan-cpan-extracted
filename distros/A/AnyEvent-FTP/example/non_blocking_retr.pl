use strict;
use warnings;
use AnyEvent;
use AnyEvent::FTP::Client;

my $client = AnyEvent::FTP::Client->new( passive => 1);

my $done = AnyEvent->condvar;

# connect to CPAN ftp server
$client->connect('ftp://ftp.cpan.org/pub/CPAN/src')->cb(sub {

  # use binary mode
  $client->type('I')->cb(sub {
      
    # download the file directly into a filehandle
    open my $fh, '>', 'perl-5.16.3.tar.gz';
    $client->retr('perl-5.16.3.tar.gz', $fh)->cb(sub {
      # notify anyone listening to $done that
      # the transfer is complete
      $done->send;
    });
  });

});

# receive the done message once the transfer is
# complete.  In real code you'd probably not
# want to do this because your event loop may
# not support blocking.
$done->recv;
