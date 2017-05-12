#!/opt/perl

use strict;
use warnings;

use lib qw(/opt/mod_perl);
use lib qw(/opt/mod_perl/lib);
use lib qw(/opt/Apache2);
use lib qw(/opt/Apache2/FileHash);

use Apache2::FileHash;
use Apache2::FileHash::PUT;
use Apache2::FileHash::GET;

use MIME::Types;

my @array = ();
foreach my $dir (@INC) {
    my $file = "$dir/$Apache2::FileHash::ConfigFile";
    eval {
        @array = &YAML::Tiny::LoadFile($file) or die("LoadFile($YAML::Tiny::errstr)");
    };
    unless ($@) {
        last;
    }
}

$Apache2::FileHash::Config = \@array;

BEGIN { MIME::Types->new() };

1;
