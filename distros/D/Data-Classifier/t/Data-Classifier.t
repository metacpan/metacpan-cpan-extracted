# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Classifier.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('Data::Classifier') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $yaml = <<EOY;
---
name: Root
children:
    - name: BMW
      children:
          - name: Diesel
            match:
                  model: "d\$"
          - name: Sports
            match:
                  model: "i\$"
                  seats: 2
          - name: Really Expensive
            match:
                  model: "^M"
EOY

my $classifier = Data::Classifier->new(yaml => $yaml);

my $attributes1 = { model => '325i', seats => 4 };
my $attributes2 = { model => '535d', seats => 4 };
my $attributes3 = { model => 'M3', seats => 2 };
my $class1 = $classifier->process($attributes1);
my $class2 = $classifier->process($attributes2);
my $class3 = $classifier->process($attributes3);

ok(! defined($class1->class), 'class1 undefined');
ok(defined($class2->class), 'class2 defined');
ok(defined($class3->class), 'class3 defined');

ok($class2->name eq 'Diesel', 'class2 was diesel');
ok($class3->name eq 'Really Expensive', 'class3 was really expensive');

ok(scalar($class1->stack) == 0, 'class1 stack length was 0');
ok(scalar($class2->stack) == 3, 'class2 stack length was 3');
ok(scalar($class3->stack) == 3, 'class3 stack length was 3');
