use lib '../lib';
use Backup::Omni::Session::Monitor;

my $monitor = Backup::Omni::Session::Monitor->new(
    -session => '2013/01/28-1'
);

while ($monitor->running) {
    
    my $device = $monitor->device;
    printf("saveset postions: %s", $device->done);
    
}

printf("session done\n");

