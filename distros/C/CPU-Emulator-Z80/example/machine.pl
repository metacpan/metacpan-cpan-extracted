#!/usr/local/bin/perl -w

use strict;

use CPU::Emulator::Z80;
use Time::HiRes qw(setitimer ITIMER_VIRTUAL ITIMER_REAL);
use Term::ReadKey;
use IO::Scalar;
use Data::Dumper;

my $cpu = CPU::Emulator::Z80->new( # RAM is 64K of zeroes
    ports => 256,
);
my $clock = 0; # clock isn't running
my @banks = (
    {
        address => 0x0000,
        type    => 'ROM',
        size    => 0x4000,
        file    => IO::Scalar->new(do { # example/LDR-0x0000.z80.o
                       open(my $f, 'example/LDR-0x0000.z80.o') ||
                           die("Can't read LDR-0x0000.z80.o\n");
                       local $/ = undef;
                       my $rom = <$f>;
                       $rom .= chr(0) x (0x4000 - length($rom));
                       \$rom;
                   }),
    },
    {
        address => 0x4000,
        type    => 'ROM',
        size    => 0x4000,
        file    => IO::Scalar->new(do { # example/LDR-0x0000.z80.o
                       open(my $f, 'example/OS-0x0000.z80.o') ||
                           die("Can't read OS-0x0000.z80.o\n");
                       local $/ = undef;
                       my $rom = <$f>;
                       $rom .= chr(0) x (0x4000 - length($rom));
                       \$rom;
                   }),
    }
);
$cpu->memory()->bank(%{$banks[0]}); # boot loader
$cpu->memory()->bank(%{$banks[1]}); # OS

$cpu->add_output_device(address => 0x00, function => \&mem_bank);
$cpu->add_output_device(address => 0x01, function => \&mem_unbank);
$cpu->add_output_device(address => 0x02, function => \&io_wr_stdout);
$cpu->add_output_device(address => 0xFF, function => \&hw_start_clock);

setitimer(ITIMER_VIRTUAL, 1, 1);
# setitimer(ITIMER_REAL, 1, 0.2);
$SIG{VTALRM} = sub {
# $SIG{ALRM} = sub {
    my $key = ReadKey(-1);
    if($key) {
        # print "Got char $key\n";
    }
    $cpu->interrupt() if($clock);
};

ReadMode 'noecho';
ReadMode 'cbreak';
$cpu->run(100000);

print Dumper($cpu->memory());
print $cpu->format_registers();

sub mem_bank {
}

sub mem_unbank {
    $cpu->memory()->unbank(address => 0x4000 * $_[0]);
}

sub io_wr_stdout {
    print chr(shift);
}

sub hw_start_clock {
    $clock++;
}

END {
    # ReadMode 'normal';
    ReadMode 'restore';
}
