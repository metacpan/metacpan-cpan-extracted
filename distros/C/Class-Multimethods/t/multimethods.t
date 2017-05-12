use 5.005;
use strict;

# SAMPLE HIERARCHY TO TEST...

	package Base1;
		sub new { bless {}, ref($_[0])||$_[0] }

	package Base2;
		sub new { bless {}, ref($_[0])||$_[0] }


	package Der1; @Der1::ISA = qw( Base1 );
	package Der2; @Der2::ISA = qw( Base1 );
	package Der3; @Der3::ISA = qw( Base2 );

	package DerDer1; @DerDer1::ISA = qw( Der1 );
	package DerDer2; @DerDer2::ISA = qw( Der2 );
	package DerDer3; @DerDer3::ISA = qw( Der3 );
	package DerDer4; @DerDer4::ISA = qw( Der3 );

# LOAD AND SHOOT...

	package main;

	BEGIN { $| = 1; print "1..350\n"; }
	END {print "not ok 1\n" unless $::loaded;}

	use Class::Multimethods;
	$::loaded = 1;
	print "ok 1\n";

# DEFINE SOME MULTIMETHODS ON THE ABOVE HIERARCHY...

	multimethod mm => ('Base1', 'Base2')   => sub { 1 };
	multimethod mm => ('Base1', 'Der3')    => sub { 2 };
	multimethod mm => ('Base1', 'DerDer3') => sub { 3 };
	multimethod mm => ('Der1',  'Base2')   => sub { 4 };

	multimethod mm => ('Base1', 'Base2', 'Base2') => sub { 11 };
	multimethod mm => ('Base1', 'Der3', 'Der3') => sub { 12 };


# RESET EXPECTATIONS FOR EVERY POSSIBLE COMBINATION...

	my @type1 = qw{Base1 Der1 Der2 DerDer1 DerDer2};
	my @type2 = qw{Base2 Der3 DerDer3 DerDer4};

	foreach my $type1 ( @type1, @type2 )
	{
		foreach my $type2 ( @type2, @type1 )
		{
			$::expect{$type1}{$type2} = 0;
		}
	}

# GIVEN THE ABOVE MULTIMETHODS, ONLY THESE TYPE COMBINATIONS SHOULD BE VIABLE...

	$::expect{Base1}{Base2}	    = 1;
	$::expect{Base1}{Der3}	    = 2;
	$::expect{Base1}{DerDer3}   = 3;
	$::expect{Base1}{DerDer4}   = 2;
	$::expect{Der1}{Base2}	    = 4;
	$::expect{Der1}{DerDer3}    = 3;
	$::expect{Der2}{Base2}	    = 1;
	$::expect{Der2}{Der3}	    = 2;
	$::expect{Der2}{DerDer3}    = 3;
	$::expect{Der2}{DerDer4}    = 2;
	$::expect{DerDer1}{Base2}   = 4;
	$::expect{DerDer1}{DerDer3} = 3;
	$::expect{DerDer2}{Base2}   = 1;
	$::expect{DerDer2}{Der3}    = 2;
	$::expect{DerDer2}{DerDer3} = 3;
	$::expect{DerDer2}{DerDer4} = 2;


# LOOP AND TEST EVERY COMBINATION (3 TIMES)...

	$::n = 1;
	for my $rep (1..3)
	{
		foreach my $type1 ( @type1, @type2 )
		{
			foreach my $type2 ( @type2, @type1 )
			{
				$::n++;
				try($type1,$type2, $::expect{$type1}{$type2}) 
					or print "not ";
				print "ok $::n\n"
			}
		}

# ON THE LAST TIME THROUGH, ADD A NEW CASE THAT CHANGES SOME EXPECTATIONS...

		if ($rep == 2)
		{
			multimethod mm => ('Der2', 'DerDer4') => sub { 5 };
			$::expect{Der2}{DerDer4}    = 5;
			$::expect{DerDer2}{DerDer4} = 5;
			# mm(new DerDer2, new DerDer4);
		}

	}

# TEST MULTIMETHODS ON NON-CLASS TYPES

	multimethod mm => ('Der2', 'ARRAY')  => sub { 6 };
	multimethod mm => ('Der2', 'Regexp') => sub { 7 };
	multimethod mm => ('Der2', '#')      => sub { 8 };
	multimethod mm => ('Der2', '$')      => sub { 9 };

	$::n++;
	eval { mm(new Der2, [1,2,3]) == 6 } or print "\n$@\n" and print "not ";
	print "ok $::n\n";

	$::n++;
	eval { mm(new Der2, qr/\w*/) == 7 } or print "\n$@\n" and print "not ";
	print "ok $::n\n";

	$::n++;
	eval { mm(new Der2, 3) == 8 } or print "\n$@\n" and print "not ";
	print "ok $::n\n";

	$::n++;
	eval { mm(new Der2, "three") == 9 } or print "\n$@\n" and print "not ";
	print "ok $::n\n";

	$::n++;
	eval { mm(new Der2, "1a") == 9 } or print "\n$@\n" and print "not ";
	print "ok $::n\n";

	$::n++;
	eval { mm(new Base1, new Base2, new Base2) == 11 }
		or print "\n$@\n" and print "not ";
	print "ok $::n\n";

	$::n++;
	eval { mm(new DerDer1, new Der3, new Base2) == 11 }
		or print "\n$@\n" and print "not ";
	print "ok $::n\n";

	$::n++;
	eval { mm(new Base1, new Der3, new Der3) == 12 }
		or print "\n$@\n" and print "not ";
	print "ok $::n\n";

	$::n++;
	eval { mm(new Base1, new DerDer3, new DerDer3) == 12 }
		or print "\n$@\n" and print "not ";
	print "ok $::n\n";


# HERE'S THE SUBROUTINE THAT POWERS THE DOUBLE LOOP ABOVE

	sub try
	{
		# print "for: $_[0], $_[1]\n";
		my $obj1 = eval "new $_[0]";
		my $obj2 = eval "new $_[1]";
		my $err = '';
		my $res = 0;
		eval { $res = mm($obj1, $obj2) } or $err = $@;
		# print "\texpecting: $_[2], got: $res\n";
		return $res == $_[2] || do {print "\n$err\n"; 0};
	}


# TRY "CROSS-PACKAGE" MULTIMETHODS...

	package elsewhere;

	use Class::Multimethods;

	multimethod 'mm';

	$::n++;
	eval { mm(new Der2, 1) == 8 } or print "\n$@\n" and print "not ";
	print "ok $::n\n";

	multimethod mm => ('Der2', 'HASH') => sub { 10 };

	$::n++;
	eval { mm(new Der2, {a=>1}) == 10 } or print "\n$@\n" and print "not ";
	print "ok $::n\n";


# TEST ALTERNATE NAME INTRODUCING SYNTAX...

	package otherwhere;

	use Class::Multimethods 'mm';

	$::n++;
	eval { mm(new Der2, 1) == 8 } or print "\n$@\n" and print "not ";
	print "ok $::n\n";


# TRY MULTIMETHODS AS CLASS METHODS...

	package OtherClass;

	use Class::Multimethods;


	multimethod new => ('$','#') => sub { bless { num=>$_[1] }, $_[0] };
	multimethod new => ('$','$') => sub { bless { str=>$_[1] }, $_[0] };

	multimethod set => ('OtherClass','#') => sub { $_[0]->{num} = $_[1] };
	multimethod set => ('OtherClass','$') => sub { $_[0]->{str} = $_[1] };

	sub hasvals
	{
		for (keys %{$_[1]})
		{
			return undef unless $_[0]->{$_} eq $_[1]->{$_};
		}
		return 1;
		return $_[0]
	}

	sub print
	{
		print "=====\n";
		print "num: $_[0]->{num}\n" if $_[0]->{num};
		print "str: $_[0]->{str}\n" if $_[0]->{str};
		print "=====\n";
	}


	package main;

	my $obj;

	$obj = new OtherClass (42);
	# $obj->print();
	$::n++;
	$obj->hasvals({num=>42}) or print "not ";
	print "ok $::n\n";

	$obj = new OtherClass ("cat");
	# $obj->print();
	$::n++;
	$obj->hasvals({str=>"cat"}) or print "not ";
	print "ok $::n\n";

	$obj->set("dog");
	# $obj->print();
	$::n++;
	$obj->hasvals({str=>"dog"}) or print "not ";
	print "ok $::n\n";

	$obj->set(99);
	# $obj->print();
	$::n++;
	$obj->hasvals({num=>99, str=>"dog"}) or print "not ";
	print "ok $::n\n";



# TEST INHERITANCE OF MULTIMETHOD CLASS METHODS...

	package SonOfOtherClass;

	@SonOfOtherClass::ISA = qw(OtherClass);

	use Class::Multimethods;
	multimethod set => ('OtherClass','ARRAY')
			=> sub { $_[0]->{nums} = $_[1] };

	sub print
	{
		print "=========\n";
		$_[0]->SUPER::print();
		print "nums: ", join(',', @{$_[0]->{nums}}), "\n"
			if $_[0]->{nums};
		print "=========\n";
	}

	package main;

	$obj = new SonOfOtherClass (42);
	# $obj->print();
	$::n++;
	$obj->hasvals({num=>42}) or print "not ";
	print "ok $::n\n";

	$obj = new SonOfOtherClass ("cat");
	# $obj->print();
	$::n++;
	$obj->hasvals({str=>"cat"}) or print "not ";
	print "ok $::n\n";

	$obj->set("dog");
	# $obj->print();
	$::n++;
	$obj->hasvals({str=>"dog"}) or print "not ";
	print "ok $::n\n";

	$obj->set(99);
	# $obj->print();
	$::n++;
	$obj->hasvals({num=>99, str=>"dog"}) or print "not ";
	print "ok $::n\n";

	my $arr = [1,2,3,4,5];
	$obj->set($arr);
	# $obj->print();
	$::n++;
	$obj->hasvals({num=>99, str=>"dog", nums=>"$arr"}) or print "not ";
	print "ok $::n\n";


# TEST WILDCARDS...

	multimethod wild => ('Base1', 'Base2') => sub { 1 };
	multimethod wild => ('Der1',  'Der3' ) => sub { 2 };
	multimethod wild => ('Base1', '*' )    => sub { 3 };
	multimethod wild => ('Base2', '*' )    => sub { 4 };
	multimethod wild => ('*',  'Der3' )    => sub { 5 };
	multimethod wild => ('*',  '*' )       => sub { 6 };

# RESET EXPECTATIONS FOR EVERY POSSIBLE COMBINATION...

	# CONSEQUENCES OF $::expect{'*'}{'*'} = 6;
	foreach my $type1 ( @type1, @type2 )
	{
		foreach my $type2 ( @type2, @type1 )
		{
			$::expect{$type1}{$type2} = 6;
		}
	}

	# CONSEQUENCES OF $::expect{Base1}{Base2} = 1;
	foreach my $type1 ( @type1 )
	{
		foreach my $type2 ( @type2 )
		{
			$::expect{$type1}{$type2} = 1;
		}
	}

	# CONSEQUENCES OF $::expect{Der1}{Der3} = 2;
	foreach my $type1 (qw( Der1 DerDer1 ))
	{
		foreach my $type2 (qw( Der3 DerDer3 DerDer4 ))
		{
			$::expect{$type1}{$type2} = 2;
		}
	}

	# CONSEQUENCES OF $::expect{Base1}{'*'} = 3;
	foreach my $type1 ( @type1 )
	{
		foreach my $type2 ( @type1, @type2 )
		{
			$::expect{$type1}{$type2} = 3 
				if $::expect{$type1}{$type2} == 6 ;
		}
	}

	# CONSEQUENCES OF $::expect{Base2}{'*'} = 4;
	foreach my $type1 ( @type2 )
	{
		foreach my $type2 ( @type1, @type2 )
		{
			$::expect{$type1}{$type2} = 4 
				if $::expect{$type1}{$type2} == 6 ;
		}
	}

	# CONSEQUENCES OF $::expect{'*'}{Der3} = 5;
	foreach my $type1 ( @type1, @type2 )
	{
		foreach my $type2 (qw( Der3 DerDer3 DerDer4 ))
		{
			$::expect{$type1}{$type2} = 5 
				if $::expect{$type1}{$type2} == 6;
			$::expect{$type1}{$type2} = 0 
				if $::expect{$type1}{$type2} == 3
				|| $::expect{$type1}{$type2} == 4;
		}
	}

	# CASES WHICH AREN'T AMBIGOUS, DESPITE THE PREVIOUS RULE
	$::expect{Base2}{DerDer3}   = 4;	# 0 -> #4, 1 -> #5
	$::expect{Base2}{DerDer4}   = 4;	# 0 -> #4, 1 -> #5

	$::expect{Der3}{Der3}       = 5;	# 0 -> #5, 1 -> #4
	$::expect{DerDer3}{Der3}    = 5;	# 0 -> #5, 2 -> #4
	$::expect{DerDer4}{Der3}    = 5;	# 0 -> #5, 2 -> #4
	$::expect{DerDer3}{DerDer3} = 5;	# 1 -> #5, 2 -> #4
	$::expect{DerDer4}{DerDer3} = 5;	# 1 -> #5, 2 -> #4
	$::expect{DerDer3}{DerDer4} = 5;	# 1 -> #5, 2 -> #4
	$::expect{DerDer4}{DerDer4} = 5;	# 1 -> #5, 2 -> #4



# LOOP AND TEST EVERY COMBINATION...

	foreach my $type1 ( @type1, @type2 )
	{
		foreach my $type2 ( @type2, @type1 )
		{
			$::n++;
			wildtry($type1,$type2, $::expect{$type1}{$type2}) 
				or print "not ";
			print "ok $::n\n"
		}
	}

	sub wildtry
	{
		# print "for: $_[0], $_[1]\n";
		my $obj1 = eval "new $_[0]";
		my $obj2 = eval "new $_[1]";
		my $err = '';
		my $res = 0;
		eval { $res = wild($obj1, $obj2) } or $err = $@;
		# print "\texpecting: $_[2], got: $res\n";
		return $res == $_[2] || do {print "\n$err\n"; 0};
	}

# TEST "INHERITANCE" OF '#' FROM '$'

	multimethod val => ('$', '$') => sub { return '$$'; };
	multimethod val => ('$', '#') => sub { return '$#'; };
	multimethod val => ('#', '#') => sub { return '##'; };

	$::n++;
	val(1,2) eq '##' or print "not ";
	print "ok $::n\n";

	$::n++;
	val('a',1) eq '$#' or print "not ";
	print "ok $::n\n";

	$::n++;
	val('a','b') eq '$$' or print "not ";
	print "ok $::n\n";

	$::n++;
	val(1,'a') eq '$$' or print "not ";
	print "ok $::n\n";
