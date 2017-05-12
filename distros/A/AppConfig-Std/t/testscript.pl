#!./perl

use AppConfig::Std;
use vars qw ($VERSION);

$VERSION = '1.0';
$| = 1;

print "Start of testscript.pl [AppConfig::Std $AppConfig::Std::VERSION]\n";

my $config = AppConfig::Std->new();

$config->define('foobar', { ARGCOUNT => 0 });
$config->define('color',  { ARGCOUNT => 1 });
$config->define('country',); # don't give ARGCOUNT - defaults to 1

$config->args(\@ARGV);

print "Verbose output enabled\n" if $config->verbose;
print "Debug output enabled\n" if $config->debug;
print "Foobar flag ON\n" if $config->foobar;
print "A color of ", $config->color, " was given\n" if $config->color;
print "The country was set to ", $config->country, ".\n" if $config->country;

print "End of testscript.pl\n";

exit 0;

__END__

=head1 NAME

testscript.pl - test script for AppConfig::Std test-suite

=head1 SYNOPSIS

  testscript.pl [ -version | -debug | -verbose | -doc | -help ]
                [ -color C | -country C | -foobar ]

=head1 DESCRIPTION

testscript.pl is a simple perl script for testing AppConfig::Std.

=head1 OPTIONS

=over 4

=item B<-color C>

Provide a color.

=item B<-country C>

Specify a country.

=item B<-foobar>

Turn on the foobar flag.

=item B<-doc>

Display the full documentation for testscript.pl.

=item B<-verbose> or B<-v>

Display verbose information as testscript.pl runs.

=item B<-version>

Display the version of testscript.pl.

=item B<-debug>

Display debugging information as testscript.pl runs.

=back

=head1 VERSION

This doc describes testscript.pl 1.0.

=head1 AUTHOR

Neil Bowers <neil@bowers.com>

=cut

