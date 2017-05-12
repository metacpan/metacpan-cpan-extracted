use lib '../lib';
use Backup::Omni::Session::Filesystem;

my $session = Backup::Omni::Session::Filesystem->new(
    -host => 'esd189-aix-01',
    -date => '2013-02-15',
);

printf("session id = %s\n", $session->sessionid);

