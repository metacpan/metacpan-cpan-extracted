use strict;
use Test;

use Array::PatternMatcher qw(:all) ;
use Data::Dumper;

BEGIN { plan tests => 6 }

# --- 0
{
    my $pattern = ['a', [qw(X *)], 'd'] ;
    my $input   = ['a', 'b', 'c',  'd'] ;

# if no bindings, add a binding between pattern and input
    my $result = pat_match ($pattern, $input, {} ) ;
    warn sprintf "X*RETVAL: %s", Data::Dumper::Dumper($result) ;
    ok ("@{$result->{X}}","b c") ;
}
# --- 1
{

    my $pattern = ['a', [qw(X *)], [qw(Y *)], 'd'] ;
    my $input   = ['a', 'b', 'c', 'd'] ;

# if no bindings, add a binding between pattern and input
    my $result = pat_match ($pattern, $input, {} ) ;
    warn sprintf "X*Y*RETVAL: %s", Data::Dumper::Dumper($result) ;
    ok ("@{$result->{Y}}","b c") ;

}
# --- 2
{
    my $pattern = ['a', [qw(X +)], 'd'] ;
    my $input   = ['a', 'b', 'c',  'd'] ;

# if no bindings, add a binding between pattern and input
    my $result = pat_match ($pattern, $input, {} ) ;
    warn sprintf "RETVAL: @{$result->{X}}" ;
    ok ("@{$result->{X}}","b c") ;
}
# --- 3
{
    my $pattern = [ 'a', [qw(X ?)], 'c' ] ;
    my $input   = [ 'a', 'b',       'c' ] ;

# if no bindings, add a binding between pattern and input
    my $result = pat_match ($pattern, $input, {} ) ;
    warn sprintf "RETVAL: $result->{X}" ;
    ok ("$result->{X}","b") ;
}
# --- 4
{
    my $pattern = [ qw(X OP Y is Z), 
	    [ 
	      sub { "($_->{X} $_->{OP} $_->{Y}) == $_->{Z}" },
		'IF?' 
	      ]
	   ] ;
    my $input   = [qw(3 + 4 is 7) ] ;

# if no bindings, add a binding between pattern and input
    my $result = pat_match ($pattern, $input, {} ) ;
    warn sprintf "IF_RETVAL: $result" ;
    ok ($result) ;
}
# --- 5
{
    my $pattern = [ qw(X OP Y is Z), 
	    [ 
	      sub { "($_->{X} $_->{OP} $_->{Y}) == $_->{Z}" },
		'IF?' 
	      ]
	   ] ;
    my $input   = [qw(3 + 4 is 8) ] ;

# if no bindings, add a binding between pattern and input
    my $result = pat_match ($pattern, $input, {} ) ;
    warn sprintf "IF_RETVAL2: *%s*", Data::Dumper::Dumper($result);
    ok ($result eq '') ;
}
