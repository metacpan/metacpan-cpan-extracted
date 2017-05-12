use warnings;
use strict;
use Test::More tests => 1;
use Config::Augeas::Validator;

my $validator = Config::Augeas::Validator->new(conf => "examples/sudo.ini");
ok($validator, "Created new Augeas validator object");
