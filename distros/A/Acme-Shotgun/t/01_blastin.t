use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::More;
use Test::Exception;

use_ok('Acme::Shotgun');

## Helpers

sub make_target {
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "$_\n" for
        "The quick brown fox jumps over the lazy dog.",
        "Pack my box with five dozen liquor jugs.",
        "How vexingly quick daft zebras jump!",
        "The five boxing wizards jump quickly.",
        "Sphinx of black quartz, judge my vow.",
        "Waltz, bad nymph, for quick jigs vex.",
        "Glib jocks quiz nymph to vex dwarf.",
        "Jackdaws love my big sphinx of quartz.",
        "The jay, pig, fox, zebra and my wolves quack.",
        "Sympathizing would fix Quaker objectives.";
    close $fh;
    return $filename;
}

sub quiet_gun {
    my %args = @_;
    return Acme::Shotgun->new(quiet => 1, %args);
}

## Construction & defaults

subtest 'construction with defaults' => sub {
    my $gun = quiet_gun();
    isa_ok($gun, 'Acme::Shotgun');
    is($gun->{type},  'double', 'default type is double');
    is($gun->{load},  'bird',   'default load is bird');
    is($gun->{num_rounds}, 2,   'double loads 2 rounds by default');
};

subtest 'pump type loads 5 rounds' => sub {
    my $gun = quiet_gun(type => 'pump');
    is($gun->{num_rounds}, 5, 'pump loads 5 rounds');
};

subtest 'shots arg caps round count' => sub {
    my $gun = quiet_gun(type => 'pump', shots => 3);
    is($gun->{num_rounds}, 3, 'shots caps pump to 3');

    $gun = quiet_gun(type => 'double', shots => 1);
    is($gun->{num_rounds}, 1, 'shots caps double to 1');
};

subtest 'shots arg does not exceed default capacity' => sub {
    my $gun = quiet_gun(type => 'double', shots => 99);
    is($gun->{num_rounds}, 2, 'shots cannot exceed double capacity of 2');

    $gun = quiet_gun(type => 'pump', shots => 99);
    is($gun->{num_rounds}, 5, 'shots cannot exceed pump capacity of 5');
};

## Validation

subtest 'invalid type dies' => sub {
    dies_ok { Acme::Shotgun->new(type => 'bazooka', quiet => 1) }
        'invalid type dies';

    like($@, qr/Invalid shotgun type/, 'error mentions invalid shotgun type');
};

subtest 'invalid load dies' => sub {
    dies_ok { Acme::Shotgun->new(load => 'rubber', quiet => 1) }
        'invalid load dies';

    like($@, qr/Invalid ammo type/, 'error mentions invalid ammo type');
};

## Reload

subtest 'reload restores round count' => sub {
    my $gun = quiet_gun();
    $gun->{num_rounds} = 0;
    $gun->reload();
    is($gun->{num_rounds}, 2, 'reload restores double to 2 rounds');
};

subtest 'reload returns $self for chaining' => sub {
    my $gun = quiet_gun();
    my $ret = $gun->reload();
    is($ret, $gun, 'reload returns $self');
};

## Check

subtest 'check returns $self for chaining' => sub {
    my $gun = quiet_gun();
    my $ret = $gun->check();
    is($ret, $gun, 'check returns $self');
};

## Fire

subtest 'fire dies with no target' => sub {
    my $gun = quiet_gun();
    dies_ok { $gun->fire() } 'fire with no target dies';
    like($@, qr/No target specified/, 'error mentions no target');
};

subtest 'fire dies on nonexistent file' => sub {
    my $gun = quiet_gun();
    dies_ok { $gun->fire(target => '/no/such/file.txt') }
        'fire on nonexistent file dies';
    like($@, qr/does not exist/, 'error mentions file does not exist');
};

subtest 'fire expends all rounds' => sub {
    my $gun    = quiet_gun();
    my $target = make_target();
    $gun->fire(target => $target);
    is($gun->{num_rounds}, 0, 'all rounds expended after fire');
};

subtest 'fire returns $self for chaining' => sub {
    my $gun    = quiet_gun();
    my $target = make_target();
    my $ret    = $gun->fire(target => $target);
    is($ret, $gun, 'fire returns $self');
};

subtest 'fire with empty mag does not die' => sub {
    my $gun    = quiet_gun();
    my $target = make_target();
    $gun->{num_rounds} = 0;
    lives_ok { $gun->fire(target => $target) } 'fire with empty mag does not die';
};

## Actual file damage

subtest 'fire modifies file contents' => sub {
    my $gun    = quiet_gun(type => 'pump', shots => 5);
    my $target = make_target();

    open my $fh, '<', $target or die "Can't open: $!";
    my $before = do { local $/; <$fh> };
    close $fh;

    # Fire multiple volleys to ensure at least one shot lands on text.
    for (1..5) {
        $gun->reload();
        $gun->fire(target => $target);
    }

    open $fh, '<', $target or die "Can't open: $!";
    my $after = do { local $/; <$fh> };
    close $fh;

    isnt($before, $after, 'file contents changed after firing');
};

subtest 'debug mode does not modify file' => sub {
    my $gun    = quiet_gun(debug => 1);
    my $target = make_target();

    open my $fh, '<', $target or die "Can't open: $!";
    my $before = do { local $/; <$fh> };
    close $fh;

    $gun->fire(target => $target);

    open $fh, '<', $target or die "Can't open: $!";
    my $after = do { local $/; <$fh> };
    close $fh;

    is($before, $after, 'file contents unchanged in debug mode');
};

subtest 'all ammo types fire without error' => sub {
    for my $load (qw(bird buck slug)) {
        my $gun    = quiet_gun(load => $load);
        my $target = make_target();
        lives_ok { $gun->fire(target => $target) } "$load fires without error";
    }
};

subtest 'all shotgun types fire without error' => sub {
    for my $type (qw(double pump)) {
        my $gun    = quiet_gun(type => $type);
        my $target = make_target();
        lives_ok { $gun->fire(target => $target) } "$type fires without error";
    }
};

done_testing();
