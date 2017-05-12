#!perl -Tw

use Test::More tests => 26;

use Carp::Assert::More;

my @funcs = ( @Carp::Assert::More::EXPORT, @Carp::Assert::More::EXPORT_OK );

my %deduped;
$deduped{$_}++ for @funcs;
@funcs = sort keys %deduped;

isnt( scalar @funcs, 0, 'There are no function names!' );

for my $func ( @funcs ) {
    my $filename = "t/$func.t";
    ok( -e $filename, "$filename exists" );
}
