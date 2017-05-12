#!/usr/bin/perl

my %flags = (
    '1.0.0' => '-htm',
    '1.1.0' => '-htm',
    '2.0.0' => '-tex',
    '2.1.0' => '-tex',
    '2.2.0' => '-tex',
    '2.3.0' => '-rst',
    '2.3.1' => '-rst',
    '2.4.0' => '-rst',
    '2.4.1' => '-rst',
    );
my $flags_default = '-rst';

my $dir = '..';
while (<$dir/OpenCV-*>) {
    next unless /OpenCV-(\d+\.\d+\.\d+)$/;
    my $version = $1;
    my $flags = $flags{$version} || $flags_default;
    print "./tools/ref2pl.pl $flags -d=full $_/ >./t/ref-$version.pm\n";
}
