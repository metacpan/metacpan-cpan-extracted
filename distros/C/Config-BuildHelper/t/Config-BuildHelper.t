# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Config-BuildHelper.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('Config::BuildHelper') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $yaml = <<EOY;
---
name: Root
data:
      config: [[SET, CHECK_BRAKES, CHECK_SPARK_PLUGS]]
children:
    - name: Car
      match: 
            model: "^(\\d{3}[a-z]?|[A-Z]\\d)\$"
      data:
            config: [[ADD, ROTATE_TIRES]]
      children:
          - name: Diesel
            match:
                  model: "d\$"
            data: 
                  config: [[REMOVE, CHECK_SPARK_PLUGS], [ADD, CHECK_GLOW_PLUGS]]
    - name: Motorcycle
      match:
            model: "^[A-Z]\\d{3,4}[^\\d]"
      data: 
            config: [[ADD, CHECK_REAR_TIRE_ALIGNMENT]]
EOY

my @customer_vehicles = (
	{ customer_id => 1, model => '325i' },
	{ customer_id => 2, model => '535d' },
	{ customer_id => 3, model => 'M3' },
	{ customer_id => 4, model => 'R1200RT' },
);

my $helper = Config::BuildHelper->new(yaml => $yaml);

for (@customer_vehicles) {
	my $result = $helper->process($_);

	ok(defined($result->class), 'class was defined');
	ok(scalar($result->config_list) == 3, 'config_list proper length');
}

