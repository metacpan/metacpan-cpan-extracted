package CSS::Parse::CompiledGrammar;
use Parse::RecDescent;

{ my $ERRORS;


package Parse::RecDescent::CSS::Parse::CompiledGrammar;
use strict;
use vars qw($skip $AUTOLOAD  $all_rulesets $ruleset $value );
@Parse::RecDescent::CSS::Parse::CompiledGrammar::ISA = ();
$skip = '';


{
local $SIG{__WARN__} = sub {0};
# PRETEND TO BE IN Parse::RecDescent NAMESPACE
*Parse::RecDescent::CSS::Parse::CompiledGrammar::AUTOLOAD   = sub
{
    no strict 'refs';
    $AUTOLOAD =~ s/^Parse::RecDescent::CSS::Parse::CompiledGrammar/Parse::RecDescent/;
    goto &{$AUTOLOAD};
}
}

push @Parse::RecDescent::CSS::Parse::CompiledGrammar::ISA, 'Parse::RecDescent';
# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_nl
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"macro_nl"};
    
    Parse::RecDescent::_trace(q{Trying rule: [macro_nl]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{macro_nl},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/\\n|\\r\\n|\\r|\\f/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\n|\\r\\n|\\r|\\f/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_nl},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_nl});
        %item = (__RULE__ => q{macro_nl});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/\\n|\\r\\n|\\r|\\f/]}, Parse::RecDescent::_tracefirst($text),
                      q{macro_nl},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\n|\r\n|\r|\f)/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nl},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/\\n|\\r\\n|\\r|\\f/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nl},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{macro_nl},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{macro_nl},
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
                      q{macro_nl},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{macro_nl},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::IDENT
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{macro_ident});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_ident]},
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


        Parse::RecDescent::_trace(q{Trying subrule: [macro_ident]},
                  Parse::RecDescent::_tracefirst($text),
                  q{IDENT},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_ident($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_ident]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{IDENT},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_ident]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{IDENT},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_ident}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{IDENT},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_ident]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{IDENT},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
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
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::_alternation_1_of_production_1_of_rule_macro_string1
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_macro_string1"};
    
    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_macro_string1]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule_macro_string1},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/[\\t !#$%&(-~]/, or '\\', or ''', or macro_nonascii, or macro_escape});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/[\\t !#$%&(-~]/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_macro_string1});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_macro_string1});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/[\\t !#$%&(-~]/]}, Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[\t !#$%&(-~])/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/[\\t !#$%&(-~]/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['\\' macro_nl]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_macro_string1});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_macro_string1});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['\\']},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\\/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [macro_nl]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_macro_string1},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{macro_nl})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_nl($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_nl]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_macro_string1},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_nl]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_nl}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = ''};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['\\' macro_nl]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [''']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_macro_string1});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_macro_string1});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [''']},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   do { $_tok = "'"; 1 } and
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
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [''']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_nonascii]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[3];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_macro_string1});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_macro_string1});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_nonascii]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_macro_string1},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_nonascii($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_nonascii]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_macro_string1},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_nonascii]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_nonascii}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_nonascii]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_escape]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[4];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_macro_string1});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_macro_string1});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_escape]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_macro_string1},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_escape($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_escape]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_macro_string1},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_escape]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_escape}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_escape]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule_macro_string1},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
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
                      q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule_macro_string1},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_unicode
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"macro_unicode"};
    
    Parse::RecDescent::_trace(q{Trying rule: [macro_unicode]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{macro_unicode},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/\\[0-9a-f]\{1,6\}[ \\n\\r\\t\\f]?/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\[0-9a-f]\{1,6\}[ \\n\\r\\t\\f]?/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_unicode},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_unicode});
        %item = (__RULE__ => q{macro_unicode});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/\\[0-9a-f]\{1,6\}[ \\n\\r\\t\\f]?/]}, Parse::RecDescent::_tracefirst($text),
                      q{macro_unicode},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\[0-9a-f]{1,6}[ \n\r\t\f]?)/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_unicode},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/\\[0-9a-f]\{1,6\}[ \\n\\r\\t\\f]?/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_unicode},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{macro_unicode},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{macro_unicode},
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
                      q{macro_unicode},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{macro_unicode},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::_alternation_1_of_production_2_of_rule_URI
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_2_of_rule_URI"};
    
    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_2_of_rule_URI]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_2_of_rule_URI},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/[!#$%&*-~]/, or macro_nonascii, or macro_escape});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/[!#$%&*-~]/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_2_of_rule_URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_2_of_rule_URI});
        %item = (__RULE__ => q{_alternation_1_of_production_2_of_rule_URI});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/[!#$%&*-~]/]}, Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_2_of_rule_URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[!#$%&*-~])/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_2_of_rule_URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/[!#$%&*-~]/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_2_of_rule_URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_nonascii]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_2_of_rule_URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_2_of_rule_URI});
        %item = (__RULE__ => q{_alternation_1_of_production_2_of_rule_URI});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_nonascii]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_2_of_rule_URI},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_nonascii($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_nonascii]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_2_of_rule_URI},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_nonascii]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_2_of_rule_URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_nonascii}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_2_of_rule_URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_nonascii]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_2_of_rule_URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_escape]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_2_of_rule_URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_2_of_rule_URI});
        %item = (__RULE__ => q{_alternation_1_of_production_2_of_rule_URI});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_escape]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_2_of_rule_URI},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_escape($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_escape]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_2_of_rule_URI},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_escape]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_2_of_rule_URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_escape}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_2_of_rule_URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_escape]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_2_of_rule_URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_2_of_rule_URI},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_2_of_rule_URI},
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
                      q{_alternation_1_of_production_2_of_rule_URI},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_2_of_rule_URI},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::atrule
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"atrule"};
    
    Parse::RecDescent::_trace(q{Trying rule: [atrule]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{atrule},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{ATKEYWORD});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [ATKEYWORD WS any block, or ';']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{atrule},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{atrule});
        %item = (__RULE__ => q{atrule});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [ATKEYWORD]},
                  Parse::RecDescent::_tracefirst($text),
                  q{atrule},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::ATKEYWORD($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [ATKEYWORD]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{atrule},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [ATKEYWORD]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{atrule},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{ATKEYWORD}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying repeated subrule: [WS]},
                  Parse::RecDescent::_tracefirst($text),
                  q{atrule},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{WS})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::WS, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [WS]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{atrule},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [WS]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{atrule},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{WS(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying repeated subrule: [any]},
                  Parse::RecDescent::_tracefirst($text),
                  q{atrule},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{any})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::any, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [any]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{atrule},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [any]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{atrule},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{any(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule_atrule]},
                  Parse::RecDescent::_tracefirst($text),
                  q{atrule},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{block, or ';'})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::_alternation_1_of_production_1_of_rule_atrule($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule_atrule]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{atrule},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule_atrule]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{atrule},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule_atrule}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{atrule},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {print "at-rule\n"};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [ATKEYWORD WS any block, or ';']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{atrule},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{atrule},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{atrule},
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
                      q{atrule},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{atrule},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::_alternation_1_of_production_1_of_rule_value
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_value"};
    
    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_value]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule_value},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{any, or block, or ATKEYWORD});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [any]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_value},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_value});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_value});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [any]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_value},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::any($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [any]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_value},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [any]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_value},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{any}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_value},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [any]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_value},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [block]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_value},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_value});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_value});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [block]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_value},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::block($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [block]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_value},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [block]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_value},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{block}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_value},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [block]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_value},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [ATKEYWORD OWS]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_value},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_value});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_value});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [ATKEYWORD]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_value},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::ATKEYWORD($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [ATKEYWORD]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_value},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [ATKEYWORD]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_value},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{ATKEYWORD}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying subrule: [OWS]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_value},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{OWS})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::OWS($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [OWS]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_value},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [OWS]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_value},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{OWS}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_value},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1].$item[2]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [ATKEYWORD OWS]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_value},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule_value},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule_value},
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
                      q{_alternation_1_of_production_1_of_rule_value},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule_value},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::statement
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"statement"};
    
    Parse::RecDescent::_trace(q{Trying rule: [statement]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{statement},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{ruleset, or atrule});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [ruleset]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{statement});
        %item = (__RULE__ => q{statement});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [ruleset]},
                  Parse::RecDescent::_tracefirst($text),
                  q{statement},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::ruleset($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [ruleset]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{statement},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [ruleset]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{ruleset}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {4;};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [ruleset]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [atrule]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{statement});
        %item = (__RULE__ => q{statement});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [atrule]},
                  Parse::RecDescent::_tracefirst($text),
                  q{statement},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::atrule($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [atrule]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{statement},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [atrule]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{atrule}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {5;};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [atrule]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{statement},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{statement},
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
                      q{statement},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{statement},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::HASH
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"HASH"};
    
    Parse::RecDescent::_trace(q{Trying rule: [HASH]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{HASH},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'#'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['#' macro_name]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{HASH},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{HASH});
        %item = (__RULE__ => q{HASH});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['#']},
                      Parse::RecDescent::_tracefirst($text),
                      q{HASH},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\#/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [macro_name]},
                  Parse::RecDescent::_tracefirst($text),
                  q{HASH},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{macro_name})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_name($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_name]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{HASH},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_name]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{HASH},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_name}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{HASH},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = '#'.$item[2]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['#' macro_name]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{HASH},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{HASH},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{HASH},
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
                      q{HASH},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{HASH},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::property
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"property"};
    
    Parse::RecDescent::_trace(q{Trying rule: [property]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{property},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{IDENT});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [IDENT OWS]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{property},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{property});
        %item = (__RULE__ => q{property});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
                  Parse::RecDescent::_tracefirst($text),
                  q{property},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{property},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{property},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{IDENT}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying subrule: [OWS]},
                  Parse::RecDescent::_tracefirst($text),
                  q{property},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{OWS})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::OWS($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [OWS]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{property},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [OWS]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{property},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{OWS}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{property},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [IDENT OWS]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{property},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{property},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{property},
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
                      q{property},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{property},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::OWS
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"OWS"};
    
    Parse::RecDescent::_trace(q{Trying rule: [OWS]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{OWS},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{WS});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [WS]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{OWS},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{OWS});
        %item = (__RULE__ => q{OWS});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying repeated subrule: [WS]},
                  Parse::RecDescent::_tracefirst($text),
                  q{OWS},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::WS, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [WS]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{OWS},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [WS]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{OWS},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{WS(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{OWS},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = ''; if (scalar(@{$item[1]}) > 0){$return = ' ';} 1;};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [WS]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{OWS},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{OWS},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{OWS},
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
                      q{OWS},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{OWS},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::selector
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"selector"};
    
    Parse::RecDescent::_trace(q{Trying rule: [selector]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{selector},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{any});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [any]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{selector},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{selector});
        %item = (__RULE__ => q{selector});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying repeated subrule: [any]},
                  Parse::RecDescent::_tracefirst($text),
                  q{selector},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::any, 1, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [any]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{selector},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [any]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{selector},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{any(s)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{selector},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {
						$ruleset->add_selector(new CSS::Selector({'name' => $_})) 
						for(map{s/^\s*(.*?)\s*$/$1/;$_}split /\s*,\s*/, join('',@{$item[1]}));
						1;
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [any]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{selector},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{selector},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{selector},
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
                      q{selector},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{selector},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::value
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"value"};
    
    Parse::RecDescent::_trace(q{Trying rule: [value]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{value},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{any, or block, or ATKEYWORD});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [any, or block, or ATKEYWORD]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{value},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{value});
        %item = (__RULE__ => q{value});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying repeated subrule: [any, or block, or ATKEYWORD]},
                  Parse::RecDescent::_tracefirst($text),
                  q{value},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::_alternation_1_of_production_1_of_rule_value, 1, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [any, or block, or ATKEYWORD]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{value},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [_alternation_1_of_production_1_of_rule_value]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{value},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule_value(s)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{value},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = join('',@{$item[1]})};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [any, or block, or ATKEYWORD]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{value},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{value},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{value},
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
                      q{value},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{value},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::_alternation_1_of_production_1_of_rule_atrule
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_atrule"};
    
    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_atrule]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule_atrule},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{block, or ';'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [block]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_atrule},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_atrule});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_atrule});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [block]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_atrule},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::block($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [block]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_atrule},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [block]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_atrule},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{block}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_atrule},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { print "token: ".shift @item; print " : @item\n" };
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
                      q{_alternation_1_of_production_1_of_rule_atrule},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [';' WS]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_atrule},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_atrule});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_atrule});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [';']},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_atrule},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\;/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying repeated subrule: [WS]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_atrule},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{WS})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::WS, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [WS]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_atrule},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [WS]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_atrule},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{WS(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_atrule},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { print "token: ".shift @item; print " : @item\n" };
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
        
        


        Parse::RecDescent::_trace(q{>>Matched production: [';' WS]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_atrule},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule_atrule},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule_atrule},
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
                      q{_alternation_1_of_production_1_of_rule_atrule},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule_atrule},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::_alternation_1_of_production_1_of_rule_ruleset
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_ruleset"};
    
    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_ruleset]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule_ruleset},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{';'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [';' WS declaration]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_ruleset});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_ruleset});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [';']},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\;/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying repeated subrule: [WS]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_ruleset},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{WS})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::WS, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [WS]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_ruleset},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [WS]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{WS(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying repeated subrule: [declaration]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_ruleset},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{declaration})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::declaration, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [declaration]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_ruleset},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [declaration]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{declaration(?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {6;};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [';' WS declaration]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule_ruleset},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule_ruleset},
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
                      q{_alternation_1_of_production_1_of_rule_ruleset},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule_ruleset},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::_alternation_1_of_production_1_of_rule_block
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_block"};
    
    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_block]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule_block},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{any, or block, or ATKEYWORD, or ';'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [any]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_block});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_block});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [any]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_block},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::any($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [any]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_block},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [any]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{any}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { print "token: ".shift @item; print " : @item\n" };
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
        
        


        Parse::RecDescent::_trace(q{>>Matched production: [any]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [block]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_block});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_block});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [block]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_block},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::block($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [block]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_block},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [block]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{block}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { print "token: ".shift @item; print " : @item\n" };
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
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [ATKEYWORD WS]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_block});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_block});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [ATKEYWORD]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_block},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::ATKEYWORD($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [ATKEYWORD]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_block},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [ATKEYWORD]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{ATKEYWORD}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying repeated subrule: [WS]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_block},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{WS})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::WS, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [WS]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_block},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [WS]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{WS(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { print "token: ".shift @item; print " : @item\n" };
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
        
        


        Parse::RecDescent::_trace(q{>>Matched production: [ATKEYWORD WS]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [';']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[3];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_block});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_block});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [';']},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\;/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { print "token: ".shift @item; print " : @item\n" };
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
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule_block},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule_block},
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
                      q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule_block},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::WS
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"WS"};
    
    Parse::RecDescent::_trace(q{Trying rule: [WS]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{WS},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/[ \\t\\r\\n\\f]+/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/[ \\t\\r\\n\\f]+/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{WS},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{WS});
        %item = (__RULE__ => q{WS});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/[ \\t\\r\\n\\f]+/]}, Parse::RecDescent::_tracefirst($text),
                      q{WS},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[ \t\r\n\f]+)/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{WS},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = ' ';};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/[ \\t\\r\\n\\f]+/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{WS},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{WS},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{WS},
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
                      q{WS},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{WS},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_ident
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"macro_ident"};
    
    Parse::RecDescent::_trace(q{Trying rule: [macro_ident]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{macro_ident},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{macro_nmstart});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_nmstart macro_nmchar]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_ident},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_ident});
        %item = (__RULE__ => q{macro_ident});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_nmstart]},
                  Parse::RecDescent::_tracefirst($text),
                  q{macro_ident},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_nmstart($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_nmstart]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{macro_ident},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_nmstart]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_ident},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_nmstart}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying repeated subrule: [macro_nmchar]},
                  Parse::RecDescent::_tracefirst($text),
                  q{macro_ident},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{macro_nmchar})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_nmchar, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [macro_nmchar]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{macro_ident},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [macro_nmchar]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_ident},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_nmchar(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_ident},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]; if (scalar(@{$item[2]}) > 0){$return .= join('',@{$item[2]});} 1;};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_nmstart macro_nmchar]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_ident},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{macro_ident},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{macro_ident},
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
                      q{macro_ident},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{macro_ident},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::_alternation_1_of_production_1_of_rule_macro_string2
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_macro_string2"};
    
    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_macro_string2]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule_macro_string2},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/[\\t !#$%&(-~]/, or '\\', or '"', or macro_nonascii, or macro_escape});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/[\\t !#$%&(-~]/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_macro_string2});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_macro_string2});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/[\\t !#$%&(-~]/]}, Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[\t !#$%&(-~])/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/[\\t !#$%&(-~]/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['\\' macro_nl]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_macro_string2});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_macro_string2});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['\\']},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\\/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [macro_nl]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_macro_string2},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{macro_nl})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_nl($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_nl]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_macro_string2},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_nl]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_nl}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = ''};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['\\' macro_nl]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['"']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_macro_string2});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_macro_string2});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['"']},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\"/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['"']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_nonascii]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[3];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_macro_string2});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_macro_string2});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_nonascii]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_macro_string2},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_nonascii($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_nonascii]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_macro_string2},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_nonascii]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_nonascii}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_nonascii]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_escape]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[4];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_macro_string2});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_macro_string2});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_escape]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_macro_string2},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_escape($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_escape]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_macro_string2},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_escape]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_escape}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_escape]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule_macro_string2},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
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
                      q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule_macro_string2},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_nmstart
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"macro_nmstart"};
    
    Parse::RecDescent::_trace(q{Trying rule: [macro_nmstart]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{macro_nmstart},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/[a-zA-Z]/, or macro_nonascii, or macro_escape});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/[a-zA-Z]/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_nmstart},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_nmstart});
        %item = (__RULE__ => q{macro_nmstart});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/[a-zA-Z]/]}, Parse::RecDescent::_tracefirst($text),
                      q{macro_nmstart},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[a-zA-Z])/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nmstart},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/[a-zA-Z]/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nmstart},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_nonascii]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_nmstart},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_nmstart});
        %item = (__RULE__ => q{macro_nmstart});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_nonascii]},
                  Parse::RecDescent::_tracefirst($text),
                  q{macro_nmstart},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_nonascii($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_nonascii]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{macro_nmstart},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_nonascii]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nmstart},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_nonascii}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nmstart},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_nonascii]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nmstart},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_escape]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_nmstart},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_nmstart});
        %item = (__RULE__ => q{macro_nmstart});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_escape]},
                  Parse::RecDescent::_tracefirst($text),
                  q{macro_nmstart},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_escape($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_escape]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{macro_nmstart},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_escape]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nmstart},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_escape}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nmstart},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_escape]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nmstart},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{macro_nmstart},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{macro_nmstart},
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
                      q{macro_nmstart},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{macro_nmstart},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::INCLUDES
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"INCLUDES"};
    
    Parse::RecDescent::_trace(q{Trying rule: [INCLUDES]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{INCLUDES},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'~='});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['~=']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{INCLUDES},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{INCLUDES});
        %item = (__RULE__ => q{INCLUDES});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['~=']},
                      Parse::RecDescent::_tracefirst($text),
                      q{INCLUDES},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\~\=/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{INCLUDES},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['~=']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{INCLUDES},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{INCLUDES},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{INCLUDES},
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
                      q{INCLUDES},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{INCLUDES},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_string1
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"macro_string1"};
    
    Parse::RecDescent::_trace(q{Trying rule: [macro_string1]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{macro_string1},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'"'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['"' /[\\t !#$%&(-~]/, or '\\', or ''', or macro_nonascii, or macro_escape '"']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_string1});
        %item = (__RULE__ => q{macro_string1});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['"']},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\"/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying repeated subrule: [/[\\t !#$%&(-~]/, or '\\', or ''', or macro_nonascii, or macro_escape]},
                  Parse::RecDescent::_tracefirst($text),
                  q{macro_string1},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{/[\\t !#$%&(-~]/, or '\\', or ''', or macro_nonascii, or macro_escape})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::_alternation_1_of_production_1_of_rule_macro_string1, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [/[\\t !#$%&(-~]/, or '\\', or ''', or macro_nonascii, or macro_escape]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{macro_string1},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [_alternation_1_of_production_1_of_rule_macro_string1]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule_macro_string1(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying terminal: ['"']},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'"'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\"/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = '"'.join('', @{$item[2]}).'"'};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['"' /[\\t !#$%&(-~]/, or '\\', or ''', or macro_nonascii, or macro_escape '"']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_string1},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{macro_string1},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{macro_string1},
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
                      q{macro_string1},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{macro_string1},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_string
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"macro_string"};
    
    Parse::RecDescent::_trace(q{Trying rule: [macro_string]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{macro_string},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{macro_string1, or macro_string2});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_string1]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_string},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_string});
        %item = (__RULE__ => q{macro_string});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_string1]},
                  Parse::RecDescent::_tracefirst($text),
                  q{macro_string},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_string1($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_string1]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{macro_string},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_string1]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_string},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_string1}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_string},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_string1]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_string},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_string2]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_string},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_string});
        %item = (__RULE__ => q{macro_string});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_string2]},
                  Parse::RecDescent::_tracefirst($text),
                  q{macro_string},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_string2($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_string2]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{macro_string},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_string2]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_string},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_string2}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_string},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_string2]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_string},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{macro_string},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{macro_string},
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
                      q{macro_string},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{macro_string},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::UNICODERANGE
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"UNICODERANGE"};
    
    Parse::RecDescent::_trace(q{Trying rule: [UNICODERANGE]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{UNICODERANGE},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/U\\+[0-9A-F?]\{1,6\}(-[0-9A-F]\{1,6\})?/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/U\\+[0-9A-F?]\{1,6\}(-[0-9A-F]\{1,6\})?/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{UNICODERANGE},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{UNICODERANGE});
        %item = (__RULE__ => q{UNICODERANGE});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/U\\+[0-9A-F?]\{1,6\}(-[0-9A-F]\{1,6\})?/]}, Parse::RecDescent::_tracefirst($text),
                      q{UNICODERANGE},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:U\+[0-9A-F?]{1,6}(-[0-9A-F]{1,6})?)/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{UNICODERANGE},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/U\\+[0-9A-F?]\{1,6\}(-[0-9A-F]\{1,6\})?/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{UNICODERANGE},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{UNICODERANGE},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{UNICODERANGE},
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
                      q{UNICODERANGE},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{UNICODERANGE},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_w
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"macro_w"};
    
    Parse::RecDescent::_trace(q{Trying rule: [macro_w]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{macro_w},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/[ \\t\\r\\n\\f]*/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/[ \\t\\r\\n\\f]*/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_w},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_w});
        %item = (__RULE__ => q{macro_w});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/[ \\t\\r\\n\\f]*/]}, Parse::RecDescent::_tracefirst($text),
                      q{macro_w},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[ \t\r\n\f]*)/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_w},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/[ \\t\\r\\n\\f]*/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_w},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{macro_w},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{macro_w},
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
                      q{macro_w},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{macro_w},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::STRING
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"STRING"};
    
    Parse::RecDescent::_trace(q{Trying rule: [STRING]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{STRING},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{macro_string});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_string]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{STRING},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{STRING});
        %item = (__RULE__ => q{STRING});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_string]},
                  Parse::RecDescent::_tracefirst($text),
                  q{STRING},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_string($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_string]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{STRING},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_string]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{STRING},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_string}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{STRING},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_string]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{STRING},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{STRING},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{STRING},
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
                      q{STRING},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{STRING},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::DIMENSION
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"DIMENSION"};
    
    Parse::RecDescent::_trace(q{Trying rule: [DIMENSION]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{DIMENSION},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{macro_num});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_num macro_ident]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{DIMENSION},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{DIMENSION});
        %item = (__RULE__ => q{DIMENSION});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_num]},
                  Parse::RecDescent::_tracefirst($text),
                  q{DIMENSION},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_num($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_num]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{DIMENSION},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_num]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{DIMENSION},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_num}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying subrule: [macro_ident]},
                  Parse::RecDescent::_tracefirst($text),
                  q{DIMENSION},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{macro_ident})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_ident($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_ident]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{DIMENSION},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_ident]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{DIMENSION},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_ident}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{DIMENSION},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1].$item[2]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_num macro_ident]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{DIMENSION},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{DIMENSION},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{DIMENSION},
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
                      q{DIMENSION},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{DIMENSION},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_string2
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"macro_string2"};
    
    Parse::RecDescent::_trace(q{Trying rule: [macro_string2]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{macro_string2},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'''});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [''' /[\\t !#$%&(-~]/, or '\\', or '"', or macro_nonascii, or macro_escape ''']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_string2});
        %item = (__RULE__ => q{macro_string2});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [''']},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   do { $_tok = "'"; 1 } and
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
        

        Parse::RecDescent::_trace(q{Trying repeated subrule: [/[\\t !#$%&(-~]/, or '\\', or '"', or macro_nonascii, or macro_escape]},
                  Parse::RecDescent::_tracefirst($text),
                  q{macro_string2},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{/[\\t !#$%&(-~]/, or '\\', or '"', or macro_nonascii, or macro_escape})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::_alternation_1_of_production_1_of_rule_macro_string2, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [/[\\t !#$%&(-~]/, or '\\', or '"', or macro_nonascii, or macro_escape]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{macro_string2},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [_alternation_1_of_production_1_of_rule_macro_string2]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule_macro_string2(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying terminal: [''']},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'''})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   do { $_tok = "'"; 1 } and
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
        push @item, $item{__STRING2__}=$_tok;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {return "'".join('', @{$item[2]})."'"};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [''' /[\\t !#$%&(-~]/, or '\\', or '"', or macro_nonascii, or macro_escape ''']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_string2},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{macro_string2},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{macro_string2},
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
                      q{macro_string2},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{macro_string2},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_num
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"macro_num"};
    
    Parse::RecDescent::_trace(q{Trying rule: [macro_num]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{macro_num},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/[0-9]+|[0-9]*\\.[0-9]+/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/[0-9]+|[0-9]*\\.[0-9]+/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_num},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_num});
        %item = (__RULE__ => q{macro_num});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/[0-9]+|[0-9]*\\.[0-9]+/]}, Parse::RecDescent::_tracefirst($text),
                      q{macro_num},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[0-9]+|[0-9]*\.[0-9]+)/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_num},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/[0-9]+|[0-9]*\\.[0-9]+/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_num},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{macro_num},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{macro_num},
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
                      q{macro_num},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{macro_num},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::declaration
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"declaration"};
    
    Parse::RecDescent::_trace(q{Trying rule: [declaration]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{declaration},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{property});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

     local $value;


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [property ':' WS value]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{declaration},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{declaration});
        %item = (__RULE__ => q{declaration});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [property]},
                  Parse::RecDescent::_tracefirst($text),
                  q{declaration},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::property($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [property]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{declaration},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [property]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{declaration},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{property}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: [':']},
                      Parse::RecDescent::_tracefirst($text),
                      q{declaration},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{':'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\:/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying repeated subrule: [WS]},
                  Parse::RecDescent::_tracefirst($text),
                  q{declaration},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{WS})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::WS, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [WS]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{declaration},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [WS]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{declaration},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{WS(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying subrule: [value]},
                  Parse::RecDescent::_tracefirst($text),
                  q{declaration},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{value})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::value($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [value]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{declaration},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [value]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{declaration},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{value}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{declaration},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {
						$ruleset->add_property(new CSS::Property({
							'property' => $item[1],
							'value' => $item[4],
						}));
						1;
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [property ':' WS value]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{declaration},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<rulevar: local $value>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{declaration},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{declaration});
        %item = (__RULE__ => q{declaration});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{>>Rejecting production<< (found <rulevar: local $value>)},
                     Parse::RecDescent::_tracefirst($text),
                      q{declaration},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $return;
        

        $_tok = undef;
        
        last unless defined $_tok;

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{declaration},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { print "token: ".shift @item; print " : @item\n" };
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
        
        


        Parse::RecDescent::_trace(q{>>Matched production: [<rulevar: local $value>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{declaration},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{declaration},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{declaration},
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
                      q{declaration},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{declaration},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_escape
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"macro_escape"};
    
    Parse::RecDescent::_trace(q{Trying rule: [macro_escape]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{macro_escape},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{macro_unicode, or /\\\\[ -~\\200-\\4177777]/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_unicode]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_escape},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_escape});
        %item = (__RULE__ => q{macro_escape});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_unicode]},
                  Parse::RecDescent::_tracefirst($text),
                  q{macro_escape},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_unicode($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_unicode]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{macro_escape},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_unicode]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_escape},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_unicode}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_escape},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_unicode]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_escape},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\\\[ -~\\200-\\4177777]/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_escape},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_escape});
        %item = (__RULE__ => q{macro_escape});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/\\\\[ -~\\200-\\4177777]/]}, Parse::RecDescent::_tracefirst($text),
                      q{macro_escape},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\\[ -~\200-\4177777])/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_escape},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/\\\\[ -~\\200-\\4177777]/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_escape},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{macro_escape},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{macro_escape},
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
                      q{macro_escape},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{macro_escape},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::FUNCTION
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"FUNCTION"};
    
    Parse::RecDescent::_trace(q{Trying rule: [FUNCTION]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{FUNCTION},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{macro_ident});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_ident '(']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{FUNCTION},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{FUNCTION});
        %item = (__RULE__ => q{FUNCTION});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_ident]},
                  Parse::RecDescent::_tracefirst($text),
                  q{FUNCTION},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_ident($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_ident]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{FUNCTION},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_ident]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{FUNCTION},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_ident}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: ['(']},
                      Parse::RecDescent::_tracefirst($text),
                      q{FUNCTION},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'('})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\(/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{FUNCTION},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1].'('};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_ident '(']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{FUNCTION},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{FUNCTION},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{FUNCTION},
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
                      q{FUNCTION},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{FUNCTION},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::stylesheet
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"stylesheet"};
    
    Parse::RecDescent::_trace(q{Trying rule: [stylesheet]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{stylesheet},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{WS, or statement});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

     local $all_rulesets;


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [WS, or statement]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{stylesheet},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{stylesheet});
        %item = (__RULE__ => q{stylesheet});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying repeated subrule: [WS, or statement]},
                  Parse::RecDescent::_tracefirst($text),
                  q{stylesheet},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::_alternation_1_of_production_1_of_rule_stylesheet, 1, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [WS, or statement]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{stylesheet},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [_alternation_1_of_production_1_of_rule_stylesheet]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{stylesheet},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule_stylesheet(s)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{stylesheet},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $all_rulesets;};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [WS, or statement]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{stylesheet},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<rulevar: local $all_rulesets>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{stylesheet},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{stylesheet});
        %item = (__RULE__ => q{stylesheet});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{>>Rejecting production<< (found <rulevar: local $all_rulesets>)},
                     Parse::RecDescent::_tracefirst($text),
                      q{stylesheet},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $return;
        

        $_tok = undef;
        
        last unless defined $_tok;

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{stylesheet},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { print "token: ".shift @item; print " : @item\n" };
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
        
        


        Parse::RecDescent::_trace(q{>>Matched production: [<rulevar: local $all_rulesets>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{stylesheet},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{stylesheet},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{stylesheet},
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
                      q{stylesheet},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{stylesheet},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::NUMBER
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"NUMBER"};
    
    Parse::RecDescent::_trace(q{Trying rule: [NUMBER]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{NUMBER},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{macro_num});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_num]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{NUMBER},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{NUMBER});
        %item = (__RULE__ => q{NUMBER});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_num]},
                  Parse::RecDescent::_tracefirst($text),
                  q{NUMBER},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_num($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_num]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{NUMBER},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_num]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{NUMBER},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_num}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{NUMBER},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_num]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{NUMBER},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{NUMBER},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{NUMBER},
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
                      q{NUMBER},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{NUMBER},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_name
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"macro_name"};
    
    Parse::RecDescent::_trace(q{Trying rule: [macro_name]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{macro_name},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{macro_nmchar});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_nmchar]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_name},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_name});
        %item = (__RULE__ => q{macro_name});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying repeated subrule: [macro_nmchar]},
                  Parse::RecDescent::_tracefirst($text),
                  q{macro_name},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_nmchar, 1, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [macro_nmchar]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{macro_name},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [macro_nmchar]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_name},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_nmchar(s)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_name},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = join('',@{$item[1]})};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_nmchar]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_name},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{macro_name},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{macro_name},
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
                      q{macro_name},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{macro_name},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::_alternation_1_of_production_1_of_rule_stylesheet
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_stylesheet"};
    
    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_stylesheet]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule_stylesheet},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{WS, or statement});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [WS]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_stylesheet},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_stylesheet});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_stylesheet});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [WS]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_stylesheet},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::WS($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [WS]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_stylesheet},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [WS]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_stylesheet},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{WS}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_stylesheet},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {2;};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [WS]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_stylesheet},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [statement]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_stylesheet},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_stylesheet});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_stylesheet});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [statement]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_stylesheet},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::statement($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [statement]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_stylesheet},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [statement]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_stylesheet},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{statement}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_stylesheet},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {3;};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [statement]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_stylesheet},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule_stylesheet},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule_stylesheet},
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
                      q{_alternation_1_of_production_1_of_rule_stylesheet},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule_stylesheet},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::ATKEYWORD
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"ATKEYWORD"};
    
    Parse::RecDescent::_trace(q{Trying rule: [ATKEYWORD]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{ATKEYWORD},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'@'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['@' macro_ident]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{ATKEYWORD},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{ATKEYWORD});
        %item = (__RULE__ => q{ATKEYWORD});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['@']},
                      Parse::RecDescent::_tracefirst($text),
                      q{ATKEYWORD},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\@/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [macro_ident]},
                  Parse::RecDescent::_tracefirst($text),
                  q{ATKEYWORD},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{macro_ident})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_ident($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_ident]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{ATKEYWORD},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_ident]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{ATKEYWORD},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_ident}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{ATKEYWORD},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = '@'.$item[2]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['@' macro_ident]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{ATKEYWORD},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{ATKEYWORD},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{ATKEYWORD},
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
                      q{ATKEYWORD},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{ATKEYWORD},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::URI
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"URI"};
    
    Parse::RecDescent::_trace(q{Trying rule: [URI]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{URI},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'url('});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['url(' macro_w macro_string macro_w ')']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{URI});
        %item = (__RULE__ => q{URI});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['url(']},
                      Parse::RecDescent::_tracefirst($text),
                      q{URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Aurl\(/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [macro_w]},
                  Parse::RecDescent::_tracefirst($text),
                  q{URI},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{macro_w})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_w($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_w]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{URI},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_w]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_w}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying subrule: [macro_string]},
                  Parse::RecDescent::_tracefirst($text),
                  q{URI},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{macro_string})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_string($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_string]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{URI},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_string]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_string}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying subrule: [macro_w]},
                  Parse::RecDescent::_tracefirst($text),
                  q{URI},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{macro_w})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_w($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_w]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{URI},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_w]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_w}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: [')']},
                      Parse::RecDescent::_tracefirst($text),
                      q{URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{')'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\)/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = "url(".$item[3].")"};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['url(' macro_w macro_string macro_w ')']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['url(' macro_w /[!#$%&*-~]/, or macro_nonascii, or macro_escape macro_w ')']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{URI});
        %item = (__RULE__ => q{URI});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['url(']},
                      Parse::RecDescent::_tracefirst($text),
                      q{URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Aurl\(/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [macro_w]},
                  Parse::RecDescent::_tracefirst($text),
                  q{URI},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{macro_w})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_w($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_w]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{URI},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_w]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_w}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying repeated subrule: [/[!#$%&*-~]/, or macro_nonascii, or macro_escape]},
                  Parse::RecDescent::_tracefirst($text),
                  q{URI},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{/[!#$%&*-~]/, or macro_nonascii, or macro_escape})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::_alternation_1_of_production_2_of_rule_URI, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [/[!#$%&*-~]/, or macro_nonascii, or macro_escape]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{URI},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [_alternation_1_of_production_2_of_rule_URI]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_2_of_rule_URI(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying subrule: [macro_w]},
                  Parse::RecDescent::_tracefirst($text),
                  q{URI},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{macro_w})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_w($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_w]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{URI},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_w]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_w}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: [')']},
                      Parse::RecDescent::_tracefirst($text),
                      q{URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{')'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\)/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = "url(".join('',@{$item[3]}).")"};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['url(' macro_w /[!#$%&*-~]/, or macro_nonascii, or macro_escape macro_w ')']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{URI},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{URI},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{URI},
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
                      q{URI},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{URI},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::any_item
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"any_item"};
    
    Parse::RecDescent::_trace(q{Trying rule: [any_item]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{any_item},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{URI, or IDENT, or NUMBER, or PERCENTAGE, or DIMENSION, or STRING, or HASH, or UNICODERANGE, or INCLUDES, or FUNCTION, or DASHMATCH, or '(', or '[', or DELIM});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [URI]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{any_item});
        %item = (__RULE__ => q{any_item});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [URI]},
                  Parse::RecDescent::_tracefirst($text),
                  q{any_item},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::URI($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [URI]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{any_item},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [URI]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{URI}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1];};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [URI]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [IDENT]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{any_item});
        %item = (__RULE__ => q{any_item});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [IDENT]},
                  Parse::RecDescent::_tracefirst($text),
                  q{any_item},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::IDENT($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [IDENT]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{any_item},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [IDENT]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{IDENT}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1];};
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
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [NUMBER]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{any_item});
        %item = (__RULE__ => q{any_item});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [NUMBER]},
                  Parse::RecDescent::_tracefirst($text),
                  q{any_item},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::NUMBER($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [NUMBER]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{any_item},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [NUMBER]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{NUMBER}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1];};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [NUMBER]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [PERCENTAGE]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[3];
        $text = $_[1];
        my $_savetext;
        @item = (q{any_item});
        %item = (__RULE__ => q{any_item});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [PERCENTAGE]},
                  Parse::RecDescent::_tracefirst($text),
                  q{any_item},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::PERCENTAGE($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [PERCENTAGE]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{any_item},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [PERCENTAGE]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{PERCENTAGE}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1];};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [PERCENTAGE]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [DIMENSION]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[4];
        $text = $_[1];
        my $_savetext;
        @item = (q{any_item});
        %item = (__RULE__ => q{any_item});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [DIMENSION]},
                  Parse::RecDescent::_tracefirst($text),
                  q{any_item},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::DIMENSION($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [DIMENSION]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{any_item},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [DIMENSION]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{DIMENSION}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1];};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [DIMENSION]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [STRING]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[5];
        $text = $_[1];
        my $_savetext;
        @item = (q{any_item});
        %item = (__RULE__ => q{any_item});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [STRING]},
                  Parse::RecDescent::_tracefirst($text),
                  q{any_item},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::STRING($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [STRING]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{any_item},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [STRING]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{STRING}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1];};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [STRING]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [HASH]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[6];
        $text = $_[1];
        my $_savetext;
        @item = (q{any_item});
        %item = (__RULE__ => q{any_item});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [HASH]},
                  Parse::RecDescent::_tracefirst($text),
                  q{any_item},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::HASH($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [HASH]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{any_item},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [HASH]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{HASH}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1];};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [HASH]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [UNICODERANGE]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[7];
        $text = $_[1];
        my $_savetext;
        @item = (q{any_item});
        %item = (__RULE__ => q{any_item});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [UNICODERANGE]},
                  Parse::RecDescent::_tracefirst($text),
                  q{any_item},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::UNICODERANGE($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [UNICODERANGE]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{any_item},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [UNICODERANGE]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{UNICODERANGE}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1];};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [UNICODERANGE]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [INCLUDES]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[8];
        $text = $_[1];
        my $_savetext;
        @item = (q{any_item});
        %item = (__RULE__ => q{any_item});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [INCLUDES]},
                  Parse::RecDescent::_tracefirst($text),
                  q{any_item},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::INCLUDES($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [INCLUDES]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{any_item},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [INCLUDES]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{INCLUDES}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1];};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [INCLUDES]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [FUNCTION]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[9];
        $text = $_[1];
        my $_savetext;
        @item = (q{any_item});
        %item = (__RULE__ => q{any_item});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [FUNCTION]},
                  Parse::RecDescent::_tracefirst($text),
                  q{any_item},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::FUNCTION($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [FUNCTION]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{any_item},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [FUNCTION]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{FUNCTION}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1];};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [FUNCTION]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [DASHMATCH]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[10];
        $text = $_[1];
        my $_savetext;
        @item = (q{any_item});
        %item = (__RULE__ => q{any_item});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [DASHMATCH]},
                  Parse::RecDescent::_tracefirst($text),
                  q{any_item},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::DASHMATCH($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [DASHMATCH]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{any_item},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [DASHMATCH]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{DASHMATCH}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1];};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [DASHMATCH]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['(' any ')']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[11];
        $text = $_[1];
        my $_savetext;
        @item = (q{any_item});
        %item = (__RULE__ => q{any_item});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['(']},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\(/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying repeated subrule: [any]},
                  Parse::RecDescent::_tracefirst($text),
                  q{any_item},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{any})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::any, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [any]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{any_item},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [any]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{any(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying terminal: [')']},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{')'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\)/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = '('.join('',@{$item[2]}).')';};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['(' any ')']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['[' any ']']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[12];
        $text = $_[1];
        my $_savetext;
        @item = (q{any_item});
        %item = (__RULE__ => q{any_item});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['[']},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\[/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying repeated subrule: [any]},
                  Parse::RecDescent::_tracefirst($text),
                  q{any_item},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{any})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::any, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [any]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{any_item},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [any]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{any(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying terminal: [']']},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{']'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\]/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = '['.join('',@{$item[2]}).']';};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['[' any ']']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [DELIM]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[13];
        $text = $_[1];
        my $_savetext;
        @item = (q{any_item});
        %item = (__RULE__ => q{any_item});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [DELIM]},
                  Parse::RecDescent::_tracefirst($text),
                  q{any_item},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::DELIM($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [DELIM]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{any_item},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [DELIM]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{DELIM}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1];};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [DELIM]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{any_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{any_item},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{any_item},
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
                      q{any_item},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{any_item},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::any
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"any"};
    
    Parse::RecDescent::_trace(q{Trying rule: [any]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{any},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{any_item});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [any_item OWS]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{any},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{any});
        %item = (__RULE__ => q{any});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [any_item]},
                  Parse::RecDescent::_tracefirst($text),
                  q{any},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::any_item($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [any_item]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{any},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [any_item]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{any},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{any_item}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying subrule: [OWS]},
                  Parse::RecDescent::_tracefirst($text),
                  q{any},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{OWS})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::OWS($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [OWS]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{any},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [OWS]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{any},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{OWS}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{any},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1].$item[2]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [any_item OWS]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{any},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{any},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{any},
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
                      q{any},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{any},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::DASHMATCH
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"DASHMATCH"};
    
    Parse::RecDescent::_trace(q{Trying rule: [DASHMATCH]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{DASHMATCH},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'|='});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['|=']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{DASHMATCH},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{DASHMATCH});
        %item = (__RULE__ => q{DASHMATCH});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['|=']},
                      Parse::RecDescent::_tracefirst($text),
                      q{DASHMATCH},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\|\=/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{DASHMATCH},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['|=']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{DASHMATCH},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{DASHMATCH},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{DASHMATCH},
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
                      q{DASHMATCH},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{DASHMATCH},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_nmchar
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"macro_nmchar"};
    
    Parse::RecDescent::_trace(q{Trying rule: [macro_nmchar]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{macro_nmchar},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/[a-z0-9-]/, or macro_nonascii, or macro_escape});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/[a-z0-9-]/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_nmchar},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_nmchar});
        %item = (__RULE__ => q{macro_nmchar});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/[a-z0-9-]/]}, Parse::RecDescent::_tracefirst($text),
                      q{macro_nmchar},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[a-z0-9-])/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nmchar},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/[a-z0-9-]/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nmchar},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_nonascii]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_nmchar},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_nmchar});
        %item = (__RULE__ => q{macro_nmchar});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_nonascii]},
                  Parse::RecDescent::_tracefirst($text),
                  q{macro_nmchar},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_nonascii($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_nonascii]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{macro_nmchar},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_nonascii]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nmchar},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_nonascii}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nmchar},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_nonascii]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nmchar},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_escape]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_nmchar},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_nmchar});
        %item = (__RULE__ => q{macro_nmchar});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_escape]},
                  Parse::RecDescent::_tracefirst($text),
                  q{macro_nmchar},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_escape($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_escape]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{macro_nmchar},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_escape]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nmchar},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_escape}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nmchar},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_escape]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nmchar},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{macro_nmchar},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{macro_nmchar},
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
                      q{macro_nmchar},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{macro_nmchar},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::ruleset
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"ruleset"};
    
    Parse::RecDescent::_trace(q{Trying rule: [ruleset]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{ruleset},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{selector});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

     local $ruleset = new CSS::Style();;


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [selector '\{' WS declaration ';' '\}' WS]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{ruleset});
        %item = (__RULE__ => q{ruleset});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying repeated subrule: [selector]},
                  Parse::RecDescent::_tracefirst($text),
                  q{ruleset},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::selector, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [selector]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{ruleset},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [selector]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{selector(?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
                      Parse::RecDescent::_tracefirst($text),
                      q{ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'\{'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\{/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying repeated subrule: [WS]},
                  Parse::RecDescent::_tracefirst($text),
                  q{ruleset},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{WS})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::WS, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [WS]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{ruleset},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [WS]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{WS(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying repeated subrule: [declaration]},
                  Parse::RecDescent::_tracefirst($text),
                  q{ruleset},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{declaration})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::declaration, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [declaration]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{ruleset},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [declaration]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{declaration(?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying repeated subrule: [';']},
                  Parse::RecDescent::_tracefirst($text),
                  q{ruleset},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{';'})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::_alternation_1_of_production_1_of_rule_ruleset, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [';']>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{ruleset},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [_alternation_1_of_production_1_of_rule_ruleset]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule_ruleset(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
                      Parse::RecDescent::_tracefirst($text),
                      q{ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'\}'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\}/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying repeated subrule: [WS]},
                  Parse::RecDescent::_tracefirst($text),
                  q{ruleset},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{WS})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::WS, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [WS]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{ruleset},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [WS]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{WS(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {push @{$all_rulesets}, $ruleset; 1;};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [selector '\{' WS declaration ';' '\}' WS]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<rulevar: local $ruleset = new CSS::Style();>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{ruleset});
        %item = (__RULE__ => q{ruleset});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{>>Rejecting production<< (found <rulevar: local $ruleset = new CSS::Style();>)},
                     Parse::RecDescent::_tracefirst($text),
                      q{ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $return;
        

        $_tok = undef;
        
        last unless defined $_tok;

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { print "token: ".shift @item; print " : @item\n" };
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
        
        


        Parse::RecDescent::_trace(q{>>Matched production: [<rulevar: local $ruleset = new CSS::Style();>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{ruleset},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{ruleset},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{ruleset},
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
                      q{ruleset},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{ruleset},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::DELIM
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"DELIM"};
    
    Parse::RecDescent::_trace(q{Trying rule: [DELIM]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{DELIM},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/[^0-9a-zA-Z\\\{\\\}\\(\\)\\[\\];]/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/[^0-9a-zA-Z\\\{\\\}\\(\\)\\[\\];]/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{DELIM},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{DELIM});
        %item = (__RULE__ => q{DELIM});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/[^0-9a-zA-Z\\\{\\\}\\(\\)\\[\\];]/]}, Parse::RecDescent::_tracefirst($text),
                      q{DELIM},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[^0-9a-zA-Z\{\}\(\)\[\];])/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{DELIM},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/[^0-9a-zA-Z\\\{\\\}\\(\\)\\[\\];]/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{DELIM},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{DELIM},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{DELIM},
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
                      q{DELIM},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{DELIM},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::PERCENTAGE
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"PERCENTAGE"};
    
    Parse::RecDescent::_trace(q{Trying rule: [PERCENTAGE]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{PERCENTAGE},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{macro_num});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [macro_num '%']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{PERCENTAGE},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{PERCENTAGE});
        %item = (__RULE__ => q{PERCENTAGE});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [macro_num]},
                  Parse::RecDescent::_tracefirst($text),
                  q{PERCENTAGE},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_num($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [macro_num]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{PERCENTAGE},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [macro_num]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{PERCENTAGE},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{macro_num}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: ['%']},
                      Parse::RecDescent::_tracefirst($text),
                      q{PERCENTAGE},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'%'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\%/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{PERCENTAGE},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1].'&'};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [macro_num '%']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{PERCENTAGE},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{PERCENTAGE},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{PERCENTAGE},
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
                      q{PERCENTAGE},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{PERCENTAGE},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::block
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'\{'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['\{' WS any, or block, or ATKEYWORD, or ';' '\}' WS]},
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


        Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
                      Parse::RecDescent::_tracefirst($text),
                      q{block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\{/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying repeated subrule: [WS]},
                  Parse::RecDescent::_tracefirst($text),
                  q{block},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{WS})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::WS, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [WS]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{block},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [WS]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{WS(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying repeated subrule: [any, or block, or ATKEYWORD, or ';']},
                  Parse::RecDescent::_tracefirst($text),
                  q{block},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{any, or block, or ATKEYWORD, or ';'})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::_alternation_1_of_production_1_of_rule_block, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [any, or block, or ATKEYWORD, or ';']>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{block},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [_alternation_1_of_production_1_of_rule_block]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule_block(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
                      Parse::RecDescent::_tracefirst($text),
                      q{block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'\}'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\}/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying repeated subrule: [WS]},
                  Parse::RecDescent::_tracefirst($text),
                  q{block},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{WS})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::CSS::Parse::CompiledGrammar::WS, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [WS]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{block},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [WS]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{WS(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {print "block\n"};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['\{' WS any, or block, or ATKEYWORD, or ';' '\}' WS]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{block},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
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
sub Parse::RecDescent::CSS::Parse::CompiledGrammar::macro_nonascii
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"macro_nonascii"};
    
    Parse::RecDescent::_trace(q{Trying rule: [macro_nonascii]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{macro_nonascii},
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/[^\\0-\\177]/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/[^\\0-\\177]/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{macro_nonascii},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{macro_nonascii});
        %item = (__RULE__ => q{macro_nonascii});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/[^\\0-\\177]/]}, Parse::RecDescent::_tracefirst($text),
                      q{macro_nonascii},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[^\0-\177])/)
        {
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
		$current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nonascii},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {$return = $item[1]};
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/[^\\0-\\177]/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{macro_nonascii},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{macro_nonascii},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{macro_nonascii},
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
                      q{macro_nonascii},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{macro_nonascii},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}
}
package CSS::Parse::CompiledGrammar; sub new { my $self = bless( {
                 '_precompiled' => 1,
                 'localvars' => ' $all_rulesets $ruleset $value',
                 'startcode' => '',
                 'namespace' => 'Parse::RecDescent::CSS::Parse::CompiledGrammar',
                 'rules' => {
                              'macro_nl' => bless( {
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
                                                                                                 'pattern' => '\\n|\\r\\n|\\r|\\f',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/\\\\n|\\\\r\\\\n|\\\\r|\\\\f/',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => 112,
                                                                                                 'mod' => '',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 112,
                                                                                                 'code' => '{$return = $item[1]}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'macro_nl',
                                                     'vars' => '',
                                                     'line' => 112
                                                   }, 'Parse::RecDescent::Rule' ),
                              'IDENT' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [
                                                               'macro_ident'
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
                                                                                              'subrule' => 'macro_ident',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 59
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 59,
                                                                                              'code' => '{$return = $item[1]}'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'IDENT',
                                                  'vars' => '',
                                                  'line' => 58
                                                }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_macro_string1' => bless( {
                                                                                                 'impcount' => 0,
                                                                                                 'calls' => [
                                                                                                              'macro_nl',
                                                                                                              'macro_nonascii',
                                                                                                              'macro_escape'
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
                                                                                                                       'patcount' => 1,
                                                                                                                       'actcount' => 1,
                                                                                                                       'items' => [
                                                                                                                                    bless( {
                                                                                                                                             'pattern' => '[\\t !#$%&(-~]',
                                                                                                                                             'hashname' => '__PATTERN1__',
                                                                                                                                             'description' => '/[\\\\t !#$%&(-~]/',
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'rdelim' => '/',
                                                                                                                                             'line' => 110,
                                                                                                                                             'mod' => '',
                                                                                                                                             'ldelim' => '/'
                                                                                                                                           }, 'Parse::RecDescent::Token' ),
                                                                                                                                    bless( {
                                                                                                                                             'hashname' => '__ACTION1__',
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 110,
                                                                                                                                             'code' => '{$return = $item[1]}'
                                                                                                                                           }, 'Parse::RecDescent::Action' )
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
                                                                                                                       'actcount' => 1,
                                                                                                                       'items' => [
                                                                                                                                    bless( {
                                                                                                                                             'pattern' => '\\',
                                                                                                                                             'hashname' => '__STRING1__',
                                                                                                                                             'description' => '\'\\\\\'',
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 111
                                                                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                                                                    bless( {
                                                                                                                                             'subrule' => 'macro_nl',
                                                                                                                                             'matchrule' => 0,
                                                                                                                                             'implicit' => undef,
                                                                                                                                             'argcode' => undef,
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 111
                                                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                                                    bless( {
                                                                                                                                             'hashname' => '__ACTION1__',
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 111,
                                                                                                                                             'code' => '{$return = \'\'}'
                                                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                                                  ],
                                                                                                                       'line' => 111
                                                                                                                     }, 'Parse::RecDescent::Production' ),
                                                                                                              bless( {
                                                                                                                       'number' => '2',
                                                                                                                       'strcount' => 1,
                                                                                                                       'dircount' => 0,
                                                                                                                       'uncommit' => undef,
                                                                                                                       'error' => undef,
                                                                                                                       'patcount' => 0,
                                                                                                                       'actcount' => 1,
                                                                                                                       'items' => [
                                                                                                                                    bless( {
                                                                                                                                             'pattern' => '\'',
                                                                                                                                             'hashname' => '__STRING1__',
                                                                                                                                             'description' => '\'\'\'',
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 112
                                                                                                                                           }, 'Parse::RecDescent::InterpLit' ),
                                                                                                                                    bless( {
                                                                                                                                             'hashname' => '__ACTION1__',
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 112,
                                                                                                                                             'code' => '{$return = $item[1]}'
                                                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                                                  ],
                                                                                                                       'line' => 112
                                                                                                                     }, 'Parse::RecDescent::Production' ),
                                                                                                              bless( {
                                                                                                                       'number' => '3',
                                                                                                                       'strcount' => 0,
                                                                                                                       'dircount' => 0,
                                                                                                                       'uncommit' => undef,
                                                                                                                       'error' => undef,
                                                                                                                       'patcount' => 0,
                                                                                                                       'actcount' => 1,
                                                                                                                       'items' => [
                                                                                                                                    bless( {
                                                                                                                                             'subrule' => 'macro_nonascii',
                                                                                                                                             'matchrule' => 0,
                                                                                                                                             'implicit' => undef,
                                                                                                                                             'argcode' => undef,
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 113
                                                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                                                    bless( {
                                                                                                                                             'hashname' => '__ACTION1__',
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 113,
                                                                                                                                             'code' => '{$return = $item[1]}'
                                                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                                                  ],
                                                                                                                       'line' => 113
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
                                                                                                                                             'subrule' => 'macro_escape',
                                                                                                                                             'matchrule' => 0,
                                                                                                                                             'implicit' => undef,
                                                                                                                                             'argcode' => undef,
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 114
                                                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                                                    bless( {
                                                                                                                                             'hashname' => '__ACTION1__',
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 114,
                                                                                                                                             'code' => '{$return = $item[1]}'
                                                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                                                  ],
                                                                                                                       'line' => 114
                                                                                                                     }, 'Parse::RecDescent::Production' )
                                                                                                            ],
                                                                                                 'name' => '_alternation_1_of_production_1_of_rule_macro_string1',
                                                                                                 'vars' => '',
                                                                                                 'line' => 109
                                                                                               }, 'Parse::RecDescent::Rule' ),
                              'macro_unicode' => bless( {
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
                                                                                                      'pattern' => '\\[0-9a-f]{1,6}[ \\n\\r\\t\\f]?',
                                                                                                      'hashname' => '__PATTERN1__',
                                                                                                      'description' => '/\\\\[0-9a-f]\\{1,6\\}[ \\\\n\\\\r\\\\t\\\\f]?/',
                                                                                                      'lookahead' => 0,
                                                                                                      'rdelim' => '/',
                                                                                                      'line' => 89,
                                                                                                      'mod' => '',
                                                                                                      'ldelim' => '/'
                                                                                                    }, 'Parse::RecDescent::Token' ),
                                                                                             bless( {
                                                                                                      'hashname' => '__ACTION1__',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 89,
                                                                                                      'code' => '{$return = $item[1]}'
                                                                                                    }, 'Parse::RecDescent::Action' )
                                                                                           ],
                                                                                'line' => undef
                                                                              }, 'Parse::RecDescent::Production' )
                                                                     ],
                                                          'name' => 'macro_unicode',
                                                          'vars' => '',
                                                          'line' => 89
                                                        }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_2_of_rule_URI' => bless( {
                                                                                       'impcount' => 0,
                                                                                       'calls' => [
                                                                                                    'macro_nonascii',
                                                                                                    'macro_escape'
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
                                                                                                             'patcount' => 1,
                                                                                                             'actcount' => 1,
                                                                                                             'items' => [
                                                                                                                          bless( {
                                                                                                                                   'pattern' => '[!#$%&*-~]',
                                                                                                                                   'hashname' => '__PATTERN1__',
                                                                                                                                   'description' => '/[!#$%&*-~]/',
                                                                                                                                   'lookahead' => 0,
                                                                                                                                   'rdelim' => '/',
                                                                                                                                   'line' => 112,
                                                                                                                                   'mod' => '',
                                                                                                                                   'ldelim' => '/'
                                                                                                                                 }, 'Parse::RecDescent::Token' ),
                                                                                                                          bless( {
                                                                                                                                   'hashname' => '__ACTION1__',
                                                                                                                                   'lookahead' => 0,
                                                                                                                                   'line' => 112,
                                                                                                                                   'code' => '{$return = $item[1]}'
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
                                                                                                                                   'subrule' => 'macro_nonascii',
                                                                                                                                   'matchrule' => 0,
                                                                                                                                   'implicit' => undef,
                                                                                                                                   'argcode' => undef,
                                                                                                                                   'lookahead' => 0,
                                                                                                                                   'line' => 113
                                                                                                                                 }, 'Parse::RecDescent::Subrule' ),
                                                                                                                          bless( {
                                                                                                                                   'hashname' => '__ACTION1__',
                                                                                                                                   'lookahead' => 0,
                                                                                                                                   'line' => 113,
                                                                                                                                   'code' => '{$return = $item[1]}'
                                                                                                                                 }, 'Parse::RecDescent::Action' )
                                                                                                                        ],
                                                                                                             'line' => 113
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
                                                                                                                                   'subrule' => 'macro_escape',
                                                                                                                                   'matchrule' => 0,
                                                                                                                                   'implicit' => undef,
                                                                                                                                   'argcode' => undef,
                                                                                                                                   'lookahead' => 0,
                                                                                                                                   'line' => 114
                                                                                                                                 }, 'Parse::RecDescent::Subrule' ),
                                                                                                                          bless( {
                                                                                                                                   'hashname' => '__ACTION1__',
                                                                                                                                   'lookahead' => 0,
                                                                                                                                   'line' => 114,
                                                                                                                                   'code' => '{$return = $item[1]}'
                                                                                                                                 }, 'Parse::RecDescent::Action' )
                                                                                                                        ],
                                                                                                             'line' => 114
                                                                                                           }, 'Parse::RecDescent::Production' )
                                                                                                  ],
                                                                                       'name' => '_alternation_1_of_production_2_of_rule_URI',
                                                                                       'vars' => '',
                                                                                       'line' => 111
                                                                                     }, 'Parse::RecDescent::Rule' ),
                              'atrule' => bless( {
                                                   'impcount' => 1,
                                                   'calls' => [
                                                                'ATKEYWORD',
                                                                'WS',
                                                                'any',
                                                                '_alternation_1_of_production_1_of_rule_atrule'
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
                                                                                               'subrule' => 'ATKEYWORD',
                                                                                               'matchrule' => 0,
                                                                                               'implicit' => undef,
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => 0,
                                                                                               'line' => 13
                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                      bless( {
                                                                                               'subrule' => 'WS',
                                                                                               'expected' => undef,
                                                                                               'min' => 0,
                                                                                               'argcode' => undef,
                                                                                               'max' => 100000000,
                                                                                               'matchrule' => 0,
                                                                                               'repspec' => 's?',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 13
                                                                                             }, 'Parse::RecDescent::Repetition' ),
                                                                                      bless( {
                                                                                               'subrule' => 'any',
                                                                                               'expected' => undef,
                                                                                               'min' => 0,
                                                                                               'argcode' => undef,
                                                                                               'max' => 100000000,
                                                                                               'matchrule' => 0,
                                                                                               'repspec' => 's?',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 13
                                                                                             }, 'Parse::RecDescent::Repetition' ),
                                                                                      bless( {
                                                                                               'subrule' => '_alternation_1_of_production_1_of_rule_atrule',
                                                                                               'matchrule' => 0,
                                                                                               'implicit' => 'block, or \';\'',
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => 0,
                                                                                               'line' => 13
                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 13,
                                                                                               'code' => '{print "at-rule\\n"}'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'atrule',
                                                   'vars' => '',
                                                   'line' => 13
                                                 }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_value' => bless( {
                                                                                         'impcount' => 0,
                                                                                         'calls' => [
                                                                                                      'any',
                                                                                                      'block',
                                                                                                      'ATKEYWORD',
                                                                                                      'OWS'
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
                                                                                                                                     'subrule' => 'any',
                                                                                                                                     'matchrule' => 0,
                                                                                                                                     'implicit' => undef,
                                                                                                                                     'argcode' => undef,
                                                                                                                                     'lookahead' => 0,
                                                                                                                                     'line' => 112
                                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                                                            bless( {
                                                                                                                                     'hashname' => '__ACTION1__',
                                                                                                                                     'lookahead' => 0,
                                                                                                                                     'line' => 112,
                                                                                                                                     'code' => '{$return = $item[1]}'
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
                                                                                                                                     'subrule' => 'block',
                                                                                                                                     'matchrule' => 0,
                                                                                                                                     'implicit' => undef,
                                                                                                                                     'argcode' => undef,
                                                                                                                                     'lookahead' => 0,
                                                                                                                                     'line' => 113
                                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                                                            bless( {
                                                                                                                                     'hashname' => '__ACTION1__',
                                                                                                                                     'lookahead' => 0,
                                                                                                                                     'line' => 113,
                                                                                                                                     'code' => '{$return = $item[1]}'
                                                                                                                                   }, 'Parse::RecDescent::Action' )
                                                                                                                          ],
                                                                                                               'line' => 113
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
                                                                                                                                     'subrule' => 'ATKEYWORD',
                                                                                                                                     'matchrule' => 0,
                                                                                                                                     'implicit' => undef,
                                                                                                                                     'argcode' => undef,
                                                                                                                                     'lookahead' => 0,
                                                                                                                                     'line' => 114
                                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                                                            bless( {
                                                                                                                                     'subrule' => 'OWS',
                                                                                                                                     'matchrule' => 0,
                                                                                                                                     'implicit' => undef,
                                                                                                                                     'argcode' => undef,
                                                                                                                                     'lookahead' => 0,
                                                                                                                                     'line' => 114
                                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                                                            bless( {
                                                                                                                                     'hashname' => '__ACTION1__',
                                                                                                                                     'lookahead' => 0,
                                                                                                                                     'line' => 114,
                                                                                                                                     'code' => '{$return = $item[1].$item[2]}'
                                                                                                                                   }, 'Parse::RecDescent::Action' )
                                                                                                                          ],
                                                                                                               'line' => 114
                                                                                                             }, 'Parse::RecDescent::Production' )
                                                                                                    ],
                                                                                         'name' => '_alternation_1_of_production_1_of_rule_value',
                                                                                         'vars' => '',
                                                                                         'line' => 111
                                                                                       }, 'Parse::RecDescent::Rule' ),
                              'statement' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'ruleset',
                                                                   'atrule'
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
                                                                                                  'subrule' => 'ruleset',
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
                                                                                                  'code' => '{4;}'
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
                                                                                                  'subrule' => 'atrule',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 12
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 12,
                                                                                                  'code' => '{5;}'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => 12
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'statement',
                                                      'vars' => '',
                                                      'line' => 11
                                                    }, 'Parse::RecDescent::Rule' ),
                              'HASH' => bless( {
                                                 'impcount' => 0,
                                                 'calls' => [
                                                              'macro_name'
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
                                                                                             'pattern' => '#',
                                                                                             'hashname' => '__STRING1__',
                                                                                             'description' => '\'#\'',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 62
                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                    bless( {
                                                                                             'subrule' => 'macro_name',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => 62
                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                    bless( {
                                                                                             'hashname' => '__ACTION1__',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 62,
                                                                                             'code' => '{$return = \'#\'.$item[2]}'
                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'HASH',
                                                 'vars' => '',
                                                 'line' => 62
                                               }, 'Parse::RecDescent::Rule' ),
                              'property' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [
                                                                  'IDENT',
                                                                  'OWS'
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
                                                                                                 'line' => 34
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'subrule' => 'OWS',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 34
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 34,
                                                                                                 'code' => '{$return = $item[1]}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'property',
                                                     'vars' => '',
                                                     'line' => 34
                                                   }, 'Parse::RecDescent::Rule' ),
                              'OWS' => bless( {
                                                'impcount' => 0,
                                                'calls' => [
                                                             'WS'
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
                                                                                            'subrule' => 'WS',
                                                                                            'expected' => undef,
                                                                                            'min' => 0,
                                                                                            'argcode' => undef,
                                                                                            'max' => 100000000,
                                                                                            'matchrule' => 0,
                                                                                            'repspec' => 's?',
                                                                                            'lookahead' => 0,
                                                                                            'line' => 74
                                                                                          }, 'Parse::RecDescent::Repetition' ),
                                                                                   bless( {
                                                                                            'hashname' => '__ACTION1__',
                                                                                            'lookahead' => 0,
                                                                                            'line' => 74,
                                                                                            'code' => '{$return = \'\'; if (scalar(@{$item[1]}) > 0){$return = \' \';} 1;}'
                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                 ],
                                                                      'line' => undef
                                                                    }, 'Parse::RecDescent::Production' )
                                                           ],
                                                'name' => 'OWS',
                                                'vars' => '',
                                                'line' => 74
                                              }, 'Parse::RecDescent::Rule' ),
                              'selector' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [
                                                                  'any'
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
                                                                                                 'subrule' => 'any',
                                                                                                 'expected' => undef,
                                                                                                 'min' => 1,
                                                                                                 'argcode' => undef,
                                                                                                 'max' => 100000000,
                                                                                                 'matchrule' => 0,
                                                                                                 'repspec' => 's',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 19
                                                                                               }, 'Parse::RecDescent::Repetition' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 20,
                                                                                                 'code' => '{
						$ruleset->add_selector(new CSS::Selector({\'name\' => $_})) 
						for(map{s/^\\s*(.*?)\\s*$/$1/;$_}split /\\s*,\\s*/, join(\'\',@{$item[1]}));
						1;
					}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'selector',
                                                     'vars' => '',
                                                     'line' => 19
                                                   }, 'Parse::RecDescent::Rule' ),
                              'value' => bless( {
                                                  'impcount' => 1,
                                                  'calls' => [
                                                               '_alternation_1_of_production_1_of_rule_value'
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
                                                                                              'subrule' => '_alternation_1_of_production_1_of_rule_value',
                                                                                              'expected' => 'any, or block, or ATKEYWORD',
                                                                                              'min' => 1,
                                                                                              'argcode' => undef,
                                                                                              'max' => 100000000,
                                                                                              'matchrule' => 0,
                                                                                              'repspec' => 's',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 39
                                                                                            }, 'Parse::RecDescent::Repetition' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 39,
                                                                                              'code' => '{$return = join(\'\',@{$item[1]})}'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'value',
                                                  'vars' => '',
                                                  'line' => 35
                                                }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_atrule' => bless( {
                                                                                          'impcount' => 0,
                                                                                          'calls' => [
                                                                                                       'block',
                                                                                                       'WS'
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
                                                                                                                                      'matchrule' => 0,
                                                                                                                                      'implicit' => undef,
                                                                                                                                      'argcode' => undef,
                                                                                                                                      'lookahead' => 0,
                                                                                                                                      'line' => 115
                                                                                                                                    }, 'Parse::RecDescent::Subrule' )
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
                                                                                                                                      'pattern' => ';',
                                                                                                                                      'hashname' => '__STRING1__',
                                                                                                                                      'description' => '\';\'',
                                                                                                                                      'lookahead' => 0,
                                                                                                                                      'line' => 115
                                                                                                                                    }, 'Parse::RecDescent::Literal' ),
                                                                                                                             bless( {
                                                                                                                                      'subrule' => 'WS',
                                                                                                                                      'expected' => undef,
                                                                                                                                      'min' => 0,
                                                                                                                                      'argcode' => undef,
                                                                                                                                      'max' => 100000000,
                                                                                                                                      'matchrule' => 0,
                                                                                                                                      'repspec' => 's?',
                                                                                                                                      'lookahead' => 0,
                                                                                                                                      'line' => 115
                                                                                                                                    }, 'Parse::RecDescent::Repetition' )
                                                                                                                           ],
                                                                                                                'line' => 115
                                                                                                              }, 'Parse::RecDescent::Production' )
                                                                                                     ],
                                                                                          'name' => '_alternation_1_of_production_1_of_rule_atrule',
                                                                                          'vars' => '',
                                                                                          'line' => 115
                                                                                        }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_ruleset' => bless( {
                                                                                           'impcount' => 0,
                                                                                           'calls' => [
                                                                                                        'WS',
                                                                                                        'declaration'
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
                                                                                                                                       'pattern' => ';',
                                                                                                                                       'hashname' => '__STRING1__',
                                                                                                                                       'description' => '\';\'',
                                                                                                                                       'lookahead' => 0,
                                                                                                                                       'line' => 114
                                                                                                                                     }, 'Parse::RecDescent::Literal' ),
                                                                                                                              bless( {
                                                                                                                                       'subrule' => 'WS',
                                                                                                                                       'expected' => undef,
                                                                                                                                       'min' => 0,
                                                                                                                                       'argcode' => undef,
                                                                                                                                       'max' => 100000000,
                                                                                                                                       'matchrule' => 0,
                                                                                                                                       'repspec' => 's?',
                                                                                                                                       'lookahead' => 0,
                                                                                                                                       'line' => 114
                                                                                                                                     }, 'Parse::RecDescent::Repetition' ),
                                                                                                                              bless( {
                                                                                                                                       'subrule' => 'declaration',
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
                                                                                                                                       'hashname' => '__ACTION1__',
                                                                                                                                       'lookahead' => 0,
                                                                                                                                       'line' => 114,
                                                                                                                                       'code' => '{6;}'
                                                                                                                                     }, 'Parse::RecDescent::Action' )
                                                                                                                            ],
                                                                                                                 'line' => undef
                                                                                                               }, 'Parse::RecDescent::Production' )
                                                                                                      ],
                                                                                           'name' => '_alternation_1_of_production_1_of_rule_ruleset',
                                                                                           'vars' => '',
                                                                                           'line' => 113
                                                                                         }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_block' => bless( {
                                                                                         'impcount' => 0,
                                                                                         'calls' => [
                                                                                                      'any',
                                                                                                      'block',
                                                                                                      'ATKEYWORD',
                                                                                                      'WS'
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
                                                                                                                                     'subrule' => 'any',
                                                                                                                                     'matchrule' => 0,
                                                                                                                                     'implicit' => undef,
                                                                                                                                     'argcode' => undef,
                                                                                                                                     'lookahead' => 0,
                                                                                                                                     'line' => 115
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
                                                                                                                                     'subrule' => 'block',
                                                                                                                                     'matchrule' => 0,
                                                                                                                                     'implicit' => undef,
                                                                                                                                     'argcode' => undef,
                                                                                                                                     'lookahead' => 0,
                                                                                                                                     'line' => 115
                                                                                                                                   }, 'Parse::RecDescent::Subrule' )
                                                                                                                          ],
                                                                                                               'line' => 115
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
                                                                                                                                     'subrule' => 'ATKEYWORD',
                                                                                                                                     'matchrule' => 0,
                                                                                                                                     'implicit' => undef,
                                                                                                                                     'argcode' => undef,
                                                                                                                                     'lookahead' => 0,
                                                                                                                                     'line' => 115
                                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                                                            bless( {
                                                                                                                                     'subrule' => 'WS',
                                                                                                                                     'expected' => undef,
                                                                                                                                     'min' => 0,
                                                                                                                                     'argcode' => undef,
                                                                                                                                     'max' => 100000000,
                                                                                                                                     'matchrule' => 0,
                                                                                                                                     'repspec' => 's?',
                                                                                                                                     'lookahead' => 0,
                                                                                                                                     'line' => 115
                                                                                                                                   }, 'Parse::RecDescent::Repetition' )
                                                                                                                          ],
                                                                                                               'line' => 115
                                                                                                             }, 'Parse::RecDescent::Production' ),
                                                                                                      bless( {
                                                                                                               'number' => '3',
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
                                                                                                                                     'line' => 115
                                                                                                                                   }, 'Parse::RecDescent::Literal' )
                                                                                                                          ],
                                                                                                               'line' => 115
                                                                                                             }, 'Parse::RecDescent::Production' )
                                                                                                    ],
                                                                                         'name' => '_alternation_1_of_production_1_of_rule_block',
                                                                                         'vars' => '',
                                                                                         'line' => 115
                                                                                       }, 'Parse::RecDescent::Rule' ),
                              'WS' => bless( {
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
                                                                                           'pattern' => '[ \\t\\r\\n\\f]+',
                                                                                           'hashname' => '__PATTERN1__',
                                                                                           'description' => '/[ \\\\t\\\\r\\\\n\\\\f]+/',
                                                                                           'lookahead' => 0,
                                                                                           'rdelim' => '/',
                                                                                           'line' => 73,
                                                                                           'mod' => '',
                                                                                           'ldelim' => '/'
                                                                                         }, 'Parse::RecDescent::Token' ),
                                                                                  bless( {
                                                                                           'hashname' => '__ACTION1__',
                                                                                           'lookahead' => 0,
                                                                                           'line' => 73,
                                                                                           'code' => '{$return = \' \';}'
                                                                                         }, 'Parse::RecDescent::Action' )
                                                                                ],
                                                                     'line' => undef
                                                                   }, 'Parse::RecDescent::Production' )
                                                          ],
                                               'name' => 'WS',
                                               'vars' => '',
                                               'line' => 73
                                             }, 'Parse::RecDescent::Rule' ),
                              'macro_ident' => bless( {
                                                        'impcount' => 0,
                                                        'calls' => [
                                                                     'macro_nmstart',
                                                                     'macro_nmchar'
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
                                                                                                    'subrule' => 'macro_nmstart',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 83
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'macro_nmchar',
                                                                                                    'expected' => undef,
                                                                                                    'min' => 0,
                                                                                                    'argcode' => undef,
                                                                                                    'max' => 100000000,
                                                                                                    'matchrule' => 0,
                                                                                                    'repspec' => 's?',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 83
                                                                                                  }, 'Parse::RecDescent::Repetition' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 83,
                                                                                                    'code' => '{$return = $item[1]; if (scalar(@{$item[2]}) > 0){$return .= join(\'\',@{$item[2]});} 1;}'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'macro_ident',
                                                        'vars' => '',
                                                        'line' => 82
                                                      }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_macro_string2' => bless( {
                                                                                                 'impcount' => 0,
                                                                                                 'calls' => [
                                                                                                              'macro_nl',
                                                                                                              'macro_nonascii',
                                                                                                              'macro_escape'
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
                                                                                                                       'patcount' => 1,
                                                                                                                       'actcount' => 1,
                                                                                                                       'items' => [
                                                                                                                                    bless( {
                                                                                                                                             'pattern' => '[\\t !#$%&(-~]',
                                                                                                                                             'hashname' => '__PATTERN1__',
                                                                                                                                             'description' => '/[\\\\t !#$%&(-~]/',
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'rdelim' => '/',
                                                                                                                                             'line' => 110,
                                                                                                                                             'mod' => '',
                                                                                                                                             'ldelim' => '/'
                                                                                                                                           }, 'Parse::RecDescent::Token' ),
                                                                                                                                    bless( {
                                                                                                                                             'hashname' => '__ACTION1__',
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 110,
                                                                                                                                             'code' => '{$return = $item[1]}'
                                                                                                                                           }, 'Parse::RecDescent::Action' )
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
                                                                                                                       'actcount' => 1,
                                                                                                                       'items' => [
                                                                                                                                    bless( {
                                                                                                                                             'pattern' => '\\',
                                                                                                                                             'hashname' => '__STRING1__',
                                                                                                                                             'description' => '\'\\\\\'',
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 111
                                                                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                                                                    bless( {
                                                                                                                                             'subrule' => 'macro_nl',
                                                                                                                                             'matchrule' => 0,
                                                                                                                                             'implicit' => undef,
                                                                                                                                             'argcode' => undef,
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 111
                                                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                                                    bless( {
                                                                                                                                             'hashname' => '__ACTION1__',
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 111,
                                                                                                                                             'code' => '{$return = \'\'}'
                                                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                                                  ],
                                                                                                                       'line' => 111
                                                                                                                     }, 'Parse::RecDescent::Production' ),
                                                                                                              bless( {
                                                                                                                       'number' => '2',
                                                                                                                       'strcount' => 1,
                                                                                                                       'dircount' => 0,
                                                                                                                       'uncommit' => undef,
                                                                                                                       'error' => undef,
                                                                                                                       'patcount' => 0,
                                                                                                                       'actcount' => 1,
                                                                                                                       'items' => [
                                                                                                                                    bless( {
                                                                                                                                             'pattern' => '"',
                                                                                                                                             'hashname' => '__STRING1__',
                                                                                                                                             'description' => '\'"\'',
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 112
                                                                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                                                                    bless( {
                                                                                                                                             'hashname' => '__ACTION1__',
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 112,
                                                                                                                                             'code' => '{$return = $item[1]}'
                                                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                                                  ],
                                                                                                                       'line' => 112
                                                                                                                     }, 'Parse::RecDescent::Production' ),
                                                                                                              bless( {
                                                                                                                       'number' => '3',
                                                                                                                       'strcount' => 0,
                                                                                                                       'dircount' => 0,
                                                                                                                       'uncommit' => undef,
                                                                                                                       'error' => undef,
                                                                                                                       'patcount' => 0,
                                                                                                                       'actcount' => 1,
                                                                                                                       'items' => [
                                                                                                                                    bless( {
                                                                                                                                             'subrule' => 'macro_nonascii',
                                                                                                                                             'matchrule' => 0,
                                                                                                                                             'implicit' => undef,
                                                                                                                                             'argcode' => undef,
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 113
                                                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                                                    bless( {
                                                                                                                                             'hashname' => '__ACTION1__',
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 113,
                                                                                                                                             'code' => '{$return = $item[1]}'
                                                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                                                  ],
                                                                                                                       'line' => 113
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
                                                                                                                                             'subrule' => 'macro_escape',
                                                                                                                                             'matchrule' => 0,
                                                                                                                                             'implicit' => undef,
                                                                                                                                             'argcode' => undef,
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 114
                                                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                                                    bless( {
                                                                                                                                             'hashname' => '__ACTION1__',
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'line' => 114,
                                                                                                                                             'code' => '{$return = $item[1]}'
                                                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                                                  ],
                                                                                                                       'line' => 114
                                                                                                                     }, 'Parse::RecDescent::Production' )
                                                                                                            ],
                                                                                                 'name' => '_alternation_1_of_production_1_of_rule_macro_string2',
                                                                                                 'vars' => '',
                                                                                                 'line' => 109
                                                                                               }, 'Parse::RecDescent::Rule' ),
                              'macro_nmstart' => bless( {
                                                          'impcount' => 0,
                                                          'calls' => [
                                                                       'macro_nonascii',
                                                                       'macro_escape'
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
                                                                                'patcount' => 1,
                                                                                'actcount' => 1,
                                                                                'items' => [
                                                                                             bless( {
                                                                                                      'pattern' => '[a-zA-Z]',
                                                                                                      'hashname' => '__PATTERN1__',
                                                                                                      'description' => '/[a-zA-Z]/',
                                                                                                      'lookahead' => 0,
                                                                                                      'rdelim' => '/',
                                                                                                      'line' => 85,
                                                                                                      'mod' => '',
                                                                                                      'ldelim' => '/'
                                                                                                    }, 'Parse::RecDescent::Token' ),
                                                                                             bless( {
                                                                                                      'hashname' => '__ACTION1__',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 85,
                                                                                                      'code' => '{$return = $item[1]}'
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
                                                                                                      'subrule' => 'macro_nonascii',
                                                                                                      'matchrule' => 0,
                                                                                                      'implicit' => undef,
                                                                                                      'argcode' => undef,
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 86
                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                             bless( {
                                                                                                      'hashname' => '__ACTION1__',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 86,
                                                                                                      'code' => '{$return = $item[1]}'
                                                                                                    }, 'Parse::RecDescent::Action' )
                                                                                           ],
                                                                                'line' => 86
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
                                                                                                      'subrule' => 'macro_escape',
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
                                                                                                      'code' => '{$return = $item[1]}'
                                                                                                    }, 'Parse::RecDescent::Action' )
                                                                                           ],
                                                                                'line' => 87
                                                                              }, 'Parse::RecDescent::Production' )
                                                                     ],
                                                          'name' => 'macro_nmstart',
                                                          'vars' => '',
                                                          'line' => 85
                                                        }, 'Parse::RecDescent::Rule' ),
                              'INCLUDES' => bless( {
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
                                                                                                 'pattern' => '~=',
                                                                                                 'hashname' => '__STRING1__',
                                                                                                 'description' => '\'~=\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 76
                                                                                               }, 'Parse::RecDescent::Literal' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 76,
                                                                                                 'code' => '{$return = $item[1]}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'INCLUDES',
                                                     'vars' => '',
                                                     'line' => 76
                                                   }, 'Parse::RecDescent::Rule' ),
                              'macro_string1' => bless( {
                                                          'impcount' => 1,
                                                          'calls' => [
                                                                       '_alternation_1_of_production_1_of_rule_macro_string1'
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
                                                                                                      'pattern' => '"',
                                                                                                      'hashname' => '__STRING1__',
                                                                                                      'description' => '\'"\'',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 98
                                                                                                    }, 'Parse::RecDescent::Literal' ),
                                                                                             bless( {
                                                                                                      'subrule' => '_alternation_1_of_production_1_of_rule_macro_string1',
                                                                                                      'expected' => '/[\\\\t !#$%&(-~]/, or \'\\\\\', or \'\'\', or macro_nonascii, or macro_escape',
                                                                                                      'min' => 0,
                                                                                                      'argcode' => undef,
                                                                                                      'max' => 100000000,
                                                                                                      'matchrule' => 0,
                                                                                                      'repspec' => 's?',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 104
                                                                                                    }, 'Parse::RecDescent::Repetition' ),
                                                                                             bless( {
                                                                                                      'pattern' => '"',
                                                                                                      'hashname' => '__STRING2__',
                                                                                                      'description' => '\'"\'',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 104
                                                                                                    }, 'Parse::RecDescent::Literal' ),
                                                                                             bless( {
                                                                                                      'hashname' => '__ACTION1__',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 104,
                                                                                                      'code' => '{$return = \'"\'.join(\'\', @{$item[2]}).\'"\'}'
                                                                                                    }, 'Parse::RecDescent::Action' )
                                                                                           ],
                                                                                'line' => undef
                                                                              }, 'Parse::RecDescent::Production' )
                                                                     ],
                                                          'name' => 'macro_string1',
                                                          'vars' => '',
                                                          'line' => 98
                                                        }, 'Parse::RecDescent::Rule' ),
                              'macro_string' => bless( {
                                                         'impcount' => 0,
                                                         'calls' => [
                                                                      'macro_string1',
                                                                      'macro_string2'
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
                                                                                                     'subrule' => 'macro_string1',
                                                                                                     'matchrule' => 0,
                                                                                                     'implicit' => undef,
                                                                                                     'argcode' => undef,
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 96
                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                            bless( {
                                                                                                     'hashname' => '__ACTION1__',
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 96,
                                                                                                     'code' => '{$return = $item[1]}'
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
                                                                                                     'subrule' => 'macro_string2',
                                                                                                     'matchrule' => 0,
                                                                                                     'implicit' => undef,
                                                                                                     'argcode' => undef,
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 97
                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                            bless( {
                                                                                                     'hashname' => '__ACTION1__',
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 97,
                                                                                                     'code' => '{$return = $item[1]}'
                                                                                                   }, 'Parse::RecDescent::Action' )
                                                                                          ],
                                                                               'line' => 97
                                                                             }, 'Parse::RecDescent::Production' )
                                                                    ],
                                                         'name' => 'macro_string',
                                                         'vars' => '',
                                                         'line' => 96
                                                       }, 'Parse::RecDescent::Rule' ),
                              'UNICODERANGE' => bless( {
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
                                                                                                     'pattern' => 'U\\+[0-9A-F?]{1,6}(-[0-9A-F]{1,6})?',
                                                                                                     'hashname' => '__PATTERN1__',
                                                                                                     'description' => '/U\\\\+[0-9A-F?]\\{1,6\\}(-[0-9A-F]\\{1,6\\})?/',
                                                                                                     'lookahead' => 0,
                                                                                                     'rdelim' => '/',
                                                                                                     'line' => 72,
                                                                                                     'mod' => '',
                                                                                                     'ldelim' => '/'
                                                                                                   }, 'Parse::RecDescent::Token' ),
                                                                                            bless( {
                                                                                                     'hashname' => '__ACTION1__',
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 72,
                                                                                                     'code' => '{$return = $item[1]}'
                                                                                                   }, 'Parse::RecDescent::Action' )
                                                                                          ],
                                                                               'line' => undef
                                                                             }, 'Parse::RecDescent::Production' )
                                                                    ],
                                                         'name' => 'UNICODERANGE',
                                                         'vars' => '',
                                                         'line' => 72
                                                       }, 'Parse::RecDescent::Rule' ),
                              'macro_w' => bless( {
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
                                                                                                'pattern' => '[ \\t\\r\\n\\f]*',
                                                                                                'hashname' => '__PATTERN1__',
                                                                                                'description' => '/[ \\\\t\\\\r\\\\n\\\\f]*/',
                                                                                                'lookahead' => 0,
                                                                                                'rdelim' => '/',
                                                                                                'line' => 113,
                                                                                                'mod' => '',
                                                                                                'ldelim' => '/'
                                                                                              }, 'Parse::RecDescent::Token' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 113,
                                                                                                'code' => '{$return = $item[1]}'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'macro_w',
                                                    'vars' => '',
                                                    'line' => 113
                                                  }, 'Parse::RecDescent::Rule' ),
                              'STRING' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'macro_string'
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
                                                                                               'subrule' => 'macro_string',
                                                                                               'matchrule' => 0,
                                                                                               'implicit' => undef,
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => 0,
                                                                                               'line' => 61
                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 61,
                                                                                               'code' => '{$return = $item[1]}'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'STRING',
                                                   'vars' => '',
                                                   'line' => 61
                                                 }, 'Parse::RecDescent::Rule' ),
                              'DIMENSION' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'macro_num',
                                                                   'macro_ident'
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
                                                                                                  'subrule' => 'macro_num',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 65
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'macro_ident',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 65
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 65,
                                                                                                  'code' => '{$return = $item[1].$item[2]}'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'DIMENSION',
                                                      'vars' => '',
                                                      'line' => 65
                                                    }, 'Parse::RecDescent::Rule' ),
                              'macro_string2' => bless( {
                                                          'impcount' => 1,
                                                          'calls' => [
                                                                       '_alternation_1_of_production_1_of_rule_macro_string2'
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
                                                                                                      'pattern' => '\'',
                                                                                                      'hashname' => '__STRING1__',
                                                                                                      'description' => '\'\'\'',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 105
                                                                                                    }, 'Parse::RecDescent::InterpLit' ),
                                                                                             bless( {
                                                                                                      'subrule' => '_alternation_1_of_production_1_of_rule_macro_string2',
                                                                                                      'expected' => '/[\\\\t !#$%&(-~]/, or \'\\\\\', or \'"\', or macro_nonascii, or macro_escape',
                                                                                                      'min' => 0,
                                                                                                      'argcode' => undef,
                                                                                                      'max' => 100000000,
                                                                                                      'matchrule' => 0,
                                                                                                      'repspec' => 's?',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 111
                                                                                                    }, 'Parse::RecDescent::Repetition' ),
                                                                                             bless( {
                                                                                                      'pattern' => '\'',
                                                                                                      'hashname' => '__STRING2__',
                                                                                                      'description' => '\'\'\'',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 111
                                                                                                    }, 'Parse::RecDescent::InterpLit' ),
                                                                                             bless( {
                                                                                                      'hashname' => '__ACTION1__',
                                                                                                      'lookahead' => 0,
                                                                                                      'line' => 111,
                                                                                                      'code' => '{return "\'".join(\'\', @{$item[2]})."\'"}'
                                                                                                    }, 'Parse::RecDescent::Action' )
                                                                                           ],
                                                                                'line' => undef
                                                                              }, 'Parse::RecDescent::Production' )
                                                                     ],
                                                          'name' => 'macro_string2',
                                                          'vars' => '',
                                                          'line' => 105
                                                        }, 'Parse::RecDescent::Rule' ),
                              'macro_num' => bless( {
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
                                                                                                  'pattern' => '[0-9]+|[0-9]*\\.[0-9]+',
                                                                                                  'hashname' => '__PATTERN1__',
                                                                                                  'description' => '/[0-9]+|[0-9]*\\\\.[0-9]+/',
                                                                                                  'lookahead' => 0,
                                                                                                  'rdelim' => '/',
                                                                                                  'line' => 95,
                                                                                                  'mod' => '',
                                                                                                  'ldelim' => '/'
                                                                                                }, 'Parse::RecDescent::Token' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 95,
                                                                                                  'code' => '{$return = $item[1]}'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'macro_num',
                                                      'vars' => '',
                                                      'line' => 95
                                                    }, 'Parse::RecDescent::Rule' ),
                              'declaration' => bless( {
                                                        'impcount' => 0,
                                                        'calls' => [
                                                                     'property',
                                                                     'WS',
                                                                     'value'
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
                                                                                                    'subrule' => 'property',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 25
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'pattern' => ':',
                                                                                                    'hashname' => '__STRING1__',
                                                                                                    'description' => '\':\'',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 25
                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'WS',
                                                                                                    'expected' => undef,
                                                                                                    'min' => 0,
                                                                                                    'argcode' => undef,
                                                                                                    'max' => 100000000,
                                                                                                    'matchrule' => 0,
                                                                                                    'repspec' => 's?',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 25
                                                                                                  }, 'Parse::RecDescent::Repetition' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'value',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 25
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 26,
                                                                                                    'code' => '{
						$ruleset->add_property(new CSS::Property({
							\'property\' => $item[1],
							\'value\' => $item[4],
						}));
						1;
					}'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' ),
                                                                     bless( {
                                                                              'number' => '1',
                                                                              'strcount' => 0,
                                                                              'dircount' => 1,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 0,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'hashname' => '__DIRECTIVE1__',
                                                                                                    'name' => '<rulevar: local $value>',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 33
                                                                                                  }, 'Parse::RecDescent::UncondReject' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'declaration',
                                                        'vars' => ' local $value;
',
                                                        'line' => 25
                                                      }, 'Parse::RecDescent::Rule' ),
                              'macro_escape' => bless( {
                                                         'impcount' => 0,
                                                         'calls' => [
                                                                      'macro_unicode'
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
                                                                                                     'subrule' => 'macro_unicode',
                                                                                                     'matchrule' => 0,
                                                                                                     'implicit' => undef,
                                                                                                     'argcode' => undef,
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 90
                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                            bless( {
                                                                                                     'hashname' => '__ACTION1__',
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 90,
                                                                                                     'code' => '{$return = $item[1]}'
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
                                                                                                     'pattern' => '\\\\[ -~\\200-\\4177777]',
                                                                                                     'hashname' => '__PATTERN1__',
                                                                                                     'description' => '/\\\\\\\\[ -~\\\\200-\\\\4177777]/',
                                                                                                     'lookahead' => 0,
                                                                                                     'rdelim' => '/',
                                                                                                     'line' => 91,
                                                                                                     'mod' => '',
                                                                                                     'ldelim' => '/'
                                                                                                   }, 'Parse::RecDescent::Token' ),
                                                                                            bless( {
                                                                                                     'hashname' => '__ACTION1__',
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 91,
                                                                                                     'code' => '{$return = $item[1]}'
                                                                                                   }, 'Parse::RecDescent::Action' )
                                                                                          ],
                                                                               'line' => 91
                                                                             }, 'Parse::RecDescent::Production' )
                                                                    ],
                                                         'name' => 'macro_escape',
                                                         'vars' => '',
                                                         'line' => 90
                                                       }, 'Parse::RecDescent::Rule' ),
                              'FUNCTION' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [
                                                                  'macro_ident'
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
                                                                                                 'subrule' => 'macro_ident',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 75
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'pattern' => '(',
                                                                                                 'hashname' => '__STRING1__',
                                                                                                 'description' => '\'(\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 75
                                                                                               }, 'Parse::RecDescent::Literal' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 75,
                                                                                                 'code' => '{$return = $item[1].\'(\'}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'FUNCTION',
                                                     'vars' => '',
                                                     'line' => 75
                                                   }, 'Parse::RecDescent::Rule' ),
                              'stylesheet' => bless( {
                                                       'impcount' => 0,
                                                       'calls' => [
                                                                    '_alternation_1_of_production_1_of_rule_stylesheet'
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
                                                                                                   'subrule' => '_alternation_1_of_production_1_of_rule_stylesheet',
                                                                                                   'expected' => 'WS, or statement',
                                                                                                   'min' => 1,
                                                                                                   'argcode' => undef,
                                                                                                   'max' => 100000000,
                                                                                                   'matchrule' => 0,
                                                                                                   'repspec' => 's',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => 9
                                                                                                 }, 'Parse::RecDescent::Repetition' ),
                                                                                          bless( {
                                                                                                   'hashname' => '__ACTION1__',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => 9,
                                                                                                   'code' => '{$return = $all_rulesets;}'
                                                                                                 }, 'Parse::RecDescent::Action' )
                                                                                        ],
                                                                             'line' => undef
                                                                           }, 'Parse::RecDescent::Production' ),
                                                                    bless( {
                                                                             'number' => '1',
                                                                             'strcount' => 0,
                                                                             'dircount' => 1,
                                                                             'uncommit' => undef,
                                                                             'error' => undef,
                                                                             'patcount' => 0,
                                                                             'actcount' => 0,
                                                                             'items' => [
                                                                                          bless( {
                                                                                                   'hashname' => '__DIRECTIVE1__',
                                                                                                   'name' => '<rulevar: local $all_rulesets>',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => 10
                                                                                                 }, 'Parse::RecDescent::UncondReject' )
                                                                                        ],
                                                                             'line' => undef
                                                                           }, 'Parse::RecDescent::Production' )
                                                                  ],
                                                       'name' => 'stylesheet',
                                                       'vars' => ' local $all_rulesets;
',
                                                       'line' => 5
                                                     }, 'Parse::RecDescent::Rule' ),
                              'NUMBER' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'macro_num'
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
                                                                                               'subrule' => 'macro_num',
                                                                                               'matchrule' => 0,
                                                                                               'implicit' => undef,
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => 0,
                                                                                               'line' => 63
                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 63,
                                                                                               'code' => '{$return = $item[1]}'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'NUMBER',
                                                   'vars' => '',
                                                   'line' => 63
                                                 }, 'Parse::RecDescent::Rule' ),
                              'macro_name' => bless( {
                                                       'impcount' => 0,
                                                       'calls' => [
                                                                    'macro_nmchar'
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
                                                                                                   'subrule' => 'macro_nmchar',
                                                                                                   'expected' => undef,
                                                                                                   'min' => 1,
                                                                                                   'argcode' => undef,
                                                                                                   'max' => 100000000,
                                                                                                   'matchrule' => 0,
                                                                                                   'repspec' => 's',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => 84
                                                                                                 }, 'Parse::RecDescent::Repetition' ),
                                                                                          bless( {
                                                                                                   'hashname' => '__ACTION1__',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => 84,
                                                                                                   'code' => '{$return = join(\'\',@{$item[1]})}'
                                                                                                 }, 'Parse::RecDescent::Action' )
                                                                                        ],
                                                                             'line' => undef
                                                                           }, 'Parse::RecDescent::Production' )
                                                                  ],
                                                       'name' => 'macro_name',
                                                       'vars' => '',
                                                       'line' => 84
                                                     }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_stylesheet' => bless( {
                                                                                              'impcount' => 0,
                                                                                              'calls' => [
                                                                                                           'WS',
                                                                                                           'statement'
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
                                                                                                                                          'subrule' => 'WS',
                                                                                                                                          'matchrule' => 0,
                                                                                                                                          'implicit' => undef,
                                                                                                                                          'argcode' => undef,
                                                                                                                                          'lookahead' => 0,
                                                                                                                                          'line' => 113
                                                                                                                                        }, 'Parse::RecDescent::Subrule' ),
                                                                                                                                 bless( {
                                                                                                                                          'hashname' => '__ACTION1__',
                                                                                                                                          'lookahead' => 0,
                                                                                                                                          'line' => 113,
                                                                                                                                          'code' => '{2;}'
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
                                                                                                                                          'subrule' => 'statement',
                                                                                                                                          'matchrule' => 0,
                                                                                                                                          'implicit' => undef,
                                                                                                                                          'argcode' => undef,
                                                                                                                                          'lookahead' => 0,
                                                                                                                                          'line' => 114
                                                                                                                                        }, 'Parse::RecDescent::Subrule' ),
                                                                                                                                 bless( {
                                                                                                                                          'hashname' => '__ACTION1__',
                                                                                                                                          'lookahead' => 0,
                                                                                                                                          'line' => 114,
                                                                                                                                          'code' => '{3;}'
                                                                                                                                        }, 'Parse::RecDescent::Action' )
                                                                                                                               ],
                                                                                                                    'line' => 114
                                                                                                                  }, 'Parse::RecDescent::Production' )
                                                                                                         ],
                                                                                              'name' => '_alternation_1_of_production_1_of_rule_stylesheet',
                                                                                              'vars' => '',
                                                                                              'line' => 112
                                                                                            }, 'Parse::RecDescent::Rule' ),
                              'ATKEYWORD' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'macro_ident'
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
                                                                                                  'pattern' => '@',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'@\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 60
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'macro_ident',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 60
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 60,
                                                                                                  'code' => '{$return = \'@\'.$item[2]}'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'ATKEYWORD',
                                                      'vars' => '',
                                                      'line' => 60
                                                    }, 'Parse::RecDescent::Rule' ),
                              'URI' => bless( {
                                                'impcount' => 1,
                                                'calls' => [
                                                             'macro_w',
                                                             'macro_string',
                                                             '_alternation_1_of_production_2_of_rule_URI'
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
                                                                                            'pattern' => 'url(',
                                                                                            'hashname' => '__STRING1__',
                                                                                            'description' => '\'url(\'',
                                                                                            'lookahead' => 0,
                                                                                            'line' => 66
                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                   bless( {
                                                                                            'subrule' => 'macro_w',
                                                                                            'matchrule' => 0,
                                                                                            'implicit' => undef,
                                                                                            'argcode' => undef,
                                                                                            'lookahead' => 0,
                                                                                            'line' => 66
                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                   bless( {
                                                                                            'subrule' => 'macro_string',
                                                                                            'matchrule' => 0,
                                                                                            'implicit' => undef,
                                                                                            'argcode' => undef,
                                                                                            'lookahead' => 0,
                                                                                            'line' => 66
                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                   bless( {
                                                                                            'subrule' => 'macro_w',
                                                                                            'matchrule' => 0,
                                                                                            'implicit' => undef,
                                                                                            'argcode' => undef,
                                                                                            'lookahead' => 0,
                                                                                            'line' => 66
                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                   bless( {
                                                                                            'pattern' => ')',
                                                                                            'hashname' => '__STRING2__',
                                                                                            'description' => '\')\'',
                                                                                            'lookahead' => 0,
                                                                                            'line' => 66
                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                   bless( {
                                                                                            'hashname' => '__ACTION1__',
                                                                                            'lookahead' => 0,
                                                                                            'line' => 66,
                                                                                            'code' => '{$return = "url(".$item[3].")"}'
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
                                                                                            'pattern' => 'url(',
                                                                                            'hashname' => '__STRING1__',
                                                                                            'description' => '\'url(\'',
                                                                                            'lookahead' => 0,
                                                                                            'line' => 67
                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                   bless( {
                                                                                            'subrule' => 'macro_w',
                                                                                            'matchrule' => 0,
                                                                                            'implicit' => undef,
                                                                                            'argcode' => undef,
                                                                                            'lookahead' => 0,
                                                                                            'line' => 67
                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                   bless( {
                                                                                            'subrule' => '_alternation_1_of_production_2_of_rule_URI',
                                                                                            'expected' => '/[!#$%&*-~]/, or macro_nonascii, or macro_escape',
                                                                                            'min' => 0,
                                                                                            'argcode' => undef,
                                                                                            'max' => 100000000,
                                                                                            'matchrule' => 0,
                                                                                            'repspec' => 's?',
                                                                                            'lookahead' => 0,
                                                                                            'line' => 71
                                                                                          }, 'Parse::RecDescent::Repetition' ),
                                                                                   bless( {
                                                                                            'subrule' => 'macro_w',
                                                                                            'matchrule' => 0,
                                                                                            'implicit' => undef,
                                                                                            'argcode' => undef,
                                                                                            'lookahead' => 0,
                                                                                            'line' => 71
                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                   bless( {
                                                                                            'pattern' => ')',
                                                                                            'hashname' => '__STRING2__',
                                                                                            'description' => '\')\'',
                                                                                            'lookahead' => 0,
                                                                                            'line' => 71
                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                   bless( {
                                                                                            'hashname' => '__ACTION1__',
                                                                                            'lookahead' => 0,
                                                                                            'line' => 71,
                                                                                            'code' => '{$return = "url(".join(\'\',@{$item[3]}).")"}'
                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                 ],
                                                                      'line' => 67
                                                                    }, 'Parse::RecDescent::Production' )
                                                           ],
                                                'name' => 'URI',
                                                'vars' => '',
                                                'line' => 66
                                              }, 'Parse::RecDescent::Rule' ),
                              'any_item' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [
                                                                  'URI',
                                                                  'IDENT',
                                                                  'NUMBER',
                                                                  'PERCENTAGE',
                                                                  'DIMENSION',
                                                                  'STRING',
                                                                  'HASH',
                                                                  'UNICODERANGE',
                                                                  'INCLUDES',
                                                                  'FUNCTION',
                                                                  'DASHMATCH',
                                                                  'any',
                                                                  'DELIM'
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
                                                                                                 'subrule' => 'URI',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 41
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 41,
                                                                                                 'code' => '{$return = $item[1];}'
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
                                                                                                 'line' => 42
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 42,
                                                                                                 'code' => '{$return = $item[1];}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => 42
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
                                                                                                 'subrule' => 'NUMBER',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 43
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 43,
                                                                                                 'code' => '{$return = $item[1];}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => 43
                                                                         }, 'Parse::RecDescent::Production' ),
                                                                  bless( {
                                                                           'number' => '3',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'PERCENTAGE',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 44
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 44,
                                                                                                 'code' => '{$return = $item[1];}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => 44
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
                                                                                                 'subrule' => 'DIMENSION',
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
                                                                                                 'code' => '{$return = $item[1];}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => 45
                                                                         }, 'Parse::RecDescent::Production' ),
                                                                  bless( {
                                                                           'number' => '5',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'STRING',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 46
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 46,
                                                                                                 'code' => '{$return = $item[1];}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => 46
                                                                         }, 'Parse::RecDescent::Production' ),
                                                                  bless( {
                                                                           'number' => '6',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'HASH',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 47
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 47,
                                                                                                 'code' => '{$return = $item[1];}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => 47
                                                                         }, 'Parse::RecDescent::Production' ),
                                                                  bless( {
                                                                           'number' => '7',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'UNICODERANGE',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 48
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 48,
                                                                                                 'code' => '{$return = $item[1];}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => 48
                                                                         }, 'Parse::RecDescent::Production' ),
                                                                  bless( {
                                                                           'number' => '8',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'INCLUDES',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 49
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 49,
                                                                                                 'code' => '{$return = $item[1];}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => 49
                                                                         }, 'Parse::RecDescent::Production' ),
                                                                  bless( {
                                                                           'number' => '9',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'FUNCTION',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 50
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 50,
                                                                                                 'code' => '{$return = $item[1];}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => 50
                                                                         }, 'Parse::RecDescent::Production' ),
                                                                  bless( {
                                                                           'number' => '10',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'DASHMATCH',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 51
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 51,
                                                                                                 'code' => '{$return = $item[1];}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => 51
                                                                         }, 'Parse::RecDescent::Production' ),
                                                                  bless( {
                                                                           'number' => '11',
                                                                           'strcount' => 2,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => '(',
                                                                                                 'hashname' => '__STRING1__',
                                                                                                 'description' => '\'(\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 52
                                                                                               }, 'Parse::RecDescent::Literal' ),
                                                                                        bless( {
                                                                                                 'subrule' => 'any',
                                                                                                 'expected' => undef,
                                                                                                 'min' => 0,
                                                                                                 'argcode' => undef,
                                                                                                 'max' => 100000000,
                                                                                                 'matchrule' => 0,
                                                                                                 'repspec' => 's?',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 52
                                                                                               }, 'Parse::RecDescent::Repetition' ),
                                                                                        bless( {
                                                                                                 'pattern' => ')',
                                                                                                 'hashname' => '__STRING2__',
                                                                                                 'description' => '\')\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 52
                                                                                               }, 'Parse::RecDescent::Literal' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 52,
                                                                                                 'code' => '{$return = \'(\'.join(\'\',@{$item[2]}).\')\';}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => 52
                                                                         }, 'Parse::RecDescent::Production' ),
                                                                  bless( {
                                                                           'number' => '12',
                                                                           'strcount' => 2,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => '[',
                                                                                                 'hashname' => '__STRING1__',
                                                                                                 'description' => '\'[\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 53
                                                                                               }, 'Parse::RecDescent::Literal' ),
                                                                                        bless( {
                                                                                                 'subrule' => 'any',
                                                                                                 'expected' => undef,
                                                                                                 'min' => 0,
                                                                                                 'argcode' => undef,
                                                                                                 'max' => 100000000,
                                                                                                 'matchrule' => 0,
                                                                                                 'repspec' => 's?',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 53
                                                                                               }, 'Parse::RecDescent::Repetition' ),
                                                                                        bless( {
                                                                                                 'pattern' => ']',
                                                                                                 'hashname' => '__STRING2__',
                                                                                                 'description' => '\']\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 53
                                                                                               }, 'Parse::RecDescent::Literal' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 53,
                                                                                                 'code' => '{$return = \'[\'.join(\'\',@{$item[2]}).\']\';}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => 53
                                                                         }, 'Parse::RecDescent::Production' ),
                                                                  bless( {
                                                                           'number' => '13',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'DELIM',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 54
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 54,
                                                                                                 'code' => '{$return = $item[1];}'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => 54
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'any_item',
                                                     'vars' => '',
                                                     'line' => 41
                                                   }, 'Parse::RecDescent::Rule' ),
                              'any' => bless( {
                                                'impcount' => 0,
                                                'calls' => [
                                                             'any_item',
                                                             'OWS'
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
                                                                                            'subrule' => 'any_item',
                                                                                            'matchrule' => 0,
                                                                                            'implicit' => undef,
                                                                                            'argcode' => undef,
                                                                                            'lookahead' => 0,
                                                                                            'line' => 40
                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                   bless( {
                                                                                            'subrule' => 'OWS',
                                                                                            'matchrule' => 0,
                                                                                            'implicit' => undef,
                                                                                            'argcode' => undef,
                                                                                            'lookahead' => 0,
                                                                                            'line' => 40
                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                   bless( {
                                                                                            'hashname' => '__ACTION1__',
                                                                                            'lookahead' => 0,
                                                                                            'line' => 40,
                                                                                            'code' => '{$return = $item[1].$item[2]}'
                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                 ],
                                                                      'line' => undef
                                                                    }, 'Parse::RecDescent::Production' )
                                                           ],
                                                'name' => 'any',
                                                'vars' => '',
                                                'line' => 40
                                              }, 'Parse::RecDescent::Rule' ),
                              'DASHMATCH' => bless( {
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
                                                                                                  'pattern' => '|=',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'|=\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 77
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 77,
                                                                                                  'code' => '{$return = $item[1]}'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'DASHMATCH',
                                                      'vars' => '',
                                                      'line' => 77
                                                    }, 'Parse::RecDescent::Rule' ),
                              'macro_nmchar' => bless( {
                                                         'impcount' => 0,
                                                         'calls' => [
                                                                      'macro_nonascii',
                                                                      'macro_escape'
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
                                                                               'patcount' => 1,
                                                                               'actcount' => 1,
                                                                               'items' => [
                                                                                            bless( {
                                                                                                     'pattern' => '[a-z0-9-]',
                                                                                                     'hashname' => '__PATTERN1__',
                                                                                                     'description' => '/[a-z0-9-]/',
                                                                                                     'lookahead' => 0,
                                                                                                     'rdelim' => '/',
                                                                                                     'line' => 92,
                                                                                                     'mod' => '',
                                                                                                     'ldelim' => '/'
                                                                                                   }, 'Parse::RecDescent::Token' ),
                                                                                            bless( {
                                                                                                     'hashname' => '__ACTION1__',
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 92,
                                                                                                     'code' => '{$return = $item[1]}'
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
                                                                                                     'subrule' => 'macro_nonascii',
                                                                                                     'matchrule' => 0,
                                                                                                     'implicit' => undef,
                                                                                                     'argcode' => undef,
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 93
                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                            bless( {
                                                                                                     'hashname' => '__ACTION1__',
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 93,
                                                                                                     'code' => '{$return = $item[1]}'
                                                                                                   }, 'Parse::RecDescent::Action' )
                                                                                          ],
                                                                               'line' => 93
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
                                                                                                     'subrule' => 'macro_escape',
                                                                                                     'matchrule' => 0,
                                                                                                     'implicit' => undef,
                                                                                                     'argcode' => undef,
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 94
                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                            bless( {
                                                                                                     'hashname' => '__ACTION1__',
                                                                                                     'lookahead' => 0,
                                                                                                     'line' => 94,
                                                                                                     'code' => '{$return = $item[1]}'
                                                                                                   }, 'Parse::RecDescent::Action' )
                                                                                          ],
                                                                               'line' => 94
                                                                             }, 'Parse::RecDescent::Production' )
                                                                    ],
                                                         'name' => 'macro_nmchar',
                                                         'vars' => '',
                                                         'line' => 92
                                                       }, 'Parse::RecDescent::Rule' ),
                              'ruleset' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [
                                                                 'selector',
                                                                 'WS',
                                                                 'declaration',
                                                                 '_alternation_1_of_production_1_of_rule_ruleset'
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
                                                                                                'subrule' => 'selector',
                                                                                                'expected' => undef,
                                                                                                'min' => 0,
                                                                                                'argcode' => undef,
                                                                                                'max' => 1,
                                                                                                'matchrule' => 0,
                                                                                                'repspec' => '?',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 15
                                                                                              }, 'Parse::RecDescent::Repetition' ),
                                                                                       bless( {
                                                                                                'pattern' => '{',
                                                                                                'hashname' => '__STRING1__',
                                                                                                'description' => '\'\\{\'',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 15
                                                                                              }, 'Parse::RecDescent::Literal' ),
                                                                                       bless( {
                                                                                                'subrule' => 'WS',
                                                                                                'expected' => undef,
                                                                                                'min' => 0,
                                                                                                'argcode' => undef,
                                                                                                'max' => 100000000,
                                                                                                'matchrule' => 0,
                                                                                                'repspec' => 's?',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 15
                                                                                              }, 'Parse::RecDescent::Repetition' ),
                                                                                       bless( {
                                                                                                'subrule' => 'declaration',
                                                                                                'expected' => undef,
                                                                                                'min' => 0,
                                                                                                'argcode' => undef,
                                                                                                'max' => 1,
                                                                                                'matchrule' => 0,
                                                                                                'repspec' => '?',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 15
                                                                                              }, 'Parse::RecDescent::Repetition' ),
                                                                                       bless( {
                                                                                                'subrule' => '_alternation_1_of_production_1_of_rule_ruleset',
                                                                                                'expected' => '\';\'',
                                                                                                'min' => 0,
                                                                                                'argcode' => undef,
                                                                                                'max' => 100000000,
                                                                                                'matchrule' => 0,
                                                                                                'repspec' => 's?',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 17
                                                                                              }, 'Parse::RecDescent::Repetition' ),
                                                                                       bless( {
                                                                                                'pattern' => '}',
                                                                                                'hashname' => '__STRING2__',
                                                                                                'description' => '\'\\}\'',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 17
                                                                                              }, 'Parse::RecDescent::Literal' ),
                                                                                       bless( {
                                                                                                'subrule' => 'WS',
                                                                                                'expected' => undef,
                                                                                                'min' => 0,
                                                                                                'argcode' => undef,
                                                                                                'max' => 100000000,
                                                                                                'matchrule' => 0,
                                                                                                'repspec' => 's?',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 17
                                                                                              }, 'Parse::RecDescent::Repetition' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 17,
                                                                                                'code' => '{push @{$all_rulesets}, $ruleset; 1;}'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' ),
                                                                 bless( {
                                                                          'number' => '1',
                                                                          'strcount' => 0,
                                                                          'dircount' => 1,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 0,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'hashname' => '__DIRECTIVE1__',
                                                                                                'name' => '<rulevar: local $ruleset = new CSS::Style();>',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 18
                                                                                              }, 'Parse::RecDescent::UncondReject' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'ruleset',
                                                    'vars' => ' local $ruleset = new CSS::Style();;
',
                                                    'line' => 15
                                                  }, 'Parse::RecDescent::Rule' ),
                              'DELIM' => bless( {
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
                                                                                              'pattern' => '[^0-9a-zA-Z\\{\\}\\(\\)\\[\\];]',
                                                                                              'hashname' => '__PATTERN1__',
                                                                                              'description' => '/[^0-9a-zA-Z\\\\\\{\\\\\\}\\\\(\\\\)\\\\[\\\\];]/',
                                                                                              'lookahead' => 0,
                                                                                              'rdelim' => '/',
                                                                                              'line' => 78,
                                                                                              'mod' => '',
                                                                                              'ldelim' => '/'
                                                                                            }, 'Parse::RecDescent::Token' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 78,
                                                                                              'code' => '{$return = $item[1]}'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'DELIM',
                                                  'vars' => '',
                                                  'line' => 78
                                                }, 'Parse::RecDescent::Rule' ),
                              'PERCENTAGE' => bless( {
                                                       'impcount' => 0,
                                                       'calls' => [
                                                                    'macro_num'
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
                                                                                                   'subrule' => 'macro_num',
                                                                                                   'matchrule' => 0,
                                                                                                   'implicit' => undef,
                                                                                                   'argcode' => undef,
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => 64
                                                                                                 }, 'Parse::RecDescent::Subrule' ),
                                                                                          bless( {
                                                                                                   'pattern' => '%',
                                                                                                   'hashname' => '__STRING1__',
                                                                                                   'description' => '\'%\'',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => 64
                                                                                                 }, 'Parse::RecDescent::Literal' ),
                                                                                          bless( {
                                                                                                   'hashname' => '__ACTION1__',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => 64,
                                                                                                   'code' => '{$return = $item[1].\'&\'}'
                                                                                                 }, 'Parse::RecDescent::Action' )
                                                                                        ],
                                                                             'line' => undef
                                                                           }, 'Parse::RecDescent::Production' )
                                                                  ],
                                                       'name' => 'PERCENTAGE',
                                                       'vars' => '',
                                                       'line' => 64
                                                     }, 'Parse::RecDescent::Rule' ),
                              'block' => bless( {
                                                  'impcount' => 1,
                                                  'calls' => [
                                                               'WS',
                                                               '_alternation_1_of_production_1_of_rule_block'
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
                                                                                              'pattern' => '{',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'\\{\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 14
                                                                                            }, 'Parse::RecDescent::Literal' ),
                                                                                     bless( {
                                                                                              'subrule' => 'WS',
                                                                                              'expected' => undef,
                                                                                              'min' => 0,
                                                                                              'argcode' => undef,
                                                                                              'max' => 100000000,
                                                                                              'matchrule' => 0,
                                                                                              'repspec' => 's?',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 14
                                                                                            }, 'Parse::RecDescent::Repetition' ),
                                                                                     bless( {
                                                                                              'subrule' => '_alternation_1_of_production_1_of_rule_block',
                                                                                              'expected' => 'any, or block, or ATKEYWORD, or \';\'',
                                                                                              'min' => 0,
                                                                                              'argcode' => undef,
                                                                                              'max' => 100000000,
                                                                                              'matchrule' => 0,
                                                                                              'repspec' => 's?',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 14
                                                                                            }, 'Parse::RecDescent::Repetition' ),
                                                                                     bless( {
                                                                                              'pattern' => '}',
                                                                                              'hashname' => '__STRING2__',
                                                                                              'description' => '\'\\}\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 14
                                                                                            }, 'Parse::RecDescent::Literal' ),
                                                                                     bless( {
                                                                                              'subrule' => 'WS',
                                                                                              'expected' => undef,
                                                                                              'min' => 0,
                                                                                              'argcode' => undef,
                                                                                              'max' => 100000000,
                                                                                              'matchrule' => 0,
                                                                                              'repspec' => 's?',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 14
                                                                                            }, 'Parse::RecDescent::Repetition' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 14,
                                                                                              'code' => '{print "block\\n"}'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'block',
                                                  'vars' => '',
                                                  'line' => 14
                                                }, 'Parse::RecDescent::Rule' ),
                              'macro_nonascii' => bless( {
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
                                                                                                       'pattern' => '[^\\0-\\177]',
                                                                                                       'hashname' => '__PATTERN1__',
                                                                                                       'description' => '/[^\\\\0-\\\\177]/',
                                                                                                       'lookahead' => 0,
                                                                                                       'rdelim' => '/',
                                                                                                       'line' => 88,
                                                                                                       'mod' => '',
                                                                                                       'ldelim' => '/'
                                                                                                     }, 'Parse::RecDescent::Token' ),
                                                                                              bless( {
                                                                                                       'hashname' => '__ACTION1__',
                                                                                                       'lookahead' => 0,
                                                                                                       'line' => 88,
                                                                                                       'code' => '{$return = $item[1]}'
                                                                                                     }, 'Parse::RecDescent::Action' )
                                                                                            ],
                                                                                 'line' => undef
                                                                               }, 'Parse::RecDescent::Production' )
                                                                      ],
                                                           'name' => 'macro_nonascii',
                                                           'vars' => '',
                                                           'line' => 88
                                                         }, 'Parse::RecDescent::Rule' )
                            },
                 '_AUTOTREE' => undef,
                 '_check' => {
                               'thisoffset' => '',
                               'itempos' => '',
                               'prevoffset' => '',
                               'prevline' => '',
                               'prevcolumn' => '',
                               'thiscolumn' => ''
                             },
                 '_AUTOACTION' => bless( {
                                           'lookahead' => 0,
                                           'line' => -1,
                                           'code' => '{ print "token: ".shift @item; print " : @item\\n" }'
                                         }, 'Parse::RecDescent::Action' )
               }, 'Parse::RecDescent' );
}