use warnings;
use strict;
use Test::More tests => 4;
use Config::Augeas::Validator;

my $sudo_validator = Config::Augeas::Validator->new(conf => "examples/rules.d/sudo.ini");
$sudo_validator->play('fakeroot/etc/sudoers');
is($sudo_validator->{err}, '0', "Sudo test returned without error");

my $sudo_fail_validator = Config::Augeas::Validator->new(conf => "examples/rules.d/sudo_fail.ini");
$sudo_fail_validator->play('fakeroot/etc/sudoers');
isnt($sudo_fail_validator->{err}, '0', "Sudo test returned with error");

my $hosts_validator = Config::Augeas::Validator->new(conf => "examples/rules.d/hosts.ini");
$hosts_validator->play('fakeroot/etc/hosts');
is($hosts_validator->{err}, '0', "Hosts test returned without error");

# Test with rulesdir
my $validator = Config::Augeas::Validator->new(rulesdir => "examples/rules.d");
$validator->play('fakeroot/etc/hosts');
is($validator->{err}, '0', "rulesdir host test returned without error");

