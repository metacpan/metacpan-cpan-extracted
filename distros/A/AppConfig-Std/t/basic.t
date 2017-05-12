#!./perl
#
# basic.t - basic tests for AppConfig::Std
#
# the tests all use testscript.pl
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


for ($i = 1; $i <= int(@expected); ++$i) {
    $args = $expected[$i-1]->[0];
    $output = `$^X -Iblib/lib t/testscript.pl $args 2>&1`;
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
Start of testscript.pl [AppConfig::Std 1.10]
End of testscript.pl
####
ARGS: -version
Start of testscript.pl [AppConfig::Std 1.10]
1.0
####
ARGS: -verbose
Start of testscript.pl [AppConfig::Std 1.10]
Verbose output enabled
End of testscript.pl
####
ARGS: -debug
Start of testscript.pl [AppConfig::Std 1.10]
Debug output enabled
End of testscript.pl
####
ARGS: -verbose -debug
Start of testscript.pl [AppConfig::Std 1.10]
Verbose output enabled
Debug output enabled
End of testscript.pl
####
ARGS: -foobar
Start of testscript.pl [AppConfig::Std 1.10]
Foobar flag ON
End of testscript.pl
####
ARGS: -foobar -verbose -debug
Start of testscript.pl [AppConfig::Std 1.10]
Verbose output enabled
Debug output enabled
Foobar flag ON
End of testscript.pl
####
ARGS: -color red
Start of testscript.pl [AppConfig::Std 1.10]
A color of red was given
End of testscript.pl
####
ARGS: -color
Start of testscript.pl [AppConfig::Std 1.10]
-color expects an argument
End of testscript.pl
####
ARGS: -color blue -foobar -verbose -debug
Start of testscript.pl [AppConfig::Std 1.10]
Verbose output enabled
Debug output enabled
Foobar flag ON
A color of blue was given
End of testscript.pl
####
ARGS: -country
Start of testscript.pl [AppConfig::Std 1.10]
-country expects an argument
End of testscript.pl
####
ARGS: -country Sweden
Start of testscript.pl [AppConfig::Std 1.10]
The country was set to Sweden.
End of testscript.pl
####
ARGS: -help
Start of testscript.pl [AppConfig::Std 1.10]
Usage:
      testscript.pl [ -version | -debug | -verbose | -doc | -help ]
                    [ -color C | -country C | -foobar ]

Options:
    -color C
        Provide a color.

    -country C
        Specify a country.

    -foobar
        Turn on the foobar flag.

    -doc
        Display the full documentation for testscript.pl.

    -verbose or -v
        Display verbose information as testscript.pl runs.

    -version
        Display the version of testscript.pl.

    -debug
        Display debugging information as testscript.pl runs.

####
