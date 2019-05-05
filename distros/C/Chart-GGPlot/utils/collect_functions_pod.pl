#!/usr/bin/env perl

# This script generates pod from packages that supports ggplot_functions()

use 5.010;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Getopt::Long;
use Path::Tiny;
use Module::Load;

my ($namespace) = @ARGV;

my $func_package = "${namespace}::Functions";
load $func_package;

my @sub_ns = do {
    no strict 'refs';
    @{"${func_package}::sub_namespaces"};
};

my $s = "=tmpl funcs\n\n";

for my $name (@sub_ns) {
    my $package = "${namespace}::${name}";
    load $package;

    my $funcs = $package->ggplot_functions();
    

    for (@$funcs) {
        my $name = $_->{name};
        my $pod = $_->{pod};
        $pod =~ s/^[\n\r]*//;
        $pod =~ s/[\n\r]*$//;
        
        $s .= "=head2 $name\n\n$pod\n\n";
    }

}
$s .= "=tmpl";

say $s;

