#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Data::Iterator::SlidingWindow;
use Data::Dumper;

open my $fh, '<', 'sample.txt';

my $iter = iterator 3 => sub{
    my $next = <$fh>;
    return $next;
};

my @trigrams;
while(<$iter>){
    push @trigrams, $_;
}

close $fh;

print Dumper(\@trigrams);

__END__
