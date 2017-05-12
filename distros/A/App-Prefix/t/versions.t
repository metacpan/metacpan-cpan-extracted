#!perl 

use strict;
use warnings;
use Test::More tests => 5;
#use App::Prefix;

# run bin/prefix to see what version it says it is
my $version_line = `$^X bin/prefix -version`;
chomp($version_line);
my ($name, $version) = split( ' ', $version_line );
(my $version_regex = $version) =~ s{\.}{\\.}; # turns 0.01 to 0\.01
diag( "Testing that versions are $version" );

my $date = scalar(localtime(time()));
my $actual_year = substr($date, -4);
my $year = 2013;
if ($year != $actual_year) {
    diag( "update next release: copyrights for year $year" );
}

in_file_ok( "dist.ini",              dist_ini_version => 'version\s*=.*' . $version_regex);

in_file_ok( "Changes",               version          => "^$version_regex" );

in_file_ok( "bin/prefix",            version          => 'our\s+\$VERSION.*=.*' . $version_regex);
in_file_ok( "bin/prefix",            copyright        => "Copyright.*$year" );

in_file_ok( "lib/App/Prefix.pm",     code_version     => 'VERSION\s*=.*' . $version_regex, 
                                     pod_version      => 'Version\s+'    . $version_regex );

sub in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %has;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$has{$desc}||=[]}, $.;
            }
        }
    }

    if (! %has) {
        fail("$filename doesn't match regex in (" . join(", ", values %regex) . ")" );
    } else {
        #diag "$_ appears on lines @{$has{$_}}" for keys %has;
        my $desc = join(", ", keys %has);
        pass("$filename matches regex(es) ($desc)" );
    }
}


