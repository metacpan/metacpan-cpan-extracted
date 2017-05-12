use 5.12.0;

use strict;
use warnings;

use Test::Fatal;
use Test::More;
use Test::Warnings;

use AntTweakBar qw/:all/;
use AntTweakBar::Type;

$ENV{ANTTWEAKBAR_DISABLE_LIB} = 1;

subtest "types creation checking" => sub {
    my %type_for = (
        bool       => 1,
        integer    => 2,
        number     => 3.14,
        string     => "abc",
        color3f    => [1, 2, 3],
        color4f    => [0.1, 0.2, 0.3, 0.4],
        direction  => [0, 1, -1],
        quaternion => [1, 2, 3, 4],
    );
    my $bar = AntTweakBar->new("TweakBar");
    for my $type (keys %type_for) {
        my ($ro, $rw) = ($type_for{$type}) x 2;
        $bar->add_variable(
            mode       => 'ro',
            name       => "${type}_ro",
            type       => $type,
            value      => \$ro,
        );
        $bar->add_variable(
            mode       => 'rw',
            name       => "${type}_rw",
            type       => $type,
            value      => \$rw,
        );
        pass "type $type variables seems to be added";
        $bar->remove_variable("${type}_rw");
        $bar->remove_variable("${type}_ro");
        pass "type $type variables seems to be removed";

        $bar->add_variable(
            mode       => 'ro',
            name       => "${type}_ro_cb",
            type       => $type,
            cb_read    => sub { $ro },
        );
        $bar->add_variable(
            mode       => 'rw',
            name       => "${type}_rw_cb",
            type       => $type,
            cb_read    => sub { $ro },
            cb_write   => sub { $ro = $_[0] },
        );
        pass "type $type variables seems to be added (cb version)";
        $bar->remove_variable("${type}_ro_cb");
        $bar->remove_variable("${type}_rw_cb");
        pass "type $type variables seems to be removed (cb version))";
    }
};

subtest "register enum" => sub {
    my $bar = AntTweakBar->new("TweakBar");
    my $t1 = AntTweakBar::Type->new(
        "custom_arr",
        ["a", "b", "c"],
    );
    my $t1_var = "a";
    pass "custom_array type has been created";
    $bar->add_variable(
        mode       => 'rw',
        name       => "ca_ro",
        type       => $t1,
        value      => \$t1_var,
    );
    pass "var of custom_array type has been added";
    my $t2 = AntTweakBar::Type->new(
        "custom_hash",
        {
            d   => 2,
            e   => 10,
            hhh => 11,
        },
    );
    pass "custom_hash type has been created";
    my $t2_var = undef;
    $bar->add_variable(
        mode       => 'ro',
        name       => "ca_ro",
        type       => $t2,
        value      => \$t2_var,
    );
    pass "var of custom_hash type has been added";
};

subtest "invalid type" => sub {
    my $bar = AntTweakBar->new("TweakBar");
    my $e = exception {
        my $val = 5;
        $bar->add_variable(
            mode       => 'ro',
            name       => "_ro",
            type       => 'unknown',
            value      => \$val,
        );
    };
    like $e, qr/Undefined var type/;
};

subtest "variable isn't reference" => sub {
    my $bar = AntTweakBar->new("TweakBar");
    my $e = exception {
        my $val = 5;
        $bar->add_variable(
            mode       => 'ro',
            name       => "_ro",
            type       => 'integer',
            value      => $val,
        );
    };
    like $e, qr/value should be a reference/;
};

done_testing;
