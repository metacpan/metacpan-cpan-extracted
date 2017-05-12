#!/usr/bin/perl
# 
# This is an example showing how to use an input filter, 
# in this case to provide a way to access data from inside 
# the source file, using a Perl-like syntax. 
# 
# The syntax to invoque the value of another parameter is: 
#   ${level1::level2[1]::leaf}
# 
# Names are always absolute. The index is used to select 
# the corresponding element of the list of the branch. When 
# omitted, take up the first, [0].
# 
use strict;
use Config::Natural;

my $elements = new Config::Natural { filter => \&varsubst }, \*DATA;
print "helium is made of: ", $elements->param('helium'), $/;
print "a proton is made with these quarks: ", $elements->param('proton'), $/;

sub varsubst {
    my $self = shift;
    my $data = shift;
    
    $data =~ s<\$(\w\S+)>
      {
        my @path = split '::', $1;
        not $path[0] and shift @path;
        my($name,$index) = ( (shift @path) =~ /^([^[]+)(?:\[(\d+)\])?$/ );
        my $node = $self->param($name);
        if(ref $node) {
            $node = $node->[$index||0];
            for my $p (@path) {
                ($name,$index) = ( ($p) =~ /^([^[]+)(?:\[(\d+)\])?$/ );
                $node = $node->{$name};
                ref $node and $node = $node->[$index||0];
            }
        }
        $node
      }ge;
    return $data
}

__END__

hydrogen = proton
deuterium = proton neutron
tritium = $deuterium neutron
helium = $deuterium $deuterium

hadrons {
    proton = up up down
    neutron = up down down
}

proton = $hadrons::proton
