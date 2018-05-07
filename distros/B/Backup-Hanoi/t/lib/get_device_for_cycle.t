use Test::More tests => 91;

use Backup::Hanoi;


######################
# test three devices #
######################

my $three_devices =   [
                    'A',
                    'B',
                    'C',
                ];

my $backup3 = Backup::Hanoi->new($three_devices);

is $backup3->get_device_for_cycle(-3), 'C', 'three devices cycle -3';
is $backup3->get_device_for_cycle(-2), 'A', 'three devices cycle -2';
is $backup3->get_device_for_cycle(-1), 'B', 'three devices cycle -1';
is $backup3->get_device_for_cycle( 0), 'C', 'three devices cycle  0';

is $backup3->get_device_for_cycle( 1), 'A', 'three devices cycle  1';
is $backup3->get_device_for_cycle( 2), 'B', 'three devices cycle  2';
is $backup3->get_device_for_cycle( 3), 'A', 'three devices cycle  3';
is $backup3->get_device_for_cycle( 4), 'C', 'three devices cycle  4';
is $backup3->get_device_for_cycle( 5), 'A', 'three devices cycle  5';
is $backup3->get_device_for_cycle( 6), 'B', 'three devices cycle  6';
is $backup3->get_device_for_cycle( 7), 'A', 'three devices cycle  7';

is $backup3->get_device_for_cycle( 8), 'C', 'three devices cycle  8';

#####################
# test four devices #
#####################

my $four_devices =   [
                    'A',
                    'B',
                    'C',
                    'D',
                ];

my $backup4 = Backup::Hanoi->new($four_devices);

is $backup4->get_device_for_cycle( 0), 'D', 'four devices cycle  0';

is $backup4->get_device_for_cycle( 1), 'A', 'four devices cycle  1';
is $backup4->get_device_for_cycle( 2), 'B', 'four devices cycle  2';
is $backup4->get_device_for_cycle( 3), 'A', 'four devices cycle  3';
is $backup4->get_device_for_cycle( 4), 'C', 'four devices cycle  4';
is $backup4->get_device_for_cycle( 5), 'A', 'four devices cycle  5';
is $backup4->get_device_for_cycle( 6), 'B', 'four devices cycle  6';
is $backup4->get_device_for_cycle( 7), 'A', 'four devices cycle  7';
is $backup4->get_device_for_cycle( 8), 'D', 'four devices cycle  8';
is $backup4->get_device_for_cycle( 9), 'A', 'four devices cycle  9';
is $backup4->get_device_for_cycle(10), 'B', 'four devices cycle 10';
is $backup4->get_device_for_cycle(11), 'A', 'four devices cycle 11';
is $backup4->get_device_for_cycle(12), 'C', 'four devices cycle 12';
is $backup4->get_device_for_cycle(13), 'A', 'four devices cycle 13';
is $backup4->get_device_for_cycle(14), 'B', 'four devices cycle 14';
is $backup4->get_device_for_cycle(15), 'A', 'four devices cycle 15';

is $backup4->get_device_for_cycle(16), 'D', 'four devices cycle 16';
is $backup4->get_device_for_cycle(17), 'A', 'four devices cycle 17';
is $backup4->get_device_for_cycle(18), 'B', 'four devices cycle 18';
is $backup4->get_device_for_cycle(19), 'A', 'four devices cycle 19';
is $backup4->get_device_for_cycle(20), 'C', 'four devices cycle 20';
is $backup4->get_device_for_cycle(21), 'A', 'four devices cycle 21';
is $backup4->get_device_for_cycle(22), 'B', 'four devices cycle 22';
is $backup4->get_device_for_cycle(23), 'A', 'four devices cycle 23';
is $backup4->get_device_for_cycle(24), 'D', 'four devices cycle 24';
is $backup4->get_device_for_cycle(25), 'A', 'four devices cycle 25';
is $backup4->get_device_for_cycle(26), 'B', 'four devices cycle 26';
is $backup4->get_device_for_cycle(27), 'A', 'four devices cycle 27';
is $backup4->get_device_for_cycle(28), 'C', 'four devices cycle 28';
is $backup4->get_device_for_cycle(29), 'A', 'four devices cycle 29';
is $backup4->get_device_for_cycle(30), 'B', 'four devices cycle 30';
is $backup4->get_device_for_cycle(31), 'A', 'four devices cycle 31';

is $backup4->get_device_for_cycle(32), 'D', 'four devices cycle 32';

#####################
# test five devices #
#####################

my $five_devices =   [
                    'A',
                    'B',
                    'C',
                    'D',
                    'E',
                ];

my $backup5 = Backup::Hanoi->new($five_devices);

is $backup5->get_device_for_cycle( 0), 'E', 'five devices cycle  0';

is $backup5->get_device_for_cycle( 1), 'A', 'five devices cycle  1';
is $backup5->get_device_for_cycle( 2), 'B', 'five devices cycle  2';
is $backup5->get_device_for_cycle( 3), 'A', 'five devices cycle  3';
is $backup5->get_device_for_cycle( 4), 'C', 'five devices cycle  4';
is $backup5->get_device_for_cycle( 5), 'A', 'five devices cycle  5';
is $backup5->get_device_for_cycle( 6), 'B', 'five devices cycle  6';
is $backup5->get_device_for_cycle( 7), 'A', 'five devices cycle  7';
is $backup5->get_device_for_cycle( 8), 'D', 'five devices cycle  8';
is $backup5->get_device_for_cycle( 9), 'A', 'five devices cycle  9';
is $backup5->get_device_for_cycle(10), 'B', 'five devices cycle 10';
is $backup5->get_device_for_cycle(11), 'A', 'five devices cycle 11';
is $backup5->get_device_for_cycle(12), 'C', 'five devices cycle 12';
is $backup5->get_device_for_cycle(13), 'A', 'five devices cycle 13';
is $backup5->get_device_for_cycle(14), 'B', 'five devices cycle 14';
is $backup5->get_device_for_cycle(15), 'A', 'five devices cycle 15';
is $backup5->get_device_for_cycle(16), 'E', 'five devices cycle 16';

is $backup5->get_device_for_cycle(31), 'A', 'five devices cycle 31';
is $backup5->get_device_for_cycle(32), 'E', 'five devices cycle 32';
is $backup5->get_device_for_cycle(128),'E', 'five devices cycle 128';
is $backup5->get_device_for_cycle(254),'B', 'five devices cycle 254';
is $backup5->get_device_for_cycle(255),'A', 'five devices cycle 255';
is $backup5->get_device_for_cycle(256),'E', 'five devices cycle 256';

####################
# test six devices #
####################

my $six_devices =   [
                    'A',
                    'B',
                    'C',
                    'D',
                    'E',
                    'F',
                ];

my $backup6 = Backup::Hanoi->new($six_devices);

is $backup6->get_device_for_cycle( 0), 'F', 'six devices cycle  0';

is $backup6->get_device_for_cycle( 1), 'A', 'six devices cycle  1';
is $backup6->get_device_for_cycle( 2), 'B', 'six devices cycle  2';
is $backup6->get_device_for_cycle( 3), 'A', 'six devices cycle  3';
is $backup6->get_device_for_cycle( 4), 'C', 'six devices cycle  4';
is $backup6->get_device_for_cycle( 5), 'A', 'six devices cycle  5';
is $backup6->get_device_for_cycle( 6), 'B', 'six devices cycle  6';
is $backup6->get_device_for_cycle( 7), 'A', 'six devices cycle  7';
is $backup6->get_device_for_cycle( 8), 'D', 'six devices cycle  8';
is $backup6->get_device_for_cycle( 9), 'A', 'six devices cycle  9';
is $backup6->get_device_for_cycle(10), 'B', 'six devices cycle 10';
is $backup6->get_device_for_cycle(11), 'A', 'six devices cycle 11';
is $backup6->get_device_for_cycle(12), 'C', 'six devices cycle 12';
is $backup6->get_device_for_cycle(13), 'A', 'six devices cycle 13';
is $backup6->get_device_for_cycle(14), 'B', 'six devices cycle 14';
is $backup6->get_device_for_cycle(15), 'A', 'six devices cycle 15';
is $backup6->get_device_for_cycle(16), 'E', 'six devices cycle 16';

is $backup6->get_device_for_cycle(31), 'A', 'six devices cycle 31';
is $backup6->get_device_for_cycle(32), 'F', 'six devices cycle 32';
is $backup6->get_device_for_cycle(128),'F', 'six devices cycle 128';
is $backup6->get_device_for_cycle(254),'B', 'six devices cycle 254';
is $backup6->get_device_for_cycle(255),'A', 'six devices cycle 255';
is $backup6->get_device_for_cycle(256),'F', 'six devices cycle 256';
