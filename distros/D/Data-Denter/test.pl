use strict;
use diagnostics;
use Test;
use Data::Denter;
use Data::Dumper;
BEGIN { plan test => 10 }

sub DEBUG() { $ENV{DENTER_DEBUG} }

my $test = 0;
system "clear" if DEBUG;

#1
my $name = *name; # just to turn off "used once" warning.
my $foo1 = bless {count => \[qw(one two three four), \\undef]}, "Bugle::Boy";
Test_This(*name => $foo1);

#2
my $a = \\\\'pizza';
my $b = $$a;
Test_This([$a,$b]);

#3
my $c;
$c = \\$c;
Test_This($c);

#4
my $d = 42;
$d = [\$d];
Test_This($d);

#5
my ($e, $f);
$e = \$f;
$f = \$e;
Test_This([$e,$f]);

#6
Test_This (bless {[], {}});

#7
my $g = "foo\x04bar\x0d\x1f";
ok((Undent(Indent($g)))[0] eq $g);

#8
my $h = "foo\x04bar\x0d\nbaz\n\n";
ok((Undent(Indent($h)))[0] eq $h);

#9
my @i = (foo => 'one', bar => 'two');
{
    local $Data::Denter::HashMode = 1;
    my $j = Indent(@i);
    my @k = Undent($j);
    ok(@k == 4 and 
       ($j =~ tr/\n//) == 2 and
       join('', @i) eq join('', @k)
      );
}

#10
my $k = "A Simple String to Test Undent in Scalar Context";
ok(Undent(Indent($k)) eq $k);

sub Test_This {
    print "=" x 30 . " Test #" . ++$test . " " . "=" x 30 . "\n" 
      if DEBUG;
    my $dump1 = Dumper @_;
    print $dump1 if DEBUG;
    my $dent1 = Indent @_;
    print $dent1 if DEBUG;
    my $dump2 = Dumper(Undent $dent1);
    print $dump2 if DEBUG;
    ok($dump2 eq $dump1);
}
