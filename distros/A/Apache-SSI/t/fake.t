# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..14\n"; }

# 1
END {print "not ok 1\n" unless $loaded;}
use Apache::SSI;
$loaded = 1;
&report_result(1);

# 2
&quick_test("<!--#echo var=TERM -->", $ENV{TERM});

# 3
&quick_test('<!--#perl sub="sub {$_[0]*2}" arg=5 pass_request=no -->', 10);

# 4
&quick_test('<!--#perl sub="sub {$_[0]*2+$_[1]}" arg=5 arg=7 pass_request=no-->', 17);

# 5
&quick_test('<!--#perl sub="sub {$_[0]*2+$_[1]}" args=5,7 pass_request=no-->', 17);

# 6
&quick_test('<!--#perl sub="sub {length \"1234\"}"-->', 4);

# 7: multiple lines
&quick_test( qq[<!--#perl\n sub="sub {return 6;\n}"-->], 6);

# 8
&quick_test( qq[<!--#if expr="!(0)" -->6<!--#else-->3<!--#endif-->], '6' );

# 9
&quick_test('<!--#perl sub="five"-->', 5);

# 10
&quick_test('<!--#perl sub="Test::five"-->', 5);

# 11
&quick_test('<!--#perl sub="Test"-->', 5);

# 12: nested conditionals
&format_quick_test(<<EOF, 12);
	     <!--#if expr=1 -->
	       1
  	       <!--#if expr=1 -->
                 2
	       <!--#endif-->
	     <!--#else-->
	       3
	     <!--#endif-->
EOF


# 13: nested conditionals
&format_quick_test(<<EOF, 13);
	     <!--#if expr=1 -->
	       1
  	       <!--#if expr=0 -->
                 2
	       <!--#else-->
                 3
	       <!--#endif-->
	     <!--#else-->
	       4
  	       <!--#if expr=1 -->
                 5
	       <!--#else-->
                 6
	       <!--#endif-->
	     <!--#endif-->
EOF

# 14: subclassing
{
  package Apache::tSSI;
  use vars qw(@ISA);
  @ISA = qw(Apache::SSI);
  sub ssi_bozo {
    my($self, $args) = @_;
    
    return 'blah blah';
  }
  
  my $tp = new Apache::tSSI('<!--#bozo -->');
  my $expected = 'blah blah';
  &::report_result(($tp->get_output() eq $expected),
		   $tp->get_output() . " eq '$expected'");
}

sub report_result {
	my $bad = !shift;
	$TEST_NUM++;
	print "not "x$bad, "ok $TEST_NUM\n";
	
	print $_[0] if ($bad and $ENV{TEST_VERBOSE});
}

sub format_quick_test {
  my $text = shift;
  $text =~ s/(^\s+)|\n//gm;
  &quick_test($text, shift());
}

sub quick_test {
  my $ssi = shift;
  my $expected = shift;
  my $p = new Apache::SSI($ssi);
  &report_result(($p->get_output() eq $expected),
		 $p->get_output() . " eq '$expected'\n");
}

sub five {5}
sub Test::five {5}
sub Test::handler {5}

