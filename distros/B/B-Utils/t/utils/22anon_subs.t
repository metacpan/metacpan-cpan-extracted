#!perl
use Test::More tests => 2;
use B 'svref_2object';
use B::Utils 'anon_subs';

my $sub = sub {
    my $arg = shift;
    return sub { time - 10 }
};
my $found = svref_2object( $sub );

{
    # List context
    my @subs = anon_subs();

    is( scalar grep( ${$found->START} == ${$_->{start}}
		     && ${$found->ROOT} == ${$_->{root}},
		     @subs ),
	1,
        "Found correct anon sub" );
}
{
    # List context
    my $subs = anon_subs();
    is( scalar grep( ${$found->START} == ${$_->{start}}
		     && ${$found->ROOT} == ${$_->{root}},
		     @$subs ),
	1,
        "Found correct anon sub" );
}
