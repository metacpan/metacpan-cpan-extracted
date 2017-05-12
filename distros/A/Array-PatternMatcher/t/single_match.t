use strict;
use Test;

use Array::PatternMatcher qw(:all) ;
use Data::Dumper;

BEGIN { plan tests => 5 }


# --- 0
{
sub numberp { $_[0] =~ /\d+/ }

my $pattern = [ qw(X    age), [qw(IS? N), \&numberp] ] ;
my $input   = [ qw(Mary age),     'thirty-four'      ] ;

# if no bindings, add a binding between pattern and input
my $result = pat_match ($pattern, $input, {} ) ;
warn "IS_RETVAL: ($result)", Data::Dumper::Dumper($result) ;
ok (!defined($result));
}

# --- 1
{
sub numberp { $_[0] =~ /\d+/ }

my $pattern = [ qw(X    age), [qw(IS? N), \&numberp] ] ;
my $input   = [ qw(Mary age),     34                ] ;
my $result  = pat_match ($pattern, $input, {} ) ;
warn "IS_RETVAL: ($result)", Data::Dumper::Dumper($result) ;
ok ($result->{N},34) ;
}

# --- 2

{
my @pattern ;
push @pattern, [ qw(X  Y)  ] ;
push @pattern, [ qw(22 Z ) ] ;
push @pattern, [ qw(M  33) ] ;

my $input    = [ qw(22 33) ] ;

my $meta_pattern = [ 'AND?', \@pattern ] ;

# if no bindings, add a binding between pattern and input
my $result = pat_match ($meta_pattern, $input, {} ) ;
warn "IS_RETVAL: ($result)", Data::Dumper::Dumper($result) ;
ok ($result->{Z},33) ;
}

# --- 3

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
warn "OR_RETVAL: ($result)", Data::Dumper::Dumper($result) ;
ok ($result->{Z},33) ;
}

# --- 4

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
    warn "OR_RETVAL: ($result)", Data::Dumper::Dumper($result) ;
    ok (scalar keys %$result == 0) ;
}
