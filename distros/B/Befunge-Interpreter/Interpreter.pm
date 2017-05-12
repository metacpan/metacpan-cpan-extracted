package Befunge::Interpreter;
# Josh's Really Cool Befunge Interpreter For Common Everyday Use

# Let's lay down the law here with some variables

# This is the program counter initialization to +1, 0;


$VERSION = "0.01c";

sub new
{
    my $self = {};
    bless $self;
    return $self;
}

$pc{'x'} = 1;
$pc{'y'} = 0;

# Let's initialize the 'torus'.
@torus = " ";

# stack too
@stack = 0;

$MAX_TORUS_X = 79;
$MAX_TORUS_Y = 24;

# position
$tx, $ty = 0;

sub spush {
    my @ARGZ = shift @_;
    my $value = $ARGZ[0];
    my $length = $#stack++;
    $stack[$#stack] = $value;
}
   
sub spop {
    if ($#stack == -1)
    { 
       spush(0);
    }
    my $result = $stack[$#stack];
    $#stack--;
    return $result;
}

sub get_befunge {
    my $self = shift;
    my $FILENAME = shift;
    #print "got $FILENAME\n";
    open (BFPROG, $FILENAME) or die "program $FILENAME not found!";
    my $counter = 0;
    my $x, $y = 0;
    # To avoid weird errors, I'll let them input as much as they want
    # but then cruelly truncate it to 80x25.
    while (chomp($curline = <BFPROG>))
    { 
	$befunge[$counter++] = $curline;
    }
    $counter = 0;
    while ($y <= $MAX_TORUS_Y)
    {
	if ($x <= $MAX_TORUS_X)
	{
	    $torus[$x++][$y] = substr $befunge[$y], $x, 1;
	} else {
	    $y++;
	    $x = 0;
	}
    }
	  return $torus;
}

sub stack_add {
    my $value2 = spop();
    my $value1 = spop();
    my $result = $value1 + $value2;
    spush($result); 
}

sub stack_sub {
    my $value2 = spop();
    my $value1 = spop();
    my $result = $value1 - $value2;
    spush($result);
}

sub stack_mul {
    my $value2 = spop();
    my $value1 = spop();
    my $result = $value1 * $value2;
    spush($result);
}

sub stack_div {
    my $value2 = spop();
    my $value1 = spop();
    my $result = int($value1 / $value2);
    spush($result);
}

sub stack_mod {
    my $value2 = spop;
    my $value1 = spop;
    my $result = int($value1 % $value2);
    spush($result);
}

sub stack_not {
    my $value1 = spop();
    if ($value1 == 0)
    {
	spush(1);
    }
    else
    {
	spush(0);
    }
}

sub stack_gre {
    my $value2 = spop();
    my $value1 = spop();
    if ($value1 > $value2) 
    {
	spush(1);
    } else
    {
	spush(0);
    }
}

sub pc_rand {
    $randnum = int(rand(4));
  SWITCH2: {
      ($randnum == 0) && do { $pc{'x'} = 1; $pc{'y'} = 0; };
      ($randnum == 1) && do { $pc{'x'} = -1; $pc{'y'} = 0; };
      ($randnum == 2) && do { $pc{'x'} = 0; $pc{'y'} = 1; };
      ($randnum == 3) && do { $pc{'x'} = 0; $pc{'y'} = -1; };
  }
}

sub horiz_if {
    my $value1 = pop @stack;
    if ($value1 == 0) 
    {
	$pc{'x'} = 1;
	$pc{'y'} = 0;
    } else
    {
	$pc{'x'} = -1;
	$pc{'y'} = 0;
    }
}

sub vert_if {
    my $value1 = pop @stack;
    if ($value1 == 0)
    {
	$pc{'x'} = 0;
	$pc{'y'} = 1;
    }
    else
    {
	$pc{'x'} = 0;
	$pc{'y'} = -1;
    }
}

# safe incrementing of position x

sub siopx {
    my @argz = @_;
    my $curx = $argz[0];
    my $amt = $argz[1];
    $curx += $amt;
    if ($curx > $MAX_TORUS_X) 
    {
	$curx -= $MAX_TORUS_X + 1;
    }
    if ($curx < 0)
    {
	$curx += $MAX_TORUS_X;
    }
    return $curx;
}

# same thing for y

sub siopy {
    my @argz = @_;
    my $cury = $argz[0];
    my $amt = $argz[1];
    $cury += $amt;
    if ($cury > $MAX_TORUS_Y)
    {
	$cury -= $MAX_TORUS_Y + 1;
    }
    if ($cury < 0)
    {
	$cury += $MAX_TORUS_Y;
    }
    return $cury;
}
    

sub string_mode {
    $lookloc = "fnerk!";
    # Here's where we found the first quote
    my @argz = @_;
    $curlocx = $argz[0];
    $curlocy = $argz[1];
    $looklocx = siopx($curlocx, $pc{'x'});
    $looklocy = siopy($curlocy, $pc{'y'});
    while ($lookloc ne "\"")
    {
	$lookloc = $torus[$looklocx][$looklocy];
	if ($lookloc eq "\"")
	{
	    $tx = $looklocx;
	    $ty = $looklocy;
	} 
	else
        {
	    spush ord $lookloc;
	    $looklocx = siopx($looklocx, $pc{'x'});
	    $looklocy = siopy($looklocy, $pc{'y'});
	}
    }
    return $tx, $ty;
}

sub stack_dup {
    my $value1 = spop();
    spush($value1);
    spush($value1);
}

sub stack_swap {
    my $value2 = spop;
    my $value1 = spop;
    spush($value2);
    spush($value1);
}

sub stack_pop {
    spop();
}

sub output_int {
    my $value1 = int(spop());
    print $value1;
}

sub output_ASCII {
    my $value1 = spop();
    print chr($value1);
}

sub torus_get {
    my $y = spop();
    my $x = spop();
    spush($torus[$x][$y]);
}

sub torus_put {
    my $y = spop();
    my $x = spop();
    my $value = spop();
    $torus[$x][$y] = $value;
}


sub input_int {
    my $number = <STDIN>;
    spush($number);
}
	
sub input_ASCII {
    my $ascii = <STDIN>;
    $ascii = ord $ascii;
    spush($ascii);
}

sub push_num {
    spush($curchar);
}

sub process_befunge {
    $tx, $ty = 0;
    $skipnext = 0;
    $done = 0;
    while ($done == 0)
    {
	$curchar = $torus[$tx][$ty];
	# Ugly processing routine about to follow. I suggest most of you close
	# your eyes.
      SWITCH: {
	  if ($skipnext == 1)   { $curchar = ' '; $skipnext = 0; last; };
	  if ($curchar eq '>')  { $pc{'x'} = 1; $pc{'y'} = 0; last;};
	  if ($curchar eq '<')  { $pc{'x'} = -1; $pc{'y'} = 0; last;};
	  if ($curchar eq '^')  { $pc{'x'} = 0; $pc{'y'} = -1; last;};
	  if ($curchar eq 'v')  { $pc{'x'} = 0; $pc{'y'} = 1; last;};
	  if ($curchar eq '?')  { pc_rand(); last;};
	  if ($curchar eq '+')  { stack_add(); last;};
	  if ($curchar eq '-')  { stack_sub(); last;};
	  if ($curchar eq '/')  { stack_div(); last;};
	  if ($curchar eq "\*")  { stack_mul(); last;};
	  if ($curchar eq '%')  { stack_mod(); last;};
	  if ($curchar eq '!')  { stack_not(); last;};
	  if ($curchar eq "\'") { stack_gre(); last;}; 
	  if ($curchar eq '_')  { horiz_if(); last;};
	  if ($curchar eq '|')  { vert_if(); last;};
	  if ($curchar eq "\"") {
	      ($tx, $ty) = (string_mode($tx, $ty));
	      last;
	  }
	  if ($curchar eq ':')  { stack_dup(); last; };
	  if ($curchar eq "\\") { stack_swap(); last;};
	  if ($curchar eq "\$") { stack_pop(); last;};
	  if ($curchar eq '.')  { output_int(); last;};
	  if ($curchar eq ',')  { output_ASCII(); last; };
	  if ($curchar eq "\#") { $skipnext = 1; last; };
	  if ($curchar eq 'g')  { torus_get(); last;};
	  if ($curchar eq 'p')  { torus_put(); last;};
	  if ($curchar eq "\&") { input_int(); last;};
	  if ($curchar eq "\~") { input_ASCII(); last;};
	  if ($curchar eq "\@") { $done = 1; exit; };      
	  if ($curchar eq '0' ) { push_num(); last; };
	  if ($curchar eq '1' ) { push_num(); last; };
	  if ($curchar eq '2' ) { push_num(); last; };
	  if ($curchar eq '3' ) { push_num(); last; };
	  if ($curchar eq '4' ) { push_num(); last; };
	  if ($curchar eq '5' ) { push_num(); last; };
	  if ($curchar eq '6' ) { push_num(); last; };
	  if ($curchar eq '7' ) { push_num(); last; };
	  if ($curchar eq '8' ) { push_num(); last; };
	  if ($curchar eq '9' ) { push_num(); last; };
}
	$tx = siopx($tx, $pc{'x'});
	$ty = siopy($ty, $pc{'y'});
    }
}


1;
__END__

=head1 NAME

Befunge::Interpreter - Perl extension for interpreting befunge.


=head1 SYNOPSIS

        use Befunge::Interpreter;


=head1 DESCRIPTION

	Befunge::Interpreter is a fully Befunge-93 compliant 
        Befunge interpreter written in Perl.

	The usage is easy.

	use Befunge::Interpreter;
	$interpreter = new Befunge::Interpreter;
	$interpreter->get_befunge("hello.bf");
	$intrepreter->process_befunge();

	That is all, so far.


=head1 TO-DO

	I have to add lots of stuff, update to Funge-98 spec...


=head1 BUGS

	I don't know of any


=head1 CONTACT

	Any problems contact xjharding@newbedford.k12.ma.us


=cut
