#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use File::Spec::Functions;
use lib catfile($FindBin::Bin, '..', 'lib');
use App::MadEye;
use Getopt::Long;

my $conffname = 'config.yaml';
my $version = 0;
GetOptions(
    'config=s' => \$conffname,
    'version'  => \$version,
) or die "Usage: $0 -c config.yaml";

if ($version) {
    print "App::MadEye/$App::MadEye::VERSION\n";
    exit;
}

App::MadEye->new({config => $conffname})->run;

