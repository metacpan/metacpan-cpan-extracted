BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;

use Test::More tests => 2;

use_ok( 'Class::ExtraAttributes' ); # just for the record
can_ok( 'Class::ExtraAttributes',qw(
 attributes
) );
