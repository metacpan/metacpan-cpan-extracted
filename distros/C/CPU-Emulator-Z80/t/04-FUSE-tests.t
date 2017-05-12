# $Id: 04-FUSE-tests.t,v 1.22 2008/03/08 14:41:55 drhyde Exp $
# FUSE tester is at http://fuse-emulator.svn.sourceforge.net/viewvc/fuse-emulator/trunk/fuse/z80/coretest.c?revision=3414&view=markup

use strict;
$^W = 1;

my %ARGV = map { $_ => 1 } @ARGV;
opendir(my $dir, 't/fuse-tests') || die("Can't read t/fuse-tests/\n");
my @tests = grep { $ARGV{"$_.in.yml"} || !keys(%ARGV) }
            map { s/\.in\.yml$//; "t/fuse-tests/$_"; }
            grep { -f "t/fuse-tests/$_" && /\.in\.yml$/ }
            grep { $_ !~ /^(
                db|               # IO instrs, tested elsewhere
                d3|               # FIXME really should use FUSE
                ed(               # tests for these too
                    [4567][0189]|
                    [AB][23AB]
                )|
                ddfd|fddd         # magic instrs, tested elsewhere
            )/ix } readdir($dir);
closedir($dir);

eval 'use Test::More tests => scalar(@tests);';

use CPU::Emulator::Z80;
use YAML::Tiny;

my(%testinstrs, %testnames) = ();
my $fh;
open($fh, 't/fuse-tests/testinstrs') && do {
    foreach(<$fh>) {
        chomp;
        my($name, $instrs) = split(/;/, $_);
        $testinstrs{$name} = $instrs;
    }
    close($fh);
};
open($fh, 't/fuse-tests/testnames') && do {
    foreach(<$fh>) {
        chomp;
        my($opcodes, $desc) = split(/;/, $_);
        $opcodes =~ s/[^0-9a-f]//gi;
        $testnames{lc($opcodes)} = $desc;
    }
    close($fh);
};

foreach my $yamlfile (@tests) {
    my $y = YAML::Tiny->read("$yamlfile.in.yml");
    my $cpu = CPU::Emulator::Z80->new(
        memory => CPU::Emulator::Memory->new(
            bytes => "\xDE\xAD\xBE\xEF" x (65536 / 4)
        )
    );
    foreach my $r (keys %{$y->[0]->{registers}}) {
        $cpu->register($r)->set($y->[0]->{registers}->{$r});
    }
    foreach my $addr (keys %{$y->[0]->{mem}}) {
        foreach(@{$y->[0]->{mem}->{$addr}}) {
            $cpu->memory()->poke($addr, $_);
            $addr++;
        }
    }
    $cpu->{iff1} = $y->[0]->{IFF1};
    $cpu->{iff2} = $y->[0]->{IFF2};

    my $beforememory = $cpu->memory()->{contents}; # FIXME - internals
    my $beforeregs = $cpu->format_registers();
    $cpu->run($testinstrs{$y->[0]->{name}} || 1); # execute this many instructions

    $y = YAML::Tiny->read("$yamlfile.expected.yml");
    my $errors = "";
    foreach my $r (keys %{$y->[0]->{registers}}) {
        if($cpu->register($r)->get() != $y->[0]->{registers}->{$r}) {
            $errors .=
              "# Register $r differs.".
              (($r eq 'AF') ? '        SZ5H3PNC' : '')."\n".
              "#   should be ".sprintf('0x%04X', $y->[0]->{registers}->{$r}).
                  (($r eq 'AF') ? sprintf(" flags: 0b%08b\n", $y->[0]->{registers}->{$r} & 0xFF) : "\n").
              "#   but is    ".sprintf('0x%04X', $cpu->register($r)->get()).
                  (($r eq 'AF') ? sprintf(" flags: 0b%08b\n", $cpu->register('F')->get()) : "\n");
        }
    }
    foreach my $addr (keys %{$y->[0]->{mem}}) {
        foreach(@{$y->[0]->{mem}->{$addr}}) {
            if($cpu->memory()->peek($addr) != $_) {
                $errors .=
                  "# Memory location ".sprintf('0x%04X', $addr)." differs\n".
                  "#   should be ".sprintf('0x%02X', $_)."\n".
                  "#   but is    ".sprintf('0x%02X', $cpu->memory()->peek($addr)).
                  (($cpu->memory()->peek($addr) == ord(substr($beforememory, $addr, 1))) ? ' (unchanged)' : '').
                  "\n";
            }
            $addr++;
        }
    }
    $errors .=
        "# IFFs differ:\n".
        "#   should be IFF1 = ".$y->[0]->{IFF1}."  IFF2 = ".$y->[0]->{IFF2}."\n".
        "#   but are   IFF1 = ".$cpu->{iff1}."  IFF2 = ".$cpu->{iff2}."\n"
      if($y->[0]->{IFF1} != $cpu->{iff1} || $y->[0]->{IFF2} != $cpu->{iff2});

    if($errors) {
        $errors .= "#\n# started with\n".$beforeregs.
                   "#\n# finished with\n".$cpu->format_registers()
    }

    ok(!$errors, uc($y->[0]->{name}).": ".
        (do {
            $y->[0]->{name} =~ s/_.*//;
            exists($testnames{$y->[0]->{name}})
        } ? $testnames{$y->[0]->{name}} : '')
    );
    print $errors;
    last if($errors);
}
