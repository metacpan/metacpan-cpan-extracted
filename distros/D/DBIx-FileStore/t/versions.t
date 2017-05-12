#!perl -T

use strict;
use warnings;
use Test::More tests => 6;
use DBIx::FileStore;

my $version = $DBIx::FileStore::VERSION;
(my $version_regex = $version) =~ s{\.}{\\.};
my $date = scalar(localtime(time()));
my $year = $ENV{RELEASE_TESTING} ? substr($date, -4) : 2015;

in_file_ok( "dist.ini",              dist_ini_version => 'version\s*=.*' . $version_regex);
in_file_ok( "lib/DBIx/FileStore.pm", code_version     => 'VERSION\s*=.*' . $version_regex, 
                                     pod_version      => 'Version\s+'    . $version_regex );
in_file_ok( "Changes",               version          => "^$version_regex" );

in_file_ok( "lib/DBIx/FileStore.pm",                  copyright => "Copyright.*$year" );
in_file_ok( "lib/DBIx/FileStore/ConfigFile.pm",       copyright => "Copyright.*$year" );
in_file_ok( "lib/DBIx/FileStore/UtilityFunctions.pm", copyright => "Copyright.*$year" );

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


