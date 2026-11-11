use 5.018;
use strict;
use warnings;
use File::Basename   qw(dirname);
use File::Temp       qw(tempfile);
use Text::ParseWords qw(shellwords);

my $command= shift @ARGV or die "Usage: $0 perltidy-command files...\n";
my @formatter= shellwords($command);
for my $file (@ARGV) {
    open my $input, '<:raw', $file or die "Cannot read $file: $!";
    my $original= do { local $/; <$input> };
    close $input or die "Cannot close $file: $!";
    open my $pipe, '-|', @formatter, '-pro=.perltidyrc', '-st', $file
        or die "Cannot run perltidy: $!";
    binmode $pipe;
    my $formatted= do { local $/; <$pipe> };
    close $pipe or die "Perltidy failed for $file (status $?)\n";
    $original  //= '';
    $formatted //= '';
    next if $original eq $formatted;

    # Unchanged inputs keep their timestamps, especially Makefile.PL.
    my ($output, $temporary)=
        tempfile('.perltidy-XXXXXX', DIR => dirname($file), UNLINK => 1);
    binmode $output;
    print {$output} $formatted or die "Cannot write $temporary: $!";
    close $output              or die "Cannot close $temporary: $!";
    my $mode= (stat $file)[2] & 07777;
    chmod $mode, $temporary or die "Cannot set permissions on $temporary: $!";
    rename $temporary, $file or die "Cannot replace $file: $!";
}
