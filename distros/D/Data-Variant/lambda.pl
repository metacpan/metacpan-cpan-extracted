# lambda.pl -- An example program for Data::Variant
#
# Copyright (c) 2004 Viktor Leijon (leijon@ludd.ltu.se) All rights reserved. 
# This program is free software; you can redistribute it and/or modify 
# it under the same terms as Perl itself. 
#
#
# This example program losely follows chapter 5 (Untyped lambda calculus)
# in Benjamin C. Pierce, Types and Programing Languages, but any failures are 
# undoubtedly my own. (Also, he uses call by value, I don't).
#
use warnings;
use strict;
use Carp;
use Switch;
use Data::Variant;
use Data::Dumper;

sub Abstraction; sub Application; sub Variable;

# First define the terms in lambda calculus.
register_variant("Term","Variable <STRING>","Abstraction <STRING> Term",
		 "Application Term Term");

# Then a little context
our %context;

# A few builtins (Church coded booleans)
# tru = \t.\f.t
$context{tru} = Abstraction("t", (Abstraction "f", (Variable "t")));
# fls = \t.\f.f
$context{fls} = Abstraction("t", (Abstraction "f", (Variable "f")));


#
# The following clearly illustrates the pain associated with building more
# complex structures by hand. This took me 15 minutes, building a parser
# would almost have been easier.
#
# c2 tru fls
my $subclause = Application( Application((Variable "c2"), Variable("tru")),
			     Variable "fls");
#  AND == \c1.\c2. (c1 (c2 tru fls) fls)
$context{and} = Abstraction("c1", 
		  (Abstraction("c2",
		   (Application(
				(Application((Variable "c1"),$subclause)),
				(Variable "fls"))))));


# Test expressions.
# tru branch1 branch2 => branch2
my $exp1 = Application (
    Application ((Variable "tru"), (Variable "branch1")) ,
    Variable("branch2"));

# fls branch1 branch2 => branch2
my $exp2 = Application (
    Application ((Variable "fls"), (Variable "branch1")) ,
    Variable("branch2"));

# and tru fls => fls    
my $exp3 = Application ( Application ((
	   Variable "and"), (Variable "tru")), (Variable "fls"));   

print "Expression: " . simpl_print($exp1) . "\n";
print "Evaluated : " . simpl_print(simpl_eval($exp1)) . "\n";
print "Expression: " . simpl_print($exp2) . "\n";
print "Evaluated : " . simpl_print(simpl_eval($exp2)) . "\n";
print "Expression: " . simpl_print($exp3) . "\n";
print "Evaluated : " . simpl_print(simpl_eval($exp3)) . "\n";


#
# Simple evaluator
# NOTE: No alpha conversion, there are so many ways this could go bad
# on anything except carefully crafted testcases.  
sub simpl_eval {
    my $term = shift;
    my ($str, $t1, $t2,$t3,$t4);

    switch($term->match()) {
	case (mkpat "Application", $t1, $t2) {	 
	    if (match $t1,"Abstraction",$str,$t3) {
		my $t = subst($t3,$str,$t2);
		return simpl_eval($t);
	    }
	    my $new_t1 = simpl_eval($t1);
	    return simpl_eval(Application($new_t1,$t2));
	}
	case (mkpat "Variable", $str) {
	    
	    if (exists $context{$str}) {
		return simpl_eval($context{$str});
	    } else { 
		warn "Unresolvable variable $str\n";
		return $term;
	    }
	}
	default { return $term };
    }
    return $term;
}

sub subst {
    my ($term,$var, $val) = @_;
    my ($t1,$t2, $str);

    switch($term->match()) {
	case (mkpat "Application", $t1,$t2) {
	    return Application subst($t1,$var,$val),subst($t2,$var,$val);
	}
	case (mkpat "Abstraction", $str,$t1) {
	    if ($str eq $var) {
		return $term;
	    } else {
		return Abstraction $str, subst($t1,$var,$val);
	    }
	}
	case (mkpat "Variable", $str) {
	    if ($str eq $var) {
		return $val;
	    } else {
		return $term;
	    }
	}
    }
    confess "Badness in subst";
}

 

#
# Simple printer
#  No intelligence about when to use parantheses.
#
sub simpl_print {
    my $expr = shift;
    my ($str,$t1,$t2);
    switch ($expr->match()) {
	case (mkpat "Variable", $str) {
	    return "$str";
	}
	case (mkpat "Abstraction", $str, $t1) {
	    return "\\$str .(" . simpl_print($t1) . ")";
	}
	case (mkpat "Application",$t1,$t2) {
	    return "(" . simpl_print($t1) . " " . simpl_print($t2) . ")";
	}
    }
}
