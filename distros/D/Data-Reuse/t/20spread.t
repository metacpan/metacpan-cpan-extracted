
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 21;
use strict;
use warnings;
 
# the module we need
use Data::Reuse qw(spread);

sub is_ro { Internals::SvREADONLY $_[0] } #is_ro

my @keys = qw(foo bar baz);
spread my %hash => undef, => @keys;

ok !defined $hash{$_} foreach @keys;
ok is_ro( $hash{$_} ) foreach @keys;
my $address = \$hash{ $keys[0] };
is \$hash{$_}, $address foreach @keys[ 1 .. $#keys ];

my @elements = 0 .. 3;
spread my @list => 1 => @elements;

is $list[$_], 1 foreach @elements;
ok is_ro( $list[$_] ) foreach @elements;
$address = \$list[ $elements[0] ];
is \$list[$_], $address foreach @elements[ 1 .. $#elements ];

eval ' spread ';
like $@, qr#^Not enough arguments for Data::Reuse::spread#;

eval ' spread %hash ';
like $@, qr#^Must specify a value as second parameter to spread#;
