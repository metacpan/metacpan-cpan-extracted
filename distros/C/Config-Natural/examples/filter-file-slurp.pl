#!/usr/bin/perl -W
# 
# This example shows you how to setup a filter that extends the syntax 
# of your configuration files. Here, we add a way to affect the content 
# of a file to a parameter. 
# 
use strict;
use Config::Natural;

my $config = new Config::Natural { filter => \&read_file }, \*DATA;
print "This example has ", length($config->param('myself')), " characters.\n", 
      "Here is the content of your /etc/hosts:\n", $config->param('hosts_file');

sub read_file {
    my $self = shift;
    if(index($_[0], '<')==0) {
        open(FILE, $_[0])
          or warn "Can't read '",substr($_[0],1),"'\n" and return '';
        local $/ = undef;
        return <FILE>
    }
    return @_
}

__END__

myself = <filter-file-slurp.pl

hosts_file = </etc/hosts

