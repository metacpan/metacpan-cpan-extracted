use strict;
use Test;

use Array::PatternMatcher qw(:all) ;
use Data::Dumper;

BEGIN { plan tests => 3 }

my $pattern = 'AGE' ;
my $input   = 969 ;

# Variables

# - 1
# if no bindings, add a binding between pattern and input
my $result = pat_match ($pattern, $input, {} ) ;
warn sprintf "RETVAL: %s", Data::Dumper::Dumper($result);
ok($result->{AGE}, 969) ;


# - 2
# if binding exists, it must equal the input

$input = 12;

my $new_result = pat_match ($pattern, $input, $result) ;
warn sprintf "RETVAL: %s", Data::Dumper::Dumper($new_result);
ok(!defined($new_result)) ;

# - 3

$pattern = [qw(X   Y)] ;
$input   = [   77, 45 ] ;

# Variables

# - 1
# if no bindings, add a binding between pattern and input
my $result = pat_match ($pattern, $input, {} ) ;
warn sprintf "LIST_MATCH_RETVAL: %s", Data::Dumper::Dumper($result);
ok($result->{X}, 77) ;
