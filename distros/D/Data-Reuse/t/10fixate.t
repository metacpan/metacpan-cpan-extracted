
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 34;
use strict;
use warnings;
 
# the module we need
use Data::Reuse qw(fixate);

sub is_ro { Internals::SvREADONLY $_[0] } #is_ro

fixate my @keys => qw(foo bar baz);
ok is_ro( $_ ) foreach @keys;

eval { push @keys,'zip' };
like $@, qr#^Modification of a read-only value attempted#;

fixate my %hash => ( foo => 1, bar => 1, baz => 1 );
ok is_ro( $hash{$_} ) foreach @keys;
is 1, $hash{$_}       foreach @keys;
my $address = \$hash{ $keys[0] };
is \$hash{$_}, $address foreach @keys[ 1 .. $#keys ];
eval { $hash{zip} = 1 };
like $@, qr#^Attempt to access disallowed key 'zip' in a restricted hash#;

my %filled_hash = ( foo => 1, bar => 1, baz => 1 );
fixate %filled_hash;
ok is_ro( $filled_hash{$_} ) foreach @keys;
is 1, $filled_hash{$_}       foreach @keys;

$address = \$filled_hash{ $keys[0] };
is \$filled_hash{$_}, $address foreach @keys[ 1 .. $#keys ];

eval { $filled_hash{zip} = 1 };
like $@, qr#^Attempt to access disallowed key 'zip' in a restricted hash#;

my @copy = @keys;
ok !is_ro( $_ ) foreach @copy;

isnt \$copy[$_], \$keys[$_] foreach 0 .. $#keys;
fixate @copy;
is \$copy[$_], \$keys[$_] foreach 0 .. $#keys;

eval { push @copy,'zip' };
like $@, qr#^Modification of a read-only value attempted#;

my $scalar = 1;
eval ' fixate $scalar ';
like $@, qr#^Type of arg 1 to Data::Reuse::fixate must be one of \[@%\] \(not private variable\)#;

eval { &fixate( $scalar ) };
like $@, qr#Must specify a hash or array as first parameter to fixate#;
