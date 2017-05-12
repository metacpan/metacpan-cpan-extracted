use lib '../lib';

use Backup::Omni::Utils 'convert_id';
use Backup::Omni::Session::Monitor;
use Backup::Omni::Session::Results;
use Backup::Omni::Session::Filesystem;
use Backup::Omni::Restore::Filesystem::Single;

my $session = Backup::Omni::Session::Filesystem->new(
    -host => 'esd189-aix-01',
    -date => '2013-01-10'
);

my $restore = Backup::Omni::Restore::Filesystem::Single->new(
    -host    => 'esd189-aix-01',
    -session => $session->sessionid,
    -from    => '/archive/pwsipc/pwsipcs.130110_002319.db',
    -to      => '/import01/pwsipc/pwsipcs.130110_002319.db',
    -target  => 'wem-lmgt-02'
);

my $temp = $restore->submit();
my $sessionid = convert_id($temp);

printf("session id: %s\n", $sessionid);

my $monitor = Backup::Omni::Session::Monitor->new(
    -session => $sessionid
);

while ($monitor->running) {

    my $device = $monitor->device;
    printf("\rsaveset position: %s", $device->done);

    sleep(10);

}

my $results = Backup::Omni::Session::Results->new(
    -session => $sessionid
);

printf("\nsession status:     %s\n", $results->status);
printf("number of errors:   %s\n", $results->number_of_errors);
printf("number of warnings: %s\n", $results->number_of_warnings);

