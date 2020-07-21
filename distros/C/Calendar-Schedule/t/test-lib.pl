#!/usr/bin/perl
# Testing library

sub my_mkdir {
  for my $d (@_) { next if -d $d;
    mkdir $d, 0700 or die "can't mkdir $d: $!" } }

sub getfile($) {
    my $f = shift;
    local *F;
    open(F, "<$f") or die "getfile:cannot open $f:$!";
    my @r = <F>;
    close(F);
    return wantarray ? @r : join ('', @r);
}

sub putfile($@) {
    my $f = shift;
    local *F;
    open(F, ">$f") or die "putfile:cannot open $f:$!";
    print F '' unless @_;
    while (@_) { print F shift(@_) }
    close(F);
}

1;
