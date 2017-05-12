#!/usr/bin/perl
use strict;
use warnings;
use blib;
use Config::Merge();
use File::Spec();

eval        { require YAML::Syck; YAML::Syck->import(); 1 }
    or eval { require YAML;       YAML->import();       1 }
    or die "ERROR: "
    . "YAML::Syck or YAML needs to be installed to use this example\n\n";

my $debug = shift @ARGV;

foreach my $hostname qw(main dev1 dev2) {
    my $config = Config::Merge->new(
        path        => get_path('advanced'),
        debug       => $debug,

        # If matches 'xxx-(yyy)'
        is_local    => sub {
            my ($self,$name) = @_;
            return $name=~/- [(] .+ [)]/x ? 1 : 0;
        },

        # If local and matches 'xxx-(hostname)', return xxx
        load_as => sub {
            my ($self,$name,$is_local) = @_;
            if ($is_local) {
                if ($name=~/(.*) - [(] ($hostname) [)] /x) {
                    return  $1;
                }
                return undef;
            }
            return $name;
        }
    );
    print "\nCONFIG FOR $hostname:\n".Dump(scalar $config->C());
}

#===================================
sub get_path {
#===================================
    my ($vol,$path) = File::Spec->splitpath(
                   File::Spec->rel2abs($0)
            );
    $path = File::Spec->catdir(
        File::Spec->splitdir($path),
        ,@_
    );
    return File::Spec->catpath($vol,$path,'');
}
