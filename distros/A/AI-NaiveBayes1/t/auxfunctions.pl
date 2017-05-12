#!/usr/bin/perl

sub compare_by_line {
    my $got = shift;
    my $file = shift;
    my $testfile = @_ ? shift @_ : '';
    my $testline = @_ ? shift @_ : '';
    my $expected = getfile($file);
    if ($got eq $expected) { pass; return }
    my $flag = '';
    while ($got ne '' or $expected ne '') {
	my $a=$got;      if ($a =~ /\s*\n/) { $a = $`; $got = $'; }
	my $b=$expected; if ($b =~ /\s*\n/) { $b = $`; $expected = $'; }
	if ($a ne $b) {
	    if ($flag eq '')
	    { print STDERR "\n$testfile:$testline: Failed comparison with $file!\n"; $flag = 1; }
	    print STDERR "     Got: $a\n".
                 	 "Expected: $b\n";
	}
    }
    if ($flag eq '') { pass } else { fail }
}

sub shorterdecimals {
    local $_ = shift;
    s/(\d{4}\.\d{10})\d+/$1/g;
    s/(\.\d{12})\d+/$1/g;
    s/---+/---/g;
    return $_;
}

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
