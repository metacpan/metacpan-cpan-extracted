use strict;
use warnings;
use utf8;
use B::Deparse;
use B;
use B::Tap;
use B::Tools qw(op_walk);
use Test::More;

# ref. https://github.com/Perl/perl5/blob/blead/pod/perl5217delta.pod
plan skip_all => "B::Deparse >= 1.35 can't parse optree modified by B::Tap." if $B::Deparse::VERSION >= 1.35;

# B::Deparse thinks OP_ENTERSUB's next op must be LISTOP.

my $mech;
test(sub { foo->bar });
test(sub { foo($mech) });

{
    my $x = 0;
    test(sub { 0+$x->y->{z} } );
}

done_testing;

sub test {
    my ($code) = @_;

    if ($ENV{DEBUG}) {
        note "-- BEFORE:";
        require B::Concise;
        my $walker = B::Concise::compile('', '', $code);
        $walker->();
    }

    my $cv = B::svref_2object($code);

    my $root = $cv->ROOT;

    my @buf;
    op_walk {
        if (1 && $_->name eq 'padsv') {
            tap($_, $cv->ROOT, \@buf);
        }
    } $cv->ROOT;

    if ($ENV{DEBUG}) {
        note "-- AFTER:";
        require B::Concise;
        my $walker = B::Concise::compile('', '', $code);
        $walker->();
    }

    my $deparse = B::Deparse->new();
    my $text = $deparse->coderef2text($code);
    ok $text;
    note $text;
}
