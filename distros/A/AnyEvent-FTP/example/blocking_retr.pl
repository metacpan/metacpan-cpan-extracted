use strict;
use warnings;
use AnyEvent;
use AnyEvent::FTP::Client;

my $client = AnyEvent::FTP::Client->new( passive => 1);

my $done = AnyEvent->condvar;

# connect to CPAN ftp server
$client->connect('ftp://ftp.cpan.org/pub/CPAN/src')->recv;

# use binary mode
$client->type('I')->recv;
      
# download the file directly into a filehandle
open my $fh, '>', 'perl-5.16.3.tar.gz';
$client->retr('perl-5.16.3.tar.gz', $fh)->recv;
