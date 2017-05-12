#!./perl
#
# basic.t - tests for getopt() method of AppConfig::Std
#
# the tests all use getscript.pl
#

my @expected;
my $e = '';
my $args = '';
my $output;

while (<DATA>)
{
    if (/^ARGS:(.*)$/) {
        $args = $1;
    }
    elsif (/^####$/) {
        push(@expected, [$args, $e]);
        $args = '';
        $e = '';
    }
    else {
        $e .= $_;
    }
}

print "1..", int(@expected), "\n";


for ($i = 1; $i <= int(@expected); ++$i)
{
    $args = $expected[$i-1]->[0];
    $output = `$^X -Iblib/lib t/getscript.pl $args 2>&1`;
    if ($output eq $expected[$i-1]->[1]) {
        print "ok $i\n";
    }
    else {
        print STDERR "OUTPUT:\n$output\nEXPECTED:\n", $expected[$i-1]->[1], "\n";
        print "not ok $i\n";
    }
}

exit 0;

__DATA__
ARGS:
Start of getscript.pl [AppConfig::Std 1.10]
End of getscript.pl
####
ARGS: -version
Start of getscript.pl [AppConfig::Std 1.10]
1.0
####
ARGS: -verbose
Start of getscript.pl [AppConfig::Std 1.10]
Verbose output enabled
End of getscript.pl
####
ARGS: -debug
Start of getscript.pl [AppConfig::Std 1.10]
Debug output enabled
End of getscript.pl
####
ARGS: -verbose -debug
Start of getscript.pl [AppConfig::Std 1.10]
Verbose output enabled
Debug output enabled
End of getscript.pl
####
ARGS: -foobar
Start of getscript.pl [AppConfig::Std 1.10]
Foobar flag ON
End of getscript.pl
####
ARGS: -foobar -verbose -debug
Start of getscript.pl [AppConfig::Std 1.10]
Verbose output enabled
Debug output enabled
Foobar flag ON
End of getscript.pl
####
ARGS: -color red
Start of getscript.pl [AppConfig::Std 1.10]
A color of red was given
End of getscript.pl
####
ARGS: -color
Start of getscript.pl [AppConfig::Std 1.10]
Option color requires an argument
End of getscript.pl
####
ARGS: -color blue -foobar -verbose -debug
Start of getscript.pl [AppConfig::Std 1.10]
Verbose output enabled
Debug output enabled
Foobar flag ON
A color of blue was given
End of getscript.pl
####
ARGS: -country
Start of getscript.pl [AppConfig::Std 1.10]
Option country requires an argument
End of getscript.pl
####
ARGS: -country Sweden
Start of getscript.pl [AppConfig::Std 1.10]
The country was set to Sweden.
End of getscript.pl
####
ARGS: -help
Start of getscript.pl [AppConfig::Std 1.10]
Usage:
      getscript.pl [ -version | -debug | -verbose | -doc | -help ]
                    [ -color C | -country C | -foobar ]

Options:
    -color C
        Provide a color.

    -country C
        Specify a country.

    -foobar
        Turn on the foobar flag.

    -doc
        Display the full documentation for getscript.pl.

    -verbose or -v
        Display verbose information as getscript.pl runs.

    -version
        Display the version of getscript.pl.

    -debug
        Display debugging information as getscript.pl runs.

####
