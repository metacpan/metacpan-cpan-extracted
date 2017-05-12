package Cheater::Parser;
use Parse::RecDescent;

{ my $ERRORS;


package Parse::RecDescent::Cheater::Parser;
use strict;
use vars qw($skip $AUTOLOAD  );
@Parse::RecDescent::Cheater::Parser::ISA = ();
$skip = '\s*(?:(?:\#[^\n]*|/\*.*?\*/)\s*)*';

    use Cheater::Parser::Util qw( parse_included_file );
;


{
local $SIG{__WARN__} = sub {0};
# PRETEND TO BE IN Parse::RecDescent NAMESPACE
*Parse::RecDescent::Cheater::Parser::AUTOLOAD   = sub
{
    no strict 'refs';
    $AUTOLOAD =~ s/^Parse::RecDescent::Cheater::Parser/Parse::RecDescent/;
    goto &{$AUTOLOAD};
}
}

push @Parse::RecDescent::Cheater::Parser::ISA, 'Parse::RecDescent';
# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::qualified_column
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"qualified_column"};
    
    Parse::RecDescent::_trace(q{Trying rule: [qualified_column]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{qualified_column},
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
    my $expectation = new Parse::RecDescent::Expectation(q{table_name});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [table_name '.' <commit> column_name]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{qualified_column},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{qualified_column});
        %item = (__RULE__ => q{qualified_column});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [table_name]},
                  Parse::RecDescent::_tracefirst($text),
                  q{qualified_column},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::table_name($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [table_name]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{qualified_column},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [table_name]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{qualified_column},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{table_name}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: ['.']},
                      Parse::RecDescent::_tracefirst($text),
                      q{qualified_column},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'.'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\./)
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
        

        

        Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{qualified_column},
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
        

        Parse::RecDescent::_trace(q{Trying subrule: [column_name]},
                  Parse::RecDescent::_tracefirst($text),
                  q{qualified_column},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{column_name})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::column_name($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [column_name]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{qualified_column},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [column_name]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{qualified_column},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{column_name}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{qualified_column},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { [$item[1], $item[4]] };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [table_name '.' <commit> column_name]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{qualified_column},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<error?:...> <reject>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{qualified_column},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        
        my $_savetext;
        @item = (q{qualified_column});
        %item = (__RULE__ => q{qualified_column});
        my $repcount = 0;


        

        Parse::RecDescent::_trace(q{Trying directive: [<error?:...>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{qualified_column},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { if ($commit) { do {
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
        

        Parse::RecDescent::_trace(q{>>Rejecting production<< (found <reject>)},
                     Parse::RecDescent::_tracefirst($text),
                      q{qualified_column},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $return;
        

        $_tok = undef;
        
        last unless defined $_tok;


        Parse::RecDescent::_trace(q{>>Matched production: [<error?:...> <reject>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{qualified_column},
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
                     q{qualified_column},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{qualified_column},
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
                      q{qualified_column},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{qualified_column},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::int
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"int"};
    
    Parse::RecDescent::_trace(q{Trying rule: [int]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{int},
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
    my $expectation = new Parse::RecDescent::Expectation(q{/-?\\d+\\b/});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/-?\\d+\\b/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{int},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{int});
        %item = (__RULE__ => q{int});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/-?\\d+\\b/]}, Parse::RecDescent::_tracefirst($text),
                      q{int},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:-?\d+\b)/)
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/-?\\d+\\b/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{int},
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
                     q{int},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{int},
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
                      q{int},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{int},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::number
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"number"};
    
    Parse::RecDescent::_trace(q{Trying rule: [number]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{number},
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
    my $expectation = new Parse::RecDescent::Expectation(q{real, or int});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [real]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{number},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{number});
        %item = (__RULE__ => q{number});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [real]},
                  Parse::RecDescent::_tracefirst($text),
                  q{number},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::real($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [real]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{number},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [real]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{number},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{real}} = $_tok;
        push @item, $_tok;
        
        }


        Parse::RecDescent::_trace(q{>>Matched production: [real]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{number},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [int]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{number},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{number});
        %item = (__RULE__ => q{number});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [int]},
                  Parse::RecDescent::_tracefirst($text),
                  q{number},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::int($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [int]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{number},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [int]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{number},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{int}} = $_tok;
        push @item, $_tok;
        
        }


        Parse::RecDescent::_trace(q{>>Matched production: [int]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{number},
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
                     q{number},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{number},
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
                      q{number},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{number},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::time
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"time"};
    
    Parse::RecDescent::_trace(q{Trying rule: [time]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{time},
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
    my $expectation = new Parse::RecDescent::Expectation(q{/\\b\\d\{2\}:\\d\{2\}:\\d\{2\}\\b/, or /\\b\\d\{2\}:\\d\{2\}\\b(?!:)/});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\b\\d\{2\}:\\d\{2\}:\\d\{2\}\\b/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{time},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{time});
        %item = (__RULE__ => q{time});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/\\b\\d\{2\}:\\d\{2\}:\\d\{2\}\\b/]}, Parse::RecDescent::_tracefirst($text),
                      q{time},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\b\d{2}:\d{2}:\d{2}\b)/)
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/\\b\\d\{2\}:\\d\{2\}:\\d\{2\}\\b/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{time},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\b\\d\{2\}:\\d\{2\}\\b(?!:)/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{time},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{time});
        %item = (__RULE__ => q{time});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/\\b\\d\{2\}:\\d\{2\}\\b(?!:)/]}, Parse::RecDescent::_tracefirst($text),
                      q{time},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\b\d{2}:\d{2}\b(?!:))/)
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
                      q{time},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { "$item[1]:00" };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/\\b\\d\{2\}:\\d\{2\}\\b(?!:)/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{time},
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
                     q{time},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{time},
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
                      q{time},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{time},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::date
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"date"};
    
    Parse::RecDescent::_trace(q{Trying rule: [date]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{date},
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
    my $expectation = new Parse::RecDescent::Expectation(q{/\\b\\d\{4\}-\\d\{2\}-\\d\{2\}\\b/});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\b\\d\{4\}-\\d\{2\}-\\d\{2\}\\b/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{date},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{date});
        %item = (__RULE__ => q{date});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/\\b\\d\{4\}-\\d\{2\}-\\d\{2\}\\b/]}, Parse::RecDescent::_tracefirst($text),
                      q{date},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\b\d{4}-\d{2}-\d{2}\b)/)
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/\\b\\d\{4\}-\\d\{2\}-\\d\{2\}\\b/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{date},
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
                     q{date},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{date},
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
                      q{date},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{date},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::rows_definition
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"rows_definition"};
    
    Parse::RecDescent::_trace(q{Trying rule: [rows_definition]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{rows_definition},
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
    my $expectation = new Parse::RecDescent::Expectation(q{/\\d+/});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\d+/ <commit> table_name]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{rows_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{rows_definition});
        %item = (__RULE__ => q{rows_definition});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/\\d+/]}, Parse::RecDescent::_tracefirst($text),
                      q{rows_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\d+)/)
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
        

        

        Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{rows_definition},
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
        

        Parse::RecDescent::_trace(q{Trying subrule: [table_name]},
                  Parse::RecDescent::_tracefirst($text),
                  q{rows_definition},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{table_name})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::table_name($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [table_name]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{rows_definition},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [table_name]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{rows_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{table_name}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{rows_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { ['rows', $item[1], $item[3]] };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/\\d+/ <commit> table_name]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{rows_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<error?:...> <reject>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{rows_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        
        my $_savetext;
        @item = (q{rows_definition});
        %item = (__RULE__ => q{rows_definition});
        my $repcount = 0;


        

        Parse::RecDescent::_trace(q{Trying directive: [<error?:...>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{rows_definition},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { if ($commit) { do {
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
        

        Parse::RecDescent::_trace(q{>>Rejecting production<< (found <reject>)},
                     Parse::RecDescent::_tracefirst($text),
                      q{rows_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $return;
        

        $_tok = undef;
        
        last unless defined $_tok;


        Parse::RecDescent::_trace(q{>>Matched production: [<error?:...> <reject>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{rows_definition},
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
                     q{rows_definition},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{rows_definition},
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
                      q{rows_definition},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{rows_definition},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::range
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"range"};
    
    Parse::RecDescent::_trace(q{Trying rule: [range]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{range},
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
    my $expectation = new Parse::RecDescent::Expectation(q{number, or date, or time, or datetime});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [number '..' <commit> number]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{range});
        %item = (__RULE__ => q{range});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [number]},
                  Parse::RecDescent::_tracefirst($text),
                  q{range},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::number($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [number]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{range},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [number]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{number}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: ['..']},
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'..'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\.\./)
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
        

        

        Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{range},
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
        

        Parse::RecDescent::_trace(q{Trying subrule: [number]},
                  Parse::RecDescent::_tracefirst($text),
                  q{range},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{number})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::number($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [number]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{range},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [number]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{number}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { ['nrange', $item[1], $item[4]] };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [number '..' <commit> number]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [date '..' <commit> date]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{range});
        %item = (__RULE__ => q{range});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [date]},
                  Parse::RecDescent::_tracefirst($text),
                  q{range},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::date($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [date]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{range},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [date]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{date}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: ['..']},
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'..'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\.\./)
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
        

        

        Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{range},
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
        

        Parse::RecDescent::_trace(q{Trying subrule: [date]},
                  Parse::RecDescent::_tracefirst($text),
                  q{range},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{date})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::date($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [date]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{range},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [date]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{date}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { ['drange', $item[1], $item[4]] };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [date '..' <commit> date]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [time '..' <commit> time]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{range});
        %item = (__RULE__ => q{range});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [time]},
                  Parse::RecDescent::_tracefirst($text),
                  q{range},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::time($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [time]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{range},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [time]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{time}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: ['..']},
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'..'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\.\./)
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
        

        

        Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{range},
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
        

        Parse::RecDescent::_trace(q{Trying subrule: [time]},
                  Parse::RecDescent::_tracefirst($text),
                  q{range},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{time})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::time($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [time]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{range},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [time]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{time}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { ['trange', $item[1], $item[4]] };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [time '..' <commit> time]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [datetime '..' <commit> datetime]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[3];
        $text = $_[1];
        my $_savetext;
        @item = (q{range});
        %item = (__RULE__ => q{range});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [datetime]},
                  Parse::RecDescent::_tracefirst($text),
                  q{range},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::datetime($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [datetime]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{range},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [datetime]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{datetime}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: ['..']},
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'..'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\.\./)
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
        

        

        Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{range},
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
        

        Parse::RecDescent::_trace(q{Trying subrule: [datetime]},
                  Parse::RecDescent::_tracefirst($text),
                  q{range},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{datetime})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::datetime($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [datetime]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{range},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [datetime]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{datetime}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { ['dtrange', $item[1], $item[4]] };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [datetime '..' <commit> datetime]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<error?:...> <reject>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[4];
        
        my $_savetext;
        @item = (q{range});
        %item = (__RULE__ => q{range});
        my $repcount = 0;


        

        Parse::RecDescent::_trace(q{Trying directive: [<error?:...>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { if ($commit) { do {
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
        

        Parse::RecDescent::_trace(q{>>Rejecting production<< (found <reject>)},
                     Parse::RecDescent::_tracefirst($text),
                      q{range},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $return;
        

        $_tok = undef;
        
        last unless defined $_tok;


        Parse::RecDescent::_trace(q{>>Matched production: [<error?:...> <reject>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{range},
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
                     q{range},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{range},
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
                      q{range},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{range},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::type_definition
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"type_definition"};
    
    Parse::RecDescent::_trace(q{Trying rule: [type_definition]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{type_definition},
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
    my $expectation = new Parse::RecDescent::Expectation(q{'type'});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['type' <commit> type '=' type domain attribute]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{type_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{type_definition});
        %item = (__RULE__ => q{type_definition});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['type']},
                      Parse::RecDescent::_tracefirst($text),
                      q{type_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Atype/)
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
        

        

        Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{type_definition},
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
        

        Parse::RecDescent::_trace(q{Trying subrule: [type]},
                  Parse::RecDescent::_tracefirst($text),
                  q{type_definition},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{type})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::type($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [type]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{type_definition},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [type]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{type_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{type}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: ['=']},
                      Parse::RecDescent::_tracefirst($text),
                      q{type_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'='})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\=/)
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
        

        Parse::RecDescent::_trace(q{Trying subrule: [type]},
                  Parse::RecDescent::_tracefirst($text),
                  q{type_definition},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{type})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::type($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [type]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{type_definition},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [type]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{type_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{type}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying repeated subrule: [domain]},
                  Parse::RecDescent::_tracefirst($text),
                  q{type_definition},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{domain})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Cheater::Parser::domain, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [domain]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{type_definition},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [domain]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{type_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{domain(?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying repeated subrule: [attribute]},
                  Parse::RecDescent::_tracefirst($text),
                  q{type_definition},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{attribute})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Cheater::Parser::attribute, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [attribute]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{type_definition},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [attribute]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{type_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{attribute(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{type_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do {
                        ['type', $item[3], $item[4], $item[5], $item[6]] };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['type' <commit> type '=' type domain attribute]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{type_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<error?:...> <reject>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{type_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        
        my $_savetext;
        @item = (q{type_definition});
        %item = (__RULE__ => q{type_definition});
        my $repcount = 0;


        

        Parse::RecDescent::_trace(q{Trying directive: [<error?:...>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{type_definition},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { if ($commit) { do {
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
        

        Parse::RecDescent::_trace(q{>>Rejecting production<< (found <reject>)},
                     Parse::RecDescent::_tracefirst($text),
                      q{type_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $return;
        

        $_tok = undef;
        
        last unless defined $_tok;


        Parse::RecDescent::_trace(q{>>Matched production: [<error?:...> <reject>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{type_definition},
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
                     q{type_definition},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{type_definition},
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
                      q{type_definition},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{type_definition},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::string
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
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep="";
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{''', or '"'});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [''' <commit> /(?:[^']|\\\\.)*/ ''']},
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


        Parse::RecDescent::_trace(q{Trying terminal: [''']},
                      Parse::RecDescent::_tracefirst($text),
                      q{string},
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
        

        

        Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{string},
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
        

        Parse::RecDescent::_trace(q{Trying terminal: [/(?:[^']|\\\\.)*/]}, Parse::RecDescent::_tracefirst($text),
                      q{string},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{/(?:[^']|\\\\.)*/})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:(?:[^']|\\.)*)/)
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
        

        Parse::RecDescent::_trace(q{Trying terminal: [''']},
                      Parse::RecDescent::_tracefirst($text),
                      q{string},
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
                      q{string},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { eval "'$item[3]'" };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [''' <commit> /(?:[^']|\\\\.)*/ ''']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{string},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['"' <commit> /(?:[^"]|\\\\.)*/ '"']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{string},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{string});
        %item = (__RULE__ => q{string});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['"']},
                      Parse::RecDescent::_tracefirst($text),
                      q{string},
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
        

        

        Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{string},
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
        

        Parse::RecDescent::_trace(q{Trying terminal: [/(?:[^"]|\\\\.)*/]}, Parse::RecDescent::_tracefirst($text),
                      q{string},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{/(?:[^"]|\\\\.)*/})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:(?:[^"]|\\.)*)/)
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
        

        Parse::RecDescent::_trace(q{Trying terminal: ['"']},
                      Parse::RecDescent::_tracefirst($text),
                      q{string},
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
                      q{string},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { eval qq{"$item[3]"} };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['"' <commit> /(?:[^"]|\\\\.)*/ '"']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{string},
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
sub Parse::RecDescent::Cheater::Parser::datetime
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"datetime"};
    
    Parse::RecDescent::_trace(q{Trying rule: [datetime]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{datetime},
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
    my $expectation = new Parse::RecDescent::Expectation(q{date});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [date time]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{datetime},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{datetime});
        %item = (__RULE__ => q{datetime});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [date]},
                  Parse::RecDescent::_tracefirst($text),
                  q{datetime},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::date($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [date]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{datetime},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [date]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{datetime},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{date}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying subrule: [time]},
                  Parse::RecDescent::_tracefirst($text),
                  q{datetime},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{time})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::time($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [time]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{datetime},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [time]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{datetime},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{time}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{datetime},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { "$item[1] $item[2]" };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [date time]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{datetime},
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
                     q{datetime},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{datetime},
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
                      q{datetime},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{datetime},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::attribute
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"attribute"};
    
    Parse::RecDescent::_trace(q{Trying rule: [attribute]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{attribute},
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
    my $expectation = new Parse::RecDescent::Expectation(q{'unique', or 'unsigned', or 'asc', or 'desc', or 'not', or 'for'});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['unique']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{attribute});
        %item = (__RULE__ => q{attribute});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['unique']},
                      Parse::RecDescent::_tracefirst($text),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Aunique/)
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['unique']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['unsigned']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{attribute});
        %item = (__RULE__ => q{attribute});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['unsigned']},
                      Parse::RecDescent::_tracefirst($text),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Aunsigned/)
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['unsigned']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['asc']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{attribute});
        %item = (__RULE__ => q{attribute});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['asc']},
                      Parse::RecDescent::_tracefirst($text),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Aasc/)
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['asc']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['desc']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[3];
        $text = $_[1];
        my $_savetext;
        @item = (q{attribute});
        %item = (__RULE__ => q{attribute});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['desc']},
                      Parse::RecDescent::_tracefirst($text),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Adesc/)
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['desc']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['not' <commit> 'null']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[4];
        $text = $_[1];
        my $_savetext;
        @item = (q{attribute});
        %item = (__RULE__ => q{attribute});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['not']},
                      Parse::RecDescent::_tracefirst($text),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Anot/)
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
        

        

        Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{attribute},
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
        

        Parse::RecDescent::_trace(q{Trying terminal: ['null']},
                      Parse::RecDescent::_tracefirst($text),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'null'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Anull/)
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
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { "$item[1] $item[3]" };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['not' <commit> 'null']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['for' string]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[5];
        $text = $_[1];
        my $_savetext;
        @item = (q{attribute});
        %item = (__RULE__ => q{attribute});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['for']},
                      Parse::RecDescent::_tracefirst($text),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Afor/)
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
        

        Parse::RecDescent::_trace(q{Trying subrule: [string]},
                  Parse::RecDescent::_tracefirst($text),
                  q{attribute},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{string})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::string($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [string]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{attribute},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [string]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{string}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { ['for', $item{string}] };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['for' string]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<error?:...> <reject>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[6];
        
        my $_savetext;
        @item = (q{attribute});
        %item = (__RULE__ => q{attribute});
        my $repcount = 0;


        

        Parse::RecDescent::_trace(q{Trying directive: [<error?:...>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { if ($commit) { do {
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
        

        Parse::RecDescent::_trace(q{>>Rejecting production<< (found <reject>)},
                     Parse::RecDescent::_tracefirst($text),
                      q{attribute},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $return;
        

        $_tok = undef;
        
        last unless defined $_tok;


        Parse::RecDescent::_trace(q{>>Matched production: [<error?:...> <reject>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{attribute},
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
                     q{attribute},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{attribute},
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
                      q{attribute},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{attribute},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::identifier
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"identifier"};
    
    Parse::RecDescent::_trace(q{Trying rule: [identifier]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{identifier},
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
    my $expectation = new Parse::RecDescent::Expectation(q{/[A-Za-z]\\w*/});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/[A-Za-z]\\w*/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{identifier},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{identifier});
        %item = (__RULE__ => q{identifier});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/[A-Za-z]\\w*/]}, Parse::RecDescent::_tracefirst($text),
                      q{identifier},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[A-Za-z]\w*)/)
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/[A-Za-z]\\w*/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{identifier},
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
                     q{identifier},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{identifier},
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
                      q{identifier},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{identifier},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::domain
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"domain"};
    
    Parse::RecDescent::_trace(q{Trying rule: [domain]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{domain},
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
    my $expectation = new Parse::RecDescent::Expectation(q{enum, or atom});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [enum]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{domain},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{domain});
        %item = (__RULE__ => q{domain});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [enum]},
                  Parse::RecDescent::_tracefirst($text),
                  q{domain},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::enum($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [enum]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{domain},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [enum]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{domain},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{enum}} = $_tok;
        push @item, $_tok;
        
        }


        Parse::RecDescent::_trace(q{>>Matched production: [enum]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{domain},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [atom]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{domain},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{domain});
        %item = (__RULE__ => q{domain});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [atom]},
                  Parse::RecDescent::_tracefirst($text),
                  q{domain},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::atom($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [atom]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{domain},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [atom]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{domain},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{atom}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{domain},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { [ $item[1] ] };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [atom]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{domain},
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
                     q{domain},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{domain},
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
                      q{domain},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{domain},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::table_definition
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"table_definition"};
    
    Parse::RecDescent::_trace(q{Trying rule: [table_definition]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{table_definition},
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
    my $expectation = new Parse::RecDescent::Expectation(q{'table'});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['table' <commit> table_name '(' column_definition ')']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{table_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{table_definition});
        %item = (__RULE__ => q{table_definition});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['table']},
                      Parse::RecDescent::_tracefirst($text),
                      q{table_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Atable/)
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
        

        

        Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{table_definition},
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
        

        Parse::RecDescent::_trace(q{Trying subrule: [table_name]},
                  Parse::RecDescent::_tracefirst($text),
                  q{table_definition},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{table_name})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::table_name($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [table_name]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{table_definition},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [table_name]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{table_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{table_name}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: ['(']},
                      Parse::RecDescent::_tracefirst($text),
                      q{table_definition},
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
        push @item, $item{__STRING2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying repeated subrule: [column_definition]},
                  Parse::RecDescent::_tracefirst($text),
                  q{table_definition},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{column_definition})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Cheater::Parser::column_definition, 1, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [column_definition]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{table_definition},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [column_definition]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{table_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{column_definition(s)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying terminal: [')']},
                      Parse::RecDescent::_tracefirst($text),
                      q{table_definition},
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
        push @item, $item{__STRING3__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{table_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { ['table', $item[3], $item[5]] };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['table' <commit> table_name '(' column_definition ')']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{table_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<error?:...> <reject>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{table_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        
        my $_savetext;
        @item = (q{table_definition});
        %item = (__RULE__ => q{table_definition});
        my $repcount = 0;


        

        Parse::RecDescent::_trace(q{Trying directive: [<error?:...>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{table_definition},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { if ($commit) { do {
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
        

        Parse::RecDescent::_trace(q{>>Rejecting production<< (found <reject>)},
                     Parse::RecDescent::_tracefirst($text),
                      q{table_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $return;
        

        $_tok = undef;
        
        last unless defined $_tok;


        Parse::RecDescent::_trace(q{>>Matched production: [<error?:...> <reject>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{table_definition},
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
                     q{table_definition},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{table_definition},
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
                      q{table_definition},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{table_definition},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::column_name
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"column_name"};
    
    Parse::RecDescent::_trace(q{Trying rule: [column_name]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{column_name},
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
    my $expectation = new Parse::RecDescent::Expectation(q{identifier});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [identifier]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{column_name},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{column_name});
        %item = (__RULE__ => q{column_name});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [identifier]},
                  Parse::RecDescent::_tracefirst($text),
                  q{column_name},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::identifier($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [identifier]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{column_name},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [identifier]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{column_name},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{identifier}} = $_tok;
        push @item, $_tok;
        
        }


        Parse::RecDescent::_trace(q{>>Matched production: [identifier]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{column_name},
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
                     q{column_name},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{column_name},
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
                      q{column_name},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{column_name},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::statement
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
    my $expectation = new Parse::RecDescent::Expectation(q{table_definition, or rows_definition, or type_definition, or include_statement, or table_assignment});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [table_definition /;?/]},
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


        Parse::RecDescent::_trace(q{Trying subrule: [table_definition]},
                  Parse::RecDescent::_tracefirst($text),
                  q{statement},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::table_definition($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [table_definition]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{statement},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [table_definition]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{table_definition}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: [/;?/]}, Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{/;?/})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:;?)/)
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
                      q{statement},
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [table_definition /;?/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [rows_definition ';']},
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


        Parse::RecDescent::_trace(q{Trying subrule: [rows_definition]},
                  Parse::RecDescent::_tracefirst($text),
                  q{statement},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::rows_definition($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [rows_definition]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{statement},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [rows_definition]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{rows_definition}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: [';']},
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{';'})->at($text);
        

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
                      q{statement},
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [rows_definition ';']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [type_definition ';']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{statement});
        %item = (__RULE__ => q{statement});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [type_definition]},
                  Parse::RecDescent::_tracefirst($text),
                  q{statement},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::type_definition($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [type_definition]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{statement},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [type_definition]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{type_definition}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: [';']},
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{';'})->at($text);
        

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
                      q{statement},
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [type_definition ';']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [include_statement ';']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[3];
        $text = $_[1];
        my $_savetext;
        @item = (q{statement});
        %item = (__RULE__ => q{statement});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [include_statement]},
                  Parse::RecDescent::_tracefirst($text),
                  q{statement},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::include_statement($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [include_statement]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{statement},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [include_statement]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{include_statement}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: [';']},
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{';'})->at($text);
        

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
                      q{statement},
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [include_statement ';']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [table_assignment ';']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[4];
        $text = $_[1];
        my $_savetext;
        @item = (q{statement});
        %item = (__RULE__ => q{statement});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [table_assignment]},
                  Parse::RecDescent::_tracefirst($text),
                  q{statement},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::table_assignment($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [table_assignment]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{statement},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [table_assignment]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{table_assignment}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: [';']},
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{';'})->at($text);
        

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
                      q{statement},
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [table_assignment ';']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<error...>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[5];
        
        my $_savetext;
        @item = (q{statement});
        %item = (__RULE__ => q{statement});
        my $repcount = 0;


        

        Parse::RecDescent::_trace(q{Trying directive: [<error...>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{statement},
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [<error...>]<<},
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
sub Parse::RecDescent::Cheater::Parser::file_name
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"file_name"};
    
    Parse::RecDescent::_trace(q{Trying rule: [file_name]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{file_name},
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
    my $expectation = new Parse::RecDescent::Expectation(q{string});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [string]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{file_name},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{file_name});
        %item = (__RULE__ => q{file_name});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [string]},
                  Parse::RecDescent::_tracefirst($text),
                  q{file_name},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::string($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [string]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{file_name},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [string]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{file_name},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{string}} = $_tok;
        push @item, $_tok;
        
        }


        Parse::RecDescent::_trace(q{>>Matched production: [string]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{file_name},
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
                     q{file_name},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{file_name},
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
                      q{file_name},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{file_name},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::atom
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"atom"};
    
    Parse::RecDescent::_trace(q{Trying rule: [atom]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{atom},
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
    my $expectation = new Parse::RecDescent::Expectation(q{range, or number, or regex, or string, or int});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [range]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{atom},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{atom});
        %item = (__RULE__ => q{atom});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [range]},
                  Parse::RecDescent::_tracefirst($text),
                  q{atom},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::range($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [range]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{atom},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [range]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{atom},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{range}} = $_tok;
        push @item, $_tok;
        
        }


        Parse::RecDescent::_trace(q{>>Matched production: [range]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{atom},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [number]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{atom},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{atom});
        %item = (__RULE__ => q{atom});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [number]},
                  Parse::RecDescent::_tracefirst($text),
                  q{atom},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::number($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [number]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{atom},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [number]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{atom},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{number}} = $_tok;
        push @item, $_tok;
        
        }


        Parse::RecDescent::_trace(q{>>Matched production: [number]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{atom},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [regex]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{atom},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{atom});
        %item = (__RULE__ => q{atom});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [regex]},
                  Parse::RecDescent::_tracefirst($text),
                  q{atom},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::regex($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [regex]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{atom},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [regex]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{atom},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{regex}} = $_tok;
        push @item, $_tok;
        
        }


        Parse::RecDescent::_trace(q{>>Matched production: [regex]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{atom},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [string]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{atom},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[3];
        $text = $_[1];
        my $_savetext;
        @item = (q{atom});
        %item = (__RULE__ => q{atom});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [string]},
                  Parse::RecDescent::_tracefirst($text),
                  q{atom},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::string($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [string]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{atom},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [string]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{atom},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{string}} = $_tok;
        push @item, $_tok;
        
        }


        Parse::RecDescent::_trace(q{>>Matched production: [string]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{atom},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [int]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{atom},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[4];
        $text = $_[1];
        my $_savetext;
        @item = (q{atom});
        %item = (__RULE__ => q{atom});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [int]},
                  Parse::RecDescent::_tracefirst($text),
                  q{atom},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::int($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [int]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{atom},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [int]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{atom},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{int}} = $_tok;
        push @item, $_tok;
        
        }


        Parse::RecDescent::_trace(q{>>Matched production: [int]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{atom},
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
                     q{atom},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{atom},
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
                      q{atom},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{atom},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::enum
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"enum"};
    
    Parse::RecDescent::_trace(q{Trying rule: [enum]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{enum},
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
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['\{' <commit> <leftop: atom /,/ atom> '\}']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{enum},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{enum});
        %item = (__RULE__ => q{enum});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
                      Parse::RecDescent::_tracefirst($text),
                      q{enum},
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
        

        

        Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{enum},
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
        

        Parse::RecDescent::_trace(q{Trying operator: [<leftop: atom /,/ atom>]},
                  Parse::RecDescent::_tracefirst($text),
                  q{enum},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{<leftop: atom /,/ atom>})->at($text);

        $_tok = undef;
        OPLOOP: while (1)
        {
          $repcount = 0;
          my  @item;
          
          # MATCH LEFTARG
          
        Parse::RecDescent::_trace(q{Trying subrule: [atom]},
                  Parse::RecDescent::_tracefirst($text),
                  q{enum},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{atom})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::atom($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [atom]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{enum},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [atom]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{enum},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{atom}} = $_tok;
        push @item, $_tok;
        
        }


          $repcount++;

          my $savetext = $text;
          my $backtrack;

          # MATCH (OP RIGHTARG)(s)
          while ($repcount < 100000000)
          {
            $backtrack = 0;
            
        Parse::RecDescent::_trace(q{Trying terminal: [/,/]}, Parse::RecDescent::_tracefirst($text),
                      q{enum},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{/,/})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:,)/)
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
        

            pop @item;
            if (defined $1) {push @item, $item{'atom(s?)'}=$1; $backtrack=1;}
            
        Parse::RecDescent::_trace(q{Trying subrule: [atom]},
                  Parse::RecDescent::_tracefirst($text),
                  q{enum},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{atom})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::atom($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [atom]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{enum},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [atom]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{enum},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{atom}} = $_tok;
        push @item, $_tok;
        
        }

            $savetext = $text;
            $repcount++;
          }
          $text = $savetext;
          pop @item if $backtrack;

          
          $_tok = [ @item ];
          last;
        } 

        unless ($repcount>=0)
        {
            Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: atom /,/ atom>]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{enum},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: atom /,/ atom>]<< (return value: [}
                      . qq{@{$_tok||[]}} . q{]},
                      Parse::RecDescent::_tracefirst($text),
                      q{enum},
                      $tracelevel)
                        if defined $::RD_TRACE;

        push @item, $item{'atom(s?)'}=$_tok||[];


        Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
                      Parse::RecDescent::_tracefirst($text),
                      q{enum},
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
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{enum},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $item[3] };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['\{' <commit> <leftop: atom /,/ atom> '\}']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{enum},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<error?:...> <reject>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{enum},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        
        my $_savetext;
        @item = (q{enum});
        %item = (__RULE__ => q{enum});
        my $repcount = 0;


        

        Parse::RecDescent::_trace(q{Trying directive: [<error?:...>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{enum},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { if ($commit) { do {
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
        

        Parse::RecDescent::_trace(q{>>Rejecting production<< (found <reject>)},
                     Parse::RecDescent::_tracefirst($text),
                      q{enum},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $return;
        

        $_tok = undef;
        
        last unless defined $_tok;


        Parse::RecDescent::_trace(q{>>Matched production: [<error?:...> <reject>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{enum},
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
                     q{enum},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{enum},
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
                      q{enum},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{enum},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::column_definition
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"column_definition"};
    
    Parse::RecDescent::_trace(q{Trying rule: [column_definition]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{column_definition},
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
    my $expectation = new Parse::RecDescent::Expectation(q{column_name});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [column_name 'references' <commit> qualified_column attribute ';']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{column_definition});
        %item = (__RULE__ => q{column_definition});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [column_name]},
                  Parse::RecDescent::_tracefirst($text),
                  q{column_definition},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::column_name($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [column_name]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{column_definition},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [column_name]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{column_name}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: ['references']},
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'references'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Areferences/)
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
        

        

        Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
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
        

        Parse::RecDescent::_trace(q{Trying subrule: [qualified_column]},
                  Parse::RecDescent::_tracefirst($text),
                  q{column_definition},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{qualified_column})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::qualified_column($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [qualified_column]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{column_definition},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [qualified_column]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{qualified_column}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying repeated subrule: [attribute]},
                  Parse::RecDescent::_tracefirst($text),
                  q{column_definition},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{attribute})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Cheater::Parser::attribute, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [attribute]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{column_definition},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [attribute]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{attribute(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying terminal: [';']},
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{';'})->at($text);
        

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
        push @item, $item{__STRING2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { [ $item[1], 'refs', $item[4], $item[5] ] };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [column_name 'references' <commit> qualified_column attribute ';']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [column_name type domain attribute ';']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{column_definition});
        %item = (__RULE__ => q{column_definition});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [column_name]},
                  Parse::RecDescent::_tracefirst($text),
                  q{column_definition},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::column_name($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [column_name]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{column_definition},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [column_name]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{column_name}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying subrule: [type]},
                  Parse::RecDescent::_tracefirst($text),
                  q{column_definition},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{type})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::type($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [type]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{column_definition},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [type]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{type}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying repeated subrule: [domain]},
                  Parse::RecDescent::_tracefirst($text),
                  q{column_definition},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{domain})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Cheater::Parser::domain, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [domain]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{column_definition},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [domain]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{domain(?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying repeated subrule: [attribute]},
                  Parse::RecDescent::_tracefirst($text),
                  q{column_definition},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{attribute})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Cheater::Parser::attribute, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [attribute]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{column_definition},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [attribute]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{attribute(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying terminal: [';']},
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{';'})->at($text);
        

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
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { [$item[1], $item[2], $item[3], $item[4] ] };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [column_name type domain attribute ';']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [column_name '=' column_name ';']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{column_definition});
        %item = (__RULE__ => q{column_definition});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [column_name]},
                  Parse::RecDescent::_tracefirst($text),
                  q{column_definition},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::column_name($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [column_name]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{column_definition},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [column_name]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{column_name}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: ['=']},
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'='})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\=/)
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
        

        Parse::RecDescent::_trace(q{Trying subrule: [column_name]},
                  Parse::RecDescent::_tracefirst($text),
                  q{column_definition},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{column_name})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::column_name($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [column_name]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{column_definition},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [column_name]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{column_name}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: [';']},
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{';'})->at($text);
        

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
        push @item, $item{__STRING2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { [$item[1], '=', $item[3]] };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [column_name '=' column_name ';']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<error?:...> <reject>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[3];
        
        my $_savetext;
        @item = (q{column_definition});
        %item = (__RULE__ => q{column_definition});
        my $repcount = 0;


        

        Parse::RecDescent::_trace(q{Trying directive: [<error?:...>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { if ($commit) { do {
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
        

        Parse::RecDescent::_trace(q{>>Rejecting production<< (found <reject>)},
                     Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $return;
        

        $_tok = undef;
        
        last unless defined $_tok;


        Parse::RecDescent::_trace(q{>>Matched production: [<error?:...> <reject>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{column_definition},
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
                     q{column_definition},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{column_definition},
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
                      q{column_definition},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{column_definition},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::real
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"real"};
    
    Parse::RecDescent::_trace(q{Trying rule: [real]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{real},
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
    my $expectation = new Parse::RecDescent::Expectation(q{/-?\\d+\\.\\d+\\b/});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/-?\\d+\\.\\d+\\b/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{real},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{real});
        %item = (__RULE__ => q{real});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/-?\\d+\\.\\d+\\b/]}, Parse::RecDescent::_tracefirst($text),
                      q{real},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:-?\d+\.\d+\b)/)
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/-?\\d+\\.\\d+\\b/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{real},
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
                     q{real},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{real},
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
                      q{real},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{real},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::spec
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"spec"};
    
    Parse::RecDescent::_trace(q{Trying rule: [spec]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{spec},
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
    my $expectation = new Parse::RecDescent::Expectation(q{statement});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [statement eof]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{spec},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{spec});
        %item = (__RULE__ => q{spec});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying repeated subrule: [statement]},
                  Parse::RecDescent::_tracefirst($text),
                  q{spec},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Cheater::Parser::statement, 1, 100000000, $_noactions,$expectation,sub { \@arg }))) 
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [statement]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{spec},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [statement]<< (}
                    . @$_tok . q{ times)},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{spec},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{statement(s)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying subrule: [eof]},
                  Parse::RecDescent::_tracefirst($text),
                  q{spec},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{eof})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::eof($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [eof]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{spec},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [eof]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{spec},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{eof}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{spec},
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [statement eof]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{spec},
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
                     q{spec},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{spec},
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
                      q{spec},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{spec},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::table_assignment
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"table_assignment"};
    
    Parse::RecDescent::_trace(q{Trying rule: [table_assignment]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{table_assignment},
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
    my $expectation = new Parse::RecDescent::Expectation(q{table_name});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [table_name '=' <commit> table_name]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{table_assignment},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{table_assignment});
        %item = (__RULE__ => q{table_assignment});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [table_name]},
                  Parse::RecDescent::_tracefirst($text),
                  q{table_assignment},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::table_name($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [table_name]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{table_assignment},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [table_name]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{table_assignment},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{table_name}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: ['=']},
                      Parse::RecDescent::_tracefirst($text),
                      q{table_assignment},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{'='})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\=/)
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
        

        

        Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{table_assignment},
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
        

        Parse::RecDescent::_trace(q{Trying subrule: [table_name]},
                  Parse::RecDescent::_tracefirst($text),
                  q{table_assignment},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{table_name})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::table_name($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [table_name]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{table_assignment},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [table_name]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{table_assignment},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{table_name}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{table_assignment},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { [ 'table_assign', $item[1], $item[4] ] };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [table_name '=' <commit> table_name]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{table_assignment},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<error?:...> <reject>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{table_assignment},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        
        my $_savetext;
        @item = (q{table_assignment});
        %item = (__RULE__ => q{table_assignment});
        my $repcount = 0;


        

        Parse::RecDescent::_trace(q{Trying directive: [<error?:...>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{table_assignment},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { if ($commit) { do {
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
        

        Parse::RecDescent::_trace(q{>>Rejecting production<< (found <reject>)},
                     Parse::RecDescent::_tracefirst($text),
                      q{table_assignment},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $return;
        

        $_tok = undef;
        
        last unless defined $_tok;


        Parse::RecDescent::_trace(q{>>Matched production: [<error?:...> <reject>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{table_assignment},
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
                     q{table_assignment},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{table_assignment},
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
                      q{table_assignment},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{table_assignment},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::include_statement
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"include_statement"};
    
    Parse::RecDescent::_trace(q{Trying rule: [include_statement]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{include_statement},
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
    my $expectation = new Parse::RecDescent::Expectation(q{'include'});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['include' <commit> file_name]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{include_statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{include_statement});
        %item = (__RULE__ => q{include_statement});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['include']},
                      Parse::RecDescent::_tracefirst($text),
                      q{include_statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Ainclude/)
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
        

        

        Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{include_statement},
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
        

        Parse::RecDescent::_trace(q{Trying subrule: [file_name]},
                  Parse::RecDescent::_tracefirst($text),
                  q{include_statement},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{file_name})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::file_name($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [file_name]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{include_statement},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [file_name]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{include_statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{file_name}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{include_statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { ['include', parse_included_file($item[3], $thisline)] };
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
        


        Parse::RecDescent::_trace(q{>>Matched production: ['include' <commit> file_name]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{include_statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $_matched = 1;
        last;
    }


    while (!$_matched)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<error?:...> <reject>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{include_statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        
        my $_savetext;
        @item = (q{include_statement});
        %item = (__RULE__ => q{include_statement});
        my $repcount = 0;


        

        Parse::RecDescent::_trace(q{Trying directive: [<error?:...>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{include_statement},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { if ($commit) { do {
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
        

        Parse::RecDescent::_trace(q{>>Rejecting production<< (found <reject>)},
                     Parse::RecDescent::_tracefirst($text),
                      q{include_statement},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $return;
        

        $_tok = undef;
        
        last unless defined $_tok;


        Parse::RecDescent::_trace(q{>>Matched production: [<error?:...> <reject>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{include_statement},
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
                     q{include_statement},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{include_statement},
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
                      q{include_statement},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{include_statement},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::regex
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"regex"};
    
    Parse::RecDescent::_trace(q{Trying rule: [regex]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{regex},
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
    my $expectation = new Parse::RecDescent::Expectation(q{/\\/(?:[^\\\\\\/]|\\\\.)*\\//});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\/(?:[^\\\\\\/]|\\\\.)*\\//]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{regex},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{regex});
        %item = (__RULE__ => q{regex});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/\\/(?:[^\\\\\\/]|\\\\.)*\\//]}, Parse::RecDescent::_tracefirst($text),
                      q{regex},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\/(?:[^\\\/]|\\.)*\/)/)
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
                      q{regex},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { my $regex = 'qr' . $item[1];
          my $re = eval $regex;
          if ($@) {
              die "Bad regex on line $prevline: $regex: $@";
          }
          $re
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/\\/(?:[^\\\\\\/]|\\\\.)*\\//]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{regex},
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
                     q{regex},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{regex},
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
                      q{regex},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{regex},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::eof
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"eof"};
    
    Parse::RecDescent::_trace(q{Trying rule: [eof]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{eof},
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
    my $expectation = new Parse::RecDescent::Expectation(q{/^\\Z/});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/^\\Z/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{eof},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{eof});
        %item = (__RULE__ => q{eof});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/^\\Z/]}, Parse::RecDescent::_tracefirst($text),
                      q{eof},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $lastsep = "";
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:^\Z)/)
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
        


        Parse::RecDescent::_trace(q{>>Matched production: [/^\\Z/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{eof},
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
                     q{eof},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{eof},
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
                      q{eof},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{eof},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::table_name
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"table_name"};
    
    Parse::RecDescent::_trace(q{Trying rule: [table_name]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{table_name},
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
    my $expectation = new Parse::RecDescent::Expectation(q{identifier});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [identifier]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{table_name},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{table_name});
        %item = (__RULE__ => q{table_name});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [identifier]},
                  Parse::RecDescent::_tracefirst($text),
                  q{table_name},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::identifier($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [identifier]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{table_name},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [identifier]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{table_name},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{identifier}} = $_tok;
        push @item, $_tok;
        
        }


        Parse::RecDescent::_trace(q{>>Matched production: [identifier]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{table_name},
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
                     q{table_name},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{table_name},
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
                      q{table_name},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{table_name},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Cheater::Parser::type
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"type"};
    
    Parse::RecDescent::_trace(q{Trying rule: [type]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{type},
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
    my $expectation = new Parse::RecDescent::Expectation(q{identifier});
    $expectation->at($_[1]);
    
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [identifier]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{type},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{type});
        %item = (__RULE__ => q{type});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [identifier]},
                  Parse::RecDescent::_tracefirst($text),
                  q{type},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Cheater::Parser::identifier($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [identifier]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{type},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [identifier]<< (return value: [}
                    . $_tok . q{]},
                      
                      Parse::RecDescent::_tracefirst($text),
                      q{type},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{identifier}} = $_tok;
        push @item, $_tok;
        
        }


        Parse::RecDescent::_trace(q{>>Matched production: [identifier]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{type},
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
                     q{type},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{type},
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
                      q{type},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
                      Parse::RecDescent::_tracefirst($text),
                      , q{type},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}
}
package Cheater::Parser; sub new { my $self = bless( {
                 '_precompiled' => 1,
                 'localvars' => '',
                 'startcode' => '',
                 'namespace' => 'Parse::RecDescent::Cheater::Parser',
                 'rules' => {
                              'qualified_column' => bless( {
                                                             'impcount' => 0,
                                                             'calls' => [
                                                                          'table_name',
                                                                          'column_name'
                                                                        ],
                                                             'changed' => 0,
                                                             'opcount' => 0,
                                                             'prods' => [
                                                                          bless( {
                                                                                   'number' => 0,
                                                                                   'strcount' => 1,
                                                                                   'dircount' => 1,
                                                                                   'uncommit' => undef,
                                                                                   'error' => undef,
                                                                                   'patcount' => 0,
                                                                                   'actcount' => 1,
                                                                                   'items' => [
                                                                                                bless( {
                                                                                                         'subrule' => 'table_name',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => undef,
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 70
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'pattern' => '.',
                                                                                                         'hashname' => '__STRING1__',
                                                                                                         'description' => '\'.\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 70
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'hashname' => '__DIRECTIVE1__',
                                                                                                         'name' => '<commit>',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 70,
                                                                                                         'code' => '$commit = 1'
                                                                                                       }, 'Parse::RecDescent::Directive' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'column_name',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => undef,
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 70
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'hashname' => '__ACTION1__',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 71,
                                                                                                         'code' => '{ [$item[1], $item[4]] }'
                                                                                                       }, 'Parse::RecDescent::Action' )
                                                                                              ],
                                                                                   'line' => undef
                                                                                 }, 'Parse::RecDescent::Production' ),
                                                                          bless( {
                                                                                   'number' => 1,
                                                                                   'strcount' => 0,
                                                                                   'dircount' => 2,
                                                                                   'uncommit' => 0,
                                                                                   'error' => 1,
                                                                                   'patcount' => 0,
                                                                                   'actcount' => 0,
                                                                                   'items' => [
                                                                                                bless( {
                                                                                                         'msg' => '',
                                                                                                         'hashname' => '__DIRECTIVE1__',
                                                                                                         'commitonly' => '?',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 72
                                                                                                       }, 'Parse::RecDescent::Error' ),
                                                                                                bless( {
                                                                                                         'hashname' => '__DIRECTIVE2__',
                                                                                                         'name' => '<reject>',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 72
                                                                                                       }, 'Parse::RecDescent::UncondReject' )
                                                                                              ],
                                                                                   'line' => 72
                                                                                 }, 'Parse::RecDescent::Production' )
                                                                        ],
                                                             'name' => 'qualified_column',
                                                             'vars' => '',
                                                             'line' => 70
                                                           }, 'Parse::RecDescent::Rule' ),
                              'int' => bless( {
                                                'impcount' => 0,
                                                'calls' => [],
                                                'changed' => 0,
                                                'opcount' => 0,
                                                'prods' => [
                                                             bless( {
                                                                      'number' => 0,
                                                                      'strcount' => 0,
                                                                      'dircount' => 0,
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => 1,
                                                                      'actcount' => 0,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'pattern' => '-?\\d+\\b',
                                                                                            'hashname' => '__PATTERN1__',
                                                                                            'description' => '/-?\\\\d+\\\\b/',
                                                                                            'lookahead' => 0,
                                                                                            'rdelim' => '/',
                                                                                            'line' => 114,
                                                                                            'mod' => '',
                                                                                            'ldelim' => '/'
                                                                                          }, 'Parse::RecDescent::Token' )
                                                                                 ],
                                                                      'line' => undef
                                                                    }, 'Parse::RecDescent::Production' )
                                                           ],
                                                'name' => 'int',
                                                'vars' => '',
                                                'line' => 114
                                              }, 'Parse::RecDescent::Rule' ),
                              'number' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'real',
                                                                'int'
                                                              ],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => 0,
                                                                         'strcount' => 0,
                                                                         'dircount' => 0,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 0,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'subrule' => 'real',
                                                                                               'matchrule' => 0,
                                                                                               'implicit' => undef,
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => 0,
                                                                                               'line' => 109
                                                                                             }, 'Parse::RecDescent::Subrule' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' ),
                                                                bless( {
                                                                         'number' => 1,
                                                                         'strcount' => 0,
                                                                         'dircount' => 0,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 0,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'subrule' => 'int',
                                                                                               'matchrule' => 0,
                                                                                               'implicit' => undef,
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => 0,
                                                                                               'line' => 110
                                                                                             }, 'Parse::RecDescent::Subrule' )
                                                                                    ],
                                                                         'line' => 110
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'number',
                                                   'vars' => '',
                                                   'line' => 109
                                                 }, 'Parse::RecDescent::Rule' ),
                              'time' => bless( {
                                                 'impcount' => 0,
                                                 'calls' => [],
                                                 'changed' => 0,
                                                 'opcount' => 0,
                                                 'prods' => [
                                                              bless( {
                                                                       'number' => 0,
                                                                       'strcount' => 0,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 1,
                                                                       'actcount' => 0,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'pattern' => '\\b\\d{2}:\\d{2}:\\d{2}\\b',
                                                                                             'hashname' => '__PATTERN1__',
                                                                                             'description' => '/\\\\b\\\\d\\{2\\}:\\\\d\\{2\\}:\\\\d\\{2\\}\\\\b/',
                                                                                             'lookahead' => 0,
                                                                                             'rdelim' => '/',
                                                                                             'line' => 104,
                                                                                             'mod' => '',
                                                                                             'ldelim' => '/'
                                                                                           }, 'Parse::RecDescent::Token' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' ),
                                                              bless( {
                                                                       'number' => 1,
                                                                       'strcount' => 0,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 1,
                                                                       'actcount' => 1,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'pattern' => '\\b\\d{2}:\\d{2}\\b(?!:)',
                                                                                             'hashname' => '__PATTERN1__',
                                                                                             'description' => '/\\\\b\\\\d\\{2\\}:\\\\d\\{2\\}\\\\b(?!:)/',
                                                                                             'lookahead' => 0,
                                                                                             'rdelim' => '/',
                                                                                             'line' => 105,
                                                                                             'mod' => '',
                                                                                             'ldelim' => '/'
                                                                                           }, 'Parse::RecDescent::Token' ),
                                                                                    bless( {
                                                                                             'hashname' => '__ACTION1__',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 105,
                                                                                             'code' => '{ "$item[1]:00" }'
                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                  ],
                                                                       'line' => 105
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'time',
                                                 'vars' => '',
                                                 'line' => 104
                                               }, 'Parse::RecDescent::Rule' ),
                              'date' => bless( {
                                                 'impcount' => 0,
                                                 'calls' => [],
                                                 'changed' => 0,
                                                 'opcount' => 0,
                                                 'prods' => [
                                                              bless( {
                                                                       'number' => 0,
                                                                       'strcount' => 0,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 1,
                                                                       'actcount' => 0,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'pattern' => '\\b\\d{4}-\\d{2}-\\d{2}\\b',
                                                                                             'hashname' => '__PATTERN1__',
                                                                                             'description' => '/\\\\b\\\\d\\{4\\}-\\\\d\\{2\\}-\\\\d\\{2\\}\\\\b/',
                                                                                             'lookahead' => 0,
                                                                                             'rdelim' => '/',
                                                                                             'line' => 102,
                                                                                             'mod' => '',
                                                                                             'ldelim' => '/'
                                                                                           }, 'Parse::RecDescent::Token' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'date',
                                                 'vars' => '',
                                                 'line' => 102
                                               }, 'Parse::RecDescent::Rule' ),
                              'rows_definition' => bless( {
                                                            'impcount' => 0,
                                                            'calls' => [
                                                                         'table_name'
                                                                       ],
                                                            'changed' => 0,
                                                            'opcount' => 0,
                                                            'prods' => [
                                                                         bless( {
                                                                                  'number' => 0,
                                                                                  'strcount' => 0,
                                                                                  'dircount' => 1,
                                                                                  'uncommit' => undef,
                                                                                  'error' => undef,
                                                                                  'patcount' => 1,
                                                                                  'actcount' => 1,
                                                                                  'items' => [
                                                                                               bless( {
                                                                                                        'pattern' => '\\d+',
                                                                                                        'hashname' => '__PATTERN1__',
                                                                                                        'description' => '/\\\\d+/',
                                                                                                        'lookahead' => 0,
                                                                                                        'rdelim' => '/',
                                                                                                        'line' => 74,
                                                                                                        'mod' => '',
                                                                                                        'ldelim' => '/'
                                                                                                      }, 'Parse::RecDescent::Token' ),
                                                                                               bless( {
                                                                                                        'hashname' => '__DIRECTIVE1__',
                                                                                                        'name' => '<commit>',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 74,
                                                                                                        'code' => '$commit = 1'
                                                                                                      }, 'Parse::RecDescent::Directive' ),
                                                                                               bless( {
                                                                                                        'subrule' => 'table_name',
                                                                                                        'matchrule' => 0,
                                                                                                        'implicit' => undef,
                                                                                                        'argcode' => undef,
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 74
                                                                                                      }, 'Parse::RecDescent::Subrule' ),
                                                                                               bless( {
                                                                                                        'hashname' => '__ACTION1__',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 75,
                                                                                                        'code' => '{ [\'rows\', $item[1], $item[3]] }'
                                                                                                      }, 'Parse::RecDescent::Action' )
                                                                                             ],
                                                                                  'line' => undef
                                                                                }, 'Parse::RecDescent::Production' ),
                                                                         bless( {
                                                                                  'number' => 1,
                                                                                  'strcount' => 0,
                                                                                  'dircount' => 2,
                                                                                  'uncommit' => 0,
                                                                                  'error' => 1,
                                                                                  'patcount' => 0,
                                                                                  'actcount' => 0,
                                                                                  'items' => [
                                                                                               bless( {
                                                                                                        'msg' => '',
                                                                                                        'hashname' => '__DIRECTIVE1__',
                                                                                                        'commitonly' => '?',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 76
                                                                                                      }, 'Parse::RecDescent::Error' ),
                                                                                               bless( {
                                                                                                        'hashname' => '__DIRECTIVE2__',
                                                                                                        'name' => '<reject>',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 76
                                                                                                      }, 'Parse::RecDescent::UncondReject' )
                                                                                             ],
                                                                                  'line' => 76
                                                                                }, 'Parse::RecDescent::Production' )
                                                                       ],
                                                            'name' => 'rows_definition',
                                                            'vars' => '',
                                                            'line' => 74
                                                          }, 'Parse::RecDescent::Rule' ),
                              'range' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [
                                                               'number',
                                                               'date',
                                                               'time',
                                                               'datetime'
                                                             ],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => 0,
                                                                        'strcount' => 1,
                                                                        'dircount' => 1,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'subrule' => 'number',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 92
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'pattern' => '..',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'..\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 92
                                                                                            }, 'Parse::RecDescent::Literal' ),
                                                                                     bless( {
                                                                                              'hashname' => '__DIRECTIVE1__',
                                                                                              'name' => '<commit>',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 92,
                                                                                              'code' => '$commit = 1'
                                                                                            }, 'Parse::RecDescent::Directive' ),
                                                                                     bless( {
                                                                                              'subrule' => 'number',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 92
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 93,
                                                                                              'code' => '{ [\'nrange\', $item[1], $item[4]] }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' ),
                                                               bless( {
                                                                        'number' => 1,
                                                                        'strcount' => 1,
                                                                        'dircount' => 1,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'subrule' => 'date',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 94
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'pattern' => '..',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'..\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 94
                                                                                            }, 'Parse::RecDescent::Literal' ),
                                                                                     bless( {
                                                                                              'hashname' => '__DIRECTIVE1__',
                                                                                              'name' => '<commit>',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 94,
                                                                                              'code' => '$commit = 1'
                                                                                            }, 'Parse::RecDescent::Directive' ),
                                                                                     bless( {
                                                                                              'subrule' => 'date',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 94
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 95,
                                                                                              'code' => '{ [\'drange\', $item[1], $item[4]] }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => 94
                                                                      }, 'Parse::RecDescent::Production' ),
                                                               bless( {
                                                                        'number' => 2,
                                                                        'strcount' => 1,
                                                                        'dircount' => 1,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'subrule' => 'time',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 96
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'pattern' => '..',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'..\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 96
                                                                                            }, 'Parse::RecDescent::Literal' ),
                                                                                     bless( {
                                                                                              'hashname' => '__DIRECTIVE1__',
                                                                                              'name' => '<commit>',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 96,
                                                                                              'code' => '$commit = 1'
                                                                                            }, 'Parse::RecDescent::Directive' ),
                                                                                     bless( {
                                                                                              'subrule' => 'time',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 96
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 97,
                                                                                              'code' => '{ [\'trange\', $item[1], $item[4]] }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => 96
                                                                      }, 'Parse::RecDescent::Production' ),
                                                               bless( {
                                                                        'number' => 3,
                                                                        'strcount' => 1,
                                                                        'dircount' => 1,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'subrule' => 'datetime',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 98
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'pattern' => '..',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'..\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 98
                                                                                            }, 'Parse::RecDescent::Literal' ),
                                                                                     bless( {
                                                                                              'hashname' => '__DIRECTIVE1__',
                                                                                              'name' => '<commit>',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 98,
                                                                                              'code' => '$commit = 1'
                                                                                            }, 'Parse::RecDescent::Directive' ),
                                                                                     bless( {
                                                                                              'subrule' => 'datetime',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 98
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 99,
                                                                                              'code' => '{ [\'dtrange\', $item[1], $item[4]] }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => 98
                                                                      }, 'Parse::RecDescent::Production' ),
                                                               bless( {
                                                                        'number' => 4,
                                                                        'strcount' => 0,
                                                                        'dircount' => 2,
                                                                        'uncommit' => 0,
                                                                        'error' => 1,
                                                                        'patcount' => 0,
                                                                        'actcount' => 0,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'msg' => '',
                                                                                              'hashname' => '__DIRECTIVE1__',
                                                                                              'commitonly' => '?',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 100
                                                                                            }, 'Parse::RecDescent::Error' ),
                                                                                     bless( {
                                                                                              'hashname' => '__DIRECTIVE2__',
                                                                                              'name' => '<reject>',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 100
                                                                                            }, 'Parse::RecDescent::UncondReject' )
                                                                                   ],
                                                                        'line' => 100
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'range',
                                                  'vars' => '',
                                                  'line' => 92
                                                }, 'Parse::RecDescent::Rule' ),
                              'type_definition' => bless( {
                                                            'impcount' => 0,
                                                            'calls' => [
                                                                         'type',
                                                                         'domain',
                                                                         'attribute'
                                                                       ],
                                                            'changed' => 0,
                                                            'opcount' => 0,
                                                            'prods' => [
                                                                         bless( {
                                                                                  'number' => 0,
                                                                                  'strcount' => 2,
                                                                                  'dircount' => 1,
                                                                                  'uncommit' => undef,
                                                                                  'error' => undef,
                                                                                  'patcount' => 0,
                                                                                  'actcount' => 1,
                                                                                  'items' => [
                                                                                               bless( {
                                                                                                        'pattern' => 'type',
                                                                                                        'hashname' => '__STRING1__',
                                                                                                        'description' => '\'type\'',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 78
                                                                                                      }, 'Parse::RecDescent::Literal' ),
                                                                                               bless( {
                                                                                                        'hashname' => '__DIRECTIVE1__',
                                                                                                        'name' => '<commit>',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 78,
                                                                                                        'code' => '$commit = 1'
                                                                                                      }, 'Parse::RecDescent::Directive' ),
                                                                                               bless( {
                                                                                                        'subrule' => 'type',
                                                                                                        'matchrule' => 0,
                                                                                                        'implicit' => undef,
                                                                                                        'argcode' => undef,
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 78
                                                                                                      }, 'Parse::RecDescent::Subrule' ),
                                                                                               bless( {
                                                                                                        'pattern' => '=',
                                                                                                        'hashname' => '__STRING2__',
                                                                                                        'description' => '\'=\'',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 78
                                                                                                      }, 'Parse::RecDescent::Literal' ),
                                                                                               bless( {
                                                                                                        'subrule' => 'type',
                                                                                                        'matchrule' => 0,
                                                                                                        'implicit' => undef,
                                                                                                        'argcode' => undef,
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 78
                                                                                                      }, 'Parse::RecDescent::Subrule' ),
                                                                                               bless( {
                                                                                                        'subrule' => 'domain',
                                                                                                        'expected' => undef,
                                                                                                        'min' => 0,
                                                                                                        'argcode' => undef,
                                                                                                        'max' => 1,
                                                                                                        'matchrule' => 0,
                                                                                                        'repspec' => '?',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 78
                                                                                                      }, 'Parse::RecDescent::Repetition' ),
                                                                                               bless( {
                                                                                                        'subrule' => 'attribute',
                                                                                                        'expected' => undef,
                                                                                                        'min' => 0,
                                                                                                        'argcode' => undef,
                                                                                                        'max' => 100000000,
                                                                                                        'matchrule' => 0,
                                                                                                        'repspec' => 's?',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 78
                                                                                                      }, 'Parse::RecDescent::Repetition' ),
                                                                                               bless( {
                                                                                                        'hashname' => '__ACTION1__',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 79,
                                                                                                        'code' => '{
                        [\'type\', $item[3], $item[4], $item[5], $item[6]] }'
                                                                                                      }, 'Parse::RecDescent::Action' )
                                                                                             ],
                                                                                  'line' => undef
                                                                                }, 'Parse::RecDescent::Production' ),
                                                                         bless( {
                                                                                  'number' => 1,
                                                                                  'strcount' => 0,
                                                                                  'dircount' => 2,
                                                                                  'uncommit' => 0,
                                                                                  'error' => 1,
                                                                                  'patcount' => 0,
                                                                                  'actcount' => 0,
                                                                                  'items' => [
                                                                                               bless( {
                                                                                                        'msg' => '',
                                                                                                        'hashname' => '__DIRECTIVE1__',
                                                                                                        'commitonly' => '?',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 81
                                                                                                      }, 'Parse::RecDescent::Error' ),
                                                                                               bless( {
                                                                                                        'hashname' => '__DIRECTIVE2__',
                                                                                                        'name' => '<reject>',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => 81
                                                                                                      }, 'Parse::RecDescent::UncondReject' )
                                                                                             ],
                                                                                  'line' => 81
                                                                                }, 'Parse::RecDescent::Production' )
                                                                       ],
                                                            'name' => 'type_definition',
                                                            'vars' => '',
                                                            'line' => 78
                                                          }, 'Parse::RecDescent::Rule' ),
                              'string' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => 0,
                                                                         'strcount' => 2,
                                                                         'dircount' => 1,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 1,
                                                                         'actcount' => 1,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'pattern' => '\'',
                                                                                               'hashname' => '__STRING1__',
                                                                                               'description' => '\'\'\'',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 65
                                                                                             }, 'Parse::RecDescent::InterpLit' ),
                                                                                      bless( {
                                                                                               'hashname' => '__DIRECTIVE1__',
                                                                                               'name' => '<commit>',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 65,
                                                                                               'code' => '$commit = 1'
                                                                                             }, 'Parse::RecDescent::Directive' ),
                                                                                      bless( {
                                                                                               'pattern' => '(?:[^\']|\\\\.)*',
                                                                                               'hashname' => '__PATTERN1__',
                                                                                               'description' => '/(?:[^\']|\\\\\\\\.)*/',
                                                                                               'lookahead' => 0,
                                                                                               'rdelim' => '/',
                                                                                               'line' => 65,
                                                                                               'mod' => '',
                                                                                               'ldelim' => '/'
                                                                                             }, 'Parse::RecDescent::Token' ),
                                                                                      bless( {
                                                                                               'pattern' => '\'',
                                                                                               'hashname' => '__STRING2__',
                                                                                               'description' => '\'\'\'',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 65
                                                                                             }, 'Parse::RecDescent::InterpLit' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 66,
                                                                                               'code' => '{ eval "\'$item[3]\'" }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' ),
                                                                bless( {
                                                                         'number' => 1,
                                                                         'strcount' => 2,
                                                                         'dircount' => 1,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 1,
                                                                         'actcount' => 1,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'pattern' => '"',
                                                                                               'hashname' => '__STRING1__',
                                                                                               'description' => '\'"\'',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 67
                                                                                             }, 'Parse::RecDescent::Literal' ),
                                                                                      bless( {
                                                                                               'hashname' => '__DIRECTIVE1__',
                                                                                               'name' => '<commit>',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 67,
                                                                                               'code' => '$commit = 1'
                                                                                             }, 'Parse::RecDescent::Directive' ),
                                                                                      bless( {
                                                                                               'pattern' => '(?:[^"]|\\\\.)*',
                                                                                               'hashname' => '__PATTERN1__',
                                                                                               'description' => '/(?:[^"]|\\\\\\\\.)*/',
                                                                                               'lookahead' => 0,
                                                                                               'rdelim' => '/',
                                                                                               'line' => 67,
                                                                                               'mod' => '',
                                                                                               'ldelim' => '/'
                                                                                             }, 'Parse::RecDescent::Token' ),
                                                                                      bless( {
                                                                                               'pattern' => '"',
                                                                                               'hashname' => '__STRING2__',
                                                                                               'description' => '\'"\'',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 67
                                                                                             }, 'Parse::RecDescent::Literal' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 68,
                                                                                               'code' => '{ eval qq{"$item[3]"} }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => 67
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'string',
                                                   'vars' => '',
                                                   'line' => 65
                                                 }, 'Parse::RecDescent::Rule' ),
                              'datetime' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [
                                                                  'date',
                                                                  'time'
                                                                ],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => 0,
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'date',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 107
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'subrule' => 'time',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 107
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 107,
                                                                                                 'code' => '{ "$item[1] $item[2]" }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'datetime',
                                                     'vars' => '',
                                                     'line' => 107
                                                   }, 'Parse::RecDescent::Rule' ),
                              'attribute' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'string'
                                                                 ],
                                                      'changed' => 0,
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'number' => 0,
                                                                            'strcount' => 1,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 0,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => 'unique',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'unique\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 47
                                                                                                }, 'Parse::RecDescent::Literal' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => 1,
                                                                            'strcount' => 1,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 0,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => 'unsigned',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'unsigned\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 47
                                                                                                }, 'Parse::RecDescent::Literal' )
                                                                                       ],
                                                                            'line' => 47
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => 2,
                                                                            'strcount' => 1,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 0,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => 'asc',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'asc\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 47
                                                                                                }, 'Parse::RecDescent::Literal' )
                                                                                       ],
                                                                            'line' => 47
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => 3,
                                                                            'strcount' => 1,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 0,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => 'desc',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'desc\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 47
                                                                                                }, 'Parse::RecDescent::Literal' )
                                                                                       ],
                                                                            'line' => 47
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => 4,
                                                                            'strcount' => 2,
                                                                            'dircount' => 1,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => 'not',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'not\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 48
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__DIRECTIVE1__',
                                                                                                  'name' => '<commit>',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 48,
                                                                                                  'code' => '$commit = 1'
                                                                                                }, 'Parse::RecDescent::Directive' ),
                                                                                         bless( {
                                                                                                  'pattern' => 'null',
                                                                                                  'hashname' => '__STRING2__',
                                                                                                  'description' => '\'null\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 48
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 48,
                                                                                                  'code' => '{ "$item[1] $item[3]" }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => 48
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => 5,
                                                                            'strcount' => 1,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => 'for',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'for\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 49
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'string',
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
                                                                                                  'code' => '{ [\'for\', $item{string}] }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => 49
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => 6,
                                                                            'strcount' => 0,
                                                                            'dircount' => 2,
                                                                            'uncommit' => 0,
                                                                            'error' => 1,
                                                                            'patcount' => 0,
                                                                            'actcount' => 0,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'msg' => '',
                                                                                                  'hashname' => '__DIRECTIVE1__',
                                                                                                  'commitonly' => '?',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 50
                                                                                                }, 'Parse::RecDescent::Error' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__DIRECTIVE2__',
                                                                                                  'name' => '<reject>',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 50
                                                                                                }, 'Parse::RecDescent::UncondReject' )
                                                                                       ],
                                                                            'line' => 50
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'attribute',
                                                      'vars' => '',
                                                      'line' => 47
                                                    }, 'Parse::RecDescent::Rule' ),
                              'identifier' => bless( {
                                                       'impcount' => 0,
                                                       'calls' => [],
                                                       'changed' => 0,
                                                       'opcount' => 0,
                                                       'prods' => [
                                                                    bless( {
                                                                             'number' => 0,
                                                                             'strcount' => 0,
                                                                             'dircount' => 0,
                                                                             'uncommit' => undef,
                                                                             'error' => undef,
                                                                             'patcount' => 1,
                                                                             'actcount' => 0,
                                                                             'items' => [
                                                                                          bless( {
                                                                                                   'pattern' => '[A-Za-z]\\w*',
                                                                                                   'hashname' => '__PATTERN1__',
                                                                                                   'description' => '/[A-Za-z]\\\\w*/',
                                                                                                   'lookahead' => 0,
                                                                                                   'rdelim' => '/',
                                                                                                   'line' => 116,
                                                                                                   'mod' => '',
                                                                                                   'ldelim' => '/'
                                                                                                 }, 'Parse::RecDescent::Token' )
                                                                                        ],
                                                                             'line' => undef
                                                                           }, 'Parse::RecDescent::Production' )
                                                                  ],
                                                       'name' => 'identifier',
                                                       'vars' => '',
                                                       'line' => 116
                                                     }, 'Parse::RecDescent::Rule' ),
                              'domain' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'enum',
                                                                'atom'
                                                              ],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => 0,
                                                                         'strcount' => 0,
                                                                         'dircount' => 0,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 0,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'subrule' => 'enum',
                                                                                               'matchrule' => 0,
                                                                                               'implicit' => undef,
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => 0,
                                                                                               'line' => 52
                                                                                             }, 'Parse::RecDescent::Subrule' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' ),
                                                                bless( {
                                                                         'number' => 1,
                                                                         'strcount' => 0,
                                                                         'dircount' => 0,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 1,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'subrule' => 'atom',
                                                                                               'matchrule' => 0,
                                                                                               'implicit' => undef,
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => 0,
                                                                                               'line' => 53
                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 53,
                                                                                               'code' => '{ [ $item[1] ] }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => 53
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'domain',
                                                   'vars' => '',
                                                   'line' => 52
                                                 }, 'Parse::RecDescent::Rule' ),
                              'table_definition' => bless( {
                                                             'impcount' => 0,
                                                             'calls' => [
                                                                          'table_name',
                                                                          'column_definition'
                                                                        ],
                                                             'changed' => 0,
                                                             'opcount' => 0,
                                                             'prods' => [
                                                                          bless( {
                                                                                   'number' => 0,
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
                                                                                                         'line' => 29
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'hashname' => '__DIRECTIVE1__',
                                                                                                         'name' => '<commit>',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 29,
                                                                                                         'code' => '$commit = 1'
                                                                                                       }, 'Parse::RecDescent::Directive' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'table_name',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => undef,
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 29
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'pattern' => '(',
                                                                                                         'hashname' => '__STRING2__',
                                                                                                         'description' => '\'(\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 29
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'column_definition',
                                                                                                         'expected' => undef,
                                                                                                         'min' => 1,
                                                                                                         'argcode' => undef,
                                                                                                         'max' => 100000000,
                                                                                                         'matchrule' => 0,
                                                                                                         'repspec' => 's',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 30
                                                                                                       }, 'Parse::RecDescent::Repetition' ),
                                                                                                bless( {
                                                                                                         'pattern' => ')',
                                                                                                         'hashname' => '__STRING3__',
                                                                                                         'description' => '\')\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 31
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'hashname' => '__ACTION1__',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 32,
                                                                                                         'code' => '{ [\'table\', $item[3], $item[5]] }'
                                                                                                       }, 'Parse::RecDescent::Action' )
                                                                                              ],
                                                                                   'line' => undef
                                                                                 }, 'Parse::RecDescent::Production' ),
                                                                          bless( {
                                                                                   'number' => 1,
                                                                                   'strcount' => 0,
                                                                                   'dircount' => 2,
                                                                                   'uncommit' => 0,
                                                                                   'error' => 1,
                                                                                   'patcount' => 0,
                                                                                   'actcount' => 0,
                                                                                   'items' => [
                                                                                                bless( {
                                                                                                         'msg' => '',
                                                                                                         'hashname' => '__DIRECTIVE1__',
                                                                                                         'commitonly' => '?',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 33
                                                                                                       }, 'Parse::RecDescent::Error' ),
                                                                                                bless( {
                                                                                                         'hashname' => '__DIRECTIVE2__',
                                                                                                         'name' => '<reject>',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 33
                                                                                                       }, 'Parse::RecDescent::UncondReject' )
                                                                                              ],
                                                                                   'line' => 33
                                                                                 }, 'Parse::RecDescent::Production' )
                                                                        ],
                                                             'name' => 'table_definition',
                                                             'vars' => '',
                                                             'line' => 29
                                                           }, 'Parse::RecDescent::Rule' ),
                              'column_name' => bless( {
                                                        'impcount' => 0,
                                                        'calls' => [
                                                                     'identifier'
                                                                   ],
                                                        'changed' => 0,
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'number' => 0,
                                                                              'strcount' => 0,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 0,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'subrule' => 'identifier',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 43
                                                                                                  }, 'Parse::RecDescent::Subrule' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'column_name',
                                                        'vars' => '',
                                                        'line' => 43
                                                      }, 'Parse::RecDescent::Rule' ),
                              'statement' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'table_definition',
                                                                   'rows_definition',
                                                                   'type_definition',
                                                                   'include_statement',
                                                                   'table_assignment'
                                                                 ],
                                                      'changed' => 0,
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'number' => 0,
                                                                            'strcount' => 0,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 1,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'subrule' => 'table_definition',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 10
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'pattern' => ';?',
                                                                                                  'hashname' => '__PATTERN1__',
                                                                                                  'description' => '/;?/',
                                                                                                  'lookahead' => 0,
                                                                                                  'rdelim' => '/',
                                                                                                  'line' => 10,
                                                                                                  'mod' => '',
                                                                                                  'ldelim' => '/'
                                                                                                }, 'Parse::RecDescent::Token' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 10,
                                                                                                  'code' => '{ $item[1] }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => 1,
                                                                            'strcount' => 1,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'subrule' => 'rows_definition',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 11
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'pattern' => ';',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\';\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 11
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 11,
                                                                                                  'code' => '{ $item[1] }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => 11
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => 2,
                                                                            'strcount' => 1,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'subrule' => 'type_definition',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 12
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'pattern' => ';',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\';\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 12
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 12,
                                                                                                  'code' => '{ $item[1] }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => 12
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => 3,
                                                                            'strcount' => 1,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'subrule' => 'include_statement',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 13
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'pattern' => ';',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\';\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 13
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 13,
                                                                                                  'code' => '{ $item[1] }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => 13
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => 4,
                                                                            'strcount' => 1,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'subrule' => 'table_assignment',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 14
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'pattern' => ';',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\';\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 14
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 14,
                                                                                                  'code' => '{ $item[1] }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => 14
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => 5,
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
                                                                                                  'line' => 15
                                                                                                }, 'Parse::RecDescent::Error' )
                                                                                       ],
                                                                            'line' => 15
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'statement',
                                                      'vars' => '',
                                                      'line' => 10
                                                    }, 'Parse::RecDescent::Rule' ),
                              'file_name' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'string'
                                                                 ],
                                                      'changed' => 0,
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'number' => 0,
                                                                            'strcount' => 0,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 0,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'subrule' => 'string',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 25
                                                                                                }, 'Parse::RecDescent::Subrule' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'file_name',
                                                      'vars' => '',
                                                      'line' => 25
                                                    }, 'Parse::RecDescent::Rule' ),
                              'atom' => bless( {
                                                 'impcount' => 0,
                                                 'calls' => [
                                                              'range',
                                                              'number',
                                                              'regex',
                                                              'string',
                                                              'int'
                                                            ],
                                                 'changed' => 0,
                                                 'opcount' => 0,
                                                 'prods' => [
                                                              bless( {
                                                                       'number' => 0,
                                                                       'strcount' => 0,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 0,
                                                                       'actcount' => 0,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'subrule' => 'range',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => 59
                                                                                           }, 'Parse::RecDescent::Subrule' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' ),
                                                              bless( {
                                                                       'number' => 1,
                                                                       'strcount' => 0,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 0,
                                                                       'actcount' => 0,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'subrule' => 'number',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => 60
                                                                                           }, 'Parse::RecDescent::Subrule' )
                                                                                  ],
                                                                       'line' => 60
                                                                     }, 'Parse::RecDescent::Production' ),
                                                              bless( {
                                                                       'number' => 2,
                                                                       'strcount' => 0,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 0,
                                                                       'actcount' => 0,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'subrule' => 'regex',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => 61
                                                                                           }, 'Parse::RecDescent::Subrule' )
                                                                                  ],
                                                                       'line' => 61
                                                                     }, 'Parse::RecDescent::Production' ),
                                                              bless( {
                                                                       'number' => 3,
                                                                       'strcount' => 0,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 0,
                                                                       'actcount' => 0,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'subrule' => 'string',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => 62
                                                                                           }, 'Parse::RecDescent::Subrule' )
                                                                                  ],
                                                                       'line' => 62
                                                                     }, 'Parse::RecDescent::Production' ),
                                                              bless( {
                                                                       'number' => 4,
                                                                       'strcount' => 0,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 0,
                                                                       'actcount' => 0,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'subrule' => 'int',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => 63
                                                                                           }, 'Parse::RecDescent::Subrule' )
                                                                                  ],
                                                                       'line' => 63
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'atom',
                                                 'vars' => '',
                                                 'line' => 59
                                               }, 'Parse::RecDescent::Rule' ),
                              'enum' => bless( {
                                                 'impcount' => 0,
                                                 'calls' => [
                                                              'atom'
                                                            ],
                                                 'changed' => 0,
                                                 'opcount' => 0,
                                                 'prods' => [
                                                              bless( {
                                                                       'number' => 0,
                                                                       'strcount' => 2,
                                                                       'dircount' => 2,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 1,
                                                                       'actcount' => 1,
                                                                       'op' => [],
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'pattern' => '{',
                                                                                             'hashname' => '__STRING1__',
                                                                                             'description' => '\'\\{\'',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 55
                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                    bless( {
                                                                                             'hashname' => '__DIRECTIVE1__',
                                                                                             'name' => '<commit>',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 55,
                                                                                             'code' => '$commit = 1'
                                                                                           }, 'Parse::RecDescent::Directive' ),
                                                                                    bless( {
                                                                                             'expected' => '<leftop: atom /,/ atom>',
                                                                                             'min' => 0,
                                                                                             'name' => '\'atom(s?)\'',
                                                                                             'max' => 100000000,
                                                                                             'leftarg' => bless( {
                                                                                                                   'subrule' => 'atom',
                                                                                                                   'matchrule' => 0,
                                                                                                                   'implicit' => undef,
                                                                                                                   'argcode' => undef,
                                                                                                                   'lookahead' => 0,
                                                                                                                   'line' => 55
                                                                                                                 }, 'Parse::RecDescent::Subrule' ),
                                                                                             'rightarg' => bless( {
                                                                                                                    'subrule' => 'atom',
                                                                                                                    'matchrule' => 0,
                                                                                                                    'implicit' => undef,
                                                                                                                    'argcode' => undef,
                                                                                                                    'lookahead' => 0,
                                                                                                                    'line' => 55
                                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                             'hashname' => '__DIRECTIVE2__',
                                                                                             'type' => 'leftop',
                                                                                             'op' => bless( {
                                                                                                              'pattern' => ',',
                                                                                                              'hashname' => '__PATTERN1__',
                                                                                                              'description' => '/,/',
                                                                                                              'lookahead' => 0,
                                                                                                              'rdelim' => '/',
                                                                                                              'line' => 55,
                                                                                                              'mod' => '',
                                                                                                              'ldelim' => '/'
                                                                                                            }, 'Parse::RecDescent::Token' )
                                                                                           }, 'Parse::RecDescent::Operator' ),
                                                                                    bless( {
                                                                                             'pattern' => '}',
                                                                                             'hashname' => '__STRING2__',
                                                                                             'description' => '\'\\}\'',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 55
                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                    bless( {
                                                                                             'hashname' => '__ACTION1__',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 56,
                                                                                             'code' => '{ $item[3] }'
                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' ),
                                                              bless( {
                                                                       'number' => 1,
                                                                       'strcount' => 0,
                                                                       'dircount' => 2,
                                                                       'uncommit' => 0,
                                                                       'error' => 1,
                                                                       'patcount' => 0,
                                                                       'actcount' => 0,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'msg' => '',
                                                                                             'hashname' => '__DIRECTIVE1__',
                                                                                             'commitonly' => '?',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 57
                                                                                           }, 'Parse::RecDescent::Error' ),
                                                                                    bless( {
                                                                                             'hashname' => '__DIRECTIVE2__',
                                                                                             'name' => '<reject>',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 57
                                                                                           }, 'Parse::RecDescent::UncondReject' )
                                                                                  ],
                                                                       'line' => 57
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'enum',
                                                 'vars' => '',
                                                 'line' => 55
                                               }, 'Parse::RecDescent::Rule' ),
                              'column_definition' => bless( {
                                                              'impcount' => 0,
                                                              'calls' => [
                                                                           'column_name',
                                                                           'qualified_column',
                                                                           'attribute',
                                                                           'type',
                                                                           'domain'
                                                                         ],
                                                              'changed' => 0,
                                                              'opcount' => 0,
                                                              'prods' => [
                                                                           bless( {
                                                                                    'number' => 0,
                                                                                    'strcount' => 2,
                                                                                    'dircount' => 1,
                                                                                    'uncommit' => undef,
                                                                                    'error' => undef,
                                                                                    'patcount' => 0,
                                                                                    'actcount' => 1,
                                                                                    'items' => [
                                                                                                 bless( {
                                                                                                          'subrule' => 'column_name',
                                                                                                          'matchrule' => 0,
                                                                                                          'implicit' => undef,
                                                                                                          'argcode' => undef,
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 36
                                                                                                        }, 'Parse::RecDescent::Subrule' ),
                                                                                                 bless( {
                                                                                                          'pattern' => 'references',
                                                                                                          'hashname' => '__STRING1__',
                                                                                                          'description' => '\'references\'',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 36
                                                                                                        }, 'Parse::RecDescent::Literal' ),
                                                                                                 bless( {
                                                                                                          'hashname' => '__DIRECTIVE1__',
                                                                                                          'name' => '<commit>',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 36,
                                                                                                          'code' => '$commit = 1'
                                                                                                        }, 'Parse::RecDescent::Directive' ),
                                                                                                 bless( {
                                                                                                          'subrule' => 'qualified_column',
                                                                                                          'matchrule' => 0,
                                                                                                          'implicit' => undef,
                                                                                                          'argcode' => undef,
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 36
                                                                                                        }, 'Parse::RecDescent::Subrule' ),
                                                                                                 bless( {
                                                                                                          'subrule' => 'attribute',
                                                                                                          'expected' => undef,
                                                                                                          'min' => 0,
                                                                                                          'argcode' => undef,
                                                                                                          'max' => 100000000,
                                                                                                          'matchrule' => 0,
                                                                                                          'repspec' => 's?',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 36
                                                                                                        }, 'Parse::RecDescent::Repetition' ),
                                                                                                 bless( {
                                                                                                          'pattern' => ';',
                                                                                                          'hashname' => '__STRING2__',
                                                                                                          'description' => '\';\'',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 36
                                                                                                        }, 'Parse::RecDescent::Literal' ),
                                                                                                 bless( {
                                                                                                          'hashname' => '__ACTION1__',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 37,
                                                                                                          'code' => '{ [ $item[1], \'refs\', $item[4], $item[5] ] }'
                                                                                                        }, 'Parse::RecDescent::Action' )
                                                                                               ],
                                                                                    'line' => undef
                                                                                  }, 'Parse::RecDescent::Production' ),
                                                                           bless( {
                                                                                    'number' => 1,
                                                                                    'strcount' => 1,
                                                                                    'dircount' => 0,
                                                                                    'uncommit' => undef,
                                                                                    'error' => undef,
                                                                                    'patcount' => 0,
                                                                                    'actcount' => 1,
                                                                                    'items' => [
                                                                                                 bless( {
                                                                                                          'subrule' => 'column_name',
                                                                                                          'matchrule' => 0,
                                                                                                          'implicit' => undef,
                                                                                                          'argcode' => undef,
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 38
                                                                                                        }, 'Parse::RecDescent::Subrule' ),
                                                                                                 bless( {
                                                                                                          'subrule' => 'type',
                                                                                                          'matchrule' => 0,
                                                                                                          'implicit' => undef,
                                                                                                          'argcode' => undef,
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 38
                                                                                                        }, 'Parse::RecDescent::Subrule' ),
                                                                                                 bless( {
                                                                                                          'subrule' => 'domain',
                                                                                                          'expected' => undef,
                                                                                                          'min' => 0,
                                                                                                          'argcode' => undef,
                                                                                                          'max' => 1,
                                                                                                          'matchrule' => 0,
                                                                                                          'repspec' => '?',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 38
                                                                                                        }, 'Parse::RecDescent::Repetition' ),
                                                                                                 bless( {
                                                                                                          'subrule' => 'attribute',
                                                                                                          'expected' => undef,
                                                                                                          'min' => 0,
                                                                                                          'argcode' => undef,
                                                                                                          'max' => 100000000,
                                                                                                          'matchrule' => 0,
                                                                                                          'repspec' => 's?',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 38
                                                                                                        }, 'Parse::RecDescent::Repetition' ),
                                                                                                 bless( {
                                                                                                          'pattern' => ';',
                                                                                                          'hashname' => '__STRING1__',
                                                                                                          'description' => '\';\'',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 38
                                                                                                        }, 'Parse::RecDescent::Literal' ),
                                                                                                 bless( {
                                                                                                          'hashname' => '__ACTION1__',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 39,
                                                                                                          'code' => '{ [$item[1], $item[2], $item[3], $item[4] ] }'
                                                                                                        }, 'Parse::RecDescent::Action' )
                                                                                               ],
                                                                                    'line' => 38
                                                                                  }, 'Parse::RecDescent::Production' ),
                                                                           bless( {
                                                                                    'number' => 2,
                                                                                    'strcount' => 2,
                                                                                    'dircount' => 0,
                                                                                    'uncommit' => undef,
                                                                                    'error' => undef,
                                                                                    'patcount' => 0,
                                                                                    'actcount' => 1,
                                                                                    'items' => [
                                                                                                 bless( {
                                                                                                          'subrule' => 'column_name',
                                                                                                          'matchrule' => 0,
                                                                                                          'implicit' => undef,
                                                                                                          'argcode' => undef,
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 40
                                                                                                        }, 'Parse::RecDescent::Subrule' ),
                                                                                                 bless( {
                                                                                                          'pattern' => '=',
                                                                                                          'hashname' => '__STRING1__',
                                                                                                          'description' => '\'=\'',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 40
                                                                                                        }, 'Parse::RecDescent::Literal' ),
                                                                                                 bless( {
                                                                                                          'subrule' => 'column_name',
                                                                                                          'matchrule' => 0,
                                                                                                          'implicit' => undef,
                                                                                                          'argcode' => undef,
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 40
                                                                                                        }, 'Parse::RecDescent::Subrule' ),
                                                                                                 bless( {
                                                                                                          'pattern' => ';',
                                                                                                          'hashname' => '__STRING2__',
                                                                                                          'description' => '\';\'',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 40
                                                                                                        }, 'Parse::RecDescent::Literal' ),
                                                                                                 bless( {
                                                                                                          'hashname' => '__ACTION1__',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 40,
                                                                                                          'code' => '{ [$item[1], \'=\', $item[3]] }'
                                                                                                        }, 'Parse::RecDescent::Action' )
                                                                                               ],
                                                                                    'line' => 40
                                                                                  }, 'Parse::RecDescent::Production' ),
                                                                           bless( {
                                                                                    'number' => 3,
                                                                                    'strcount' => 0,
                                                                                    'dircount' => 2,
                                                                                    'uncommit' => 0,
                                                                                    'error' => 1,
                                                                                    'patcount' => 0,
                                                                                    'actcount' => 0,
                                                                                    'items' => [
                                                                                                 bless( {
                                                                                                          'msg' => '',
                                                                                                          'hashname' => '__DIRECTIVE1__',
                                                                                                          'commitonly' => '?',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 41
                                                                                                        }, 'Parse::RecDescent::Error' ),
                                                                                                 bless( {
                                                                                                          'hashname' => '__DIRECTIVE2__',
                                                                                                          'name' => '<reject>',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 41
                                                                                                        }, 'Parse::RecDescent::UncondReject' )
                                                                                               ],
                                                                                    'line' => 41
                                                                                  }, 'Parse::RecDescent::Production' )
                                                                         ],
                                                              'name' => 'column_definition',
                                                              'vars' => '',
                                                              'line' => 35
                                                            }, 'Parse::RecDescent::Rule' ),
                              'real' => bless( {
                                                 'impcount' => 0,
                                                 'calls' => [],
                                                 'changed' => 0,
                                                 'opcount' => 0,
                                                 'prods' => [
                                                              bless( {
                                                                       'number' => 0,
                                                                       'strcount' => 0,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 1,
                                                                       'actcount' => 0,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'pattern' => '-?\\d+\\.\\d+\\b',
                                                                                             'hashname' => '__PATTERN1__',
                                                                                             'description' => '/-?\\\\d+\\\\.\\\\d+\\\\b/',
                                                                                             'lookahead' => 0,
                                                                                             'rdelim' => '/',
                                                                                             'line' => 112,
                                                                                             'mod' => '',
                                                                                             'ldelim' => '/'
                                                                                           }, 'Parse::RecDescent::Token' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'real',
                                                 'vars' => '',
                                                 'line' => 112
                                               }, 'Parse::RecDescent::Rule' ),
                              'spec' => bless( {
                                                 'impcount' => 0,
                                                 'calls' => [
                                                              'statement',
                                                              'eof'
                                                            ],
                                                 'changed' => 0,
                                                 'opcount' => 0,
                                                 'prods' => [
                                                              bless( {
                                                                       'number' => 0,
                                                                       'strcount' => 0,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 0,
                                                                       'actcount' => 1,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'subrule' => 'statement',
                                                                                             'expected' => undef,
                                                                                             'min' => 1,
                                                                                             'argcode' => undef,
                                                                                             'max' => 100000000,
                                                                                             'matchrule' => 0,
                                                                                             'repspec' => 's',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 5
                                                                                           }, 'Parse::RecDescent::Repetition' ),
                                                                                    bless( {
                                                                                             'subrule' => 'eof',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => 5
                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                    bless( {
                                                                                             'hashname' => '__ACTION1__',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 6,
                                                                                             'code' => '{ $item[1] }'
                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'spec',
                                                 'vars' => '',
                                                 'line' => 5
                                               }, 'Parse::RecDescent::Rule' ),
                              'table_assignment' => bless( {
                                                             'impcount' => 0,
                                                             'calls' => [
                                                                          'table_name'
                                                                        ],
                                                             'changed' => 0,
                                                             'opcount' => 0,
                                                             'prods' => [
                                                                          bless( {
                                                                                   'number' => 0,
                                                                                   'strcount' => 1,
                                                                                   'dircount' => 1,
                                                                                   'uncommit' => undef,
                                                                                   'error' => undef,
                                                                                   'patcount' => 0,
                                                                                   'actcount' => 1,
                                                                                   'items' => [
                                                                                                bless( {
                                                                                                         'subrule' => 'table_name',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => undef,
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 17
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'pattern' => '=',
                                                                                                         'hashname' => '__STRING1__',
                                                                                                         'description' => '\'=\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 17
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'hashname' => '__DIRECTIVE1__',
                                                                                                         'name' => '<commit>',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 17,
                                                                                                         'code' => '$commit = 1'
                                                                                                       }, 'Parse::RecDescent::Directive' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'table_name',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => undef,
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 17
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'hashname' => '__ACTION1__',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 18,
                                                                                                         'code' => '{ [ \'table_assign\', $item[1], $item[4] ] }'
                                                                                                       }, 'Parse::RecDescent::Action' )
                                                                                              ],
                                                                                   'line' => undef
                                                                                 }, 'Parse::RecDescent::Production' ),
                                                                          bless( {
                                                                                   'number' => 1,
                                                                                   'strcount' => 0,
                                                                                   'dircount' => 2,
                                                                                   'uncommit' => 0,
                                                                                   'error' => 1,
                                                                                   'patcount' => 0,
                                                                                   'actcount' => 0,
                                                                                   'items' => [
                                                                                                bless( {
                                                                                                         'msg' => '',
                                                                                                         'hashname' => '__DIRECTIVE1__',
                                                                                                         'commitonly' => '?',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 19
                                                                                                       }, 'Parse::RecDescent::Error' ),
                                                                                                bless( {
                                                                                                         'hashname' => '__DIRECTIVE2__',
                                                                                                         'name' => '<reject>',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => 19
                                                                                                       }, 'Parse::RecDescent::UncondReject' )
                                                                                              ],
                                                                                   'line' => 19
                                                                                 }, 'Parse::RecDescent::Production' )
                                                                        ],
                                                             'name' => 'table_assignment',
                                                             'vars' => '',
                                                             'line' => 17
                                                           }, 'Parse::RecDescent::Rule' ),
                              'include_statement' => bless( {
                                                              'impcount' => 0,
                                                              'calls' => [
                                                                           'file_name'
                                                                         ],
                                                              'changed' => 0,
                                                              'opcount' => 0,
                                                              'prods' => [
                                                                           bless( {
                                                                                    'number' => 0,
                                                                                    'strcount' => 1,
                                                                                    'dircount' => 1,
                                                                                    'uncommit' => undef,
                                                                                    'error' => undef,
                                                                                    'patcount' => 0,
                                                                                    'actcount' => 1,
                                                                                    'items' => [
                                                                                                 bless( {
                                                                                                          'pattern' => 'include',
                                                                                                          'hashname' => '__STRING1__',
                                                                                                          'description' => '\'include\'',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 21
                                                                                                        }, 'Parse::RecDescent::Literal' ),
                                                                                                 bless( {
                                                                                                          'hashname' => '__DIRECTIVE1__',
                                                                                                          'name' => '<commit>',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 21,
                                                                                                          'code' => '$commit = 1'
                                                                                                        }, 'Parse::RecDescent::Directive' ),
                                                                                                 bless( {
                                                                                                          'subrule' => 'file_name',
                                                                                                          'matchrule' => 0,
                                                                                                          'implicit' => undef,
                                                                                                          'argcode' => undef,
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 21
                                                                                                        }, 'Parse::RecDescent::Subrule' ),
                                                                                                 bless( {
                                                                                                          'hashname' => '__ACTION1__',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 22,
                                                                                                          'code' => '{ [\'include\', parse_included_file($item[3], $thisline)] }'
                                                                                                        }, 'Parse::RecDescent::Action' )
                                                                                               ],
                                                                                    'line' => undef
                                                                                  }, 'Parse::RecDescent::Production' ),
                                                                           bless( {
                                                                                    'number' => 1,
                                                                                    'strcount' => 0,
                                                                                    'dircount' => 2,
                                                                                    'uncommit' => 0,
                                                                                    'error' => 1,
                                                                                    'patcount' => 0,
                                                                                    'actcount' => 0,
                                                                                    'items' => [
                                                                                                 bless( {
                                                                                                          'msg' => '',
                                                                                                          'hashname' => '__DIRECTIVE1__',
                                                                                                          'commitonly' => '?',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 23
                                                                                                        }, 'Parse::RecDescent::Error' ),
                                                                                                 bless( {
                                                                                                          'hashname' => '__DIRECTIVE2__',
                                                                                                          'name' => '<reject>',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => 23
                                                                                                        }, 'Parse::RecDescent::UncondReject' )
                                                                                               ],
                                                                                    'line' => 23
                                                                                  }, 'Parse::RecDescent::Production' )
                                                                         ],
                                                              'name' => 'include_statement',
                                                              'vars' => '',
                                                              'line' => 21
                                                            }, 'Parse::RecDescent::Rule' ),
                              'regex' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => 0,
                                                                        'strcount' => 0,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 1,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => '\\/(?:[^\\\\\\/]|\\\\.)*\\/',
                                                                                              'hashname' => '__PATTERN1__',
                                                                                              'description' => '/\\\\/(?:[^\\\\\\\\\\\\/]|\\\\\\\\.)*\\\\//',
                                                                                              'lookahead' => 0,
                                                                                              'rdelim' => '/',
                                                                                              'line' => 83,
                                                                                              'mod' => '',
                                                                                              'ldelim' => '/'
                                                                                            }, 'Parse::RecDescent::Token' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 84,
                                                                                              'code' => '{ my $regex = \'qr\' . $item[1];
          my $re = eval $regex;
          if ($@) {
              die "Bad regex on line $prevline: $regex: $@";
          }
          $re
        }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'regex',
                                                  'vars' => '',
                                                  'line' => 83
                                                }, 'Parse::RecDescent::Rule' ),
                              'eof' => bless( {
                                                'impcount' => 0,
                                                'calls' => [],
                                                'changed' => 0,
                                                'opcount' => 0,
                                                'prods' => [
                                                             bless( {
                                                                      'number' => 0,
                                                                      'strcount' => 0,
                                                                      'dircount' => 0,
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => 1,
                                                                      'actcount' => 0,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'pattern' => '^\\Z',
                                                                                            'hashname' => '__PATTERN1__',
                                                                                            'description' => '/^\\\\Z/',
                                                                                            'lookahead' => 0,
                                                                                            'rdelim' => '/',
                                                                                            'line' => 8,
                                                                                            'mod' => '',
                                                                                            'ldelim' => '/'
                                                                                          }, 'Parse::RecDescent::Token' )
                                                                                 ],
                                                                      'line' => undef
                                                                    }, 'Parse::RecDescent::Production' )
                                                           ],
                                                'name' => 'eof',
                                                'vars' => '',
                                                'line' => 8
                                              }, 'Parse::RecDescent::Rule' ),
                              'table_name' => bless( {
                                                       'impcount' => 0,
                                                       'calls' => [
                                                                    'identifier'
                                                                  ],
                                                       'changed' => 0,
                                                       'opcount' => 0,
                                                       'prods' => [
                                                                    bless( {
                                                                             'number' => 0,
                                                                             'strcount' => 0,
                                                                             'dircount' => 0,
                                                                             'uncommit' => undef,
                                                                             'error' => undef,
                                                                             'patcount' => 0,
                                                                             'actcount' => 0,
                                                                             'items' => [
                                                                                          bless( {
                                                                                                   'subrule' => 'identifier',
                                                                                                   'matchrule' => 0,
                                                                                                   'implicit' => undef,
                                                                                                   'argcode' => undef,
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => 27
                                                                                                 }, 'Parse::RecDescent::Subrule' )
                                                                                        ],
                                                                             'line' => undef
                                                                           }, 'Parse::RecDescent::Production' )
                                                                  ],
                                                       'name' => 'table_name',
                                                       'vars' => '',
                                                       'line' => 27
                                                     }, 'Parse::RecDescent::Rule' ),
                              'type' => bless( {
                                                 'impcount' => 0,
                                                 'calls' => [
                                                              'identifier'
                                                            ],
                                                 'changed' => 0,
                                                 'opcount' => 0,
                                                 'prods' => [
                                                              bless( {
                                                                       'number' => 0,
                                                                       'strcount' => 0,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 0,
                                                                       'actcount' => 0,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'subrule' => 'identifier',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => 45
                                                                                           }, 'Parse::RecDescent::Subrule' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'type',
                                                 'vars' => '',
                                                 'line' => 45
                                               }, 'Parse::RecDescent::Rule' )
                            },
                 '_AUTOTREE' => undef,
                 '_check' => {
                               'thisoffset' => '',
                               'itempos' => '',
                               'prevoffset' => '',
                               'prevline' => 1,
                               'prevcolumn' => '',
                               'thiscolumn' => ''
                             },
                 '_AUTOACTION' => undef
               }, 'Parse::RecDescent' );
}