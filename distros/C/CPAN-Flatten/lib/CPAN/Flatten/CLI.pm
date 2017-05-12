package CPAN::Flatten::CLI;
use strict;
use warnings;
use Getopt::Long qw(:config no_auto_abbrev no_ignore_case bundling);
use Pod::Usage 'pod2usage';
use CPAN::Flatten;

sub run {
    my $class = shift;
    local @ARGV = @_;
    GetOptions
        "h|help" => sub { pod2usage(-verbose => 1) },
        "version" => sub { print "CPAN::Flatten $CPAN::Flatten::VERSION\n"; exit },
        "v|verbose" => \my $verbose,
        "q|quiet" => \my $quiet,
        "target-perl=s" => \my $target_perl,
    or exit 1;
    my $package = shift @ARGV or die "Missing package argument, try `flatten --help`.\n";
    my $flatten = CPAN::Flatten->new(
        target_perl => $target_perl, quiet => $quiet, verbose => $verbose,
    );
    my ($distributions, $miss) = $flatten->flatten($package);
    print STDERR "\n" unless $quiet;
    if ($miss) {
        my $err = join ", ", @$miss;
        die "Failed to flatten requirements of $package\n";
    }
    $distributions->emit(\*STDOUT);
}

1;
