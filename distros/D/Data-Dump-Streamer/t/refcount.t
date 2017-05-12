use Test::More tests => 18;
use Devel::Peek;

#$Id: refcount.t 26 2006-04-16 15:18:52Z demerphq $#

BEGIN { use_ok( 'Data::Dump::Streamer',
            qw(refcount sv_refcount is_numeric looks_like_number weak_refcount weaken isweak));
}

my $sv="Foo";
my $rav=[];
my $rhv={};

is sv_refcount($sv),1,"sv_refcount";
is refcount($rav),1,"refcount av";
is refcount($rhv),1,"refcount hv";

is refcount(\$sv),2,'refcount \\$foo';

my $ref=\$sv;

is sv_refcount($sv),2,'sv_refcount after';
is refcount(\$sv),3,'refcount after';

SKIP: {
    skip ( "No Weak Refs", 3 )
        unless eval { weaken($ref) };

    is isweak($ref),1,"is weakened";
    is sv_refcount($sv),2,"weakened sv_refcount";
    is weak_refcount($sv),1,"weak_refcount";
    is refcount(\$sv),3,"weakened refcount";
}

{
    use strict;
    my $sv="Foo";
    my $iv=100;
    my $nv=1.234;
    my $dbl=1e40;

    my %hash=(100=>1,1.234=>1,1e40=>1);

    for my $t ( [$sv,''],
                [$iv,1], [$nv,1],
                [$dbl,1],
                map {[$_,'']} keys %hash
    ){
        is is_numeric($t->[0]),$t->[1],"Test:".$t->[0];
    }
}
__END__
