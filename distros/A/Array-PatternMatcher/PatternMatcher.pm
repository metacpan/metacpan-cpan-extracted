package Array::PatternMatcher;

require 5.005_62;
use strict;
use warnings;
use diagnostics;

require Exporter;

our @ISA = qw(Exporter);



use Carp::Datum qw(:all on);
#use Carp::Datum;

#DLOAD_CONFIG(-config => "all(on)");
#DLOAD_CONFIG(-config => "all(off)");
#DLOAD_CONFIG(-config => "all(yes)");
#DLOAD_CONFIG(-config => "all(no)");
#DLOAD_CONFIG(-config => $ENV{Array_PatternMatcher_Trace});

use Data::Dumper;
use Storable;
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Array::PatternMatcher ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(pat_match rest subseq
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.04';


# Preloaded methods go here.



=head1 NAME

Array::PatternMatcher - Pattern matching for arrays.

=head1 SYNOPSIS

This section inlines the entire test suite. Please excuse the ok()s.

 use Array::PatternMatcher;

=head2 Matching logical variables to input stream
 
 #  1 - simple match of logical variable to input
 my $pattern = 'AGE' ;
 my $input   = 969 ;
 my $result = pat_match ($pattern, $input, {} ) ;
 ok($result->{AGE}, 969) ;
 
 # 2 - if binding exists, it must equal the input
 $input = 12;
 my $new_result = pat_match ($pattern, $input, $result) ;
 ok(!defined($new_result)) ;
 
 # 3 - bind the pattern logical variables to the input list
 
 $pattern = [qw(X   Y)] ;
 $input   = [   77, 45 ] ;
 my $result = pat_match ($pattern, $input, {} ) ;
 ok($result->{X}, 77) ;
 
=head2 Matching segments (quantifying) portions of the input stream
 
 # 1
 {
     my $pattern = ['a', [qw(X *)], 'd'] ;
     my $input   = ['a', 'b', 'c',  'd'] ;
 
     my $result = pat_match ($pattern, $input, {} ) ;
     ok ("@{$result->{X}}","b c") ;
 }
 
 # 2
 {
 
     my $pattern = ['a', [qw(X *)], [qw(Y *)], 'd'] ;
     my $input   = ['a', 'b', 'c', 'd'] ;
     my $result = pat_match ($pattern, $input, {} ) ;
     ok ("@{$result->{Y}}","b c") ;
 
 }
 # 3
 {
     my $pattern = ['a', [qw(X +)], 'd'] ;
     my $input   = ['a', 'b', 'c',  'd'] ;
     ok ("@{$result->{X}}","b c") ;
 }
 # 4
 {
     my $pattern = [ 'a', [qw(X ?)], 'c' ] ;
     my $input   = [ 'a', 'b',       'c' ] ;
     my $result = pat_match ($pattern, $input, {} ) ;
     ok ("$result->{X}","b") ;
 }
 # 5
 {
     my $pattern = [ qw(X OP Y is Z), 
 	    [ 
 	      sub { "($_->{X} $_->{OP} $_->{Y}) == $_->{Z}" },
 		'IF?' 
 	      ]
 	   ] ;
     my $input   = [qw(3 + 4 is 7) ] ;
     my $result = pat_match ($pattern, $input, {} ) ;
     ok ($result) ;
 }
 
=head2 Single-matching:
 
 Take a single input and a series of patterns and decide which pattern
 matches the input:
 
 # 1 - Here all input patterns must match the input
 
 {
 my @pattern ;
 push @pattern, [ qw(X  Y)  ] ;
 push @pattern, [ qw(22 Z ) ] ;
 push @pattern, [ qw(M  33) ] ;
 
 my $input    = [ qw(22 33) ] ;
 
 my $meta_pattern = [ 'AND?', \@pattern ] ;
 
 # if no bindings, add a binding between pattern and input
 my $result = pat_match ($meta_pattern, $input, {} ) ;
 ok ($result->{Z},33) ;
 }
 
 # 2 - Here, any one of the patterns must match the input
 
 {
 my @pattern ;
 push @pattern, [ qw(99  22)  ] ;
 push @pattern, [ qw(33 22) ] ;
 push @pattern, [ qw(44 3) ] ;
 push @pattern, [ qw(22 Z) ] ;
 
 my $input    = [ qw(22 33) ] ;
 
 my $meta_pattern = [ 'OR?', \@pattern ] ;
 
 # if no bindings, add a binding between pattern and input
 my $result = pat_match ($meta_pattern, $input, {} ) ;
 ok ($result->{Z},33) ;
 }
 
 # 3 - Here, none of the patterns must match the input
 
 {
     my @pattern ;
     push @pattern, [ qw(99  22)  ] ;
     push @pattern, [ qw(33 22) ] ;
     push @pattern, [ qw(44 3) ] ;
     push @pattern, [ qw(22 Z) ] ;
 
     my $input    = [ qw(22 33) ] ;
 
     my $meta_pattern = [ 'NOT?', \@pattern ] ;
 
 # if no bindings, add a binding between pattern and input
     my $result = pat_match ($meta_pattern, $input, {} ) ;
     ok (scalar keys %$result == 0) ;
 }
 
 # 4 - here the input must satisfy the predicate
 {
 sub numberp { $_[0] =~ /\d+/ }
 
 my $pattern = [ qw(X    age), [qw(IS? N), \&numberp] ] ;
 my $input   = [ qw(Mary age),     'thirty-four'      ] ;
 
 # if no bindings, add a binding between pattern and input
 my $result = pat_match ($pattern, $input, {} ) ;
 ok (!defined($result));
 }
 
 # 5 - same thing, but this time a failing result --- ''
 # not undef because it is the return val of numberp 
 {
 sub numberp { $_[0] =~ /\d+/ }
 
 my $pattern = [ qw(X    age), [qw(IS? N), \&numberp] ] ;
 my $input   = [ qw(Mary age),     34                ] ;
 my $result  = pat_match ($pattern, $input, {} ) ;
 
 ok ($result->{N},34) ;
 }
 
=head2 Segment-matching:
 
 Match a chunk of the input stream using *, +, ?
 
 # 1 - * is greedy in this case, but not with 2 consecutve * patterns
 {
     my $pattern = ['a', [qw(X *)], 'd'] ;
     my $input   = ['a', 'b', 'c',  'd'] ;
 
 # if no bindings, add a binding between pattern and input
     my $result = pat_match ($pattern, $input, {} ) ;
     warn sprintf "X*RETVAL: %s", Data::Dumper::Dumper($result) ;
     ok ("@{$result->{X}}","b c") ;
 }
 # 2 - X* gets nothing, Y* gets all it can:
 {
 
     my $pattern = ['a', [qw(X *)], [qw(Y *)], 'd'] ;
     my $input   = ['a', 'b', 'c', 'd'] ;
 
 # if no bindings, add a binding between pattern and input
     my $result = pat_match ($pattern, $input, {} ) ;
     warn sprintf "X*Y*RETVAL: %s", Data::Dumper::Dumper($result) ;
     ok ("@{$result->{Y}}","b c") ;
 
 }
 # 3 - samething , but require at least one match for X
 {
     my $pattern = ['a', [qw(X +)], 'd'] ;
     my $input   = ['a', 'b', 'c',  'd'] ;
 
     my $result = pat_match ($pattern, $input, {} ) ;
     warn sprintf "RETVAL: @{$result->{X}}" ;
     ok ("@{$result->{X}}","b c") ;
 }
 # 4 - require 0 or 1 match for X
 {
     my $pattern = [ 'a', [qw(X ?)], 'c' ] ;
     my $input   = [ 'a', 'b',       'c' ] ;
 
 
     my $result = pat_match ($pattern, $input, {} ) ;
 
     ok ("$result->{X}","b") ;
 }
 # 5 - evaluate a sub on the fly after match
 {
     my $pattern = [ qw(X OP Y is Z), 
 	    [ 
 	      sub { "($_->{X} $_->{OP} $_->{Y}) == $_->{Z}" },
 		'IF?' 
 	      ]
 	   ] ;
     my $input   = [qw(3 + 4 is 7) ] ;
 
     my $result = pat_match ($pattern, $input, {} ) ;
 
     ok ($result) ;
 }
 # --- 6 same thing, but fail
 {
     my $pattern = [ qw(X OP Y is Z), 
 	    [ 
 	      sub { "($_->{X} $_->{OP} $_->{Y}) == $_->{Z}" },
 		'IF?' 
 	      ]
 	   ] ;
     my $input   = [qw(3 + 4 is 8) ] ;
 
     my $result = pat_match ($pattern, $input, {} ) ;
     warn sprintf "IF_RETVAL2: *%s*", Data::Dumper::Dumper($result);
     ok ($result eq '') ;
 }
 

=head1 DESCRIPTION

Array::PatternMatcher is based directly on the pattern matcher in
Peter Norvig's excellent text 
"Paradigms of AI Programming: Case Studies in Common Lisp".

All in all, it basically offers a different way to work with an array.
Instead of manually indexing into the array and using if-thens to 
validate and otherwise characterize the array, you can use 
pattern-matching instead.

=head2 EXPORT

None by default.

use Array::PatternMatcher qw(:all) exports pat_match(), rest(), subseq()

=head1 Description of Pattern Matching

The pattern-matching routine, pat-match, takes 3 arguments, a pattern,
an input, and a set of "bindings".

The input is an array ref of constants:

  my $input_1 = [qw(how   is it going   dude) ] ;
  my $input_2 = [qw(where is it going   dude) ] ;
  my $input_3 = [qw(when  is it going   pal) ] ;
  my $input_4 = [qw(when  is it flying  chum) ] ;
  my $input_5 = [qw(how   is it hanging homeboy) ] ;

The pattern is your spec on how you expect to match the input:

  my $pattern = [qw(ADJECTIVE is it VERB OBJECT)] ;

=head2 Valid pattern elements:

=over 4

=item 1 a variable

=item 2 a constant (a string or number)

=item 3 a segment pattern

=item 4 a meta-pattern to applied to the input

=item 5 an array ref whose array consists of items 1 .. 4

=back


The bindings is a hashref consisting of all logical variables 
bound during the matching of the input to the pattern. Thus:

 use Array::PatternMatcher qw(:all);
 {
 my $b1 =  pat_match  $pattern, $input_1, {} ; 

 # yields these bindings
 { ADJECTIVE => 'how', VERB => 'going, OBJECT => 'dude' }
 }
Skipping to input_4:
 {
 my $b1 =  pat_match  $pattern, $input_1, {} ; 

 # yields these bindings
 { ADJECTIVE => 'when', VERB => 'flying', OBJECT => 'chum' }
 }


Please see the synopsis for comprehensive usage examples.

=head1 BUGS

Please report them, if possible submitting a test case similar to the
ones in the /t directory.

=head1 AUTHOR

Terrence M. Brannon, tbone@cpan.org

=cut


sub match_variable {
    DFEATURE my $f_;
    my ($var,$input,$bindings) = @_;
    my $binding = $bindings->{$var} ;
    if (!$binding) {
	DTRACE "no bindings for $var. extending and setting equal to %s", Data::Dumper::Dumper($input);
	$bindings->{$var} = $input ;
	return DVAL $bindings;
    } elsif ($binding eq $input) { # this equal will be inadequate for lists
	DTRACE "binding for $var with $input already exists";
	return DVAL $bindings ;
    } else {
	return DVOID ;
    }
}

sub subseq {
    DFEATURE my $f_;
    my ($input,$start,$end) = @_;

    my $max = $#$input ;
    $end = defined($end) ? $end : $max ;

    DTRACE "subseq_start: $start end: $end max: $max";

    [ @{$input}[$start..$end] ] ;

}

sub atomic {
    DFEATURE my $f_;
    my $pat = shift ;

    if (ref($pat) eq 'ARRAY') { return DVOID }
    return DVAL 1;
}

sub is_variable { 
    DFEATURE my $f_;

    my $p = shift;

    if (ref($p)) {
	return DVOID;
    } else { 
	my $r = ($p =~ /^[A-Z][A-Z0-9]*$/) ;
	return DVAL $r ;
    }
}


sub first_match_pos {
    DFEATURE my $f_;
    my ($pattern, $input, $start) = @_;

    $start = int($start) if (!defined($start));

    DTRACE sprintf "first_match_pos_pattern: %s", Data::Dumper::Dumper($pattern);
    DTRACE sprintf "first_match_pos_input: %s", Data::Dumper::Dumper($input);
    DTRACE sprintf "first_match_pos_start: %s", Data::Dumper::Dumper($start);

    if ((atomic $pattern) && (!is_variable($pattern))) {
	# look for first place that pattern equals input
	for (my $i = $start; $i <= $#$input; ++$i) {
	    if ($pattern eq $input->[$i]) {
		return DVAL $i;
	    }
	}	
	return DVAL undef;
    }
    elsif ($start < @$input) {
	return DVAL $start;
    }
}
sub rest {
    DFEATURE my $f_;
    my $aref = shift;
    my @ary  = @$aref;

    if (@$aref == 1) {
	return DVAL undef ;
    }

    if (@$aref > 1) {
	splice @ary, 0, 1;
	return DVAL \@ary;
    }

}

sub segment_match {
    DFEATURE my $f_;
    my ($pattern, $input, $bindings, $start) = @_;
    my $var = $pattern->[0]->[0] ;
    my $pat = rest $pattern ;

    if (!defined($pat)) {
	DTRACE "not defined pat";
	return DVAL match_variable($var,$input,$bindings) ;
    } else {
	DTRACE "    defined pat";
	my $pos = first_match_pos($pat->[0], $input, $start) ;

	if (!defined($pos)) {
	    DTRACE "no first match pos";
	    return DVAL undef;
	} else {
	    DTRACE "there is a first match pos ($pos)";
	    # if it does have a match
	    my $match_variable_subseq_end = (!$pos) ? 0 : $pos - 1 ;
	    my $b2 = pat_match($pat, subseq($input,$pos),
			       match_variable($var, subseq($input,0,$match_variable_subseq_end), $bindings));
	    if ($b2) {
		DTRACE "found our match ($b2)";
		return DVAL $b2;
	    } else {
		DTRACE "incrementing and attempting again";
		return DVAL (segment_match($pattern, $input, $bindings,
			     (1+$pos)));
	    }
	}
    }
}
		
sub segment_match_plus {
    DFEATURE my $f_;
    my ($pattern, $input, $bindings) = @_;
    return DVAL segment_match $pattern, $input, $bindings, 1 ;
}

sub segment_match_optional {
    DFEATURE my $f_;
    my ($pattern, $input, $bindings) = @_ ;
    my $var = $pattern->[0][0] ;
    my $pat = rest $pattern ;

    return DVAL (
		 (pat_match ( [($var, @$pat)], $input, $bindings) ) ||
		 (pat_match            $pat  , $input, $bindings) 
		 ) ;
}


sub pat_match ;
sub single_match_is {
    DFEATURE my $f_;
    my ($is_var_and_pred, $input, $bindings) = @_ ;

    DTRACE "INPUT ", Data::Dumper::Dumper(\@_) ;
    my ($var,$pred)  = ($is_var_and_pred->[1],$is_var_and_pred->[2]) ;
    my $new_bindings = pat_match $var, $input, $bindings ;
    DTRACE "NEW_BINDINGS ", Data::Dumper::Dumper($new_bindings) ;

    if (!defined($new_bindings) or !defined($pred->($input))) {
	DTRACE "pred FAILED";
	return DVOID ;
    } else {
	my $result = $pred->($input) ;
	DTRACE "pred result: $result";
	if ($result) {
	    return DVAL $bindings ;
	} else {
	    return DVOID;
	}
    }
}

sub single_match_or ;
sub single_match_not {
    DFEATURE my $f_;    

    my ($pattern,$input,$bindings) = @_;
    my $o = single_match_or $pattern, $input, $bindings ;
    if ($o) { 
	return DVOID ;
    } else {
	return DVAL $bindings ;
    }
}

sub match_or;
sub single_match_or {
    DFEATURE my $f_;    

    my ($pattern,$input,$bindings) = @_;

    DTRACE "smor_input: ", Data::Dumper::Dumper($input) ;

    if (!defined($pattern) or (scalar @$pattern == 0)) { return DVOID }
    my $input_copy = Storable::dclone($input);
    my $rest_pattern = rest $pattern;
    my $new_bindings = pat_match $pattern->[0], $input, $bindings ;
    if (!defined($new_bindings)) { 
	my $r = single_match_or $rest_pattern, $input_copy, $bindings ;
    } else {
	return DVAL $new_bindings ;
    }
}

sub single_match_and {
    DFEATURE my $f_;    

    my ($meta_pattern,$input,$bindings) = @_;
    DTRACE "single_match_and meta_p: i: b:", Data::Dumper::Dumper($meta_pattern,$input,$bindings) ;

    if (!defined($bindings)) { return DVOID }
    if (!defined($meta_pattern) or !@$meta_pattern) { return DVAL $bindings }
    my $rest_meta_pattern = rest $meta_pattern ;

    my $input_copy = [ @$input ] ;
    my $f = pat_match $meta_pattern->[0], $input, $bindings ;
    DTRACE sprintf "and_first gave this: %s now we work with these: %s,%s", 
          Data::Dumper::Dumper($f), 
          Data::Dumper::Dumper($rest_meta_pattern), 
          Data::Dumper::Dumper($input_copy) ;
    my $ret = single_match_and ($rest_meta_pattern, $input_copy, $f) ;
		
    return DVAL $ret ;
}


sub segment_match_if {
    DFEATURE my $f_;
    my ($pattern, $input, $bindings) = @_ ;

    DTRACE "p: i: b:", Data::Dumper::Dumper($pattern,$input,$bindings) ;
    

    local $_ = $bindings ;

    return DVAL eval $pattern->[0]->[0]->() ;

}

our %segment_dispatch = 
(
 '*'  => \&segment_match,
 '+'  => \&segment_match_plus,
 '?'  => \&segment_match_optional,
 'IF?' => \&segment_match_if
 ) ;

our %single_dispatch = 
(
 'IS?'  => \&single_match_is,
 'AND?' => \&single_match_and,
 'OR?'  => \&single_match_or,
 'NOT?' => \&single_match_not,
 ) ;


sub is_array_ref {
    DFEATURE my $f_;
    return DVAL ref ($_[0]) eq 'ARRAY';
}
sub is_code_ref {
    DFEATURE my $f_;
    return DVAL ref ($_[0]) eq 'CODE';
}



sub segment_match_fn {
    my $x = shift;
    DTRACE "dispatching on $x";
    my $fn = $segment_dispatch{$x} ;
    return $fn;
}
		     
sub is_single_pattern {
    DFEATURE my $f_;
#    warn "@_" , Data::Dumper::Dumper(\@_) ;
    my $term_aref = $_[0] ;
    if (is_array_ref($term_aref)) {
	DTRACE "dispatching on", Data::Dumper::Dumper($term_aref->[0]);
	return DVAL $single_dispatch{$term_aref->[0]} ;	
    } else {
	return DVOID ;
    }

}

sub is_segment_pattern {
    DFEATURE my $f_;
    my $pat = shift;
    DTRACE "is_segment_pattern ", Data::Dumper::Dumper($pat) ;
    my $a = is_array_ref($pat) ;
    my $first = $a ? $pat->[0] : undef ;
    my $a2 = is_array_ref($first) ;

    return undef unless ($a && $a2) ;

    DTRACE "hi there $first->[1]" ;

    my $s = segment_match_fn($first->[1]) ;

    DTRACE "s $s" ;

    if ($s) {
	return  $s ;
    } else {
	return undef ;
    }

}
    


sub pat_match {
    DFEATURE my $f_;

    my ($pattern, $input, $bindings) = @_;

    DTRACE "pattern,input,bindings", Data::Dumper::Dumper($pattern,$input,$bindings) ;

    if (!defined($bindings))   { return DVOID }
    if (is_variable($pattern)) { return DVAL match_variable(@_) } 
    if (my $segment_matcher = is_segment_pattern($pattern)) {
	return DVAL $segment_matcher->(@_) ;
    }

    if (my $single_matcher = is_single_pattern($pattern)) {
	if (($pattern->[0] eq 'AND?') or ($pattern->[0] eq 'OR?')) {
	    DTRACE sprintf "p0: %s p1: %s p2: %s", Data::Dumper::Dumper($pattern->[0]), Data::Dumper::Dumper($pattern->[1]), Data::Dumper::Dumper($pattern->[2]) ;
	    # remove AND? and the entire outer list
	    $pattern = $pattern->[1] ;
	}
	return DVAL $single_matcher->($pattern,$input,$bindings) ;
    }

    if ( (
	  (ref($pattern) eq 'ARRAY') && 
	  (ref($input)   eq 'ARRAY') &&
	  (@$pattern) && (@$input)
	  )
	 ) {
	DTRACE "handling first and rest" ;
	my $b = pat_match($pattern->[0], $input->[0], $bindings) ;
	my $newer_binds  = pat_match((rest $pattern), (rest $input), $b);
	DTRACE "new binds($newer_binds)", Data::Dumper::Dumper($newer_binds) ;
	return DVAL $newer_binds;
	}
    if ($pattern eq $input) {
	DTRACE "$pattern eq $input ... returning bindings($bindings)";
	return DVAL $bindings ;
    }
    return DVOID ;
}

=head1 AUTHOR

T.M. Brannon <tbone@cpan.org>

=head1 SEE ALSO

L<Data::Walker|Data::Walker>,
L<Data::Match|Data::Match>, L<Data::Compare|Data::Compare>

=cut

1;
__END__
