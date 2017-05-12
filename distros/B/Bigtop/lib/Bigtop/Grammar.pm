package Bigtop::Grammar;
use Parse::RecDescent;

{ my $ERRORS;


package Parse::RecDescent::Bigtop::Grammar;
use strict;
use vars qw($skip $AUTOLOAD  );
$skip = '\s*';

    my $backtick_line = 0;
    my $backtick_warning = '';
;


{
local $SIG{__WARN__} = sub {0};
# PRETEND TO BE IN Parse::RecDescent NAMESPACE
*Parse::RecDescent::Bigtop::Grammar::AUTOLOAD	= sub
{
	no strict 'refs';
	$AUTOLOAD =~ s/^Parse::RecDescent::Bigtop::Grammar/Parse::RecDescent/;
	goto &{$AUTOLOAD};
}
}

push @Parse::RecDescent::Bigtop::Grammar::ISA, 'Parse::RecDescent';
# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::method_type
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"method_type"};
	
	Parse::RecDescent::_trace(q{Trying rule: [method_type]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{method_type},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['is' IDENT]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{method_type},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{method_type});
		%item = (__RULE__ => q{method_type});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['is']},
					  Parse::RecDescent::_tracefirst($text),
					  q{method_type},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Ais//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{method_type},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{IDENT})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{method_type},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{method_type},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{method_type},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $item{IDENT} };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['is' IDENT]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{method_type},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{method_type},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{method_type},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{method_type},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{method_type},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::join_table_statement
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"join_table_statement"};
	
	Parse::RecDescent::_trace(q{Trying rule: [join_table_statement]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{join_table_statement},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['field' <commit> IDENT '\{' field_body '\}']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{join_table_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{join_table_statement});
		%item = (__RULE__ => q{join_table_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['field']},
					  Parse::RecDescent::_tracefirst($text),
					  q{join_table_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Afield//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		

		Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
					Parse::RecDescent::_tracefirst($text),
					  q{join_table_statement},
					  $tracelevel)
						if defined $::RD_TRACE; 
		$_tok = do { $commit = 1 };
		if (defined($_tok))
		{
			Parse::RecDescent::_trace(q{>>Matched directive<< (return value: [}
						. $_tok . q{])},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		else
		{
			Parse::RecDescent::_trace(q{<<Didn't match directive>>},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		
		last unless defined $_tok;
		push @item, $item{__DIRECTIVE1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{join_table_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{IDENT})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{join_table_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{join_table_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{join_table_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\{'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [field_body]},
				  Parse::RecDescent::_tracefirst($text),
				  q{join_table_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{field_body})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::field_body($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [field_body]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{join_table_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [field_body]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{join_table_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{field_body}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{join_table_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING3__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{join_table_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                           bless {
                               __IDENT__ => Bigtop::Parser->get_ident(),
                               __TYPE__  => 'field',
                               __NAME__  => $item{IDENT},
                               __BODY__  =>
                                    $item{field_body}{'field_statement(s?)'},
                           }, 'table_element_block'
                       };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['field' <commit> IDENT '\{' field_body '\}']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{join_table_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [keyword arg_list SEMI_COLON]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{join_table_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{join_table_statement});
		%item = (__RULE__ => q{join_table_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [keyword]},
				  Parse::RecDescent::_tracefirst($text),
				  q{join_table_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::keyword($thisparser,$text,$repeating,$_noactions,sub { return ['join_table'] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [keyword]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{join_table_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [keyword]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{join_table_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{keyword}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [arg_list]},
				  Parse::RecDescent::_tracefirst($text),
				  q{join_table_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{arg_list})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::arg_list($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [arg_list]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{join_table_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [arg_list]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{join_table_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg_list}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [SEMI_COLON]},
				  Parse::RecDescent::_tracefirst($text),
				  q{join_table_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{SEMI_COLON})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::SEMI_COLON($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [SEMI_COLON]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{join_table_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [SEMI_COLON]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{join_table_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{SEMI_COLON}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{join_table_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                      bless {
                          __KEYWORD__ => $item[1], __DEF__ => $item[2]
                      }, 'join_table_statement'
                  };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [keyword arg_list SEMI_COLON]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{join_table_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{join_table_statement},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{join_table_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{join_table_statement},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{join_table_statement},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::backend_body
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"backend_body"};
	
	Parse::RecDescent::_trace(q{Trying rule: [backend_body]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{backend_body},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [backend_statement]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{backend_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{backend_body});
		%item = (__RULE__ => q{backend_body});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying repeated subrule: [backend_statement]},
				  Parse::RecDescent::_tracefirst($text),
				  q{backend_body},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::backend_statement, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [backend_statement]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{backend_body},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [backend_statement]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{backend_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{backend_statement(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{backend_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
    my %config;
    foreach my $statement ( @{ $item{'backend_statement(s?)'} } ) {
        $config{ $statement->[0] } = $statement->[1];
    }
    $return = \%config;
};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [backend_statement]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{backend_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{backend_body},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{backend_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{backend_body},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{backend_body},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::arg
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"arg"};
	
	Parse::RecDescent::_trace(q{Trying rule: [arg]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{arg},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [arg_element '=>' arg_element]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{arg},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{arg});
		%item = (__RULE__ => q{arg});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [arg_element]},
				  Parse::RecDescent::_tracefirst($text),
				  q{arg},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::arg_element($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [arg_element]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{arg},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [arg_element]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{arg},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg_element}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['=>']},
					  Parse::RecDescent::_tracefirst($text),
					  q{arg},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'=>'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\=\>//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [arg_element]},
				  Parse::RecDescent::_tracefirst($text),
				  q{arg},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{arg_element})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::arg_element($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [arg_element]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{arg},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [arg_element]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{arg},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg_element}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{arg},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = { $item[1] => $item[3] } };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [arg_element '=>' arg_element]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{arg},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [arg_element]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{arg},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{arg});
		%item = (__RULE__ => q{arg});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [arg_element]},
				  Parse::RecDescent::_tracefirst($text),
				  q{arg},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::arg_element($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [arg_element]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{arg},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [arg_element]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{arg},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg_element}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{arg},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $item[1] };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [arg_element]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{arg},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{arg},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{arg},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{arg},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{arg},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::IDENT
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"IDENT"};
	
	Parse::RecDescent::_trace(q{Trying rule: [IDENT]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{IDENT},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/^\\w[\\w\\d_]*/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{IDENT},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{IDENT});
		%item = (__RULE__ => q{IDENT});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/^\\w[\\w\\d_]*/]}, Parse::RecDescent::_tracefirst($text),
					  q{IDENT},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:^\w[\w\d_]*)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{IDENT},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $item[1] };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/^\\w[\\w\\d_]*/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{IDENT},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{IDENT},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{IDENT},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{IDENT},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{IDENT},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::string
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"string"};
	
	Parse::RecDescent::_trace(q{Trying rule: [string]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{string},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		local $skip = defined($skip) ? $skip : $Parse::RecDescent::skip;
		Parse::RecDescent::_trace(q{Trying production: [BACKTICK <skip:''> text BACKTICK]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{string});
		%item = (__RULE__ => q{string});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [BACKTICK]},
				  Parse::RecDescent::_tracefirst($text),
				  q{string},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::BACKTICK($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [BACKTICK]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{string},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [BACKTICK]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{BACKTICK}} = $_tok;
		push @item, $_tok;
		
		}

		

		Parse::RecDescent::_trace(q{Trying directive: [<skip:''>]},
					Parse::RecDescent::_tracefirst($text),
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE; 
		$_tok = do { my $oldskip = $skip; $skip=''; $oldskip };
		if (defined($_tok))
		{
			Parse::RecDescent::_trace(q{>>Matched directive<< (return value: [}
						. $_tok . q{])},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		else
		{
			Parse::RecDescent::_trace(q{<<Didn't match directive>>},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		
		last unless defined $_tok;
		push @item, $item{__DIRECTIVE1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying subrule: [text]},
				  Parse::RecDescent::_tracefirst($text),
				  q{string},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{text})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::text($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [text]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{string},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [text]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{text}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [BACKTICK]},
				  Parse::RecDescent::_tracefirst($text),
				  q{string},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{BACKTICK})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::BACKTICK($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [BACKTICK]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{string},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [BACKTICK]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{BACKTICK}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $item{text} };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [BACKTICK <skip:''> text BACKTICK]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{string},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{string},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{string},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::app_config_statement
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"app_config_statement"};
	
	Parse::RecDescent::_trace(q{Trying rule: [app_config_statement]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{app_config_statement},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [IDENT arg_list SEMI_COLON]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{app_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{app_config_statement});
		%item = (__RULE__ => q{app_config_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{app_config_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{app_config_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{app_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [arg_list]},
				  Parse::RecDescent::_tracefirst($text),
				  q{app_config_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{arg_list})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::arg_list($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [arg_list]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{app_config_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [arg_list]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{app_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg_list}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [SEMI_COLON]},
				  Parse::RecDescent::_tracefirst($text),
				  q{app_config_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{SEMI_COLON})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::SEMI_COLON($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [SEMI_COLON]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{app_config_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [SEMI_COLON]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{app_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{SEMI_COLON}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{app_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                         bless {
                            __KEYWORD__ => $item{IDENT},
                            __ARGS__    => $item{arg_list}
                         }, 'app_config_statement'
                       };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [IDENT arg_list SEMI_COLON]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{app_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/[^\\\}]/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{app_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{app_config_statement});
		%item = (__RULE__ => q{app_config_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/[^\\\}]/]}, Parse::RecDescent::_tracefirst($text),
					  q{app_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:[^\}])//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{app_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                            my $message = "bad config statement, "
                                        . "possible extra semicolon";
                            if ( $backtick_warning ) {
                                $message .= " ($backtick_warning)";
                                $backtick_warning = '';
                            }
                            my $diag_text = $item[1] . $text;
                            Bigtop::Parser->fatal_error_two_lines(
                                $message, $diag_text, $thisline
                            );
                       };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/[^\\\}]/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{app_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{app_config_statement},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{app_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{app_config_statement},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{app_config_statement},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::arg_element
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"arg_element"};
	
	Parse::RecDescent::_trace(q{Trying rule: [arg_element]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{arg_element},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [module_ident]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{arg_element},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{arg_element});
		%item = (__RULE__ => q{arg_element});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [module_ident]},
				  Parse::RecDescent::_tracefirst($text),
				  q{arg_element},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::module_ident($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [module_ident]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{arg_element},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [module_ident]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{arg_element},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{module_ident}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{arg_element},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $item[1] };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [module_ident]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{arg_element},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [string]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{arg_element},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{arg_element});
		%item = (__RULE__ => q{arg_element});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [string]},
				  Parse::RecDescent::_tracefirst($text),
				  q{arg_element},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::string($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [string]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{arg_element},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [string]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{arg_element},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{string}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{arg_element},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $item[1] };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [string]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{arg_element},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: []},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{arg_element},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{arg_element});
		%item = (__RULE__ => q{arg_element});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{arg_element},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
    my $message = "I was expecting an argument or argument list";
    if ( $backtick_warning ) {
        $message .= " ($backtick_warning)";
        $backtick_warning = '';
    }
    Bigtop::Parser->fatal_error_two_lines(
        $message, $text, $thisline
    );
};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: []<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{arg_element},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{arg_element},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{arg_element},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{arg_element},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{arg_element},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::backend_statement
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"backend_statement"};
	
	Parse::RecDescent::_trace(q{Trying rule: [backend_statement]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{backend_statement},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [IDENT arg_element SEMI_COLON]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{backend_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{backend_statement});
		%item = (__RULE__ => q{backend_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{backend_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{backend_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{backend_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [arg_element]},
				  Parse::RecDescent::_tracefirst($text),
				  q{backend_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{arg_element})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::arg_element($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [arg_element]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{backend_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [arg_element]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{backend_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg_element}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [SEMI_COLON]},
				  Parse::RecDescent::_tracefirst($text),
				  q{backend_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{SEMI_COLON})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::SEMI_COLON($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [SEMI_COLON]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{backend_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [SEMI_COLON]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{backend_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{SEMI_COLON}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{backend_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
    $return = [ $item{IDENT} => $item{arg_element} ];
};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [IDENT arg_element SEMI_COLON]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{backend_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{backend_statement},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{backend_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{backend_statement},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{backend_statement},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::config_only
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"config_only"};
	
	Parse::RecDescent::_trace(q{Trying rule: [config_only]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{config_only},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [configuration anything]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{config_only},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{config_only});
		%item = (__RULE__ => q{config_only});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [configuration]},
				  Parse::RecDescent::_tracefirst($text),
				  q{config_only},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::configuration($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [configuration]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{config_only},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [configuration]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{config_only},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{configuration}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [anything]},
				  Parse::RecDescent::_tracefirst($text),
				  q{config_only},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{anything})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::anything($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [anything]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{config_only},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [anything]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{config_only},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{anything}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{config_only},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $item[1] };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [configuration anything]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{config_only},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{config_only},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{config_only},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{config_only},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{config_only},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::extra_sql_statement_def
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"extra_sql_statement_def"};
	
	Parse::RecDescent::_trace(q{Trying rule: [extra_sql_statement_def]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{extra_sql_statement_def},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [arg_list]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{extra_sql_statement_def},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{extra_sql_statement_def});
		%item = (__RULE__ => q{extra_sql_statement_def});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying repeated subrule: [arg_list]},
				  Parse::RecDescent::_tracefirst($text),
				  q{extra_sql_statement_def},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::arg_list, 0, 1, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [arg_list]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{extra_sql_statement_def},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [arg_list]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{extra_sql_statement_def},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg_list(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{extra_sql_statement_def},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                    bless {
                        __ARGS__ => $item[1]->[0]
                    }, 'extra_sql_statement_def'
                };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [arg_list]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{extra_sql_statement_def},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{extra_sql_statement_def},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{extra_sql_statement_def},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{extra_sql_statement_def},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{extra_sql_statement_def},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::field_statement_def
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"field_statement_def"};
	
	Parse::RecDescent::_trace(q{Trying rule: [field_statement_def]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{field_statement_def},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [arg_list]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{field_statement_def},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{field_statement_def});
		%item = (__RULE__ => q{field_statement_def});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying repeated subrule: [arg_list]},
				  Parse::RecDescent::_tracefirst($text),
				  q{field_statement_def},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::arg_list, 0, 1, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [arg_list]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{field_statement_def},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [arg_list]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{field_statement_def},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg_list(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{field_statement_def},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                        bless {
                            __ARGS__ => $item[1]->[0]
                        }, 'field_statement_def'
                      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [arg_list]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{field_statement_def},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{field_statement_def},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{field_statement_def},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{field_statement_def},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{field_statement_def},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::controller_statement
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"controller_statement"};
	
	Parse::RecDescent::_trace(q{Trying rule: [controller_statement]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{controller_statement},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['method' IDENT method_type '\{' method_body '\}']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{controller_statement});
		%item = (__RULE__ => q{controller_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['method']},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Amethod//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{IDENT})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [method_type]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{method_type})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::method_type($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [method_type]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [method_type]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{method_type}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\{'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [method_body]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{method_body})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::method_body($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [method_body]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [method_body]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{method_body}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING3__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                            bless {
                                __IDENT__ => Bigtop::Parser->get_ident(),
                                __NAME__  => $item{IDENT},
                                __BODY__  => $item{method_body},
                                __TYPE__  => $item{method_type},
                            }, 'controller_method'
                        };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['method' IDENT method_type '\{' method_body '\}']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['method' IDENT '\{']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{controller_statement});
		%item = (__RULE__ => q{controller_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['method']},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Amethod//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{IDENT})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\{'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                            my $diag_text = $item[1] . ' '
                                          . $item[2] . ' {'
                                          . $text;
                            Bigtop::Parser->fatal_error_two_lines(
                                'missing method type', $diag_text, $thisline
                            );
                     };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['method' IDENT '\{']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [CONFIG IDENT '\{' controller_config_statement '\}']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{controller_statement});
		%item = (__RULE__ => q{controller_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [CONFIG]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::CONFIG($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [CONFIG]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [CONFIG]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{CONFIG}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying repeated subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{IDENT})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::IDENT, 0, 1, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [IDENT]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\{'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: [controller_config_statement]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{controller_config_statement})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::controller_config_statement, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [controller_config_statement]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [controller_config_statement]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{controller_config_statement(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                   bless {
                       __IDENT__ => Bigtop::Parser->get_ident(),
                       __BODY__  => $item{'controller_config_statement(s?)'},
                       __TYPE__  => $item{'IDENT(?)'}[0],
                   }, 'controller_config_block'
                };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [CONFIG IDENT '\{' controller_config_statement '\}']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['literal' keyword string SEMI_COLON]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[3];
		$text = $_[1];
		my $_savetext;
		@item = (q{controller_statement});
		%item = (__RULE__ => q{controller_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['literal']},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Aliteral//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [keyword]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{keyword})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::keyword($thisparser,$text,$repeating,$_noactions,sub { return [ 'controller_literal' ] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [keyword]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [keyword]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{keyword}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [string]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{string})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::string($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [string]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [string]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{string}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [SEMI_COLON]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{SEMI_COLON})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::SEMI_COLON($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [SEMI_COLON]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [SEMI_COLON]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{SEMI_COLON}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                    bless {
                        __IDENT__   => Bigtop::Parser->get_ident(),
                        __BACKEND__ => $item{ keyword },
                        __BODY__    => $item{ string },
                    }, 'controller_literal_block'
           };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['literal' keyword string SEMI_COLON]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [keyword arg_list SEMI_COLON]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[4];
		$text = $_[1];
		my $_savetext;
		@item = (q{controller_statement});
		%item = (__RULE__ => q{controller_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [keyword]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::keyword($thisparser,$text,$repeating,$_noactions,sub { return ['controller'] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [keyword]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [keyword]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{keyword}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying repeated subrule: [arg_list]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{arg_list})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::arg_list, 0, 1, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [arg_list]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [arg_list]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg_list(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying subrule: [SEMI_COLON]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{SEMI_COLON})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::SEMI_COLON($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [SEMI_COLON]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [SEMI_COLON]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{SEMI_COLON}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                           bless {
                               __KEYWORD__ => $item{keyword},
                               __ARGS__    => $item{'arg_list(?)'}->[0],
                           }, 'controller_statement'
           };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [keyword arg_list SEMI_COLON]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{controller_statement},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{controller_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{controller_statement},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{controller_statement},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::configuration
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"configuration"};
	
	Parse::RecDescent::_trace(q{Trying rule: [configuration]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{configuration},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['config' '\{' config_body '\}']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{configuration},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{configuration});
		%item = (__RULE__ => q{configuration});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['config']},
					  Parse::RecDescent::_tracefirst($text),
					  q{configuration},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Aconfig//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{configuration},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\{'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [config_body]},
				  Parse::RecDescent::_tracefirst($text),
				  q{configuration},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{config_body})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::config_body($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [config_body]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{configuration},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [config_body]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{configuration},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{config_body}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{configuration},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING3__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{configuration},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $item{config_body} };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['config' '\{' config_body '\}']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{configuration},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{configuration},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{configuration},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{configuration},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{configuration},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::config_statement
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"config_statement"};
	
	Parse::RecDescent::_trace(q{Trying rule: [config_statement]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{config_statement},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [module_ident IDENT '\{' backend_body '\}']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{config_statement});
		%item = (__RULE__ => q{config_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [module_ident]},
				  Parse::RecDescent::_tracefirst($text),
				  q{config_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::module_ident($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [module_ident]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{config_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [module_ident]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{module_ident}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{config_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{IDENT})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{config_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\{'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [backend_body]},
				  Parse::RecDescent::_tracefirst($text),
				  q{config_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{backend_body})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::backend_body($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [backend_body]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{config_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [backend_body]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{backend_body}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
    my $backend_data = $item{backend_body};
    my $backend_type = $item{module_ident};
    my $backend_name = $item{IDENT};

    $backend_data->{__NAME__} = $backend_name;

    $return = [ $backend_type => $backend_data ];
};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [module_ident IDENT '\{' backend_body '\}']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [keyword arg_element SEMI_COLON]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{config_statement});
		%item = (__RULE__ => q{config_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [keyword]},
				  Parse::RecDescent::_tracefirst($text),
				  q{config_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::keyword($thisparser,$text,$repeating,$_noactions,sub { return [ 'config' ] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [keyword]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{config_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [keyword]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{keyword}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [arg_element]},
				  Parse::RecDescent::_tracefirst($text),
				  q{config_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{arg_element})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::arg_element($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [arg_element]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{config_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [arg_element]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg_element}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [SEMI_COLON]},
				  Parse::RecDescent::_tracefirst($text),
				  q{config_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{SEMI_COLON})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::SEMI_COLON($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [SEMI_COLON]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{config_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [SEMI_COLON]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{SEMI_COLON}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
    $return = [ $item{keyword} => $item{arg_element} ];
};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [keyword arg_element SEMI_COLON]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{config_statement},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{config_statement},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{config_statement},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::table_ident
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"table_ident"};
	
	Parse::RecDescent::_trace(q{Trying rule: [table_ident]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{table_ident},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [IDENT '.' IDENT]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{table_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{table_ident});
		%item = (__RULE__ => q{table_ident});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{table_ident},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{table_ident},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{table_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['.']},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'.'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\.//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{table_ident},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{IDENT})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{table_ident},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{table_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $item[1] . '.' . $item[3] };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [IDENT '.' IDENT]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [IDENT]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{table_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{table_ident});
		%item = (__RULE__ => q{table_ident});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{table_ident},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{table_ident},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{table_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $item[1] };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [IDENT]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{table_ident},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{table_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{table_ident},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{table_ident},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::table_body
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"table_body"};
	
	Parse::RecDescent::_trace(q{Trying rule: [table_body]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{table_body},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [table_element_block]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{table_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{table_body});
		%item = (__RULE__ => q{table_body});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying repeated subrule: [table_element_block]},
				  Parse::RecDescent::_tracefirst($text),
				  q{table_body},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::table_element_block, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [table_element_block]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{table_body},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [table_element_block]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{table_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{table_element_block(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless \%item, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [table_element_block]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{table_body},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{table_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{table_body},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{table_body},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::anything
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"anything"};
	
	Parse::RecDescent::_trace(q{Trying rule: [anything]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{anything},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/.*/s]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{anything},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{anything});
		%item = (__RULE__ => q{anything});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/.*/s]}, Parse::RecDescent::_tracefirst($text),
					  q{anything},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:.*)//s)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{anything},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless {__VALUE__=>$item[1]}, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [/.*/s]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{anything},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{anything},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{anything},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{anything},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{anything},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::app_statement
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"app_statement"};
	
	Parse::RecDescent::_trace(q{Trying rule: [app_statement]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{app_statement},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [keyword arg_list SEMI_COLON]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{app_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{app_statement});
		%item = (__RULE__ => q{app_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [keyword]},
				  Parse::RecDescent::_tracefirst($text),
				  q{app_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::keyword($thisparser,$text,$repeating,$_noactions,sub { return [ 'app' ] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [keyword]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{app_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [keyword]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{app_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{keyword}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying repeated subrule: [arg_list]},
				  Parse::RecDescent::_tracefirst($text),
				  q{app_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{arg_list})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::arg_list, 0, 1, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [arg_list]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{app_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [arg_list]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{app_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg_list(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying subrule: [SEMI_COLON]},
				  Parse::RecDescent::_tracefirst($text),
				  q{app_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{SEMI_COLON})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::SEMI_COLON($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [SEMI_COLON]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{app_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [SEMI_COLON]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{app_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{SEMI_COLON}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{app_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                           bless {
                               __KEYWORD__ => $item{keyword},
                               __ARGS__    => $item{'arg_list(?)'}->[0],
                           }, 'app_statement'
                };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [keyword arg_list SEMI_COLON]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{app_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{app_statement},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{app_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{app_statement},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{app_statement},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::BACKTICK
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"BACKTICK"};
	
	Parse::RecDescent::_trace(q{Trying rule: [BACKTICK]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{BACKTICK},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['`']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{BACKTICK},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{BACKTICK});
		%item = (__RULE__ => q{BACKTICK});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['`']},
					  Parse::RecDescent::_tracefirst($text),
					  q{BACKTICK},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   do { $_tok = "`"; 1 } and
		     substr($text,0,length($_tok)) eq $_tok and
		     do { substr($text,0,length($_tok)) = ""; 1; }
		)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $_tok . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{BACKTICK},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $backtick_line = $thisline; };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['`']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{BACKTICK},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{BACKTICK},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{BACKTICK},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{BACKTICK},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{BACKTICK},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::join_table_body
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"join_table_body"};
	
	Parse::RecDescent::_trace(q{Trying rule: [join_table_body]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{join_table_body},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [join_table_statement]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{join_table_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{join_table_body});
		%item = (__RULE__ => q{join_table_body});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying repeated subrule: [join_table_statement]},
				  Parse::RecDescent::_tracefirst($text),
				  q{join_table_body},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::join_table_statement, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [join_table_statement]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{join_table_body},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [join_table_statement]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{join_table_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{join_table_statement(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{join_table_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless \%item, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [join_table_statement]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{join_table_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{join_table_body},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{join_table_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{join_table_body},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{join_table_body},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::literal_block
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"literal_block"};
	
	Parse::RecDescent::_trace(q{Trying rule: [literal_block]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{literal_block},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['literal' keyword string SEMI_COLON]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{literal_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{literal_block});
		%item = (__RULE__ => q{literal_block});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['literal']},
					  Parse::RecDescent::_tracefirst($text),
					  q{literal_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Aliteral//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [keyword]},
				  Parse::RecDescent::_tracefirst($text),
				  q{literal_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{keyword})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::keyword($thisparser,$text,$repeating,$_noactions,sub { return [ 'app_literal' ] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [keyword]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{literal_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [keyword]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{literal_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{keyword}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [string]},
				  Parse::RecDescent::_tracefirst($text),
				  q{literal_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{string})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::string($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [string]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{literal_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [string]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{literal_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{string}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [SEMI_COLON]},
				  Parse::RecDescent::_tracefirst($text),
				  q{literal_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{SEMI_COLON})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::SEMI_COLON($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [SEMI_COLON]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{literal_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [SEMI_COLON]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{literal_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{SEMI_COLON}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{literal_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                    bless {
                        __IDENT__   => Bigtop::Parser->get_ident(),
                        __BACKEND__ => $item{ keyword },
                        __BODY__    => $item{ string },
                    }, 'literal_block'
                };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['literal' keyword string SEMI_COLON]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{literal_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{literal_block},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{literal_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{literal_block},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{literal_block},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::field_statement
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"field_statement"};
	
	Parse::RecDescent::_trace(q{Trying rule: [field_statement]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{field_statement},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [keyword field_statement_def SEMI_COLON]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{field_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{field_statement});
		%item = (__RULE__ => q{field_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [keyword]},
				  Parse::RecDescent::_tracefirst($text),
				  q{field_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::keyword($thisparser,$text,$repeating,$_noactions,sub { return ['field'] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [keyword]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{field_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [keyword]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{field_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{keyword}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [field_statement_def]},
				  Parse::RecDescent::_tracefirst($text),
				  q{field_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{field_statement_def})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::field_statement_def($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [field_statement_def]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{field_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [field_statement_def]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{field_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{field_statement_def}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [SEMI_COLON]},
				  Parse::RecDescent::_tracefirst($text),
				  q{field_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{SEMI_COLON})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::SEMI_COLON($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [SEMI_COLON]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{field_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [SEMI_COLON]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{field_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{SEMI_COLON}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{field_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                      bless {
                          __KEYWORD__ => $item[1], __DEF__ => $item[2]
                      }, 'field_statement'
                  };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [keyword field_statement_def SEMI_COLON]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{field_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{field_statement},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{field_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{field_statement},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{field_statement},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::method_statement
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"method_statement"};
	
	Parse::RecDescent::_trace(q{Trying rule: [method_statement]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{method_statement},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [keyword arg_list SEMI_COLON]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{method_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{method_statement});
		%item = (__RULE__ => q{method_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [keyword]},
				  Parse::RecDescent::_tracefirst($text),
				  q{method_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::keyword($thisparser,$text,$repeating,$_noactions,sub { return ['method'] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [keyword]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{method_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [keyword]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{method_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{keyword}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [arg_list]},
				  Parse::RecDescent::_tracefirst($text),
				  q{method_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{arg_list})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::arg_list($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [arg_list]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{method_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [arg_list]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{method_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg_list}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [SEMI_COLON]},
				  Parse::RecDescent::_tracefirst($text),
				  q{method_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{SEMI_COLON})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::SEMI_COLON($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [SEMI_COLON]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{method_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [SEMI_COLON]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{method_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{SEMI_COLON}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{method_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                        bless {
                            __KEYWORD__ => $item{keyword},
                            __ARGS__    => $item{arg_list}
                        }, 'method_statement'
                   };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [keyword arg_list SEMI_COLON]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{method_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{method_statement},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{method_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{method_statement},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{method_statement},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::controller_body
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"controller_body"};
	
	Parse::RecDescent::_trace(q{Trying rule: [controller_body]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{controller_body},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [controller_statement]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{controller_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{controller_body});
		%item = (__RULE__ => q{controller_body});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying repeated subrule: [controller_statement]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_body},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::controller_statement, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [controller_statement]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_body},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [controller_statement]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{controller_statement(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless \%item, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [controller_statement]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{controller_body},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{controller_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{controller_body},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{controller_body},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::keyword
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"keyword"};
	
	Parse::RecDescent::_trace(q{Trying rule: [keyword]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{keyword},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [IDENT]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{keyword},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{keyword});
		%item = (__RULE__ => q{keyword});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{keyword},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{keyword},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{keyword},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{keyword},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
    if ( Bigtop::Parser->is_valid_keyword( $arg[0], $item[1] ) ) {
        $return = $item[1];
    }
    else {
        my @expected = Bigtop::Parser->get_valid_keywords( $arg[0] );
        Bigtop::Parser->fatal_keyword_error(
            {
                bad_keyword   => $item[1],
                diag_text     => $text,
                input_linenum => $thisline,
                expected      => \@expected,
                type          => $arg[0],
            }
        );
    }
};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [IDENT]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{keyword},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{keyword},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{keyword},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{keyword},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{keyword},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::SEMI_COLON
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"SEMI_COLON"};
	
	Parse::RecDescent::_trace(q{Trying rule: [SEMI_COLON]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{SEMI_COLON},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [';']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{SEMI_COLON},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{SEMI_COLON});
		%item = (__RULE__ => q{SEMI_COLON});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [';']},
					  Parse::RecDescent::_tracefirst($text),
					  q{SEMI_COLON},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\;//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{SEMI_COLON},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless {__VALUE__=>$item[1]}, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [';']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{SEMI_COLON},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: []},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{SEMI_COLON},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{SEMI_COLON});
		%item = (__RULE__ => q{SEMI_COLON});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{SEMI_COLON},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
    my $message = "missing semi-colon";
    if ( $backtick_warning ) {
        $message .= " ($backtick_warning)";
        $backtick_warning = '';
    }
    Bigtop::Parser->fatal_error_two_lines(
        $message, $text, $thisline
    );
};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: []<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{SEMI_COLON},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{SEMI_COLON},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{SEMI_COLON},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{SEMI_COLON},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{SEMI_COLON},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::app_config_block
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"app_config_block"};
	
	Parse::RecDescent::_trace(q{Trying rule: [app_config_block]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{app_config_block},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [CONFIG IDENT '\{' app_config_statement '\}']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{app_config_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{app_config_block});
		%item = (__RULE__ => q{app_config_block});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [CONFIG]},
				  Parse::RecDescent::_tracefirst($text),
				  q{app_config_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::CONFIG($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [CONFIG]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{app_config_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [CONFIG]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{app_config_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{CONFIG}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying repeated subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{app_config_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{IDENT})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::IDENT, 0, 1, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{app_config_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [IDENT]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{app_config_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{app_config_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\{'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: [app_config_statement]},
				  Parse::RecDescent::_tracefirst($text),
				  q{app_config_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{app_config_statement})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::app_config_statement, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [app_config_statement]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{app_config_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [app_config_statement]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{app_config_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{app_config_statement(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{app_config_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{app_config_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                   bless {
                       __IDENT__ => Bigtop::Parser->get_ident(),
                       __BODY__ => $item{'app_config_statement(s?)'},
                       __TYPE__ => $item{'IDENT(?)'}[0],
                   }, 'app_config_block'
                };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [CONFIG IDENT '\{' app_config_statement '\}']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{app_config_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{app_config_block},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{app_config_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{app_config_block},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{app_config_block},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::controller_block
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"controller_block"};
	
	Parse::RecDescent::_trace(q{Trying rule: [controller_block]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{controller_block},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['controller' 'is' 'base_controller' '\{' controller_body '\}']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{controller_block});
		%item = (__RULE__ => q{controller_block});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['controller']},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Acontroller//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying terminal: ['is']},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'is'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Ais//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying terminal: ['base_controller']},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'base_controller'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Abase_controller//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING3__}=$&;
		

		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\{'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING4__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [controller_body]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{controller_body})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::controller_body($thisparser,$text,$repeating,$_noactions,sub { return [ 'base_controller' ] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [controller_body]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [controller_body]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{controller_body}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING5__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                        bless {
                            __IDENT__ => Bigtop::Parser->get_ident(),
                            __BODY__  => $item{controller_body}
                                              {'controller_statement(s?)'},
                            __NAME__  => 'base_controller',
                            __TYPE__  => 'base_controller',
                        }, 'controller_block'
                    };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['controller' 'is' 'base_controller' '\{' controller_body '\}']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['controller' module_ident is_type '\{' controller_body '\}']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{controller_block});
		%item = (__RULE__ => q{controller_block});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['controller']},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Acontroller//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [module_ident]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{module_ident})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::module_ident($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [module_ident]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [module_ident]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{module_ident}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying repeated subrule: [is_type]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{is_type})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::is_type, 0, 1, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [is_type]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [is_type]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{is_type(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\{'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [controller_body]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{controller_body})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::controller_body($thisparser,$text,$repeating,$_noactions,sub { return [ $item{module_ident} ] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [controller_body]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [controller_body]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{controller_body}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING3__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                        if ( defined $item{'is_type(?)'}[0]
                                and
                             $item{'is_type(?)'}[0] eq 'base_controller'
                        ) {
                            my $message = "base_controller cannot have an "
                                        . "explicit name";
                            my $diag_text = "controller $item{module_ident} "
                                          . "is base_controller";
                            Bigtop::Parser->fatal_error_two_lines(
                                $message, $diag_text, $thisline
                            );
                        }
                        bless {
                            __IDENT__ => Bigtop::Parser->get_ident(),
                            __NAME__  => $item{module_ident},
                            __BODY__  => $item{controller_body}
                                              {'controller_statement(s?)'},
                            __TYPE__        => $item{'is_type(?)'}[0],
                        }, 'controller_block'
                   };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['controller' module_ident is_type '\{' controller_body '\}']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{controller_block},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{controller_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{controller_block},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{controller_block},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::field_body
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"field_body"};
	
	Parse::RecDescent::_trace(q{Trying rule: [field_body]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{field_body},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [field_statement]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{field_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{field_body});
		%item = (__RULE__ => q{field_body});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying repeated subrule: [field_statement]},
				  Parse::RecDescent::_tracefirst($text),
				  q{field_body},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::field_statement, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [field_statement]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{field_body},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [field_statement]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{field_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{field_statement(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{field_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless \%item, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [field_statement]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{field_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{field_body},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{field_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{field_body},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{field_body},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::CONFIG
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"CONFIG"};
	
	Parse::RecDescent::_trace(q{Trying rule: [CONFIG]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{CONFIG},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['config']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{CONFIG},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{CONFIG});
		%item = (__RULE__ => q{CONFIG});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['config']},
					  Parse::RecDescent::_tracefirst($text),
					  q{CONFIG},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Aconfig//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{CONFIG},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless {__VALUE__=>$item[1]}, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['config']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{CONFIG},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['set_vars']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{CONFIG},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{CONFIG});
		%item = (__RULE__ => q{CONFIG});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['set_vars']},
					  Parse::RecDescent::_tracefirst($text),
					  q{CONFIG},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Aset_vars//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{CONFIG},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless {__VALUE__=>$item[1]}, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['set_vars']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{CONFIG},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{CONFIG},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{CONFIG},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{CONFIG},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{CONFIG},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::config_body
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"config_body"};
	
	Parse::RecDescent::_trace(q{Trying rule: [config_body]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{config_body},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [config_statement]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{config_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{config_body});
		%item = (__RULE__ => q{config_body});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying repeated subrule: [config_statement]},
				  Parse::RecDescent::_tracefirst($text),
				  q{config_body},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::config_statement, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [config_statement]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{config_body},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [config_statement]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{config_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{config_statement(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{config_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
    my %config;
    my %backend_lookup;
    my @statements;
    foreach my $statement ( @{ $item{'config_statement(s?)'} } ) {
        $config{ $statement->[0] } = $statement->[1];
        push @statements, [ $statement->[0], $statement->[1] ];

        if ( ref( $statement->[1] ) eq 'HASH' ) {
            push @{ $backend_lookup{ $statement->[0] } }, $statement->[1];
        }
    }
    $config{__STATEMENTS__} = \@statements;
    $config{__BACKENDS__}   = \%backend_lookup;
    $return = \%config;
};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [config_statement]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{config_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{config_body},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{config_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{config_body},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{config_body},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::extra_sql_statement
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"extra_sql_statement"};
	
	Parse::RecDescent::_trace(q{Trying rule: [extra_sql_statement]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{extra_sql_statement},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [keyword extra_sql_statement_def SEMI_COLON]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{extra_sql_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{extra_sql_statement});
		%item = (__RULE__ => q{extra_sql_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [keyword]},
				  Parse::RecDescent::_tracefirst($text),
				  q{extra_sql_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::keyword($thisparser,$text,$repeating,$_noactions,sub { return ['extra_sql'] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [keyword]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{extra_sql_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [keyword]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{extra_sql_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{keyword}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [extra_sql_statement_def]},
				  Parse::RecDescent::_tracefirst($text),
				  q{extra_sql_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{extra_sql_statement_def})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::extra_sql_statement_def($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [extra_sql_statement_def]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{extra_sql_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [extra_sql_statement_def]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{extra_sql_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{extra_sql_statement_def}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [SEMI_COLON]},
				  Parse::RecDescent::_tracefirst($text),
				  q{extra_sql_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{SEMI_COLON})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::SEMI_COLON($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [SEMI_COLON]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{extra_sql_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [SEMI_COLON]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{extra_sql_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{SEMI_COLON}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{extra_sql_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                        bless {
                            __KEYWORD__ => $item[1], __DEF__ => $item[2]
                        }, 'extra_sql_statement'
                      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [keyword extra_sql_statement_def SEMI_COLON]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{extra_sql_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{extra_sql_statement},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{extra_sql_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{extra_sql_statement},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{extra_sql_statement},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::app_body
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"app_body"};
	
	Parse::RecDescent::_trace(q{Trying rule: [app_body]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{app_body},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [block]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{app_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{app_body});
		%item = (__RULE__ => q{app_body});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying repeated subrule: [block]},
				  Parse::RecDescent::_tracefirst($text),
				  q{app_body},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::block, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [block]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{app_body},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [block]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{app_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{block(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{app_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless \%item, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [block]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{app_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{app_body},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{app_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{app_body},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{app_body},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::arg_list
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"arg_list"};
	
	Parse::RecDescent::_trace(q{Trying rule: [arg_list]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{arg_list},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [arg ',' arg_list]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{arg_list},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{arg_list});
		%item = (__RULE__ => q{arg_list});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [arg]},
				  Parse::RecDescent::_tracefirst($text),
				  q{arg_list},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::arg($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [arg]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{arg_list},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [arg]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{arg_list},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: [',']},
					  Parse::RecDescent::_tracefirst($text),
					  q{arg_list},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{','})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\,//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [arg_list]},
				  Parse::RecDescent::_tracefirst($text),
				  q{arg_list},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{arg_list})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::arg_list($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [arg_list]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{arg_list},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [arg_list]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{arg_list},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg_list}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{arg_list},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
               unshift @{ $item[3] }, $item[1];
               $return = $item[3];
           };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [arg ',' arg_list]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{arg_list},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [arg]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{arg_list},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{arg_list});
		%item = (__RULE__ => q{arg_list});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [arg]},
				  Parse::RecDescent::_tracefirst($text),
				  q{arg_list},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::arg($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [arg]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{arg_list},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [arg]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{arg_list},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{arg_list},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { bless [ $item[1] ], 'arg_list' };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [arg]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{arg_list},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{arg_list},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{arg_list},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{arg_list},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{arg_list},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::is_type
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"is_type"};
	
	Parse::RecDescent::_trace(q{Trying rule: [is_type]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{is_type},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['is' module_ident]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{is_type},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{is_type});
		%item = (__RULE__ => q{is_type});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['is']},
					  Parse::RecDescent::_tracefirst($text),
					  q{is_type},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Ais//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [module_ident]},
				  Parse::RecDescent::_tracefirst($text),
				  q{is_type},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{module_ident})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::module_ident($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [module_ident]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{is_type},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [module_ident]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{is_type},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{module_ident}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{is_type},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $item{module_ident} };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['is' module_ident]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{is_type},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{is_type},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{is_type},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{is_type},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{is_type},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::table_element_block
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"table_element_block"};
	
	Parse::RecDescent::_trace(q{Trying rule: [table_element_block]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{table_element_block},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['field' <commit> IDENT '\{' field_body '\}']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{table_element_block});
		%item = (__RULE__ => q{table_element_block});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['field']},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Afield//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		

		Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
					Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE; 
		$_tok = do { $commit = 1 };
		if (defined($_tok))
		{
			Parse::RecDescent::_trace(q{>>Matched directive<< (return value: [}
						. $_tok . q{])},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		else
		{
			Parse::RecDescent::_trace(q{<<Didn't match directive>>},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		
		last unless defined $_tok;
		push @item, $item{__DIRECTIVE1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{table_element_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{IDENT})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{table_element_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\{'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [field_body]},
				  Parse::RecDescent::_tracefirst($text),
				  q{table_element_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{field_body})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::field_body($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [field_body]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{table_element_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [field_body]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{field_body}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING3__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                           bless {
                               __IDENT__ => Bigtop::Parser->get_ident(),
                               __TYPE__  => 'field',
                               __NAME__  => $item{IDENT},
                               __BODY__  =>
                                    $item{field_body}{'field_statement(s?)'},
                           }, 'table_element_block'
                       };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['field' <commit> IDENT '\{' field_body '\}']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['extra_sql' <commit> IDENT '\{' extra_sql_body '\}']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{table_element_block});
		%item = (__RULE__ => q{table_element_block});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['extra_sql']},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Aextra_sql//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		

		Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
					Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE; 
		$_tok = do { $commit = 1 };
		if (defined($_tok))
		{
			Parse::RecDescent::_trace(q{>>Matched directive<< (return value: [}
						. $_tok . q{])},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		else
		{
			Parse::RecDescent::_trace(q{<<Didn't match directive>>},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		
		last unless defined $_tok;
		push @item, $item{__DIRECTIVE1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{table_element_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{IDENT})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{table_element_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\{'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [extra_sql_body]},
				  Parse::RecDescent::_tracefirst($text),
				  q{table_element_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{extra_sql_body})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::extra_sql_body($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [extra_sql_body]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{table_element_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [extra_sql_body]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{extra_sql_body}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING3__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                           bless {
                               __IDENT__ => Bigtop::Parser->get_ident(),
                               __TYPE__  => 'extra_sql',
                               __NAME__  => $item{IDENT},
                               __BODY__  =>
                                    $item{extra_sql_body}
                                         {'extra_sql_statement(s?)'},
                           }, 'extra_sql_block'
                       };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['extra_sql' <commit> IDENT '\{' extra_sql_body '\}']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [keyword arg_list SEMI_COLON]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{table_element_block});
		%item = (__RULE__ => q{table_element_block});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [keyword]},
				  Parse::RecDescent::_tracefirst($text),
				  q{table_element_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::keyword($thisparser,$text,$repeating,$_noactions,sub { return ['table'] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [keyword]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{table_element_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [keyword]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{keyword}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [arg_list]},
				  Parse::RecDescent::_tracefirst($text),
				  q{table_element_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{arg_list})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::arg_list($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [arg_list]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{table_element_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [arg_list]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg_list}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [SEMI_COLON]},
				  Parse::RecDescent::_tracefirst($text),
				  q{table_element_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{SEMI_COLON})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::SEMI_COLON($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [SEMI_COLON]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{table_element_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [SEMI_COLON]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{SEMI_COLON}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                           bless {
                               __TYPE__  => $item[1],
                               __ARGS__  => $item[2],
                               __BODY__  => $item[1],
                           }, 'table_element_block'
                       };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [keyword arg_list SEMI_COLON]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [<error...>]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[3];
		
		my $_savetext;
		@item = (q{table_element_block});
		%item = (__RULE__ => q{table_element_block});
		my $repcount = 0;


		

		Parse::RecDescent::_trace(q{Trying directive: [<error...>]},
					Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE; 
		$_tok = do { if (1) { do {
		my $rule = $item[0];
		   $rule =~ s/_/ /g;
		#WAS: Parse::RecDescent::_error("Invalid $rule: " . $expectation->message() ,$thisline);
		push @{$thisparser->{errors}}, ["Invalid $rule: " . $expectation->message() ,$thisline];
		} unless  $_noactions; undef } else {0} };
		if (defined($_tok))
		{
			Parse::RecDescent::_trace(q{>>Matched directive<< (return value: [}
						. $_tok . q{])},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		else
		{
			Parse::RecDescent::_trace(q{<<Didn't match directive>>},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		
		last unless defined $_tok;
		push @item, $item{__DIRECTIVE1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless \%item, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [<error...>]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{table_element_block},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{table_element_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{table_element_block},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{table_element_block},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::text
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"text"};
	
	Parse::RecDescent::_trace(q{Trying rule: [text]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{text},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/[^`]*/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{text},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{text});
		%item = (__RULE__ => q{text});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/[^`]*/]}, Parse::RecDescent::_tracefirst($text),
					  q{text},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:[^`]*)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{text},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
    my @lines = split /\n/, $item[1];
    if ( @lines > 1 ) {
        $backtick_warning
            = "possible run-away string beginning on line "
            . "$backtick_line.";
    }
    $item[1];
};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/[^`]*/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{text},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{text},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{text},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{text},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{text},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::sequence_statement
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"sequence_statement"};
	
	Parse::RecDescent::_trace(q{Trying rule: [sequence_statement]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{sequence_statement},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [IDENT arg_list SEMI_COLON]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{sequence_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{sequence_statement});
		%item = (__RULE__ => q{sequence_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{sequence_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{sequence_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{sequence_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [arg_list]},
				  Parse::RecDescent::_tracefirst($text),
				  q{sequence_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{arg_list})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::arg_list($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [arg_list]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{sequence_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [arg_list]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{sequence_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg_list}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [SEMI_COLON]},
				  Parse::RecDescent::_tracefirst($text),
				  q{sequence_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{SEMI_COLON})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::SEMI_COLON($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [SEMI_COLON]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{sequence_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [SEMI_COLON]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{sequence_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{SEMI_COLON}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{sequence_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
        bless {
            __NAME__ => $item[1], __ARGS__ => $item{arg_list}
        }, 'sequence_statement'
    };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [IDENT arg_list SEMI_COLON]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{sequence_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{sequence_statement},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{sequence_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{sequence_statement},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{sequence_statement},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::module_ident
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"module_ident"};
	
	Parse::RecDescent::_trace(q{Trying rule: [module_ident]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{module_ident},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [IDENT '::' module_ident]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{module_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{module_ident});
		%item = (__RULE__ => q{module_ident});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{module_ident},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{module_ident},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{module_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['::']},
					  Parse::RecDescent::_tracefirst($text),
					  q{module_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'::'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\:\://)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [module_ident]},
				  Parse::RecDescent::_tracefirst($text),
				  q{module_ident},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{module_ident})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::module_ident($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [module_ident]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{module_ident},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [module_ident]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{module_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{module_ident}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{module_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $item[1] . '::' . $item[3] };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [IDENT '::' module_ident]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{module_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [IDENT]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{module_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{module_ident});
		%item = (__RULE__ => q{module_ident});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{module_ident},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{module_ident},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{module_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{module_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $item[1] };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [IDENT]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{module_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{module_ident},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{module_ident},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{module_ident},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{module_ident},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::bigtop_file
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"bigtop_file"};
	
	Parse::RecDescent::_trace(q{Trying rule: [bigtop_file]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{bigtop_file},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [configuration application]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{bigtop_file},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{bigtop_file});
		%item = (__RULE__ => q{bigtop_file});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [configuration]},
				  Parse::RecDescent::_tracefirst($text),
				  q{bigtop_file},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::configuration($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [configuration]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{bigtop_file},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [configuration]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{bigtop_file},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{configuration}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [application]},
				  Parse::RecDescent::_tracefirst($text),
				  q{bigtop_file},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{application})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::application($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [application]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{bigtop_file},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [application]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{bigtop_file},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{application}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{bigtop_file},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless \%item, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [configuration application]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{bigtop_file},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{bigtop_file},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{bigtop_file},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{bigtop_file},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{bigtop_file},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::sequence_body
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"sequence_body"};
	
	Parse::RecDescent::_trace(q{Trying rule: [sequence_body]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{sequence_body},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [sequence_statement]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{sequence_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{sequence_body});
		%item = (__RULE__ => q{sequence_body});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying repeated subrule: [sequence_statement]},
				  Parse::RecDescent::_tracefirst($text),
				  q{sequence_body},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::sequence_statement, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [sequence_statement]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{sequence_body},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [sequence_statement]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{sequence_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{sequence_statement(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{sequence_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless \%item, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [sequence_statement]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{sequence_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{sequence_body},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{sequence_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{sequence_body},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{sequence_body},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::application
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"application"};
	
	Parse::RecDescent::_trace(q{Trying rule: [application]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{application},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['app' module_ident '\{' app_body '\}']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{application},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{application});
		%item = (__RULE__ => q{application});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['app']},
					  Parse::RecDescent::_tracefirst($text),
					  q{application},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Aapp//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [module_ident]},
				  Parse::RecDescent::_tracefirst($text),
				  q{application},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{module_ident})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::module_ident($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [module_ident]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{application},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [module_ident]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{application},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{module_ident}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{application},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\{'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [app_body]},
				  Parse::RecDescent::_tracefirst($text),
				  q{application},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{app_body})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::app_body($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [app_body]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{application},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [app_body]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{application},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{app_body}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{application},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING3__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{application},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                  my $retval = bless {
                      __NAME__ => $item{module_ident},
                      __BODY__ => $item{app_body},
                  }, 'application';

                  $retval->walk_postorder( 'set_parent' );

                  my $lookup_hash = $retval->walk_postorder(
                        'build_lookup_hash'
                  );

                  $retval->{lookup} = { @{ $lookup_hash } };

                  $retval;
              };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['app' module_ident '\{' app_body '\}']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{application},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [<error...>]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{application},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		
		my $_savetext;
		@item = (q{application});
		%item = (__RULE__ => q{application});
		my $repcount = 0;


		

		Parse::RecDescent::_trace(q{Trying directive: [<error...>]},
					Parse::RecDescent::_tracefirst($text),
					  q{application},
					  $tracelevel)
						if defined $::RD_TRACE; 
		$_tok = do { if (1) { do {
		my $rule = $item[0];
		   $rule =~ s/_/ /g;
		#WAS: Parse::RecDescent::_error("Invalid $rule: " . $expectation->message() ,$thisline);
		push @{$thisparser->{errors}}, ["Invalid $rule: " . $expectation->message() ,$thisline];
		} unless  $_noactions; undef } else {0} };
		if (defined($_tok))
		{
			Parse::RecDescent::_trace(q{>>Matched directive<< (return value: [}
						. $_tok . q{])},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		else
		{
			Parse::RecDescent::_trace(q{<<Didn't match directive>>},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		
		last unless defined $_tok;
		push @item, $item{__DIRECTIVE1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{application},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless \%item, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [<error...>]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{application},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{application},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{application},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{application},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{application},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::controller_config_statement
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"controller_config_statement"};
	
	Parse::RecDescent::_trace(q{Trying rule: [controller_config_statement]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{controller_config_statement},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [IDENT arg_list SEMI_COLON]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{controller_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{controller_config_statement});
		%item = (__RULE__ => q{controller_config_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_config_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_config_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [arg_list]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_config_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{arg_list})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::arg_list($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [arg_list]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_config_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [arg_list]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{arg_list}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [SEMI_COLON]},
				  Parse::RecDescent::_tracefirst($text),
				  q{controller_config_statement},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{SEMI_COLON})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::SEMI_COLON($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [SEMI_COLON]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{controller_config_statement},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [SEMI_COLON]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{SEMI_COLON}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                        bless {
                            __KEYWORD__ => $item{IDENT},
                            __ARGS__    => $item{arg_list}
                        }, 'controller_config_statement'
                    };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [IDENT arg_list SEMI_COLON]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/[^\\\}]/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{controller_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{controller_config_statement});
		%item = (__RULE__ => q{controller_config_statement});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/[^\\\}]/]}, Parse::RecDescent::_tracefirst($text),
					  q{controller_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:[^\}])//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                            my $message = "bad config statement, "
                                        . "possible extra semicolon";
                            if ( $backtick_warning ) {
                                $message .= " ($backtick_warning)";
                                $backtick_warning = '';
                            }
                            my $diag_text = $item[1] . $text;
                            Bigtop::Parser->fatal_error_two_lines(
                                $message, $diag_text, $thisline
                            );
                      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/[^\\\}]/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{controller_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{controller_config_statement},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{controller_config_statement},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{controller_config_statement},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{controller_config_statement},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::block
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"block"};
	
	Parse::RecDescent::_trace(q{Trying rule: [block]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{block},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [literal_block]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{block});
		%item = (__RULE__ => q{block});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [literal_block]},
				  Parse::RecDescent::_tracefirst($text),
				  q{block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::literal_block($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [literal_block]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [literal_block]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{literal_block}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless \%item, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [literal_block]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [controller_block]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{block});
		%item = (__RULE__ => q{block});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [controller_block]},
				  Parse::RecDescent::_tracefirst($text),
				  q{block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::controller_block($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [controller_block]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [controller_block]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{controller_block}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless \%item, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [controller_block]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [sql_block]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{block});
		%item = (__RULE__ => q{block});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [sql_block]},
				  Parse::RecDescent::_tracefirst($text),
				  q{block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::sql_block($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [sql_block]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [sql_block]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{sql_block}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless \%item, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [sql_block]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [app_config_block]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[3];
		$text = $_[1];
		my $_savetext;
		@item = (q{block});
		%item = (__RULE__ => q{block});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [app_config_block]},
				  Parse::RecDescent::_tracefirst($text),
				  q{block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::app_config_block($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [app_config_block]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [app_config_block]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{app_config_block}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless \%item, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [app_config_block]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [app_statement]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[4];
		$text = $_[1];
		my $_savetext;
		@item = (q{block});
		%item = (__RULE__ => q{block});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [app_statement]},
				  Parse::RecDescent::_tracefirst($text),
				  q{block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::app_statement($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [app_statement]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [app_statement]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{app_statement}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless \%item, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [app_statement]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{block},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{block},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{block},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::sql_block
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"sql_block"};
	
	Parse::RecDescent::_trace(q{Trying rule: [sql_block]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{sql_block},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['sequence' <commit> table_ident '\{' sequence_body '\}']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{sql_block});
		%item = (__RULE__ => q{sql_block});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['sequence']},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Asequence//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		

		Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
					Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE; 
		$_tok = do { $commit = 1 };
		if (defined($_tok))
		{
			Parse::RecDescent::_trace(q{>>Matched directive<< (return value: [}
						. $_tok . q{])},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		else
		{
			Parse::RecDescent::_trace(q{<<Didn't match directive>>},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		
		last unless defined $_tok;
		push @item, $item{__DIRECTIVE1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying subrule: [table_ident]},
				  Parse::RecDescent::_tracefirst($text),
				  q{sql_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{table_ident})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::table_ident($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [table_ident]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{sql_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [table_ident]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{table_ident}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\{'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [sequence_body]},
				  Parse::RecDescent::_tracefirst($text),
				  q{sql_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{sequence_body})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::sequence_body($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [sequence_body]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{sql_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [sequence_body]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{sequence_body}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING3__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                bless {
                            __IDENT__ => Bigtop::Parser->get_ident(),
                            __NAME__  => $item{table_ident},
                            __TYPE__  => 'sequences',
                            __BODY__  => $item{sequence_body}
                                              {'sequence_statement(s?)'},
                }, 'seq_block'
            };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['sequence' <commit> table_ident '\{' sequence_body '\}']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['table' <commit> table_ident '\{' table_body '\}']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{sql_block});
		%item = (__RULE__ => q{sql_block});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['table']},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Atable//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		

		Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
					Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE; 
		$_tok = do { $commit = 1 };
		if (defined($_tok))
		{
			Parse::RecDescent::_trace(q{>>Matched directive<< (return value: [}
						. $_tok . q{])},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		else
		{
			Parse::RecDescent::_trace(q{<<Didn't match directive>>},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		
		last unless defined $_tok;
		push @item, $item{__DIRECTIVE1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying subrule: [table_ident]},
				  Parse::RecDescent::_tracefirst($text),
				  q{sql_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{table_ident})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::table_ident($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [table_ident]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{sql_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [table_ident]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{table_ident}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\{'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [table_body]},
				  Parse::RecDescent::_tracefirst($text),
				  q{sql_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{table_body})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::table_body($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [table_body]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{sql_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [table_body]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{table_body}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING3__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                bless {
                            __IDENT__ => Bigtop::Parser->get_ident(),
                            __NAME__  => $item{table_ident},
                            __TYPE__  => 'tables',
                            __BODY__  => $item{table_body}
                                              {'table_element_block(s?)'},
                }, 'table_block'
            };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['table' <commit> table_ident '\{' table_body '\}']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['join_table' <commit> table_ident '\{' join_table_body '\}']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{sql_block});
		%item = (__RULE__ => q{sql_block});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['join_table']},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Ajoin_table//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		

		Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
					Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE; 
		$_tok = do { $commit = 1 };
		if (defined($_tok))
		{
			Parse::RecDescent::_trace(q{>>Matched directive<< (return value: [}
						. $_tok . q{])},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		else
		{
			Parse::RecDescent::_trace(q{<<Didn't match directive>>},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		
		last unless defined $_tok;
		push @item, $item{__DIRECTIVE1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying subrule: [table_ident]},
				  Parse::RecDescent::_tracefirst($text),
				  q{sql_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{table_ident})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::table_ident($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [table_ident]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{sql_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [table_ident]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{table_ident}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\{'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [join_table_body]},
				  Parse::RecDescent::_tracefirst($text),
				  q{sql_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{join_table_body})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::join_table_body($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [join_table_body]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{sql_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [join_table_body]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{join_table_body}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING3__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                bless {
                            __IDENT__ => Bigtop::Parser->get_ident(),
                            __NAME__  => $item{table_ident},
                            __BODY__  => $item{join_table_body}
                                              {'join_table_statement(s?)'},
                }, 'join_table'
            };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['join_table' <commit> table_ident '\{' join_table_body '\}']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['schema' <commit> IDENT '\{' '\}']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[3];
		$text = $_[1];
		my $_savetext;
		@item = (q{sql_block});
		%item = (__RULE__ => q{sql_block});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['schema']},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Aschema//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		

		Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
					Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE; 
		$_tok = do { $commit = 1 };
		if (defined($_tok))
		{
			Parse::RecDescent::_trace(q{>>Matched directive<< (return value: [}
						. $_tok . q{])},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		else
		{
			Parse::RecDescent::_trace(q{<<Didn't match directive>>},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		
		last unless defined $_tok;
		push @item, $item{__DIRECTIVE1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
				  Parse::RecDescent::_tracefirst($text),
				  q{sql_block},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{IDENT})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Bigtop::Grammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{sql_block},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{IDENT}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\{'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING3__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                bless {
                            __IDENT__ => Bigtop::Parser->get_ident(),
                            __NAME__  => $item{ IDENT },
                }, 'schema_block'
            };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['schema' <commit> IDENT '\{' '\}']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{sql_block},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{sql_block},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{sql_block},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{sql_block},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::extra_sql_body
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"extra_sql_body"};
	
	Parse::RecDescent::_trace(q{Trying rule: [extra_sql_body]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{extra_sql_body},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [extra_sql_statement]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{extra_sql_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{extra_sql_body});
		%item = (__RULE__ => q{extra_sql_body});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying repeated subrule: [extra_sql_statement]},
				  Parse::RecDescent::_tracefirst($text),
				  q{extra_sql_body},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::extra_sql_statement, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [extra_sql_statement]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{extra_sql_body},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [extra_sql_statement]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{extra_sql_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{extra_sql_statement(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{extra_sql_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless \%item, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [extra_sql_statement]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{extra_sql_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{extra_sql_body},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{extra_sql_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{extra_sql_body},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{extra_sql_body},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Bigtop::Grammar::method_body
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"method_body"};
	
	Parse::RecDescent::_trace(q{Trying rule: [method_body]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{method_body},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [method_statement]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{method_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{method_body});
		%item = (__RULE__ => q{method_body});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying repeated subrule: [method_statement]},
				  Parse::RecDescent::_tracefirst($text),
				  q{method_body},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Bigtop::Grammar::method_statement, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [method_statement]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{method_body},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [method_statement]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{method_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{method_statement(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{method_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {bless \%item, $item[0]};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [method_statement]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{method_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{method_body},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{method_body},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{method_body},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{method_body},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}
}
package Bigtop::Grammar; sub new { my $self = bless( {
                 '_AUTOTREE' => {
                                  'TERMINAL' => bless( {
                                                         'lookahead' => 0,
                                                         'line' => -1,
                                                         'code' => '{bless {__VALUE__=>$item[1]}, $item[0]}'
                                                       }, 'Parse::RecDescent::Action' ),
                                  'NODE' => bless( {
                                                     'lookahead' => 0,
                                                     'line' => -1,
                                                     'code' => '{bless \\%item, $item[0]}'
                                                   }, 'Parse::RecDescent::Action' )
                                },
                 'localvars' => '',
                 'startcode' => '',
                 '_check' => {
                               'thisoffset' => '',
                               'itempos' => '',
                               'prevoffset' => '',
                               'prevline' => '',
                               'prevcolumn' => '',
                               'thiscolumn' => ''
                             },
                 'namespace' => 'Parse::RecDescent::Bigtop::Grammar',
                 '_AUTOACTION' => undef,
                 'rules' => {
                              'method_type' => bless( {
                                                        'impcount' => 0,
                                                        'calls' => [
                                                                     'IDENT'
                                                                   ],
                                                        'changed' => 0,
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'number' => '0',
                                                                              'strcount' => 1,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'pattern' => 'is',
                                                                                                    'hashname' => '__STRING1__',
                                                                                                    'description' => '\'is\'',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 200
                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'IDENT',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 200
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 200,
                                                                                                    'code' => '{ $item{IDENT} }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'method_type',
                                                        'vars' => '',
                                                        'line' => 200
                                                      }, 'Parse::RecDescent::Rule' ),
                              'join_table_statement' => bless( {
                                                                 'impcount' => 0,
                                                                 'calls' => [
                                                                              'IDENT',
                                                                              'field_body',
                                                                              'keyword',
                                                                              'arg_list',
                                                                              'SEMI_COLON'
                                                                            ],
                                                                 'changed' => 0,
                                                                 'opcount' => 0,
                                                                 'prods' => [
                                                                              bless( {
                                                                                       'number' => '0',
                                                                                       'strcount' => 3,
                                                                                       'dircount' => 1,
                                                                                       'uncommit' => undef,
                                                                                       'error' => undef,
                                                                                       'patcount' => 0,
                                                                                       'actcount' => 1,
                                                                                       'items' => [
                                                                                                    bless( {
                                                                                                             'pattern' => 'field',
                                                                                                             'hashname' => '__STRING1__',
                                                                                                             'description' => '\'field\'',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 313
                                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                                    bless( {
                                                                                                             'hashname' => '__DIRECTIVE1__',
                                                                                                             'name' => '<commit>',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 313,
                                                                                                             'code' => '$commit = 1'
                                                                                                           }, 'Parse::RecDescent::Directive' ),
                                                                                                    bless( {
                                                                                                             'subrule' => 'IDENT',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => undef,
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 313
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'pattern' => '{',
                                                                                                             'hashname' => '__STRING2__',
                                                                                                             'description' => '\'\\{\'',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 313
                                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                                    bless( {
                                                                                                             'subrule' => 'field_body',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => undef,
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 313
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'pattern' => '}',
                                                                                                             'hashname' => '__STRING3__',
                                                                                                             'description' => '\'\\}\'',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 313
                                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                                    bless( {
                                                                                                             'hashname' => '__ACTION1__',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 313,
                                                                                                             'code' => '{
                           bless {
                               __IDENT__ => Bigtop::Parser->get_ident(),
                               __TYPE__  => \'field\',
                               __NAME__  => $item{IDENT},
                               __BODY__  =>
                                    $item{field_body}{\'field_statement(s?)\'},
                           }, \'table_element_block\'
                       }'
                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                  ],
                                                                                       'line' => undef
                                                                                     }, 'Parse::RecDescent::Production' ),
                                                                              bless( {
                                                                                       'number' => '1',
                                                                                       'strcount' => 0,
                                                                                       'dircount' => 0,
                                                                                       'uncommit' => undef,
                                                                                       'error' => undef,
                                                                                       'patcount' => 0,
                                                                                       'actcount' => 1,
                                                                                       'items' => [
                                                                                                    bless( {
                                                                                                             'subrule' => 'keyword',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => '[\'join_table\']',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 323
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'subrule' => 'arg_list',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => undef,
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 323
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'subrule' => 'SEMI_COLON',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => undef,
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 323
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'hashname' => '__ACTION1__',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 323,
                                                                                                             'code' => '{
                      bless {
                          __KEYWORD__ => $item[1], __DEF__ => $item[2]
                      }, \'join_table_statement\'
                  }'
                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                  ],
                                                                                       'line' => 323
                                                                                     }, 'Parse::RecDescent::Production' )
                                                                            ],
                                                                 'name' => 'join_table_statement',
                                                                 'vars' => '',
                                                                 'line' => 313
                                                               }, 'Parse::RecDescent::Rule' ),
                              'backend_body' => bless( {
                                                         'impcount' => 0,
                                                         'calls' => [
                                                                      'backend_statement'
                                                                    ],
                                                         'changed' => 0,
                                                         'opcount' => 0,
                                                         'prods' => [
                                                                      bless( {
                                                                               'number' => '0',
                                                                               'strcount' => 0,
                                                                               'dircount' => 0,
                                                                               'uncommit' => undef,
                                                                               'error' => undef,
                                                                               'patcount' => 0,
                                                                               'actcount' => 1,
                                                                               'items' => [
                                                                                            bless( {
                                                                                                     'subrule' => 'backend_statement',
                                                                                                     'expected' => undef,
                                                                                                     'min' => 0,
                                                                                                     'argcode' => undef,
                                                                                                     'max' => 100000000,
                                                                                                     'matchrule' => 0,
                                                                                                     'repspec' => 's?',
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 49
                                                                                                   }, 'Parse::RecDescent::Repetition' ),
                                                                                            bless( {
                                                                                                     'hashname' => '__ACTION1__',
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 49,
                                                                                                     'code' => '{
    my %config;
    foreach my $statement ( @{ $item{\'backend_statement(s?)\'} } ) {
        $config{ $statement->[0] } = $statement->[1];
    }
    $return = \\%config;
}'
                                                                                                   }, 'Parse::RecDescent::Action' )
                                                                                          ],
                                                                               'line' => undef
                                                                             }, 'Parse::RecDescent::Production' )
                                                                    ],
                                                         'name' => 'backend_body',
                                                         'vars' => '',
                                                         'line' => 49
                                                       }, 'Parse::RecDescent::Rule' ),
                              'arg' => bless( {
                                                'impcount' => 0,
                                                'calls' => [
                                                             'arg_element'
                                                           ],
                                                'changed' => 0,
                                                'opcount' => 0,
                                                'prods' => [
                                                             bless( {
                                                                      'number' => '0',
                                                                      'strcount' => 1,
                                                                      'dircount' => 0,
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => 0,
                                                                      'actcount' => 1,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'subrule' => 'arg_element',
                                                                                            'matchrule' => 0,
                                                                                            'implicit' => undef,
                                                                                            'argcode' => undef,
                                                                                            'lookahead' => 0,
                                                                                            'line' => 380
                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                   bless( {
                                                                                            'pattern' => '=>',
                                                                                            'hashname' => '__STRING1__',
                                                                                            'description' => '\'=>\'',
                                                                                            'lookahead' => 0,
                                                                                            'line' => 380
                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                   bless( {
                                                                                            'subrule' => 'arg_element',
                                                                                            'matchrule' => 0,
                                                                                            'implicit' => undef,
                                                                                            'argcode' => undef,
                                                                                            'lookahead' => 0,
                                                                                            'line' => 380
                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                   bless( {
                                                                                            'hashname' => '__ACTION1__',
                                                                                            'lookahead' => 0,
                                                                                            'line' => 380,
                                                                                            'code' => '{ $return = { $item[1] => $item[3] } }'
                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                 ],
                                                                      'line' => undef
                                                                    }, 'Parse::RecDescent::Production' ),
                                                             bless( {
                                                                      'number' => '1',
                                                                      'strcount' => 0,
                                                                      'dircount' => 0,
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => 0,
                                                                      'actcount' => 1,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'subrule' => 'arg_element',
                                                                                            'matchrule' => 0,
                                                                                            'implicit' => undef,
                                                                                            'argcode' => undef,
                                                                                            'lookahead' => 0,
                                                                                            'line' => 381
                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                   bless( {
                                                                                            'hashname' => '__ACTION1__',
                                                                                            'lookahead' => 0,
                                                                                            'line' => 381,
                                                                                            'code' => '{ $item[1] }'
                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                 ],
                                                                      'line' => 381
                                                                    }, 'Parse::RecDescent::Production' )
                                                           ],
                                                'name' => 'arg',
                                                'vars' => '',
                                                'line' => 380
                                              }, 'Parse::RecDescent::Rule' ),
                              'IDENT' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => '0',
                                                                        'strcount' => 0,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 1,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => '^\\w[\\w\\d_]*',
                                                                                              'hashname' => '__PATTERN1__',
                                                                                              'description' => '/^\\\\w[\\\\w\\\\d_]*/',
                                                                                              'lookahead' => 0,
                                                                                              'rdelim' => '/',
                                                                                              'line' => 418,
                                                                                              'mod' => '',
                                                                                              'ldelim' => '/'
                                                                                            }, 'Parse::RecDescent::Token' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 418,
                                                                                              'code' => '{ $item[1] }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'IDENT',
                                                  'vars' => '',
                                                  'line' => 418
                                                }, 'Parse::RecDescent::Rule' ),
                              'string' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'BACKTICK',
                                                                'text'
                                                              ],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => '0',
                                                                         'strcount' => 0,
                                                                         'dircount' => 1,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 1,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'subrule' => 'BACKTICK',
                                                                                               'matchrule' => 0,
                                                                                               'implicit' => undef,
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => 0,
                                                                                               'line' => 402
                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                      bless( {
                                                                                               'hashname' => '__DIRECTIVE1__',
                                                                                               'name' => '<skip:\'\'>',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 402,
                                                                                               'code' => 'my $oldskip = $skip; $skip=\'\'; $oldskip'
                                                                                             }, 'Parse::RecDescent::Directive' ),
                                                                                      bless( {
                                                                                               'subrule' => 'text',
                                                                                               'matchrule' => 0,
                                                                                               'implicit' => undef,
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => 0,
                                                                                               'line' => 402
                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                      bless( {
                                                                                               'subrule' => 'BACKTICK',
                                                                                               'matchrule' => 0,
                                                                                               'implicit' => undef,
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => 0,
                                                                                               'line' => 402
                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 402,
                                                                                               'code' => '{ $item{text} }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'string',
                                                   'vars' => '',
                                                   'line' => 402
                                                 }, 'Parse::RecDescent::Rule' ),
                              'app_config_statement' => bless( {
                                                                 'impcount' => 0,
                                                                 'calls' => [
                                                                              'IDENT',
                                                                              'arg_list',
                                                                              'SEMI_COLON'
                                                                            ],
                                                                 'changed' => 0,
                                                                 'opcount' => 0,
                                                                 'prods' => [
                                                                              bless( {
                                                                                       'number' => '0',
                                                                                       'strcount' => 0,
                                                                                       'dircount' => 0,
                                                                                       'uncommit' => undef,
                                                                                       'error' => undef,
                                                                                       'patcount' => 0,
                                                                                       'actcount' => 1,
                                                                                       'items' => [
                                                                                                    bless( {
                                                                                                             'subrule' => 'IDENT',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => undef,
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 337
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'subrule' => 'arg_list',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => undef,
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 337
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'subrule' => 'SEMI_COLON',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => undef,
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 337
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'hashname' => '__ACTION1__',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 337,
                                                                                                             'code' => '{
                         bless {
                            __KEYWORD__ => $item{IDENT},
                            __ARGS__    => $item{arg_list}
                         }, \'app_config_statement\'
                       }'
                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                  ],
                                                                                       'line' => undef
                                                                                     }, 'Parse::RecDescent::Production' ),
                                                                              bless( {
                                                                                       'number' => '1',
                                                                                       'strcount' => 0,
                                                                                       'dircount' => 0,
                                                                                       'uncommit' => undef,
                                                                                       'error' => undef,
                                                                                       'patcount' => 1,
                                                                                       'actcount' => 1,
                                                                                       'items' => [
                                                                                                    bless( {
                                                                                                             'pattern' => '[^\\}]',
                                                                                                             'hashname' => '__PATTERN1__',
                                                                                                             'description' => '/[^\\\\\\}]/',
                                                                                                             'lookahead' => 0,
                                                                                                             'rdelim' => '/',
                                                                                                             'line' => 343,
                                                                                                             'mod' => '',
                                                                                                             'ldelim' => '/'
                                                                                                           }, 'Parse::RecDescent::Token' ),
                                                                                                    bless( {
                                                                                                             'hashname' => '__ACTION1__',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 343,
                                                                                                             'code' => '{
                            my $message = "bad config statement, "
                                        . "possible extra semicolon";
                            if ( $backtick_warning ) {
                                $message .= " ($backtick_warning)";
                                $backtick_warning = \'\';
                            }
                            my $diag_text = $item[1] . $text;
                            Bigtop::Parser->fatal_error_two_lines(
                                $message, $diag_text, $thisline
                            );
                       }'
                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                  ],
                                                                                       'line' => 343
                                                                                     }, 'Parse::RecDescent::Production' )
                                                                            ],
                                                                 'name' => 'app_config_statement',
                                                                 'vars' => '',
                                                                 'line' => 337
                                                               }, 'Parse::RecDescent::Rule' ),
                              'arg_element' => bless( {
                                                        'impcount' => 0,
                                                        'calls' => [
                                                                     'module_ident',
                                                                     'string'
                                                                   ],
                                                        'changed' => 0,
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'number' => '0',
                                                                              'strcount' => 0,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'subrule' => 'module_ident',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 383
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 383,
                                                                                                    'code' => '{ $item[1] }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' ),
                                                                     bless( {
                                                                              'number' => '1',
                                                                              'strcount' => 0,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'subrule' => 'string',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 384
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 384,
                                                                                                    'code' => '{ $item[1] }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => 384
                                                                            }, 'Parse::RecDescent::Production' ),
                                                                     bless( {
                                                                              'number' => '2',
                                                                              'strcount' => 0,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 385,
                                                                                                    'code' => '{
    my $message = "I was expecting an argument or argument list";
    if ( $backtick_warning ) {
        $message .= " ($backtick_warning)";
        $backtick_warning = \'\';
    }
    Bigtop::Parser->fatal_error_two_lines(
        $message, $text, $thisline
    );
}'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => 385
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'arg_element',
                                                        'vars' => '',
                                                        'line' => 383
                                                      }, 'Parse::RecDescent::Rule' ),
                              'backend_statement' => bless( {
                                                              'impcount' => 0,
                                                              'calls' => [
                                                                           'IDENT',
                                                                           'arg_element',
                                                                           'SEMI_COLON'
                                                                         ],
                                                              'changed' => 0,
                                                              'opcount' => 0,
                                                              'prods' => [
                                                                           bless( {
                                                                                    'number' => '0',
                                                                                    'strcount' => 0,
                                                                                    'dircount' => 0,
                                                                                    'uncommit' => undef,
                                                                                    'error' => undef,
                                                                                    'patcount' => 0,
                                                                                    'actcount' => 1,
                                                                                    'items' => [
                                                                                                 bless( {
                                                                                                          'subrule' => 'IDENT',
                                                                                                          'matchrule' => 0,
                                                                                                          'implicit' => undef,
                                                                                                          'argcode' => undef,
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 57
                                                                                                        }, 'Parse::RecDescent::Subrule' ),
                                                                                                 bless( {
                                                                                                          'subrule' => 'arg_element',
                                                                                                          'matchrule' => 0,
                                                                                                          'implicit' => undef,
                                                                                                          'argcode' => undef,
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 57
                                                                                                        }, 'Parse::RecDescent::Subrule' ),
                                                                                                 bless( {
                                                                                                          'subrule' => 'SEMI_COLON',
                                                                                                          'matchrule' => 0,
                                                                                                          'implicit' => undef,
                                                                                                          'argcode' => undef,
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 57
                                                                                                        }, 'Parse::RecDescent::Subrule' ),
                                                                                                 bless( {
                                                                                                          'hashname' => '__ACTION1__',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 57,
                                                                                                          'code' => '{
    $return = [ $item{IDENT} => $item{arg_element} ];
}'
                                                                                                        }, 'Parse::RecDescent::Action' )
                                                                                               ],
                                                                                    'line' => undef
                                                                                  }, 'Parse::RecDescent::Production' )
                                                                         ],
                                                              'name' => 'backend_statement',
                                                              'vars' => '',
                                                              'line' => 57
                                                            }, 'Parse::RecDescent::Rule' ),
                              'config_only' => bless( {
                                                        'impcount' => 0,
                                                        'calls' => [
                                                                     'configuration',
                                                                     'anything'
                                                                   ],
                                                        'changed' => 0,
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'number' => '0',
                                                                              'strcount' => 0,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'subrule' => 'configuration',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 11
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'anything',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 11
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 11,
                                                                                                    'code' => '{ $item[1] }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'config_only',
                                                        'vars' => '',
                                                        'line' => 9
                                                      }, 'Parse::RecDescent::Rule' ),
                              'extra_sql_statement_def' => bless( {
                                                                    'impcount' => 0,
                                                                    'calls' => [
                                                                                 'arg_list'
                                                                               ],
                                                                    'changed' => 0,
                                                                    'opcount' => 0,
                                                                    'prods' => [
                                                                                 bless( {
                                                                                          'number' => '0',
                                                                                          'strcount' => 0,
                                                                                          'dircount' => 0,
                                                                                          'uncommit' => undef,
                                                                                          'error' => undef,
                                                                                          'patcount' => 0,
                                                                                          'actcount' => 1,
                                                                                          'items' => [
                                                                                                       bless( {
                                                                                                                'subrule' => 'arg_list',
                                                                                                                'expected' => undef,
                                                                                                                'min' => 0,
                                                                                                                'argcode' => undef,
                                                                                                                'max' => 1,
                                                                                                                'matchrule' => 0,
                                                                                                                'repspec' => '?',
                                                                                                                'lookahead' => 0,
                                                                                                                'line' => 305
                                                                                                              }, 'Parse::RecDescent::Repetition' ),
                                                                                                       bless( {
                                                                                                                'hashname' => '__ACTION1__',
                                                                                                                'lookahead' => 0,
                                                                                                                'line' => 305,
                                                                                                                'code' => '{
                    bless {
                        __ARGS__ => $item[1]->[0]
                    }, \'extra_sql_statement_def\'
                }'
                                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                                     ],
                                                                                          'line' => undef
                                                                                        }, 'Parse::RecDescent::Production' )
                                                                               ],
                                                                    'name' => 'extra_sql_statement_def',
                                                                    'vars' => '',
                                                                    'line' => 305
                                                                  }, 'Parse::RecDescent::Rule' ),
                              'field_statement_def' => bless( {
                                                                'impcount' => 0,
                                                                'calls' => [
                                                                             'arg_list'
                                                                           ],
                                                                'changed' => 0,
                                                                'opcount' => 0,
                                                                'prods' => [
                                                                             bless( {
                                                                                      'number' => '0',
                                                                                      'strcount' => 0,
                                                                                      'dircount' => 0,
                                                                                      'uncommit' => undef,
                                                                                      'error' => undef,
                                                                                      'patcount' => 0,
                                                                                      'actcount' => 1,
                                                                                      'items' => [
                                                                                                   bless( {
                                                                                                            'subrule' => 'arg_list',
                                                                                                            'expected' => undef,
                                                                                                            'min' => 0,
                                                                                                            'argcode' => undef,
                                                                                                            'max' => 1,
                                                                                                            'matchrule' => 0,
                                                                                                            'repspec' => '?',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 291
                                                                                                          }, 'Parse::RecDescent::Repetition' ),
                                                                                                   bless( {
                                                                                                            'hashname' => '__ACTION1__',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 291,
                                                                                                            'code' => '{
                        bless {
                            __ARGS__ => $item[1]->[0]
                        }, \'field_statement_def\'
                      }'
                                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                                 ],
                                                                                      'line' => undef
                                                                                    }, 'Parse::RecDescent::Production' )
                                                                           ],
                                                                'name' => 'field_statement_def',
                                                                'vars' => '',
                                                                'line' => 291
                                                              }, 'Parse::RecDescent::Rule' ),
                              'controller_statement' => bless( {
                                                                 'impcount' => 0,
                                                                 'calls' => [
                                                                              'IDENT',
                                                                              'method_type',
                                                                              'method_body',
                                                                              'CONFIG',
                                                                              'controller_config_statement',
                                                                              'keyword',
                                                                              'string',
                                                                              'SEMI_COLON',
                                                                              'arg_list'
                                                                            ],
                                                                 'changed' => 0,
                                                                 'opcount' => 0,
                                                                 'prods' => [
                                                                              bless( {
                                                                                       'number' => '0',
                                                                                       'strcount' => 3,
                                                                                       'dircount' => 0,
                                                                                       'uncommit' => undef,
                                                                                       'error' => undef,
                                                                                       'patcount' => 0,
                                                                                       'actcount' => 1,
                                                                                       'items' => [
                                                                                                    bless( {
                                                                                                             'pattern' => 'method',
                                                                                                             'hashname' => '__STRING1__',
                                                                                                             'description' => '\'method\'',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 142
                                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                                    bless( {
                                                                                                             'subrule' => 'IDENT',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => undef,
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 142
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'subrule' => 'method_type',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => undef,
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 143
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'pattern' => '{',
                                                                                                             'hashname' => '__STRING2__',
                                                                                                             'description' => '\'\\{\'',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 143
                                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                                    bless( {
                                                                                                             'subrule' => 'method_body',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => undef,
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 143
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'pattern' => '}',
                                                                                                             'hashname' => '__STRING3__',
                                                                                                             'description' => '\'\\}\'',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 143
                                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                                    bless( {
                                                                                                             'hashname' => '__ACTION1__',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 143,
                                                                                                             'code' => '{
                            bless {
                                __IDENT__ => Bigtop::Parser->get_ident(),
                                __NAME__  => $item{IDENT},
                                __BODY__  => $item{method_body},
                                __TYPE__  => $item{method_type},
                            }, \'controller_method\'
                        }'
                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                  ],
                                                                                       'line' => undef
                                                                                     }, 'Parse::RecDescent::Production' ),
                                                                              bless( {
                                                                                       'number' => '1',
                                                                                       'strcount' => 2,
                                                                                       'dircount' => 0,
                                                                                       'uncommit' => undef,
                                                                                       'error' => undef,
                                                                                       'patcount' => 0,
                                                                                       'actcount' => 1,
                                                                                       'items' => [
                                                                                                    bless( {
                                                                                                             'pattern' => 'method',
                                                                                                             'hashname' => '__STRING1__',
                                                                                                             'description' => '\'method\'',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 151
                                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                                    bless( {
                                                                                                             'subrule' => 'IDENT',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => undef,
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 151
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'pattern' => '{',
                                                                                                             'hashname' => '__STRING2__',
                                                                                                             'description' => '\'\\{\'',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 151
                                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                                    bless( {
                                                                                                             'hashname' => '__ACTION1__',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 151,
                                                                                                             'code' => '{
                            my $diag_text = $item[1] . \' \'
                                          . $item[2] . \' {\'
                                          . $text;
                            Bigtop::Parser->fatal_error_two_lines(
                                \'missing method type\', $diag_text, $thisline
                            );
                     }'
                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                  ],
                                                                                       'line' => 151
                                                                                     }, 'Parse::RecDescent::Production' ),
                                                                              bless( {
                                                                                       'number' => '2',
                                                                                       'strcount' => 2,
                                                                                       'dircount' => 0,
                                                                                       'uncommit' => undef,
                                                                                       'error' => undef,
                                                                                       'patcount' => 0,
                                                                                       'actcount' => 1,
                                                                                       'items' => [
                                                                                                    bless( {
                                                                                                             'subrule' => 'CONFIG',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => undef,
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 159
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'subrule' => 'IDENT',
                                                                                                             'expected' => undef,
                                                                                                             'min' => 0,
                                                                                                             'argcode' => undef,
                                                                                                             'max' => 1,
                                                                                                             'matchrule' => 0,
                                                                                                             'repspec' => '?',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 159
                                                                                                           }, 'Parse::RecDescent::Repetition' ),
                                                                                                    bless( {
                                                                                                             'pattern' => '{',
                                                                                                             'hashname' => '__STRING1__',
                                                                                                             'description' => '\'\\{\'',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 159
                                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                                    bless( {
                                                                                                             'subrule' => 'controller_config_statement',
                                                                                                             'expected' => undef,
                                                                                                             'min' => 0,
                                                                                                             'argcode' => undef,
                                                                                                             'max' => 100000000,
                                                                                                             'matchrule' => 0,
                                                                                                             'repspec' => 's?',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 159
                                                                                                           }, 'Parse::RecDescent::Repetition' ),
                                                                                                    bless( {
                                                                                                             'pattern' => '}',
                                                                                                             'hashname' => '__STRING2__',
                                                                                                             'description' => '\'\\}\'',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 159
                                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                                    bless( {
                                                                                                             'hashname' => '__ACTION1__',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 159,
                                                                                                             'code' => '{
                   bless {
                       __IDENT__ => Bigtop::Parser->get_ident(),
                       __BODY__  => $item{\'controller_config_statement(s?)\'},
                       __TYPE__  => $item{\'IDENT(?)\'}[0],
                   }, \'controller_config_block\'
                }'
                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                  ],
                                                                                       'line' => 159
                                                                                     }, 'Parse::RecDescent::Production' ),
                                                                              bless( {
                                                                                       'number' => '3',
                                                                                       'strcount' => 1,
                                                                                       'dircount' => 0,
                                                                                       'uncommit' => undef,
                                                                                       'error' => undef,
                                                                                       'patcount' => 0,
                                                                                       'actcount' => 1,
                                                                                       'items' => [
                                                                                                    bless( {
                                                                                                             'pattern' => 'literal',
                                                                                                             'hashname' => '__STRING1__',
                                                                                                             'description' => '\'literal\'',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 166
                                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                                    bless( {
                                                                                                             'subrule' => 'keyword',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => '[ \'controller_literal\' ]',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 166
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'subrule' => 'string',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => undef,
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 167
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'subrule' => 'SEMI_COLON',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => undef,
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 167
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'hashname' => '__ACTION1__',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 167,
                                                                                                             'code' => '{
                    bless {
                        __IDENT__   => Bigtop::Parser->get_ident(),
                        __BACKEND__ => $item{ keyword },
                        __BODY__    => $item{ string },
                    }, \'controller_literal_block\'
           }'
                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                  ],
                                                                                       'line' => 166
                                                                                     }, 'Parse::RecDescent::Production' ),
                                                                              bless( {
                                                                                       'number' => '4',
                                                                                       'strcount' => 0,
                                                                                       'dircount' => 0,
                                                                                       'uncommit' => undef,
                                                                                       'error' => undef,
                                                                                       'patcount' => 0,
                                                                                       'actcount' => 1,
                                                                                       'items' => [
                                                                                                    bless( {
                                                                                                             'subrule' => 'keyword',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => '[\'controller\']',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 174
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'subrule' => 'arg_list',
                                                                                                             'expected' => undef,
                                                                                                             'min' => 0,
                                                                                                             'argcode' => undef,
                                                                                                             'max' => 1,
                                                                                                             'matchrule' => 0,
                                                                                                             'repspec' => '?',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 174
                                                                                                           }, 'Parse::RecDescent::Repetition' ),
                                                                                                    bless( {
                                                                                                             'subrule' => 'SEMI_COLON',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => undef,
                                                                                                             'argcode' => undef,
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 174
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'hashname' => '__ACTION1__',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => 174,
                                                                                                             'code' => '{
                           bless {
                               __KEYWORD__ => $item{keyword},
                               __ARGS__    => $item{\'arg_list(?)\'}->[0],
                           }, \'controller_statement\'
           }'
                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                  ],
                                                                                       'line' => 174
                                                                                     }, 'Parse::RecDescent::Production' )
                                                                            ],
                                                                 'name' => 'controller_statement',
                                                                 'vars' => '',
                                                                 'line' => 142
                                                               }, 'Parse::RecDescent::Rule' ),
                              'configuration' => bless( {
                                                          'impcount' => 0,
                                                          'calls' => [
                                                                       'config_body'
                                                                     ],
                                                          'changed' => 0,
                                                          'opcount' => 0,
                                                          'prods' => [
                                                                       bless( {
                                                                                'number' => '0',
                                                                                'strcount' => 3,
                                                                                'dircount' => 0,
                                                                                'uncommit' => undef,
                                                                                'error' => undef,
                                                                                'patcount' => 0,
                                                                                'actcount' => 1,
                                                                                'items' => [
                                                                                             bless( {
                                                                                                      'pattern' => 'config',
                                                                                                      'hashname' => '__STRING1__',
                                                                                                      'description' => '\'config\'',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 17
                                                                                                    }, 'Parse::RecDescent::Literal' ),
                                                                                             bless( {
                                                                                                      'pattern' => '{',
                                                                                                      'hashname' => '__STRING2__',
                                                                                                      'description' => '\'\\{\'',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 17
                                                                                                    }, 'Parse::RecDescent::Literal' ),
                                                                                             bless( {
                                                                                                      'subrule' => 'config_body',
                                                                                                      'matchrule' => 0,
                                                                                                      'implicit' => undef,
                                                                                                      'argcode' => undef,
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 17
                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                             bless( {
                                                                                                      'pattern' => '}',
                                                                                                      'hashname' => '__STRING3__',
                                                                                                      'description' => '\'\\}\'',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 17
                                                                                                    }, 'Parse::RecDescent::Literal' ),
                                                                                             bless( {
                                                                                                      'hashname' => '__ACTION1__',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 17,
                                                                                                      'code' => '{ $item{config_body} }'
                                                                                                    }, 'Parse::RecDescent::Action' )
                                                                                           ],
                                                                                'line' => undef
                                                                              }, 'Parse::RecDescent::Production' )
                                                                     ],
                                                          'name' => 'configuration',
                                                          'vars' => '',
                                                          'line' => 17
                                                        }, 'Parse::RecDescent::Rule' ),
                              'config_statement' => bless( {
                                                             'impcount' => 0,
                                                             'calls' => [
                                                                          'module_ident',
                                                                          'IDENT',
                                                                          'backend_body',
                                                                          'keyword',
                                                                          'arg_element',
                                                                          'SEMI_COLON'
                                                                        ],
                                                             'changed' => 0,
                                                             'opcount' => 0,
                                                             'prods' => [
                                                                          bless( {
                                                                                   'number' => '0',
                                                                                   'strcount' => 2,
                                                                                   'dircount' => 0,
                                                                                   'uncommit' => undef,
                                                                                   'error' => undef,
                                                                                   'patcount' => 0,
                                                                                   'actcount' => 1,
                                                                                   'items' => [
                                                                                                bless( {
                                                                                                         'subrule' => 'module_ident',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => undef,
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 36
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'IDENT',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => undef,
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 36
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'pattern' => '{',
                                                                                                         'hashname' => '__STRING1__',
                                                                                                         'description' => '\'\\{\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 36
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'backend_body',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => undef,
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 36
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'pattern' => '}',
                                                                                                         'hashname' => '__STRING2__',
                                                                                                         'description' => '\'\\}\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 36
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'hashname' => '__ACTION1__',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 36,
                                                                                                         'code' => '{
    my $backend_data = $item{backend_body};
    my $backend_type = $item{module_ident};
    my $backend_name = $item{IDENT};

    $backend_data->{__NAME__} = $backend_name;

    $return = [ $backend_type => $backend_data ];
}'
                                                                                                       }, 'Parse::RecDescent::Action' )
                                                                                              ],
                                                                                   'line' => undef
                                                                                 }, 'Parse::RecDescent::Production' ),
                                                                          bless( {
                                                                                   'number' => '1',
                                                                                   'strcount' => 0,
                                                                                   'dircount' => 0,
                                                                                   'uncommit' => undef,
                                                                                   'error' => undef,
                                                                                   'patcount' => 0,
                                                                                   'actcount' => 1,
                                                                                   'items' => [
                                                                                                bless( {
                                                                                                         'subrule' => 'keyword',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => '[ \'config\' ]',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 45
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'arg_element',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => undef,
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 45
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'SEMI_COLON',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => undef,
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 45
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'hashname' => '__ACTION1__',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 45,
                                                                                                         'code' => '{
    $return = [ $item{keyword} => $item{arg_element} ];
}'
                                                                                                       }, 'Parse::RecDescent::Action' )
                                                                                              ],
                                                                                   'line' => 45
                                                                                 }, 'Parse::RecDescent::Production' )
                                                                        ],
                                                             'name' => 'config_statement',
                                                             'vars' => '',
                                                             'line' => 36
                                                           }, 'Parse::RecDescent::Rule' ),
                              'table_ident' => bless( {
                                                        'impcount' => 0,
                                                        'calls' => [
                                                                     'IDENT'
                                                                   ],
                                                        'changed' => 0,
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'number' => '0',
                                                                              'strcount' => 1,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'subrule' => 'IDENT',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 396
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'pattern' => '.',
                                                                                                    'hashname' => '__STRING1__',
                                                                                                    'description' => '\'.\'',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 396
                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'IDENT',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 396
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 396,
                                                                                                    'code' => '{ $item[1] . \'.\' . $item[3] }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' ),
                                                                     bless( {
                                                                              'number' => '1',
                                                                              'strcount' => 0,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'subrule' => 'IDENT',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 397
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 397,
                                                                                                    'code' => '{ $item[1] }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => 397
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'table_ident',
                                                        'vars' => '',
                                                        'line' => 396
                                                      }, 'Parse::RecDescent::Rule' ),
                              'table_body' => bless( {
                                                       'impcount' => 0,
                                                       'calls' => [
                                                                    'table_element_block'
                                                                  ],
                                                       'changed' => 0,
                                                       'opcount' => 0,
                                                       'prods' => [
                                                                    bless( {
                                                                             'number' => '0',
                                                                             'strcount' => 0,
                                                                             'dircount' => 0,
                                                                             'uncommit' => undef,
                                                                             'error' => undef,
                                                                             'patcount' => 0,
                                                                             'actcount' => 0,
                                                                             'items' => [
                                                                                          bless( {
                                                                                                   'subrule' => 'table_element_block',
                                                                                                   'expected' => undef,
                                                                                                   'min' => 0,
                                                                                                   'argcode' => undef,
                                                                                                   'max' => 100000000,
                                                                                                   'matchrule' => 0,
                                                                                                   'repspec' => 's?',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => 253
                                                                                                 }, 'Parse::RecDescent::Repetition' )
                                                                                        ],
                                                                             'line' => undef
                                                                           }, 'Parse::RecDescent::Production' )
                                                                  ],
                                                       'name' => 'table_body',
                                                       'vars' => '',
                                                       'line' => 253
                                                     }, 'Parse::RecDescent::Rule' ),
                              'anything' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => '0',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 1,
                                                                           'actcount' => 0,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => '.*',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/.*/s',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => 13,
                                                                                                 'mod' => 's',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'anything',
                                                     'vars' => '',
                                                     'line' => 13
                                                   }, 'Parse::RecDescent::Rule' ),
                              'app_statement' => bless( {
                                                          'impcount' => 0,
                                                          'calls' => [
                                                                       'keyword',
                                                                       'arg_list',
                                                                       'SEMI_COLON'
                                                                     ],
                                                          'changed' => 0,
                                                          'opcount' => 0,
                                                          'prods' => [
                                                                       bless( {
                                                                                'number' => '0',
                                                                                'strcount' => 0,
                                                                                'dircount' => 0,
                                                                                'uncommit' => undef,
                                                                                'error' => undef,
                                                                                'patcount' => 0,
                                                                                'actcount' => 1,
                                                                                'items' => [
                                                                                             bless( {
                                                                                                      'subrule' => 'keyword',
                                                                                                      'matchrule' => 0,
                                                                                                      'implicit' => undef,
                                                                                                      'argcode' => '[ \'app\' ]',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 87
                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                             bless( {
                                                                                                      'subrule' => 'arg_list',
                                                                                                      'expected' => undef,
                                                                                                      'min' => 0,
                                                                                                      'argcode' => undef,
                                                                                                      'max' => 1,
                                                                                                      'matchrule' => 0,
                                                                                                      'repspec' => '?',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 87
                                                                                                    }, 'Parse::RecDescent::Repetition' ),
                                                                                             bless( {
                                                                                                      'subrule' => 'SEMI_COLON',
                                                                                                      'matchrule' => 0,
                                                                                                      'implicit' => undef,
                                                                                                      'argcode' => undef,
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 87
                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                             bless( {
                                                                                                      'hashname' => '__ACTION1__',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 87,
                                                                                                      'code' => '{
                           bless {
                               __KEYWORD__ => $item{keyword},
                               __ARGS__    => $item{\'arg_list(?)\'}->[0],
                           }, \'app_statement\'
                }'
                                                                                                    }, 'Parse::RecDescent::Action' )
                                                                                           ],
                                                                                'line' => undef
                                                                              }, 'Parse::RecDescent::Production' )
                                                                     ],
                                                          'name' => 'app_statement',
                                                          'vars' => '',
                                                          'line' => 87
                                                        }, 'Parse::RecDescent::Rule' ),
                              'BACKTICK' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => '0',
                                                                           'strcount' => 1,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => '`',
                                                                                                 'hashname' => '__STRING1__',
                                                                                                 'description' => '\'`\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 416
                                                                                               }, 'Parse::RecDescent::InterpLit' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 416,
                                                                                                 'code' => '{ $backtick_line = $thisline; }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'BACKTICK',
                                                     'vars' => '',
                                                     'line' => 416
                                                   }, 'Parse::RecDescent::Rule' ),
                              'join_table_body' => bless( {
                                                            'impcount' => 0,
                                                            'calls' => [
                                                                         'join_table_statement'
                                                                       ],
                                                            'changed' => 0,
                                                            'opcount' => 0,
                                                            'prods' => [
                                                                         bless( {
                                                                                  'number' => '0',
                                                                                  'strcount' => 0,
                                                                                  'dircount' => 0,
                                                                                  'uncommit' => undef,
                                                                                  'error' => undef,
                                                                                  'patcount' => 0,
                                                                                  'actcount' => 0,
                                                                                  'items' => [
                                                                                               bless( {
                                                                                                        'subrule' => 'join_table_statement',
                                                                                                        'expected' => undef,
                                                                                                        'min' => 0,
                                                                                                        'argcode' => undef,
                                                                                                        'max' => 100000000,
                                                                                                        'matchrule' => 0,
                                                                                                        'repspec' => 's?',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 311
                                                                                                      }, 'Parse::RecDescent::Repetition' )
                                                                                             ],
                                                                                  'line' => undef
                                                                                }, 'Parse::RecDescent::Production' )
                                                                       ],
                                                            'name' => 'join_table_body',
                                                            'vars' => '',
                                                            'line' => 311
                                                          }, 'Parse::RecDescent::Rule' ),
                              'literal_block' => bless( {
                                                          'impcount' => 0,
                                                          'calls' => [
                                                                       'keyword',
                                                                       'string',
                                                                       'SEMI_COLON'
                                                                     ],
                                                          'changed' => 0,
                                                          'opcount' => 0,
                                                          'prods' => [
                                                                       bless( {
                                                                                'number' => '0',
                                                                                'strcount' => 1,
                                                                                'dircount' => 0,
                                                                                'uncommit' => undef,
                                                                                'error' => undef,
                                                                                'patcount' => 0,
                                                                                'actcount' => 1,
                                                                                'items' => [
                                                                                             bless( {
                                                                                                      'pattern' => 'literal',
                                                                                                      'hashname' => '__STRING1__',
                                                                                                      'description' => '\'literal\'',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 94
                                                                                                    }, 'Parse::RecDescent::Literal' ),
                                                                                             bless( {
                                                                                                      'subrule' => 'keyword',
                                                                                                      'matchrule' => 0,
                                                                                                      'implicit' => undef,
                                                                                                      'argcode' => '[ \'app_literal\' ]',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 94
                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                             bless( {
                                                                                                      'subrule' => 'string',
                                                                                                      'matchrule' => 0,
                                                                                                      'implicit' => undef,
                                                                                                      'argcode' => undef,
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 95
                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                             bless( {
                                                                                                      'subrule' => 'SEMI_COLON',
                                                                                                      'matchrule' => 0,
                                                                                                      'implicit' => undef,
                                                                                                      'argcode' => undef,
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 95
                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                             bless( {
                                                                                                      'hashname' => '__ACTION1__',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 95,
                                                                                                      'code' => '{
                    bless {
                        __IDENT__   => Bigtop::Parser->get_ident(),
                        __BACKEND__ => $item{ keyword },
                        __BODY__    => $item{ string },
                    }, \'literal_block\'
                }'
                                                                                                    }, 'Parse::RecDescent::Action' )
                                                                                           ],
                                                                                'line' => undef
                                                                              }, 'Parse::RecDescent::Production' )
                                                                     ],
                                                          'name' => 'literal_block',
                                                          'vars' => '',
                                                          'line' => 94
                                                        }, 'Parse::RecDescent::Rule' ),
                              'field_statement' => bless( {
                                                            'impcount' => 0,
                                                            'calls' => [
                                                                         'keyword',
                                                                         'field_statement_def',
                                                                         'SEMI_COLON'
                                                                       ],
                                                            'changed' => 0,
                                                            'opcount' => 0,
                                                            'prods' => [
                                                                         bless( {
                                                                                  'number' => '0',
                                                                                  'strcount' => 0,
                                                                                  'dircount' => 0,
                                                                                  'uncommit' => undef,
                                                                                  'error' => undef,
                                                                                  'patcount' => 0,
                                                                                  'actcount' => 1,
                                                                                  'items' => [
                                                                                               bless( {
                                                                                                        'subrule' => 'keyword',
                                                                                                        'matchrule' => 0,
                                                                                                        'implicit' => undef,
                                                                                                        'argcode' => '[\'field\']',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 285
                                                                                                      }, 'Parse::RecDescent::Subrule' ),
                                                                                               bless( {
                                                                                                        'subrule' => 'field_statement_def',
                                                                                                        'matchrule' => 0,
                                                                                                        'implicit' => undef,
                                                                                                        'argcode' => undef,
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 285
                                                                                                      }, 'Parse::RecDescent::Subrule' ),
                                                                                               bless( {
                                                                                                        'subrule' => 'SEMI_COLON',
                                                                                                        'matchrule' => 0,
                                                                                                        'implicit' => undef,
                                                                                                        'argcode' => undef,
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 285
                                                                                                      }, 'Parse::RecDescent::Subrule' ),
                                                                                               bless( {
                                                                                                        'hashname' => '__ACTION1__',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 285,
                                                                                                        'code' => '{
                      bless {
                          __KEYWORD__ => $item[1], __DEF__ => $item[2]
                      }, \'field_statement\'
                  }'
                                                                                                      }, 'Parse::RecDescent::Action' )
                                                                                             ],
                                                                                  'line' => undef
                                                                                }, 'Parse::RecDescent::Production' )
                                                                       ],
                                                            'name' => 'field_statement',
                                                            'vars' => '',
                                                            'line' => 285
                                                          }, 'Parse::RecDescent::Rule' ),
                              'method_statement' => bless( {
                                                             'impcount' => 0,
                                                             'calls' => [
                                                                          'keyword',
                                                                          'arg_list',
                                                                          'SEMI_COLON'
                                                                        ],
                                                             'changed' => 0,
                                                             'opcount' => 0,
                                                             'prods' => [
                                                                          bless( {
                                                                                   'number' => '0',
                                                                                   'strcount' => 0,
                                                                                   'dircount' => 0,
                                                                                   'uncommit' => undef,
                                                                                   'error' => undef,
                                                                                   'patcount' => 0,
                                                                                   'actcount' => 1,
                                                                                   'items' => [
                                                                                                bless( {
                                                                                                         'subrule' => 'keyword',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => '[\'method\']',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 204
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'arg_list',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => undef,
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 204
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'SEMI_COLON',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => undef,
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 204
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'hashname' => '__ACTION1__',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 204,
                                                                                                         'code' => '{
                        bless {
                            __KEYWORD__ => $item{keyword},
                            __ARGS__    => $item{arg_list}
                        }, \'method_statement\'
                   }'
                                                                                                       }, 'Parse::RecDescent::Action' )
                                                                                              ],
                                                                                   'line' => undef
                                                                                 }, 'Parse::RecDescent::Production' )
                                                                        ],
                                                             'name' => 'method_statement',
                                                             'vars' => '',
                                                             'line' => 204
                                                           }, 'Parse::RecDescent::Rule' ),
                              'controller_body' => bless( {
                                                            'impcount' => 0,
                                                            'calls' => [
                                                                         'controller_statement'
                                                                       ],
                                                            'changed' => 0,
                                                            'opcount' => 0,
                                                            'prods' => [
                                                                         bless( {
                                                                                  'number' => '0',
                                                                                  'strcount' => 0,
                                                                                  'dircount' => 0,
                                                                                  'uncommit' => undef,
                                                                                  'error' => undef,
                                                                                  'patcount' => 0,
                                                                                  'actcount' => 0,
                                                                                  'items' => [
                                                                                               bless( {
                                                                                                        'subrule' => 'controller_statement',
                                                                                                        'expected' => undef,
                                                                                                        'min' => 0,
                                                                                                        'argcode' => undef,
                                                                                                        'max' => 100000000,
                                                                                                        'matchrule' => 0,
                                                                                                        'repspec' => 's?',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 140
                                                                                                      }, 'Parse::RecDescent::Repetition' )
                                                                                             ],
                                                                                  'line' => undef
                                                                                }, 'Parse::RecDescent::Production' )
                                                                       ],
                                                            'name' => 'controller_body',
                                                            'vars' => '',
                                                            'line' => 140
                                                          }, 'Parse::RecDescent::Rule' ),
                              'keyword' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [
                                                                 'IDENT'
                                                               ],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => '0',
                                                                          'strcount' => 0,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'subrule' => 'IDENT',
                                                                                                'matchrule' => 0,
                                                                                                'implicit' => undef,
                                                                                                'argcode' => undef,
                                                                                                'lookahead' => 0,
                                                                                                'line' => 356
                                                                                              }, 'Parse::RecDescent::Subrule' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 356,
                                                                                                'code' => '{
    if ( Bigtop::Parser->is_valid_keyword( $arg[0], $item[1] ) ) {
        $return = $item[1];
    }
    else {
        my @expected = Bigtop::Parser->get_valid_keywords( $arg[0] );
        Bigtop::Parser->fatal_keyword_error(
            {
                bad_keyword   => $item[1],
                diag_text     => $text,
                input_linenum => $thisline,
                expected      => \\@expected,
                type          => $arg[0],
            }
        );
    }
}'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'keyword',
                                                    'vars' => '',
                                                    'line' => 356
                                                  }, 'Parse::RecDescent::Rule' ),
                              'SEMI_COLON' => bless( {
                                                       'impcount' => 0,
                                                       'calls' => [],
                                                       'changed' => 0,
                                                       'opcount' => 0,
                                                       'prods' => [
                                                                    bless( {
                                                                             'number' => '0',
                                                                             'strcount' => 1,
                                                                             'dircount' => 0,
                                                                             'uncommit' => undef,
                                                                             'error' => undef,
                                                                             'patcount' => 0,
                                                                             'actcount' => 0,
                                                                             'items' => [
                                                                                          bless( {
                                                                                                   'pattern' => ';',
                                                                                                   'hashname' => '__STRING1__',
                                                                                                   'description' => '\';\'',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => 420
                                                                                                 }, 'Parse::RecDescent::Literal' )
                                                                                        ],
                                                                             'line' => undef
                                                                           }, 'Parse::RecDescent::Production' ),
                                                                    bless( {
                                                                             'number' => '1',
                                                                             'strcount' => 0,
                                                                             'dircount' => 0,
                                                                             'uncommit' => undef,
                                                                             'error' => undef,
                                                                             'patcount' => 0,
                                                                             'actcount' => 1,
                                                                             'items' => [
                                                                                          bless( {
                                                                                                   'hashname' => '__ACTION1__',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => 421,
                                                                                                   'code' => '{
    my $message = "missing semi-colon";
    if ( $backtick_warning ) {
        $message .= " ($backtick_warning)";
        $backtick_warning = \'\';
    }
    Bigtop::Parser->fatal_error_two_lines(
        $message, $text, $thisline
    );
}'
                                                                                                 }, 'Parse::RecDescent::Action' )
                                                                                        ],
                                                                             'line' => 421
                                                                           }, 'Parse::RecDescent::Production' )
                                                                  ],
                                                       'name' => 'SEMI_COLON',
                                                       'vars' => '',
                                                       'line' => 420
                                                     }, 'Parse::RecDescent::Rule' ),
                              'app_config_block' => bless( {
                                                             'impcount' => 0,
                                                             'calls' => [
                                                                          'CONFIG',
                                                                          'IDENT',
                                                                          'app_config_statement'
                                                                        ],
                                                             'changed' => 0,
                                                             'opcount' => 0,
                                                             'prods' => [
                                                                          bless( {
                                                                                   'number' => '0',
                                                                                   'strcount' => 2,
                                                                                   'dircount' => 0,
                                                                                   'uncommit' => undef,
                                                                                   'error' => undef,
                                                                                   'patcount' => 0,
                                                                                   'actcount' => 1,
                                                                                   'items' => [
                                                                                                bless( {
                                                                                                         'subrule' => 'CONFIG',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => undef,
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 329
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'IDENT',
                                                                                                         'expected' => undef,
                                                                                                         'min' => 0,
                                                                                                         'argcode' => undef,
                                                                                                         'max' => 1,
                                                                                                         'matchrule' => 0,
                                                                                                         'repspec' => '?',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 329
                                                                                                       }, 'Parse::RecDescent::Repetition' ),
                                                                                                bless( {
                                                                                                         'pattern' => '{',
                                                                                                         'hashname' => '__STRING1__',
                                                                                                         'description' => '\'\\{\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 329
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'app_config_statement',
                                                                                                         'expected' => undef,
                                                                                                         'min' => 0,
                                                                                                         'argcode' => undef,
                                                                                                         'max' => 100000000,
                                                                                                         'matchrule' => 0,
                                                                                                         'repspec' => 's?',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 329
                                                                                                       }, 'Parse::RecDescent::Repetition' ),
                                                                                                bless( {
                                                                                                         'pattern' => '}',
                                                                                                         'hashname' => '__STRING2__',
                                                                                                         'description' => '\'\\}\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 329
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'hashname' => '__ACTION1__',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 329,
                                                                                                         'code' => '{
                   bless {
                       __IDENT__ => Bigtop::Parser->get_ident(),
                       __BODY__ => $item{\'app_config_statement(s?)\'},
                       __TYPE__ => $item{\'IDENT(?)\'}[0],
                   }, \'app_config_block\'
                }'
                                                                                                       }, 'Parse::RecDescent::Action' )
                                                                                              ],
                                                                                   'line' => undef
                                                                                 }, 'Parse::RecDescent::Production' )
                                                                        ],
                                                             'name' => 'app_config_block',
                                                             'vars' => '',
                                                             'line' => 329
                                                           }, 'Parse::RecDescent::Rule' ),
                              'controller_block' => bless( {
                                                             'impcount' => 0,
                                                             'calls' => [
                                                                          'controller_body',
                                                                          'module_ident',
                                                                          'is_type'
                                                                        ],
                                                             'changed' => 0,
                                                             'opcount' => 0,
                                                             'prods' => [
                                                                          bless( {
                                                                                   'number' => '0',
                                                                                   'strcount' => 5,
                                                                                   'dircount' => 0,
                                                                                   'uncommit' => undef,
                                                                                   'error' => undef,
                                                                                   'patcount' => 0,
                                                                                   'actcount' => 1,
                                                                                   'items' => [
                                                                                                bless( {
                                                                                                         'pattern' => 'controller',
                                                                                                         'hashname' => '__STRING1__',
                                                                                                         'description' => '\'controller\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 103
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'pattern' => 'is',
                                                                                                         'hashname' => '__STRING2__',
                                                                                                         'description' => '\'is\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 103
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'pattern' => 'base_controller',
                                                                                                         'hashname' => '__STRING3__',
                                                                                                         'description' => '\'base_controller\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 103
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'pattern' => '{',
                                                                                                         'hashname' => '__STRING4__',
                                                                                                         'description' => '\'\\{\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 103
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'controller_body',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => '[ \'base_controller\' ]',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 104
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'pattern' => '}',
                                                                                                         'hashname' => '__STRING5__',
                                                                                                         'description' => '\'\\}\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 105
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'hashname' => '__ACTION1__',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 105,
                                                                                                         'code' => '{
                        bless {
                            __IDENT__ => Bigtop::Parser->get_ident(),
                            __BODY__  => $item{controller_body}
                                              {\'controller_statement(s?)\'},
                            __NAME__  => \'base_controller\',
                            __TYPE__  => \'base_controller\',
                        }, \'controller_block\'
                    }'
                                                                                                       }, 'Parse::RecDescent::Action' )
                                                                                              ],
                                                                                   'line' => undef
                                                                                 }, 'Parse::RecDescent::Production' ),
                                                                          bless( {
                                                                                   'number' => '1',
                                                                                   'strcount' => 3,
                                                                                   'dircount' => 0,
                                                                                   'uncommit' => undef,
                                                                                   'error' => undef,
                                                                                   'patcount' => 0,
                                                                                   'actcount' => 1,
                                                                                   'items' => [
                                                                                                bless( {
                                                                                                         'pattern' => 'controller',
                                                                                                         'hashname' => '__STRING1__',
                                                                                                         'description' => '\'controller\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 114
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'module_ident',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => undef,
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 114
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'is_type',
                                                                                                         'expected' => undef,
                                                                                                         'min' => 0,
                                                                                                         'argcode' => undef,
                                                                                                         'max' => 1,
                                                                                                         'matchrule' => 0,
                                                                                                         'repspec' => '?',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 114
                                                                                                       }, 'Parse::RecDescent::Repetition' ),
                                                                                                bless( {
                                                                                                         'pattern' => '{',
                                                                                                         'hashname' => '__STRING2__',
                                                                                                         'description' => '\'\\{\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 114
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'controller_body',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => '[ $item{module_ident} ]',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 115
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'pattern' => '}',
                                                                                                         'hashname' => '__STRING3__',
                                                                                                         'description' => '\'\\}\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 116
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'hashname' => '__ACTION1__',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 116,
                                                                                                         'code' => '{
                        if ( defined $item{\'is_type(?)\'}[0]
                                and
                             $item{\'is_type(?)\'}[0] eq \'base_controller\'
                        ) {
                            my $message = "base_controller cannot have an "
                                        . "explicit name";
                            my $diag_text = "controller $item{module_ident} "
                                          . "is base_controller";
                            Bigtop::Parser->fatal_error_two_lines(
                                $message, $diag_text, $thisline
                            );
                        }
                        bless {
                            __IDENT__ => Bigtop::Parser->get_ident(),
                            __NAME__  => $item{module_ident},
                            __BODY__  => $item{controller_body}
                                              {\'controller_statement(s?)\'},
                            __TYPE__        => $item{\'is_type(?)\'}[0],
                        }, \'controller_block\'
                   }'
                                                                                                       }, 'Parse::RecDescent::Action' )
                                                                                              ],
                                                                                   'line' => 114
                                                                                 }, 'Parse::RecDescent::Production' )
                                                                        ],
                                                             'name' => 'controller_block',
                                                             'vars' => '',
                                                             'line' => 103
                                                           }, 'Parse::RecDescent::Rule' ),
                              'field_body' => bless( {
                                                       'impcount' => 0,
                                                       'calls' => [
                                                                    'field_statement'
                                                                  ],
                                                       'changed' => 0,
                                                       'opcount' => 0,
                                                       'prods' => [
                                                                    bless( {
                                                                             'number' => '0',
                                                                             'strcount' => 0,
                                                                             'dircount' => 0,
                                                                             'uncommit' => undef,
                                                                             'error' => undef,
                                                                             'patcount' => 0,
                                                                             'actcount' => 0,
                                                                             'items' => [
                                                                                          bless( {
                                                                                                   'subrule' => 'field_statement',
                                                                                                   'expected' => undef,
                                                                                                   'min' => 0,
                                                                                                   'argcode' => undef,
                                                                                                   'max' => 100000000,
                                                                                                   'matchrule' => 0,
                                                                                                   'repspec' => 's?',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => 283
                                                                                                 }, 'Parse::RecDescent::Repetition' )
                                                                                        ],
                                                                             'line' => undef
                                                                           }, 'Parse::RecDescent::Production' )
                                                                  ],
                                                       'name' => 'field_body',
                                                       'vars' => '',
                                                       'line' => 283
                                                     }, 'Parse::RecDescent::Rule' ),
                              'CONFIG' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => '0',
                                                                         'strcount' => 1,
                                                                         'dircount' => 0,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 0,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'pattern' => 'config',
                                                                                               'hashname' => '__STRING1__',
                                                                                               'description' => '\'config\'',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 414
                                                                                             }, 'Parse::RecDescent::Literal' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' ),
                                                                bless( {
                                                                         'number' => '1',
                                                                         'strcount' => 1,
                                                                         'dircount' => 0,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 0,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'pattern' => 'set_vars',
                                                                                               'hashname' => '__STRING1__',
                                                                                               'description' => '\'set_vars\'',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 414
                                                                                             }, 'Parse::RecDescent::Literal' )
                                                                                    ],
                                                                         'line' => 414
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'CONFIG',
                                                   'vars' => '',
                                                   'line' => 414
                                                 }, 'Parse::RecDescent::Rule' ),
                              'config_body' => bless( {
                                                        'impcount' => 0,
                                                        'calls' => [
                                                                     'config_statement'
                                                                   ],
                                                        'changed' => 0,
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'number' => '0',
                                                                              'strcount' => 0,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'subrule' => 'config_statement',
                                                                                                    'expected' => undef,
                                                                                                    'min' => 0,
                                                                                                    'argcode' => undef,
                                                                                                    'max' => 100000000,
                                                                                                    'matchrule' => 0,
                                                                                                    'repspec' => 's?',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 19
                                                                                                  }, 'Parse::RecDescent::Repetition' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 19,
                                                                                                    'code' => '{
    my %config;
    my %backend_lookup;
    my @statements;
    foreach my $statement ( @{ $item{\'config_statement(s?)\'} } ) {
        $config{ $statement->[0] } = $statement->[1];
        push @statements, [ $statement->[0], $statement->[1] ];

        if ( ref( $statement->[1] ) eq \'HASH\' ) {
            push @{ $backend_lookup{ $statement->[0] } }, $statement->[1];
        }
    }
    $config{__STATEMENTS__} = \\@statements;
    $config{__BACKENDS__}   = \\%backend_lookup;
    $return = \\%config;
}'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'config_body',
                                                        'vars' => '',
                                                        'line' => 17
                                                      }, 'Parse::RecDescent::Rule' ),
                              'extra_sql_statement' => bless( {
                                                                'impcount' => 0,
                                                                'calls' => [
                                                                             'keyword',
                                                                             'extra_sql_statement_def',
                                                                             'SEMI_COLON'
                                                                           ],
                                                                'changed' => 0,
                                                                'opcount' => 0,
                                                                'prods' => [
                                                                             bless( {
                                                                                      'number' => '0',
                                                                                      'strcount' => 0,
                                                                                      'dircount' => 0,
                                                                                      'uncommit' => undef,
                                                                                      'error' => undef,
                                                                                      'patcount' => 0,
                                                                                      'actcount' => 1,
                                                                                      'items' => [
                                                                                                   bless( {
                                                                                                            'subrule' => 'keyword',
                                                                                                            'matchrule' => 0,
                                                                                                            'implicit' => undef,
                                                                                                            'argcode' => '[\'extra_sql\']',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 299
                                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                                   bless( {
                                                                                                            'subrule' => 'extra_sql_statement_def',
                                                                                                            'matchrule' => 0,
                                                                                                            'implicit' => undef,
                                                                                                            'argcode' => undef,
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 299
                                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                                   bless( {
                                                                                                            'subrule' => 'SEMI_COLON',
                                                                                                            'matchrule' => 0,
                                                                                                            'implicit' => undef,
                                                                                                            'argcode' => undef,
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 299
                                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                                   bless( {
                                                                                                            'hashname' => '__ACTION1__',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 299,
                                                                                                            'code' => '{
                        bless {
                            __KEYWORD__ => $item[1], __DEF__ => $item[2]
                        }, \'extra_sql_statement\'
                      }'
                                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                                 ],
                                                                                      'line' => undef
                                                                                    }, 'Parse::RecDescent::Production' )
                                                                           ],
                                                                'name' => 'extra_sql_statement',
                                                                'vars' => '',
                                                                'line' => 299
                                                              }, 'Parse::RecDescent::Rule' ),
                              'app_body' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [
                                                                  'block'
                                                                ],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => '0',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 0,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'block',
                                                                                                 'expected' => undef,
                                                                                                 'min' => 0,
                                                                                                 'argcode' => undef,
                                                                                                 'max' => 100000000,
                                                                                                 'matchrule' => 0,
                                                                                                 'repspec' => 's?',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 79
                                                                                               }, 'Parse::RecDescent::Repetition' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'app_body',
                                                     'vars' => '',
                                                     'line' => 79
                                                   }, 'Parse::RecDescent::Rule' ),
                              'arg_list' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [
                                                                  'arg',
                                                                  'arg_list'
                                                                ],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => '0',
                                                                           'strcount' => 1,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'arg',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 374
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'pattern' => ',',
                                                                                                 'hashname' => '__STRING1__',
                                                                                                 'description' => '\',\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 374
                                                                                               }, 'Parse::RecDescent::Literal' ),
                                                                                        bless( {
                                                                                                 'subrule' => 'arg_list',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 374
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 374,
                                                                                                 'code' => '{
               unshift @{ $item[3] }, $item[1];
               $return = $item[3];
           }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' ),
                                                                  bless( {
                                                                           'number' => '1',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'arg',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 378
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 378,
                                                                                                 'code' => '{ bless [ $item[1] ], \'arg_list\' }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => 378
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'arg_list',
                                                     'vars' => '',
                                                     'line' => 374
                                                   }, 'Parse::RecDescent::Rule' ),
                              'is_type' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [
                                                                 'module_ident'
                                                               ],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => '0',
                                                                          'strcount' => 1,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => 'is',
                                                                                                'hashname' => '__STRING1__',
                                                                                                'description' => '\'is\'',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 138
                                                                                              }, 'Parse::RecDescent::Literal' ),
                                                                                       bless( {
                                                                                                'subrule' => 'module_ident',
                                                                                                'matchrule' => 0,
                                                                                                'implicit' => undef,
                                                                                                'argcode' => undef,
                                                                                                'lookahead' => 0,
                                                                                                'line' => 138
                                                                                              }, 'Parse::RecDescent::Subrule' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 138,
                                                                                                'code' => '{ $item{module_ident} }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'is_type',
                                                    'vars' => '',
                                                    'line' => 138
                                                  }, 'Parse::RecDescent::Rule' ),
                              'table_element_block' => bless( {
                                                                'impcount' => 0,
                                                                'calls' => [
                                                                             'IDENT',
                                                                             'field_body',
                                                                             'extra_sql_body',
                                                                             'keyword',
                                                                             'arg_list',
                                                                             'SEMI_COLON'
                                                                           ],
                                                                'changed' => 0,
                                                                'opcount' => 0,
                                                                'prods' => [
                                                                             bless( {
                                                                                      'number' => '0',
                                                                                      'strcount' => 3,
                                                                                      'dircount' => 1,
                                                                                      'uncommit' => undef,
                                                                                      'error' => undef,
                                                                                      'patcount' => 0,
                                                                                      'actcount' => 1,
                                                                                      'items' => [
                                                                                                   bless( {
                                                                                                            'pattern' => 'field',
                                                                                                            'hashname' => '__STRING1__',
                                                                                                            'description' => '\'field\'',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 255
                                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                                   bless( {
                                                                                                            'hashname' => '__DIRECTIVE1__',
                                                                                                            'name' => '<commit>',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 255,
                                                                                                            'code' => '$commit = 1'
                                                                                                          }, 'Parse::RecDescent::Directive' ),
                                                                                                   bless( {
                                                                                                            'subrule' => 'IDENT',
                                                                                                            'matchrule' => 0,
                                                                                                            'implicit' => undef,
                                                                                                            'argcode' => undef,
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 255
                                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                                   bless( {
                                                                                                            'pattern' => '{',
                                                                                                            'hashname' => '__STRING2__',
                                                                                                            'description' => '\'\\{\'',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 255
                                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                                   bless( {
                                                                                                            'subrule' => 'field_body',
                                                                                                            'matchrule' => 0,
                                                                                                            'implicit' => undef,
                                                                                                            'argcode' => undef,
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 255
                                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                                   bless( {
                                                                                                            'pattern' => '}',
                                                                                                            'hashname' => '__STRING3__',
                                                                                                            'description' => '\'\\}\'',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 255
                                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                                   bless( {
                                                                                                            'hashname' => '__ACTION1__',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 255,
                                                                                                            'code' => '{
                           bless {
                               __IDENT__ => Bigtop::Parser->get_ident(),
                               __TYPE__  => \'field\',
                               __NAME__  => $item{IDENT},
                               __BODY__  =>
                                    $item{field_body}{\'field_statement(s?)\'},
                           }, \'table_element_block\'
                       }'
                                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                                 ],
                                                                                      'line' => undef
                                                                                    }, 'Parse::RecDescent::Production' ),
                                                                             bless( {
                                                                                      'number' => '1',
                                                                                      'strcount' => 3,
                                                                                      'dircount' => 1,
                                                                                      'uncommit' => undef,
                                                                                      'error' => undef,
                                                                                      'patcount' => 0,
                                                                                      'actcount' => 1,
                                                                                      'items' => [
                                                                                                   bless( {
                                                                                                            'pattern' => 'extra_sql',
                                                                                                            'hashname' => '__STRING1__',
                                                                                                            'description' => '\'extra_sql\'',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 264
                                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                                   bless( {
                                                                                                            'hashname' => '__DIRECTIVE1__',
                                                                                                            'name' => '<commit>',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 264,
                                                                                                            'code' => '$commit = 1'
                                                                                                          }, 'Parse::RecDescent::Directive' ),
                                                                                                   bless( {
                                                                                                            'subrule' => 'IDENT',
                                                                                                            'matchrule' => 0,
                                                                                                            'implicit' => undef,
                                                                                                            'argcode' => undef,
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 264
                                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                                   bless( {
                                                                                                            'pattern' => '{',
                                                                                                            'hashname' => '__STRING2__',
                                                                                                            'description' => '\'\\{\'',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 264
                                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                                   bless( {
                                                                                                            'subrule' => 'extra_sql_body',
                                                                                                            'matchrule' => 0,
                                                                                                            'implicit' => undef,
                                                                                                            'argcode' => undef,
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 264
                                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                                   bless( {
                                                                                                            'pattern' => '}',
                                                                                                            'hashname' => '__STRING3__',
                                                                                                            'description' => '\'\\}\'',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 264
                                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                                   bless( {
                                                                                                            'hashname' => '__ACTION1__',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 264,
                                                                                                            'code' => '{
                           bless {
                               __IDENT__ => Bigtop::Parser->get_ident(),
                               __TYPE__  => \'extra_sql\',
                               __NAME__  => $item{IDENT},
                               __BODY__  =>
                                    $item{extra_sql_body}
                                         {\'extra_sql_statement(s?)\'},
                           }, \'extra_sql_block\'
                       }'
                                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                                 ],
                                                                                      'line' => 264
                                                                                    }, 'Parse::RecDescent::Production' ),
                                                                             bless( {
                                                                                      'number' => '2',
                                                                                      'strcount' => 0,
                                                                                      'dircount' => 0,
                                                                                      'uncommit' => undef,
                                                                                      'error' => undef,
                                                                                      'patcount' => 0,
                                                                                      'actcount' => 1,
                                                                                      'items' => [
                                                                                                   bless( {
                                                                                                            'subrule' => 'keyword',
                                                                                                            'matchrule' => 0,
                                                                                                            'implicit' => undef,
                                                                                                            'argcode' => '[\'table\']',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 274
                                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                                   bless( {
                                                                                                            'subrule' => 'arg_list',
                                                                                                            'matchrule' => 0,
                                                                                                            'implicit' => undef,
                                                                                                            'argcode' => undef,
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 274
                                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                                   bless( {
                                                                                                            'subrule' => 'SEMI_COLON',
                                                                                                            'matchrule' => 0,
                                                                                                            'implicit' => undef,
                                                                                                            'argcode' => undef,
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 274
                                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                                   bless( {
                                                                                                            'hashname' => '__ACTION1__',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 274,
                                                                                                            'code' => '{
                           bless {
                               __TYPE__  => $item[1],
                               __ARGS__  => $item[2],
                               __BODY__  => $item[1],
                           }, \'table_element_block\'
                       }'
                                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                                 ],
                                                                                      'line' => 274
                                                                                    }, 'Parse::RecDescent::Production' ),
                                                                             bless( {
                                                                                      'number' => '3',
                                                                                      'strcount' => 0,
                                                                                      'dircount' => 1,
                                                                                      'uncommit' => 0,
                                                                                      'error' => 1,
                                                                                      'patcount' => 0,
                                                                                      'actcount' => 0,
                                                                                      'items' => [
                                                                                                   bless( {
                                                                                                            'msg' => '',
                                                                                                            'hashname' => '__DIRECTIVE1__',
                                                                                                            'commitonly' => '',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => 281
                                                                                                          }, 'Parse::RecDescent::Error' )
                                                                                                 ],
                                                                                      'line' => 281
                                                                                    }, 'Parse::RecDescent::Production' )
                                                                           ],
                                                                'name' => 'table_element_block',
                                                                'vars' => '',
                                                                'line' => 255
                                                              }, 'Parse::RecDescent::Rule' ),
                              'text' => bless( {
                                                 'impcount' => 0,
                                                 'calls' => [],
                                                 'changed' => 0,
                                                 'opcount' => 0,
                                                 'prods' => [
                                                              bless( {
                                                                       'number' => '0',
                                                                       'strcount' => 0,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 1,
                                                                       'actcount' => 1,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'pattern' => '[^`]*',
                                                                                             'hashname' => '__PATTERN1__',
                                                                                             'description' => '/[^`]*/',
                                                                                             'lookahead' => 0,
                                                                                             'rdelim' => '/',
                                                                                             'line' => 404,
                                                                                             'mod' => '',
                                                                                             'ldelim' => '/'
                                                                                           }, 'Parse::RecDescent::Token' ),
                                                                                    bless( {
                                                                                             'hashname' => '__ACTION1__',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 404,
                                                                                             'code' => '{
    my @lines = split /\\n/, $item[1];
    if ( @lines > 1 ) {
        $backtick_warning
            = "possible run-away string beginning on line "
            . "$backtick_line.";
    }
    $item[1];
}'
                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'text',
                                                 'vars' => '',
                                                 'line' => 404
                                               }, 'Parse::RecDescent::Rule' ),
                              'sequence_statement' => bless( {
                                                               'impcount' => 0,
                                                               'calls' => [
                                                                            'IDENT',
                                                                            'arg_list',
                                                                            'SEMI_COLON'
                                                                          ],
                                                               'changed' => 0,
                                                               'opcount' => 0,
                                                               'prods' => [
                                                                            bless( {
                                                                                     'number' => '0',
                                                                                     'strcount' => 0,
                                                                                     'dircount' => 0,
                                                                                     'uncommit' => undef,
                                                                                     'error' => undef,
                                                                                     'patcount' => 0,
                                                                                     'actcount' => 1,
                                                                                     'items' => [
                                                                                                  bless( {
                                                                                                           'subrule' => 'IDENT',
                                                                                                           'matchrule' => 0,
                                                                                                           'implicit' => undef,
                                                                                                           'argcode' => undef,
                                                                                                           'lookahead' => 0,
                                                                                                           'line' => 247
                                                                                                         }, 'Parse::RecDescent::Subrule' ),
                                                                                                  bless( {
                                                                                                           'subrule' => 'arg_list',
                                                                                                           'matchrule' => 0,
                                                                                                           'implicit' => undef,
                                                                                                           'argcode' => undef,
                                                                                                           'lookahead' => 0,
                                                                                                           'line' => 247
                                                                                                         }, 'Parse::RecDescent::Subrule' ),
                                                                                                  bless( {
                                                                                                           'subrule' => 'SEMI_COLON',
                                                                                                           'matchrule' => 0,
                                                                                                           'implicit' => undef,
                                                                                                           'argcode' => undef,
                                                                                                           'lookahead' => 0,
                                                                                                           'line' => 247
                                                                                                         }, 'Parse::RecDescent::Subrule' ),
                                                                                                  bless( {
                                                                                                           'hashname' => '__ACTION1__',
                                                                                                           'lookahead' => 0,
                                                                                                           'line' => 247,
                                                                                                           'code' => '{
        bless {
            __NAME__ => $item[1], __ARGS__ => $item{arg_list}
        }, \'sequence_statement\'
    }'
                                                                                                         }, 'Parse::RecDescent::Action' )
                                                                                                ],
                                                                                     'line' => undef
                                                                                   }, 'Parse::RecDescent::Production' )
                                                                          ],
                                                               'name' => 'sequence_statement',
                                                               'vars' => '',
                                                               'line' => 246
                                                             }, 'Parse::RecDescent::Rule' ),
                              'module_ident' => bless( {
                                                         'impcount' => 0,
                                                         'calls' => [
                                                                      'IDENT',
                                                                      'module_ident'
                                                                    ],
                                                         'changed' => 0,
                                                         'opcount' => 0,
                                                         'prods' => [
                                                                      bless( {
                                                                               'number' => '0',
                                                                               'strcount' => 1,
                                                                               'dircount' => 0,
                                                                               'uncommit' => undef,
                                                                               'error' => undef,
                                                                               'patcount' => 0,
                                                                               'actcount' => 1,
                                                                               'items' => [
                                                                                            bless( {
                                                                                                     'subrule' => 'IDENT',
                                                                                                     'matchrule' => 0,
                                                                                                     'implicit' => undef,
                                                                                                     'argcode' => undef,
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 399
                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                            bless( {
                                                                                                     'pattern' => '::',
                                                                                                     'hashname' => '__STRING1__',
                                                                                                     'description' => '\'::\'',
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 399
                                                                                                   }, 'Parse::RecDescent::Literal' ),
                                                                                            bless( {
                                                                                                     'subrule' => 'module_ident',
                                                                                                     'matchrule' => 0,
                                                                                                     'implicit' => undef,
                                                                                                     'argcode' => undef,
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 399
                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                            bless( {
                                                                                                     'hashname' => '__ACTION1__',
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 399,
                                                                                                     'code' => '{ $item[1] . \'::\' . $item[3] }'
                                                                                                   }, 'Parse::RecDescent::Action' )
                                                                                          ],
                                                                               'line' => undef
                                                                             }, 'Parse::RecDescent::Production' ),
                                                                      bless( {
                                                                               'number' => '1',
                                                                               'strcount' => 0,
                                                                               'dircount' => 0,
                                                                               'uncommit' => undef,
                                                                               'error' => undef,
                                                                               'patcount' => 0,
                                                                               'actcount' => 1,
                                                                               'items' => [
                                                                                            bless( {
                                                                                                     'subrule' => 'IDENT',
                                                                                                     'matchrule' => 0,
                                                                                                     'implicit' => undef,
                                                                                                     'argcode' => undef,
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 400
                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                            bless( {
                                                                                                     'hashname' => '__ACTION1__',
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 400,
                                                                                                     'code' => '{ $item[1] }'
                                                                                                   }, 'Parse::RecDescent::Action' )
                                                                                          ],
                                                                               'line' => 400
                                                                             }, 'Parse::RecDescent::Production' )
                                                                    ],
                                                         'name' => 'module_ident',
                                                         'vars' => '',
                                                         'line' => 399
                                                       }, 'Parse::RecDescent::Rule' ),
                              'bigtop_file' => bless( {
                                                        'impcount' => 0,
                                                        'calls' => [
                                                                     'configuration',
                                                                     'application'
                                                                   ],
                                                        'changed' => 0,
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'number' => '0',
                                                                              'strcount' => 0,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 0,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'subrule' => 'configuration',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 15
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'application',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 15
                                                                                                  }, 'Parse::RecDescent::Subrule' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'bigtop_file',
                                                        'vars' => '',
                                                        'line' => 15
                                                      }, 'Parse::RecDescent::Rule' ),
                              'sequence_body' => bless( {
                                                          'impcount' => 0,
                                                          'calls' => [
                                                                       'sequence_statement'
                                                                     ],
                                                          'changed' => 0,
                                                          'opcount' => 0,
                                                          'prods' => [
                                                                       bless( {
                                                                                'number' => '0',
                                                                                'strcount' => 0,
                                                                                'dircount' => 0,
                                                                                'uncommit' => undef,
                                                                                'error' => undef,
                                                                                'patcount' => 0,
                                                                                'actcount' => 0,
                                                                                'items' => [
                                                                                             bless( {
                                                                                                      'subrule' => 'sequence_statement',
                                                                                                      'expected' => undef,
                                                                                                      'min' => 0,
                                                                                                      'argcode' => undef,
                                                                                                      'max' => 100000000,
                                                                                                      'matchrule' => 0,
                                                                                                      'repspec' => 's?',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 244
                                                                                                    }, 'Parse::RecDescent::Repetition' )
                                                                                           ],
                                                                                'line' => undef
                                                                              }, 'Parse::RecDescent::Production' )
                                                                     ],
                                                          'name' => 'sequence_body',
                                                          'vars' => '',
                                                          'line' => 244
                                                        }, 'Parse::RecDescent::Rule' ),
                              'application' => bless( {
                                                        'impcount' => 0,
                                                        'calls' => [
                                                                     'module_ident',
                                                                     'app_body'
                                                                   ],
                                                        'changed' => 0,
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'number' => '0',
                                                                              'strcount' => 3,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'pattern' => 'app',
                                                                                                    'hashname' => '__STRING1__',
                                                                                                    'description' => '\'app\'',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 61
                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'module_ident',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 61
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'pattern' => '{',
                                                                                                    'hashname' => '__STRING2__',
                                                                                                    'description' => '\'\\{\'',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 61
                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'app_body',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 61
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'pattern' => '}',
                                                                                                    'hashname' => '__STRING3__',
                                                                                                    'description' => '\'\\}\'',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 61
                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 61,
                                                                                                    'code' => '{
                  my $retval = bless {
                      __NAME__ => $item{module_ident},
                      __BODY__ => $item{app_body},
                  }, \'application\';

                  $retval->walk_postorder( \'set_parent\' );

                  my $lookup_hash = $retval->walk_postorder(
                        \'build_lookup_hash\'
                  );

                  $retval->{lookup} = { @{ $lookup_hash } };

                  $retval;
              }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' ),
                                                                     bless( {
                                                                              'number' => '1',
                                                                              'strcount' => 0,
                                                                              'dircount' => 1,
                                                                              'uncommit' => 0,
                                                                              'error' => 1,
                                                                              'patcount' => 0,
                                                                              'actcount' => 0,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'msg' => '',
                                                                                                    'hashname' => '__DIRECTIVE1__',
                                                                                                    'commitonly' => '',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 77
                                                                                                  }, 'Parse::RecDescent::Error' )
                                                                                         ],
                                                                              'line' => 77
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'application',
                                                        'vars' => '',
                                                        'line' => 61
                                                      }, 'Parse::RecDescent::Rule' ),
                              'controller_config_statement' => bless( {
                                                                        'impcount' => 0,
                                                                        'calls' => [
                                                                                     'IDENT',
                                                                                     'arg_list',
                                                                                     'SEMI_COLON'
                                                                                   ],
                                                                        'changed' => 0,
                                                                        'opcount' => 0,
                                                                        'prods' => [
                                                                                     bless( {
                                                                                              'number' => '0',
                                                                                              'strcount' => 0,
                                                                                              'dircount' => 0,
                                                                                              'uncommit' => undef,
                                                                                              'error' => undef,
                                                                                              'patcount' => 0,
                                                                                              'actcount' => 1,
                                                                                              'items' => [
                                                                                                           bless( {
                                                                                                                    'subrule' => 'IDENT',
                                                                                                                    'matchrule' => 0,
                                                                                                                    'implicit' => undef,
                                                                                                                    'argcode' => undef,
                                                                                                                    'lookahead' => 0,
                                                                                                                    'line' => 181
                                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                                           bless( {
                                                                                                                    'subrule' => 'arg_list',
                                                                                                                    'matchrule' => 0,
                                                                                                                    'implicit' => undef,
                                                                                                                    'argcode' => undef,
                                                                                                                    'lookahead' => 0,
                                                                                                                    'line' => 181
                                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                                           bless( {
                                                                                                                    'subrule' => 'SEMI_COLON',
                                                                                                                    'matchrule' => 0,
                                                                                                                    'implicit' => undef,
                                                                                                                    'argcode' => undef,
                                                                                                                    'lookahead' => 0,
                                                                                                                    'line' => 181
                                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                                           bless( {
                                                                                                                    'hashname' => '__ACTION1__',
                                                                                                                    'lookahead' => 0,
                                                                                                                    'line' => 181,
                                                                                                                    'code' => '{
                        bless {
                            __KEYWORD__ => $item{IDENT},
                            __ARGS__    => $item{arg_list}
                        }, \'controller_config_statement\'
                    }'
                                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                                         ],
                                                                                              'line' => undef
                                                                                            }, 'Parse::RecDescent::Production' ),
                                                                                     bless( {
                                                                                              'number' => '1',
                                                                                              'strcount' => 0,
                                                                                              'dircount' => 0,
                                                                                              'uncommit' => undef,
                                                                                              'error' => undef,
                                                                                              'patcount' => 1,
                                                                                              'actcount' => 1,
                                                                                              'items' => [
                                                                                                           bless( {
                                                                                                                    'pattern' => '[^\\}]',
                                                                                                                    'hashname' => '__PATTERN1__',
                                                                                                                    'description' => '/[^\\\\\\}]/',
                                                                                                                    'lookahead' => 0,
                                                                                                                    'rdelim' => '/',
                                                                                                                    'line' => 187,
                                                                                                                    'mod' => '',
                                                                                                                    'ldelim' => '/'
                                                                                                                  }, 'Parse::RecDescent::Token' ),
                                                                                                           bless( {
                                                                                                                    'hashname' => '__ACTION1__',
                                                                                                                    'lookahead' => 0,
                                                                                                                    'line' => 187,
                                                                                                                    'code' => '{
                            my $message = "bad config statement, "
                                        . "possible extra semicolon";
                            if ( $backtick_warning ) {
                                $message .= " ($backtick_warning)";
                                $backtick_warning = \'\';
                            }
                            my $diag_text = $item[1] . $text;
                            Bigtop::Parser->fatal_error_two_lines(
                                $message, $diag_text, $thisline
                            );
                      }'
                                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                                         ],
                                                                                              'line' => 187
                                                                                            }, 'Parse::RecDescent::Production' )
                                                                                   ],
                                                                        'name' => 'controller_config_statement',
                                                                        'vars' => '',
                                                                        'line' => 181
                                                                      }, 'Parse::RecDescent::Rule' ),
                              'block' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [
                                                               'literal_block',
                                                               'controller_block',
                                                               'sql_block',
                                                               'app_config_block',
                                                               'app_statement'
                                                             ],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => '0',
                                                                        'strcount' => 0,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 0,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'subrule' => 'literal_block',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 81
                                                                                            }, 'Parse::RecDescent::Subrule' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' ),
                                                               bless( {
                                                                        'number' => '1',
                                                                        'strcount' => 0,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 0,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'subrule' => 'controller_block',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 82
                                                                                            }, 'Parse::RecDescent::Subrule' )
                                                                                   ],
                                                                        'line' => 82
                                                                      }, 'Parse::RecDescent::Production' ),
                                                               bless( {
                                                                        'number' => '2',
                                                                        'strcount' => 0,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 0,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'subrule' => 'sql_block',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 83
                                                                                            }, 'Parse::RecDescent::Subrule' )
                                                                                   ],
                                                                        'line' => 83
                                                                      }, 'Parse::RecDescent::Production' ),
                                                               bless( {
                                                                        'number' => '3',
                                                                        'strcount' => 0,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 0,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'subrule' => 'app_config_block',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 84
                                                                                            }, 'Parse::RecDescent::Subrule' )
                                                                                   ],
                                                                        'line' => 84
                                                                      }, 'Parse::RecDescent::Production' ),
                                                               bless( {
                                                                        'number' => '4',
                                                                        'strcount' => 0,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 0,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'subrule' => 'app_statement',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 85
                                                                                            }, 'Parse::RecDescent::Subrule' )
                                                                                   ],
                                                                        'line' => 85
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'block',
                                                  'vars' => '',
                                                  'line' => 81
                                                }, 'Parse::RecDescent::Rule' ),
                              'sql_block' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'table_ident',
                                                                   'sequence_body',
                                                                   'table_body',
                                                                   'join_table_body',
                                                                   'IDENT'
                                                                 ],
                                                      'changed' => 0,
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'number' => '0',
                                                                            'strcount' => 3,
                                                                            'dircount' => 1,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => 'sequence',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'sequence\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 211
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__DIRECTIVE1__',
                                                                                                  'name' => '<commit>',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 211,
                                                                                                  'code' => '$commit = 1'
                                                                                                }, 'Parse::RecDescent::Directive' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'table_ident',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 211
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'pattern' => '{',
                                                                                                  'hashname' => '__STRING2__',
                                                                                                  'description' => '\'\\{\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 211
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'sequence_body',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 211
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'pattern' => '}',
                                                                                                  'hashname' => '__STRING3__',
                                                                                                  'description' => '\'\\}\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 211
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 211,
                                                                                                  'code' => '{
                bless {
                            __IDENT__ => Bigtop::Parser->get_ident(),
                            __NAME__  => $item{table_ident},
                            __TYPE__  => \'sequences\',
                            __BODY__  => $item{sequence_body}
                                              {\'sequence_statement(s?)\'},
                }, \'seq_block\'
            }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => '1',
                                                                            'strcount' => 3,
                                                                            'dircount' => 1,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => 'table',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'table\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 220
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__DIRECTIVE1__',
                                                                                                  'name' => '<commit>',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 220,
                                                                                                  'code' => '$commit = 1'
                                                                                                }, 'Parse::RecDescent::Directive' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'table_ident',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 220
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'pattern' => '{',
                                                                                                  'hashname' => '__STRING2__',
                                                                                                  'description' => '\'\\{\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 220
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'table_body',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 220
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'pattern' => '}',
                                                                                                  'hashname' => '__STRING3__',
                                                                                                  'description' => '\'\\}\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 220
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 220,
                                                                                                  'code' => '{
                bless {
                            __IDENT__ => Bigtop::Parser->get_ident(),
                            __NAME__  => $item{table_ident},
                            __TYPE__  => \'tables\',
                            __BODY__  => $item{table_body}
                                              {\'table_element_block(s?)\'},
                }, \'table_block\'
            }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => 220
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => '2',
                                                                            'strcount' => 3,
                                                                            'dircount' => 1,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => 'join_table',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'join_table\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 229
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__DIRECTIVE1__',
                                                                                                  'name' => '<commit>',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 229,
                                                                                                  'code' => '$commit = 1'
                                                                                                }, 'Parse::RecDescent::Directive' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'table_ident',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 229
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'pattern' => '{',
                                                                                                  'hashname' => '__STRING2__',
                                                                                                  'description' => '\'\\{\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 229
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'join_table_body',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 229
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'pattern' => '}',
                                                                                                  'hashname' => '__STRING3__',
                                                                                                  'description' => '\'\\}\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 229
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 229,
                                                                                                  'code' => '{
                bless {
                            __IDENT__ => Bigtop::Parser->get_ident(),
                            __NAME__  => $item{table_ident},
                            __BODY__  => $item{join_table_body}
                                              {\'join_table_statement(s?)\'},
                }, \'join_table\'
            }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => 229
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => '3',
                                                                            'strcount' => 3,
                                                                            'dircount' => 1,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => 'schema',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'schema\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 237
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__DIRECTIVE1__',
                                                                                                  'name' => '<commit>',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 237,
                                                                                                  'code' => '$commit = 1'
                                                                                                }, 'Parse::RecDescent::Directive' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'IDENT',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 237
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'pattern' => '{',
                                                                                                  'hashname' => '__STRING2__',
                                                                                                  'description' => '\'\\{\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 237
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'pattern' => '}',
                                                                                                  'hashname' => '__STRING3__',
                                                                                                  'description' => '\'\\}\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 237
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 237,
                                                                                                  'code' => '{
                bless {
                            __IDENT__ => Bigtop::Parser->get_ident(),
                            __NAME__  => $item{ IDENT },
                }, \'schema_block\'
            }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => 237
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'sql_block',
                                                      'vars' => '',
                                                      'line' => 211
                                                    }, 'Parse::RecDescent::Rule' ),
                              'extra_sql_body' => bless( {
                                                           'impcount' => 0,
                                                           'calls' => [
                                                                        'extra_sql_statement'
                                                                      ],
                                                           'changed' => 0,
                                                           'opcount' => 0,
                                                           'prods' => [
                                                                        bless( {
                                                                                 'number' => '0',
                                                                                 'strcount' => 0,
                                                                                 'dircount' => 0,
                                                                                 'uncommit' => undef,
                                                                                 'error' => undef,
                                                                                 'patcount' => 0,
                                                                                 'actcount' => 0,
                                                                                 'items' => [
                                                                                              bless( {
                                                                                                       'subrule' => 'extra_sql_statement',
                                                                                                       'expected' => undef,
                                                                                                       'min' => 0,
                                                                                                       'argcode' => undef,
                                                                                                       'max' => 100000000,
                                                                                                       'matchrule' => 0,
                                                                                                       'repspec' => 's?',
                                                                                                       'lookahead' => 0,
                                                                                                       'line' => 297
                                                                                                     }, 'Parse::RecDescent::Repetition' )
                                                                                            ],
                                                                                 'line' => undef
                                                                               }, 'Parse::RecDescent::Production' )
                                                                      ],
                                                           'name' => 'extra_sql_body',
                                                           'vars' => '',
                                                           'line' => 297
                                                         }, 'Parse::RecDescent::Rule' ),
                              'method_body' => bless( {
                                                        'impcount' => 0,
                                                        'calls' => [
                                                                     'method_statement'
                                                                   ],
                                                        'changed' => 0,
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'number' => '0',
                                                                              'strcount' => 0,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 0,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'subrule' => 'method_statement',
                                                                                                    'expected' => undef,
                                                                                                    'min' => 0,
                                                                                                    'argcode' => undef,
                                                                                                    'max' => 100000000,
                                                                                                    'matchrule' => 0,
                                                                                                    'repspec' => 's?',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 202
                                                                                                  }, 'Parse::RecDescent::Repetition' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'method_body',
                                                        'vars' => '',
                                                        'line' => 202
                                                      }, 'Parse::RecDescent::Rule' )
                            }
               }, 'Parse::RecDescent' );
}

=head1 NAME

Bigtop::Grammar - generated by Parse::RecDescent from bigtop.grammar

=head1 METHODS

=head2 new

Returns a new Parse::RecDescent grammar for bigtop.

=head1 AUTHOR

Generated by:

    perl -MParse::RecDescent - bigtop.grammar Bigtop::Grammar
    cat Grammar.pm grammar.pod > tmp; mv tmp Grammar.pm

=cut
