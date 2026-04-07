#!/usr/bin/env perl

use 5.020;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use Config;
use Term::ANSIColor;
use Time::HiRes qw(sleep);

# It's nolstalgia folks

my $baud  = 9600;
my $speed = 1 / ($baud / 8);
if (scalar(@ARGV)) {
	$baud = $ARGV[0];
	if ($baud eq 'FULL') {
		$speed = 0;
	} else {
		$baud = int($baud);
		$speed = 1 / ($baud / 8);
	}
}

$| = 1;                                 # Turn off buffering
print "\e[2J\e[H\e[0m";

baud_print("WOPR Retro-Terminal.  Hayes modem 8/N/1 $baud bps\n");
delay(0.25);

baud_print('> ');
delay(0.50);

baud_print("ATDT BBS::Universal\n\n");
delay(1);

baud_print('Connected ... ');
delay(0.25);

baud_print("$baud baud...\n\n");
delay(0.5);

baud_print("Welcome to...\n\n");
delay(0.5);

baud_print('==============================================================================' . "\n");
baud_print(color('red'));
baud_print('        ____  ____ ____    _   _       _                          _' . "\n");
baud_print(color('yellow'));
baud_print('       | __ )| __ ) ___|  | | | |_ __ (_)_   _____ _ __ ___  __ _| |' . "\n");
baud_print(color('green'));
baud_print(q{       |  _ \|  _ \___ \  | | | | '_ \| \ \ / / _ \ '__/ __|/ _` | |} . "\n");
baud_print(color('magenta'));
baud_print('       | |_) | |_) |__) | | |_| | | | | |\ V /  __/ |  \__ \ (_| | |' . "\n");
baud_print(color('bright_blue'));
baud_print('       |____/|____/____/   \___/|_| |_|_| \_/ \___|_|  |___/\__,_|_|' . "\n\n");
baud_print(color('reset'));
baud_print("==============================================================================\n\n");

baud_print('TCP/IP ' . colored(['red'], 'R') . colored(['yellow'], 'e') . colored(['green'], 't') . colored(['magenta'], 'r') . colored(['bright_blue'], 'o') . " BBS software for your modern computer, written in Perl\n\n");

# Merge files because you tick me off Perl

baud_print("Creating a proper Universal.pm ... ");
merge();
baud_print(colored(['green'], "Done\n\n"));

WriteMakefile(
	NAME               => 'BBS::Universal',
	AUTHOR             => q{Richard Kelsch <rkelsch@cpan.org>},
	VERSION_FROM       => 'lib/BBS/Universal.pm',
	ABSTRACT           => 'Universal BBS Server',
	PL_FILES           => {},
	MIN_PERL_VERSION   => 5.020000,
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '7.20',
		'Time::HiRes'         => '1.9700',
		'Term::ANSIColor'     => '4.00',
		'Config'              => 0,
	},
	BUILD_REQUIRES => {
		'Test::More' => '0.44',
	},
	PREREQ_PRINT => 1,
	PREREQ_FATAL => 1,
	PREREQ_PM => {
		'Config'                 => '0',
		'English'                => '0',
		'Time::HiRes'            => '0',
		'Text::Format'           => '0.50',
		'Term::ANSIColor'        => '4.00',
		'Term::ANSIScreen'       => '1.50',
		'DateTime'               => '1.18',
		'File::Basename'         => '2.85',
		'Text::SimpleTable'      => '2.07',
		'DBI'                    => '1.50',
		'DBD::mysql'             => '4.00',
		'Term::ReadKey'          => '2.30',
		'IO::Socket'             => '1.20',
		'Debug::Easy'            => '0',
		'List::Util'             => '1.40',
		'Cache::Memcached::Fast' => '0.25',
		'XML::RSS::LibXML'       => '0.3105',
		'Number::Format'         => '0',
		'File::Path'             => '0',
		'File::Which'            => '0',
	},

	EXE_FILES => ['bin/bbs'],
	dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean     => { FILES    => 'BBS-Universal-* _build* *bak *old' },
	LICENSE   => 'artistic',
);

print chr(27) . '[0m', color('reset');
delay(0.50);

baud_print("\nProcess complete\n\n");
delay(0.50);

baud_print(color('on_blue') . color('bright_yellow') . ' INSTALLING' . ' ' x 69 . color('reset') . "\n");
baud_print("       make\n       make test\n" . color('red') . "[sudo]" . color('reset') . " make install\n");
baud_print(color('on_blue') . ' ' x 80 . color('reset') . "\n\n");

baud_print("Disconnecting...");
delay(0.50);

print "\n\n";

exit(0);

sub baud_print {
    my $text = shift;
    if ($speed == 0) {
        print $text;
    } else {
        my $l = length($text) - 1;
        foreach my $c (0 .. $l) {
            print substr($text, $c, 1);
            sleep $speed;
        }
    } ## end else [ if ($speed eq '57600') ]
} ## end sub baud_print

sub merge {    # Perl sometimes is a pain in the ...
    my @dir;
    opendir(my $DIR, 'lib/BBS/Universal/');
    chomp(@dir = readdir($DIR));
    closedir($DIR);

    my $master = slurp_file('src/Universal.pm');
    foreach my $file (sort(@dir)) {
        next if ($file !~ /\.pm$/ || $file =~ /^\./);
        my $shortfile = "$file";
        $shortfile =~ s/\.pm//;
        $shortfile = uc($shortfile) . '_VERSION';
        open(my $FILE, '<', "lib/BBS/Universal/$file");
        chomp(my @lines = <$FILE>);
        close($FILE);
        my $text = '';

        foreach my $line (@lines) {
            $line =~ s/^1\;//;
            $line =~ s/^package/\# package/;
            if ($line =~ /^BEGIN/) {
                $line   =~ s/BEGIN \{ //;
                $line   =~ s/ \}//;
                $line   =~ s/\$VERSION/\$$shortfile/;
                $master =~ s/(\# VERSIONS \#)/    $line\n$1/s;
            } else {
                $text .= "$line\n";
            }
        } ## end foreach my $line (@lines)
        $master =~ s/\# MANUAL IMPORT HERE #/$text \n\n\# MANUAL IMPORT HERE \#/;

    } ## end foreach my $file (sort(@dir...))
    $master =~ s/\# (VERSIONS|MANUAL IMPORT HERE) \#\n//s;
    while ($master =~ /\n\n\n+/s) {
        $master =~ s/\n\n\n+/\n\n/gs;
    }
    open(my $OUT, '>', 'lib/BBS/Universal.pm');
    print $OUT $master;
    close($OUT);
} ## end sub merge

sub delay {
	my $d = shift;
	sleep $d if ($speed > 0);
}

sub slurp_file {
    my $file = shift;
    return (
        do { local (@ARGV, $/) = $file; <> }
    );
} ## end sub slurp_file

__END__

