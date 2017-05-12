#!perl

use strict;
use warnings;

use Test::More;    # plan is down at bottom
use Test::Exception;

eval 'use Test::Differences';    # display convenience
my $deeply = $@ ? \&is_deeply : \&eq_or_diff;

########################################################################

use Acme::List::CarCdr;
my $can = Acme::List::CarCdr->new;

# The reason for using names instead of numbers is that numbers may be
# returned by various array operations (length, index) that might be
# improperly confused with a test list that contains numbers instead of
# names. (Alternative: make the numbers contained by the list larger
# than the number of elements possible in the list.)
$deeply->( $can->car(qw/cat dog fish/), qw/cat/ );
$deeply->( [ $can->cdr(qw/cat dog fish/) ], [qw/dog fish/] );
$deeply->( $can->cddr(qw/cat dog fish/), qw/fish/ );

# Slightly more complicated, plus comparison with GNU CLISP 2.48
# [1]> (setf numlist '(("one" "two") ("three" "four") ("five" "six")))
my @numlist = ([q/one two/],[qw/three four/],[qw/five six/]);
my @ret;

# [2]> (cadr numlist)
# ("three" "four")
@ret = $can->cadr(@numlist);
$deeply->( \@ret, [qw/three four/] );

# [3]> (caadr numlist)
# "three"
@ret = $can->caadr(@numlist);
$deeply->( \@ret, ["three"] );

# [4]> (cdadr numlist)
# ("four")
@ret = $can->cdadr(@numlist);
$deeply->( \@ret, ["four"] );

dies_ok { $can->caaaaaar(1) } 'too deep';
dies_ok { $can->escape_from("a fiendish death trap") } 'No Bond, ';

plan tests => 8;
